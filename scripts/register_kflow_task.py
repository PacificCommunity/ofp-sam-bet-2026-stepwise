#!/usr/bin/env python3
"""Register or refresh a Kflow task from a repository kflow.yaml."""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import re
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[1]


def run_git(repo_root: Path, *args: str) -> str:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_root), *args],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return ""
    return result.stdout.strip()


def repo_full_name(repo_root: Path) -> str:
    remote = run_git(repo_root, "remote", "get-url", "origin")
    if remote.endswith(".git"):
        remote = remote[:-4]
    if remote.startswith("git@github.com:"):
        return remote.split(":", 1)[1]
    marker = "github.com/"
    if marker in remote:
        return remote.split(marker, 1)[1].strip("/")
    return ""


def read_yaml(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a YAML mapping")
    return data


def effective_local_apps(config: dict[str, Any]) -> list[dict[str, Any]]:
    """Use the shared launcher for model-producing task-specific configs."""
    if "local_apps" in config:
        apps = config.get("local_apps") or []
        return apps if isinstance(apps, list) else []
    output_patterns = [str(value) for value in config.get("output_patterns") or []]
    produces_models = any(
        pattern == "outputs/models/**" or pattern.startswith("outputs/models/")
        for pattern in output_patterns
    )
    if not produces_models:
        return []
    shared = read_yaml(ROOT / "kflow.yaml").get("local_apps") or []
    return shared if isinstance(shared, list) else []


def api_json(
    method: str,
    url: str,
    token: str,
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    headers = {"Authorization": f"Bearer {token}"}
    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: HTTP {exc.code}: {detail}") from exc
    if not raw:
        return {}
    return json.loads(raw.decode("utf-8"))


def existing_report(base_url: str, token: str, task_name: str) -> dict[str, Any]:
    try:
        task_path = urllib.parse.quote(task_name, safe="")
        payload = api_json("GET", f"{base_url}/api/report/{task_path}", token)
    except Exception:
        return {}
    report = payload.get("report", payload)
    return report if isinstance(report, dict) else {}


def first_present(*values: Any) -> Any:
    for value in values:
        if value not in (None, ""):
            return value
    return None


def truthy(value: Any) -> bool:
    return str(value or "").strip().lower() in {"1", "true", "yes", "y", "on"}


def read_model_rows(repo_root: Path, config: dict[str, Any]) -> list[dict[str, str]]:
    campaign = config.get("model_campaign") or {}
    if not isinstance(campaign, dict) or not campaign:
        return []
    source = repo_root / str(campaign.get("rows_source") or "job-config.R")
    if not source.is_file():
        raise ValueError(f"Model row source does not exist: {source}")
    r_code = r'''
args <- commandArgs(trailingOnly = TRUE)
cfg <- new.env(parent = baseenv())
sys.source(args[[1]], envir = cfg)
if (!exists("stepwise_models", envir = cfg, inherits = FALSE)) {
  stop("stepwise_models was not defined by ", args[[1]], call. = FALSE)
}
rows <- get("stepwise_models", envir = cfg, inherits = FALSE)
if (!is.data.frame(rows)) stop("stepwise_models must be a data.frame", call. = FALSE)
if ("enabled" %in% names(rows)) {
  enabled <- as.logical(rows$enabled)
  enabled[is.na(enabled)] <- FALSE
  rows <- rows[enabled, , drop = FALSE]
}
utils::write.csv(rows, stdout(), row.names = FALSE, na = "")
'''
    result = subprocess.run(
        ["Rscript", "--vanilla", "-e", r_code, str(source)],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    rows = [
        {str(key): str(value or "").strip() for key, value in row.items()}
        for row in csv.DictReader(io.StringIO(result.stdout))
    ]
    required = ("step_id", "job_key", "job_title", "model_label")
    if not rows:
        raise ValueError("The model campaign has no enabled rows.")
    for field in required:
        values = [row.get(field, "") for row in rows]
        if any(not value for value in values):
            raise ValueError(f"Every enabled model row must define {field}.")
        if len(values) != len(set(values)):
            raise ValueError(f"Enabled model rows must have unique {field} values.")
    if any(row["step_id"].lower() in {"all", "*"} for row in rows):
        raise ValueError("Campaign rows may never use STEP_SELECT=all or STEP_SELECT=*.")
    return rows


def validate_immutable_campaign(config: dict[str, Any], rows: list[dict[str, str]]) -> None:
    if not rows:
        return
    image = str(config.get("docker_image") or "")
    if not re.fullmatch(r"[^@\s]+@sha256:[0-9a-fA-F]{64}", image):
        raise ValueError("Campaign docker_image must use an immutable sha256 digest.")
    if str(config.get("remote_host") or "").strip().lower() != "suva":
        raise ValueError("Campaign remote_host must explicitly be suva.")
    requirement = str(config.get("slot_requirements") or "").strip()
    if "suvofp" not in requirement.lower():
        raise ValueError("Campaign slot_requirements must explicitly select Suva nodes.")
    resources = config.get("resources") or {}
    for field in ("cpus", "memory", "disk"):
        if resources.get(field) in (None, ""):
            raise ValueError(f"Campaign resources.{field} must be explicit.")
    if not config.get("output_patterns"):
        raise ValueError("Campaign output_patterns must be explicit.")
    env = config.get("env") or {}
    if str(env.get("STEP_SELECT") or "").strip().lower() in {"", "all", "*"}:
        raise ValueError("The public task default STEP_SELECT must name one model row.")
    if truthy(env.get("TRIGGER_NEXT")):
        raise ValueError("Campaign TRIGGER_NEXT must be false.")
    if config.get("triggers"):
        raise ValueError("Independent fit jobs must not define per-fit triggers.")
    specs = str(env.get("KFLOW_REPO_RUNTIME_PACKAGES") or "").split(",")
    expected_refs: dict[str, str] = {}
    for spec in specs:
        match = re.fullmatch(r"([^=\s]+)=([^@\s]+)@([0-9a-fA-F]{40})", spec.strip())
        if not match:
            raise ValueError(f"Runtime package spec is not pinned to a full commit SHA: {spec}")
        expected_refs[match.group(1)] = match.group(3).lower()
    for package, env_name in (("mfclkit", "MFCLKIT_GITHUB_REF"), ("mfclshiny", "MFCLSHINY_GITHUB_REF")):
        ref = str(env.get(env_name) or "").lower()
        if expected_refs.get(package) != ref:
            raise ValueError(f"{env_name} must exactly match the pinned {package} package spec.")


def scientific_parent(rows: list[dict[str, str]], index: int) -> str:
    configured = rows[index].get("scientific_parent", "")
    if configured:
        return configured
    return rows[index - 1]["step_id"] if index else ""


def model_job_payloads(config: dict[str, Any], rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    if not rows:
        return []
    resources = config["resources"]
    base_env = dict(config.get("env") or {})
    count = len(rows)
    payloads: list[dict[str, Any]] = []
    for index, row in enumerate(rows):
        parent = scientific_parent(rows, index)
        description = (
            f"Independent frozen-input fit {index + 1} of {count}: "
            f"{row['model_label']} ({row['step_id']})."
        )
        if parent:
            description += f" Scientific parent {parent} is provenance metadata only."
        env = {
            **base_env,
            "STEP_SELECT": row["step_id"],
            "STEPWISE_ALLOW_SEQUENTIAL_ALL": "false",
            "JOB_KEY": row["job_key"],
            "JOB_TITLE": row["job_title"],
            "MODEL_LABEL": row["model_label"],
            "JOB_DESCRIPTION": description,
            "TRIGGER_NEXT": "false",
            "KFLOW_JOB_MEMORY": row.get("kflow_memory") or str(resources["memory"]),
        }
        for column, env_name in (
            ("run_mode", "RUN_MODE"),
            ("input_par", "INPUT_PAR"),
            ("frq", "FRQ"),
            ("output_par", "OUTPUT_PAR"),
            ("mfcl_program_path", "PROGRAM_PATH"),
        ):
            if row.get(column):
                env[env_name] = row[column]
        metadata = {
            **dict(config.get("metadata") or {}),
            "campaign_row": index + 1,
            "campaign_row_count": count,
            "job_description": description,
            "scientific_parent": parent,
            "scientific_parent_mode": "metadata-only",
            "inputs_frozen": True,
            "major_step": row.get("major_step", ""),
            "substep": row.get("substep", ""),
            "change_axis": row.get("change_axis", ""),
        }
        payloads.append(
            {
                "docker_image": config["docker_image"],
                "remote_host": config["remote_host"],
                "remote_user": config.get("remote_user"),
                "remote_base_dir": config.get("remote_base_dir"),
                "slot_requirements": config["slot_requirements"],
                "cpus": resources["cpus"],
                "memory": row.get("kflow_memory") or resources["memory"],
                "disk": resources["disk"],
                "batch_name": str(base_env.get("FLOW_GROUP") or "BET stepwise independent fits"),
                "output_patterns": list(config["output_patterns"]),
                "input_jobs": [],
                "env": env,
                "tags": {
                    **dict(config.get("tags") or {}),
                    "stage": "stepwise-fit",
                    "step": row["step_id"],
                    "job_key": row["job_key"],
                    "model_label": row["model_label"],
                    "independent_fit": "true",
                    "inputs_frozen": "true",
                },
                "metadata": {key: value for key, value in metadata.items() if value not in (None, "")},
                "triggers": {},
            }
        )
    return payloads


def build_payload(
    config: dict[str, Any],
    repo_root: Path,
    existing: dict[str, Any],
    args: argparse.Namespace,
    rows: list[dict[str, str]] | None = None,
) -> dict[str, Any]:
    task_name = args.task_name or config.get("name")
    if not task_name:
        raise ValueError("Task name is missing; set name in kflow.yaml or pass --task-name.")

    resources = config.get("resources") or {}
    metadata = dict(config.get("metadata") or {})
    rows = rows or []
    if rows:
        metadata["model_campaign"] = {
            **dict(config.get("model_campaign") or {}),
            "model_count": len(rows),
            "execution": "independent-concurrent",
            "inputs": "frozen",
            "scientific_parent": "metadata-only",
        }
        metadata["model_rows"] = [
            {
                "step_select": row["step_id"],
                "job_key": row["job_key"],
                "job_title": row["job_title"],
                "model_label": row["model_label"],
                "memory": row.get("kflow_memory") or resources.get("memory"),
                "scientific_parent": scientific_parent(rows, index),
            }
            for index, row in enumerate(rows)
        ]
    if config.get("job_config") is not None:
        metadata["job_config"] = config["job_config"]
    # Task-specific model configs inherit the shared launcher so completed jobs
    # do not lose mfclshiny merely because their compact YAML omits the block.
    # Explicit local_apps: [] still disables launchers for a particular task.
    metadata["local_apps"] = effective_local_apps(config)

    branch = first_present(args.branch, config.get("branch"), run_git(repo_root, "branch", "--show-current"), "main")
    full_name = first_present(args.repo_full_name, config.get("repo_full_name"), repo_full_name(repo_root))

    payload: dict[str, Any] = {
        "name": task_name,
        "description": (
            f"{str(config.get('description') or '').rstrip()} "
            f"Configured from {len(rows)} enabled independent model rows."
            if rows
            else config.get("description", "")
        ),
        "repo_full_name": full_name,
        "branch": branch,
        "make_target": config.get("make_target", existing.get("make_target", "all")),
        "command": config.get("command", existing.get("command")),
        "target_folder": config.get("target_folder", existing.get("target_folder", "")),
        "docker_image": config.get("docker_image", existing.get("docker_image")),
        "cpus": resources.get("cpus", existing.get("cpus")),
        "memory": resources.get("memory", existing.get("memory")),
        "disk": resources.get("disk", existing.get("disk")),
        "stream_error": config.get("stream_error", existing.get("stream_error", True)),
        "ghcr_login": config.get("ghcr_login", existing.get("ghcr_login", False)),
        "slot_requirements": config.get("slot_requirements", existing.get("slot_requirements", "")),
        # Do not preserve stale node exclusions from an existing Kflow task.
        # If a repo wants a fixed exclusion it must say so explicitly in
        # kflow.yaml; otherwise the registered task should launch without
        # manual exclusions and let scheduler-health auto-exclude bad nodes.
        "exclude_machines": config.get("exclude_machines", []),
        "exclude_slots": config.get("exclude_slots", []),
        "env": config.get("env", {}),
        "tags": config.get("tags", {}),
        "metadata": metadata,
        "output_patterns": config.get("output_patterns", []),
        "artifacts": config.get("artifacts", []),
        "input_jobs": config.get("input_jobs", []),
        "triggers": config.get("triggers", {}),
    }

    checkout = config.get("checkout", existing.get("checkout"))
    if checkout is not None:
        payload["checkout"] = checkout

    for key, env_name in (
        ("owner_login", "KFLOW_OWNER_LOGIN"),
        ("remote_user", "KFLOW_REMOTE_USER"),
        ("remote_host", "KFLOW_REMOTE_HOST"),
        ("remote_base_dir", "KFLOW_REMOTE_BASE_DIR"),
    ):
        value = first_present(config.get(key), os.environ.get(env_name), existing.get(key))
        if value is not None:
            payload[key] = value

    return {key: value for key, value in payload.items() if value is not None}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="kflow.yaml", help="Path to kflow.yaml.")
    parser.add_argument("--repo-root", default=".", help="Repository root used for git metadata.")
    parser.add_argument("--task-name", default="", help="Override the task name from kflow.yaml.")
    parser.add_argument("--repo-full-name", default="", help="Override GitHub owner/repo.")
    parser.add_argument("--branch", default="", help="Override branch.")
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument("--dry-run", action="store_true", help="Print payload without registering.")
    parser.add_argument(
        "--submit-model-rows",
        action="store_true",
        help="After task registration, submit all enabled model rows as independent concurrent jobs.",
    )
    return parser.parse_args()


def submit_model_rows(
    base_url: str,
    token: str,
    task_name: str,
    payloads: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    task_path = urllib.parse.quote(task_name, safe="")
    results: list[dict[str, Any] | None] = [None] * len(payloads)
    failures: list[str] = []
    with ThreadPoolExecutor(max_workers=len(payloads)) as executor:
        futures = {
            executor.submit(api_json, "POST", f"{base_url}/api/job/{task_path}", token, payload): index
            for index, payload in enumerate(payloads)
        }
        for future in as_completed(futures):
            index = futures[future]
            step = str(payloads[index]["env"]["STEP_SELECT"])
            try:
                results[index] = future.result()
            except Exception as exc:
                failures.append(f"{step}: {exc}")
    if failures:
        raise RuntimeError(
            "Some model rows failed to submit after all independent submissions were attempted: "
            + " | ".join(failures)
        )
    return [result or {} for result in results]


def main() -> int:
    args = parse_args()
    repo_root = (ROOT / args.repo_root).resolve()
    config_path = (ROOT / args.config).resolve()
    token = os.environ.get("KFLOW_API_TOKEN", "")
    base_url = args.kflow_url.rstrip("/")

    config = read_yaml(config_path)
    task_name = args.task_name or config.get("name")
    if not task_name:
        raise SystemExit("Task name is missing.")

    rows = read_model_rows(repo_root, config)
    validate_immutable_campaign(config, rows)
    job_payloads = model_job_payloads(config, rows)

    existing = {}
    if token:
        existing = existing_report(base_url, token, task_name)
    payload = build_payload(config, repo_root, existing, args, rows=rows)

    if args.dry_run:
        print(json.dumps({"task": payload, "model_jobs": job_payloads}, indent=2, sort_keys=True))
        return 0

    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before registering Kflow tasks.")

    task_path = urllib.parse.quote(task_name, safe="")
    response = api_json("POST", f"{base_url}/api/report/{task_path}", token, payload)
    report = response.get("report", response)
    code = report.get("code", task_name) if isinstance(report, dict) else task_name
    repo = payload.get("repo_full_name", "")
    branch = payload.get("branch", "")
    print(f"registered {code}: {repo}@{branch}")

    if args.submit_model_rows:
        submitted = submit_model_rows(base_url, token, task_name, job_payloads)
        for index, item in enumerate(submitted):
            job = item.get("job", item) if isinstance(item, dict) else {}
            job_ref = job.get("job_number", job.get("id", "submitted")) if isinstance(job, dict) else "submitted"
            print(f"submitted {job_payloads[index]['env']['STEP_SELECT']}: {job_ref}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
