#!/usr/bin/env python3
"""Launch the isolated Step 12 OPR terminal-penalty/LF sensitivity flow.

Each explicitly configured model gets one fit job.  With ``--fits-only`` the
launcher stops there so screening fits can be inspected before diagnostics are
chosen.  Otherwise it submits the queue-safe Hessian partition count (two
parts for at most 50 selected models, otherwise one), one merge per model, and
one final BET results job.
The Hessian merge publishes its diagnostic delta directly onto the originating
fit, so no separate attachment job is created.

Examples:
  python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --dry-run
  python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --dry-run --limit 1
  python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --fits-only
  python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py
  python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --resume \
    --manifest work/<flow-group>-launch.json
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import getpass
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_STEPWISE_TASK = "ofp-sam-bet-2026-stepwise-opr-terminal-penalty-lf"
DEFAULT_RESULTS_TASK = "ofp-sam-bet-2026-results"
DEFAULT_CHECK_PREFIX = "ofp-sam-bet-2026-check"
DEFAULT_MODEL_REPO = "PacificCommunity/ofp-sam-bet-2026-stepwise"
DEFAULT_BRANCH = "experiment/step12-opr-terminal-penalty-lf-sensitivity"
GRID_CODE = "opr-terminal-penalty-lf"
GRID_LABEL = "Step 12 OPR terminal-penalty and LF/selectivity"
MANIFEST_SCHEMA = "bet-2026-opr-terminal-penalty-lf-launch-v3"
DEFAULT_MFCLKIT_REF = "5075c9a4ab5e14b4b725e4135deabfb474da3681"
DEFAULT_MFCLSHINY_REF = "65cf0aff15f5fd85ce96fda8c5bd89e9e2a6afe7"
DEFAULT_SUVA_HOST = "suvofpsubmit.corp.spc.int"
DEFAULT_SUVA_USER = (
    os.environ.get("KFLOW_REMOTE_USER")
    or os.environ.get("USER")
    or getpass.getuser()
)
DEFAULT_SUVA_BASE_DIR = os.environ.get(
    "KFLOW_REMOTE_BASE_DIR",
    f"/home/{DEFAULT_SUVA_USER}/KflowOutput",
)
SELECTOR_ENV = "OPR_TERMINAL_PENALTY_LF_SELECTOR"
SELECTOR_CONFIG_KEYS = (
    "opr_terminal_penalty_lf_sensitivity_step_select",
    "step12_opr_terminal_penalty_lf_sensitivity_step_select",
)


def split_values(value: str) -> list[str]:
    return [
        part.strip()
        for part in str(value or "").replace("\n", ",").split(",")
        if part.strip()
    ]


def verify_remote_branch(branch: str) -> None:
    result = subprocess.run(
        ["git", "ls-remote", "--exit-code", "origin", f"refs/heads/{branch}"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        detail = result.stderr.strip() or "branch not found at origin"
        raise RuntimeError(f"Push {branch!r} before submitting Kflow jobs: {detail}")


def configured_models(selector: str = "") -> list[dict[str, str]]:
    """Resolve only the explicit sensitivity rows declared by job-config.R."""
    expression = r'''
source("R/stepwise_config_helpers.R")
source_stepwise_config("job-config.R")
selection <- Sys.getenv("OPR_TERMINAL_PENALTY_LF_SELECTOR", "")
if (!nzchar(selection)) {
  keys <- c(
    "opr_terminal_penalty_lf_sensitivity_step_select",
    "step12_opr_terminal_penalty_lf_sensitivity_step_select"
  )
  for (key in keys) {
    candidate <- stepwise_value(key, "")
    if (nzchar(candidate)) {
      selection <- candidate
      break
    }
  }
}
if (!nzchar(selection)) {
  stop(
    "job-config.R must define opr_terminal_penalty_lf_sensitivity_step_select",
    call. = FALSE
  )
}
rows <- stepwise_selected_models(selection)
needed <- c(
  "step_id", "model_label", "job_title", "job_key", "major_step", "substep",
  "change_axis", "run_mode", "kflow_memory", "source_dir"
)
for (name in setdiff(needed, names(rows))) rows[[name]] <- ""
utils::write.csv(rows[, needed, drop = FALSE], row.names = FALSE, quote = TRUE)
'''
    env = dict(os.environ)
    env[SELECTOR_ENV] = selector
    result = subprocess.run(
        ["Rscript", "-e", expression],
        cwd=ROOT,
        env=env,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    rows = list(csv.DictReader(result.stdout.splitlines()))
    if not rows:
        raise RuntimeError(
            "No OPR terminal-penalty/LF sensitivity rows were resolved from job-config.R."
        )
    rows = [{key: str(value or "") for key, value in row.items()} for row in rows]

    step_ids = [row["step_id"] for row in rows]
    job_keys = [row["job_key"] for row in rows if row["job_key"]]
    duplicate_steps = sorted({value for value in step_ids if step_ids.count(value) > 1})
    duplicate_job_keys = sorted({value for value in job_keys if job_keys.count(value) > 1})
    if duplicate_steps or duplicate_job_keys:
        details = []
        if duplicate_steps:
            details.append("duplicate step IDs: " + ", ".join(duplicate_steps))
        if duplicate_job_keys:
            details.append("duplicate job keys: " + ", ".join(duplicate_job_keys))
        raise RuntimeError("Invalid sensitivity selection; " + "; ".join(details))

    requested = split_values(selector)
    if any(value.lower() in {"all", "*"} for value in requested):
        raise RuntimeError(
            "--models must contain explicit sensitivity step IDs; omit it to run "
            "the complete configured sensitivity set."
        )
    if requested:
        missing_requested = [value for value in requested if value not in step_ids]
        if missing_requested:
            raise RuntimeError("Unknown selected model(s): " + ", ".join(missing_requested))

    invalid_folders: list[str] = []
    for row in rows:
        step = row["step_id"]
        step_dir = ROOT / "steps" / step
        direct_script = step_dir / "model" / "doitall.sh"
        if direct_script.is_file():
            continue

        # Generated sensitivities are intentionally thin: the normal runner
        # copies source_dir, applies patch.R, and only then executes the
        # parent's doitall.sh. Requiring a duplicated model/ directory here
        # would defeat that compact design and reject every generated row.
        patch_file = step_dir / "patch.R"
        config_file = step_dir / "config.env"
        source_dir = str(row.get("source_dir") or "").strip()
        if not patch_file.is_file() or not config_file.is_file() or not source_dir:
            invalid_folders.append(step)
            continue
        source_path = Path(source_dir)
        candidates = (
            [source_path]
            if source_path.is_absolute()
            else [step_dir / source_path, ROOT / source_path]
        )
        resolved_source = next((path for path in candidates if path.is_dir()), None)
        if resolved_source is None or not (resolved_source / "doitall.sh").is_file():
            invalid_folders.append(step)

    if invalid_folders:
        raise RuntimeError(
            "Selected model folder(s) lack either model/doitall.sh or a valid "
            "thin patch/config with a parent doitall.sh: "
            + ", ".join(invalid_folders)
        )
    return rows


def model_selection_signature(models: list[dict[str, str]]) -> str:
    """Fingerprint the ordered launch configuration used by a manifest."""
    canonical = [
        {key: str(row.get(key) or "") for key in sorted(row)}
        for row in models
    ]
    encoded = json.dumps(
        canonical,
        ensure_ascii=True,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def resolve_hessian_nsplit(model_count: int, requested: str | int = "auto") -> int:
    """Apply the agreed queue policy and reject contradictory overrides."""
    if model_count < 1:
        raise ValueError("At least one selected model is required.")
    expected = 1 if model_count > 50 else 2
    text = str(requested).strip().lower()
    if text == "auto":
        return expected
    selected = int(text)
    if selected != expected:
        relation = "more than 50" if model_count > 50 else "at most 50"
        raise ValueError(
            f"{model_count} selected models ({relation}) require Hessian nsplit={expected}."
        )
    return selected


def api_json(
    method: str,
    url: str,
    token: str,
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    headers = {"Authorization": f"Bearer {token}"}
    body = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: HTTP {exc.code}: {detail}") from exc
    if not raw:
        return {}
    return json.loads(raw.decode("utf-8"))


def report_exists(base_url: str, token: str, task: str) -> dict[str, Any]:
    response = api_json("GET", f"{base_url}/api/report/{task}", token)
    report = response.get("report", response)
    if not isinstance(report, dict):
        raise RuntimeError(f"Kflow task {task!r} returned an invalid task record.")
    return report


def api_job(base_url: str, token: str, ref: str) -> dict[str, Any]:
    normalized_ref = str(ref or "").strip().lstrip("#")
    if not normalized_ref:
        raise ValueError("A non-empty Kflow job reference is required.")
    response = api_json("GET", f"{base_url}/api/job/{normalized_ref}", token)
    job = response.get("job", response)
    if not isinstance(job, dict):
        raise RuntimeError(f"Kflow job {normalized_ref!r} returned an invalid job record.")
    return job


def attached_output_ref(value: Any) -> str:
    if isinstance(value, dict):
        value = value.get("output_job") or value.get("job") or value.get("job_number") or ""
    return str(value or "").strip().lstrip("#")


def attached_work_slot_key(value: Any) -> str:
    text = str(value or "").strip().lower()
    return re.sub(r"[^a-z0-9_.-]+", "-", text).strip("-_.")


def latest_attached_output_job_for_slot(
    base_url: str,
    token: str,
    base_job: str,
    slot: str,
) -> str:
    """Return a completed predecessor from exactly the same diagnostic slot."""
    normalized_base = str(base_job or "").strip().lstrip("#")
    slot_key = attached_work_slot_key(slot)
    if not normalized_base or not slot_key:
        raise ValueError("A base job and diagnostic slot are required.")

    parent = api_job(base_url, token, normalized_base)
    metadata = parent.get("metadata") if isinstance(parent.get("metadata"), dict) else {}
    latest_by_slot = metadata.get("attached_work_latest_by_slot")
    if latest_by_slot in (None, ""):
        return ""
    if not isinstance(latest_by_slot, dict):
        raise RuntimeError(
            f"Kflow job {normalized_base} has invalid attached_work_latest_by_slot metadata."
        )

    predecessor = ""
    for recorded_slot, value in latest_by_slot.items():
        if attached_work_slot_key(recorded_slot) == slot_key:
            predecessor = attached_output_ref(value)
            break
    if not predecessor:
        return ""
    if predecessor == normalized_base:
        raise RuntimeError(
            f"Kflow job {normalized_base} points diagnostic slot {slot!r} back to itself."
        )

    child = api_job(base_url, token, predecessor)
    child_metadata = child.get("metadata") if isinstance(child.get("metadata"), dict) else {}
    child_parent = str(child_metadata.get("attached_work_parent_job") or "").strip().lstrip("#")
    child_slot = attached_work_slot_key(child_metadata.get("attached_work_slot"))
    child_status = str(child.get("status") or "").strip().lower()
    if child_parent != normalized_base or child_slot != slot_key:
        raise RuntimeError(
            f"Kflow diagnostic slot {slot!r} points to unrelated output job {predecessor}."
        )
    if child_status not in {"success", "completed"}:
        raise RuntimeError(
            f"Kflow diagnostic slot {slot!r} points to non-completed output job "
            f"{predecessor} ({child_status or 'unknown status'})."
        )
    return predecessor


def submitted_job(response: dict[str, Any], task: str) -> dict[str, str]:
    job = response.get("job", response)
    if not isinstance(job, dict):
        raise RuntimeError(f"Kflow task {task!r} returned an invalid job record.")
    number = job.get("job_number") or job.get("number") or job.get("code")
    if number in (None, "", "?"):
        raise RuntimeError(f"Kflow task {task!r} did not return a job number: {job}")
    return {
        "job_number": str(number),
        "job_id": str(job.get("id") or ""),
        "status": str(job.get("status") or ""),
    }


def submitter_fields(args: argparse.Namespace) -> dict[str, str]:
    return {
        "remote_host": args.remote_host,
        "remote_user": args.remote_user,
        "remote_base_dir": args.remote_base_dir,
    }


def runtime_packages() -> str:
    return (
        f"mfclkit=PacificCommunity/ofp-sam-mfclkit@{DEFAULT_MFCLKIT_REF},"
        f"mfclshiny=PacificCommunity/mfclshiny@{DEFAULT_MFCLSHINY_REF}"
    )


def fit_payload(
    row: dict[str, str], args: argparse.Namespace, branch: str
) -> dict[str, Any]:
    step = row["step_id"]
    title = f"Step 12 sensitivity: {row['job_title'] or step}"
    description = row["change_axis"] or f"{GRID_LABEL} sensitivity {step}."
    memory = row["kflow_memory"] or "8GB"
    env = {
        "STEP_SELECT": step,
        "STEPWISE_ALLOW_DISABLED_SELECTED": "true",
        "RUN_MODE": row["run_mode"] or "doitall",
        "FLOW_GROUP": args.flow_group,
        "TRIGGER_NEXT": "false",
        "BET_PHASE10_11_CONVERGENCE": args.phase_convergence,
        "MFCL_LIVE_LOG": "true",
        "KFLOW_JOB_MEMORY": memory,
        "KFLOW_JOB_TITLE": title,
        "KFLOW_JOB_DESCRIPTION": description,
        "MODEL_LABEL": row["model_label"] or step,
        "JOB_KEY": f"{GRID_CODE}-{row['job_key'] or step.lower()}",
        "MAJOR_STEP": row["major_step"],
        "SUBSTEP": row["substep"],
        "CHANGE_AXIS": description,
        "STEPWISE_BUILD_PAYLOAD": "true",
        # Keep one exact, patched restart-input set with the base fit. The
        # fitted PAR remains embedded in model_payload.rds, and diagnostic
        # merges publish deltas only, so native inputs are not duplicated by
        # Hessian or results attachments.
        "STEPWISE_SAVE_RAW_MFCL_INPUTS": "true",
        "STEPWISE_SAVE_FINAL_PAR": "false",
        "STEPWISE_COMMIT_FINAL_PARS": "false",
        "STEPWISE_PUSH_FINAL_PARS": "false",
        "STEPWISE_PUBLISH_REQUIRED": "false",
        "KFLOW_RUNTIME_UPDATE": "never",
        "TUNA_FLOW_RUNTIME_UPDATE": "never",
        "KFLOW_REPO_RUNTIME_UPDATE": "auto",
        "KFLOW_RUNTIME_PACKAGES": "none",
        "KFLOW_REPO_RUNTIME_PACKAGES": runtime_packages(),
        "MFCLKIT_GITHUB_REF": DEFAULT_MFCLKIT_REF,
        "MFCLSHINY_GITHUB_REF": DEFAULT_MFCLSHINY_REF,
    }
    return {
        **submitter_fields(args),
        "repo": args.model_source_repo,
        "branch": branch,
        "memory": memory,
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "opr_terminal_penalty_lf_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "model_selector": step,
            "job_title": title,
            "job_description": description,
            "hessian_nsplit": args.hessian_nsplit,
            "launch_mode": "fits-only" if args.fits_only else "full",
            "trigger_next": False,
            "compact_model_payload": True,
            "raw_mfcl_inputs_saved": True,
        },
        "tags": {
            "stage": "stepwise",
            "flow": args.flow_group,
            "experiment": GRID_CODE,
            "model": step,
            "hessian_nsplit": str(args.hessian_nsplit),
        },
        "triggers": {},
    }


def check_runtime_env(
    row: dict[str, str],
    args: argparse.Namespace,
    branch: str,
    check_type: str,
    title: str,
    description: str,
) -> dict[str, str]:
    return {
        "CHECK_TYPE": check_type,
        "MODEL_SELECTOR": row["step_id"],
        "MODEL_SOURCE_REPO": args.model_source_repo,
        "MODEL_SOURCE_REF": branch,
        "PROGRAM_PATH": "/home/mfcl/mfclo64",
        "FLOW_GROUP": args.flow_group,
        "KFLOW_JOB_TITLE": title,
        "KFLOW_JOB_DESCRIPTION": description,
        "JOB_KEY": f"{GRID_CODE}-{check_type.replace('_', '-')}-{row['step_id'].lower()}",
        "KFLOW_RUNTIME_UPDATE": "never",
        "TUNA_FLOW_RUNTIME_UPDATE": "never",
        "KFLOW_REPO_RUNTIME_UPDATE": "auto",
        "KFLOW_RUNTIME_PACKAGES": "none",
        "KFLOW_REPO_RUNTIME_PACKAGES": runtime_packages(),
        "MFCLKIT_GITHUB_REF": DEFAULT_MFCLKIT_REF,
        "MFCLSHINY_GITHUB_REF": DEFAULT_MFCLSHINY_REF,
        "KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES": "true",
        "KFLOW_RUNTIME_GITHUB_AUTH": "true",
        "KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME": "true",
        "CHECK_COMPACT_OUTPUTS": "true",
        "CHECK_ENRICH_PAYLOADS": "true",
        "CHECK_KEEP_RAW_OUTPUTS": "false",
        "CHECK_BUILD_REPORT_FIGURES": "false",
        "CHECK_RENDER_REVIEW_HTML": "false",
    }


def hessian_payload(
    row: dict[str, str],
    args: argparse.Namespace,
    branch: str,
    fit_job: str,
    part: int,
) -> dict[str, Any]:
    title = f"Step 12 Hessian {part}/{args.hessian_nsplit}: {row['step_id']}"
    description = (
        f"Hessian partition {part}/{args.hessian_nsplit} for {GRID_LABEL} "
        f"sensitivity {row['step_id']}."
    )
    env = check_runtime_env(row, args, branch, "hessian", title, description)
    env.update(
        {
            "HESSIAN_NSPLIT": str(args.hessian_nsplit),
            "HESSIAN_PARTS": str(part),
            "HESSIAN_PART": str(part),
            "HESSIAN_COMPACT": "true",
            "CHECK_FAIL_ON_FAILED_UNITS": "true",
        }
    )
    return {
        **submitter_fields(args),
        "checkout": {"mode": "full"},
        "input_jobs": [fit_job],
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "opr_terminal_penalty_lf_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "check_type": "hessian",
            "model_selector": row["step_id"],
            "input_jobs": [fit_job],
            "input_jobs_override": True,
            "hessian_nsplit": args.hessian_nsplit,
            "hessian_part": part,
            "parallel_units": False,
        },
        "tags": {
            "stage": "checks",
            "flow": args.flow_group,
            "experiment": GRID_CODE,
            "check_type": "hessian",
            "model": row["step_id"],
            "hessian_part": str(part),
        },
    }


def hessian_merge_payload(
    row: dict[str, str],
    args: argparse.Namespace,
    branch: str,
    fit_job: str,
    hessian_jobs: list[str],
    previous_attached_output_job: str = "",
) -> dict[str, Any]:
    if len(hessian_jobs) != int(args.hessian_nsplit):
        raise ValueError(
            f"Hessian merge requires exactly {args.hessian_nsplit} Hessian job references."
        )
    input_jobs = list(
        dict.fromkeys(
            str(job).strip()
            for job in [fit_job, *hessian_jobs]
            if job is not None and str(job).strip()
        )
    )
    if not str(fit_job or "").strip() or len(input_jobs) != len(hessian_jobs) + 1:
        raise ValueError(
            "Hessian merge requires one fit and unique, non-empty Hessian job references."
        )

    title = f"Step 12 Hessian merge: {row['step_id']}"
    description = f"Merge Hessian output for {GRID_LABEL} sensitivity {row['step_id']}."
    hessian_job_refs = [str(job).strip().lstrip("#") for job in hessian_jobs]
    predecessor = str(previous_attached_output_job or "").strip().lstrip("#")
    env = check_runtime_env(row, args, branch, "hessian_merge", title, description)
    env.update(
        {
            "HESSIAN_NSPLIT": str(args.hessian_nsplit),
            "HESSIAN_MERGE_RUN": "true",
            "HESSIAN_MERGE_EIGEN": "true",
            "HESSIAN_KEEP_MATRIX": "false",
            "ATTACH_OUTPUT_MODE": "delta",
            "MODEL_BASE_INPUT_JOB": fit_job,
            "BASE_MODEL_JOB": fit_job,
            "MODEL_ORIGINAL_BASE_INPUT_JOB": fit_job,
            "CHECK_INPUT_JOBS": " ".join(hessian_job_refs),
            "ATTACH_CHECK_TYPES": "hessian",
            "ATTACH_UPDATED_CHECK_TYPES": "hessian",
        }
    )
    slot = f"diagnostics:{row['step_id']}:hessian"
    return {
        **submitter_fields(args),
        "checkout": {"mode": "full"},
        "input_jobs": input_jobs,
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "opr_terminal_penalty_lf_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "check_type": "hessian-merge",
            "merged_check_type": "hessian",
            "model_selector": row["step_id"],
            "base_job": fit_job,
            "check_input_jobs": hessian_job_refs,
            "attach_check_types": ["hessian"],
            "attached_check_types": ["hessian"],
            "attached_updated_check_types": ["hessian"],
            "input_jobs": input_jobs,
            "input_jobs_override": True,
            "allow_failed_input_jobs": True,
            "hessian_nsplit": args.hessian_nsplit,
            "parallel_units": False,
            "independent_diagnostic_merge": True,
            "direct_merge_attach": True,
            "attach_output_mode": "delta",
            "original_base_job": fit_job,
            "attach_base_input_job": fit_job,
            "overlay_base_input_job": fit_job,
            "attached_work_parent_job": fit_job,
            "attached_work_latest": True,
            "attached_output_overlay": True,
            "attached_output_overlay_mode": "diagnostics_with_payload",
            "attached_output_overlay_preserve_payload": True,
            "attached_output_overlay_replace_payload": True,
            "attached_output_overlay_replace_names": ["hessian"],
            "attached_work_group": f"{args.flow_group}:{row['step_id']}:diagnostics",
            "attached_work_slot": slot,
            "previous_attached_output_job": predecessor,
            "same_slot_predecessor_job": predecessor,
            "attached_work_headline": "Diagnostics",
            "attached_work_label": f"{row['step_id']} Hessian",
            "attached_work_summary": (
                "Merged Hessian diagnostic overlay for the originating sensitivity fit."
            ),
            "attached_work_role": "diagnostic overlay",
            "auto_attach": True,
        },
        "tags": {
            "stage": "checks",
            "flow": args.flow_group,
            "experiment": GRID_CODE,
            "check_type": "hessian-merge",
            "merge_for": "hessian",
            "model": row["step_id"],
            "base_job": fit_job,
            "attached_output_overlay": "true",
        },
    }


def results_payload(
    models: list[dict[str, str]],
    args: argparse.Namespace,
    model_jobs: list[str],
) -> dict[str, Any]:
    if len(model_jobs) != len(models) or any(not str(job).strip() for job in model_jobs):
        raise ValueError("Results require one Hessian merge job per selected model.")
    input_jobs = list(dict.fromkeys(str(job).strip() for job in model_jobs))
    if len(input_jobs) != len(models):
        raise ValueError("Results require unique Hessian merge jobs for every model.")

    title = f"BET Step 12 OPR terminal-penalty/LF results ({len(models)} models)"
    description = (
        "Build one standard BET results/MFCL Shiny bundle from the independent "
        "sensitivity fits and their Hessian diagnostic overlays."
    )
    env = {
        "TRIGGER_NEXT": "false",
        "FLOW_GROUP": args.flow_group,
        "JOB_TITLE": title,
        "JOB_DESCRIPTION": description,
        "JOB_KEY": f"{GRID_CODE}-results",
        "PLOT_TITLE": "BET 2026 Step 12 OPR terminal-penalty/LF sensitivity results",
        "MFCLSHINY_INTERACTIVE_VIEWER_TITLE": (
            "BET 2026 Step 12 OPR terminal-penalty/LF sensitivity viewer"
        ),
        "MFCLSHINY_INTERACTIVE_FIT_MODEL_LIMIT": "Inf",
        "PLOT_RENDER_REVIEW_HTML": "false",
        "KFLOW_RUNTIME_REQUIRE_PRIVATE_PACKAGES": "true",
        "KFLOW_RUNTIME_UPDATE": "never",
        "TUNA_FLOW_RUNTIME_UPDATE": "never",
        "KFLOW_REPO_RUNTIME_UPDATE": "auto",
        "KFLOW_RUNTIME_PACKAGES": "none",
        "KFLOW_REPO_RUNTIME_PACKAGES": runtime_packages(),
        "MFCLKIT_GITHUB_REF": DEFAULT_MFCLKIT_REF,
        "MFCLSHINY_GITHUB_REF": DEFAULT_MFCLSHINY_REF,
        "KFLOW_RUNTIME_GITHUB_AUTH": "true",
        "KFLOW_FORWARD_GITHUB_TOKEN_TO_RUNTIME": "true",
    }
    return {
        **submitter_fields(args),
        "disk": "40GB" if len(models) <= 50 else "60GB",
        "input_jobs": input_jobs,
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "opr_terminal_penalty_lf_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "stage": "results",
            "model_count": len(models),
            "model_selectors": [row["step_id"] for row in models],
            "input_jobs": input_jobs,
            "input_jobs_override": True,
            "allow_failed_input_jobs": True,
            "job_title": title,
            "job_description": description,
        },
        "tags": {
            "stage": "results",
            "flow": args.flow_group,
            "experiment": GRID_CODE,
            "check_type": "hessian-merged-results",
            "model_count": str(len(models)),
        },
        "triggers": {},
    }


def default_manifest_path(flow_group: str) -> Path:
    safe = "".join(
        character if character.isalnum() or character in "-_." else "-"
        for character in flow_group
    )
    return ROOT / "work" / f"{safe}-launch.json"


def write_manifest(
    path: Path,
    manifest: dict[str, Any],
    *,
    exclusive: bool = False,
) -> None:
    """Persist recovery state without exposing a partial JSON document."""
    path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    if exclusive:
        try:
            with path.open("x", encoding="utf-8") as handle:
                handle.write(content)
                handle.flush()
                os.fsync(handle.fileno())
        except FileExistsError as exc:
            raise RuntimeError(
                f"Launch manifest already exists: {path}. Use --resume or choose "
                "a new --flow-group."
            ) from exc
        return

    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    try:
        with temporary.open("w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def persist_manifest(
    path: Path, manifest: dict[str, Any], *, dry_run: bool
) -> None:
    if not dry_run:
        write_manifest(path, manifest)


def load_or_create_manifest(
    path: Path,
    args: argparse.Namespace,
    branch: str,
    models: list[dict[str, str]],
) -> dict[str, Any]:
    expected_steps = [row["step_id"] for row in models]
    if args.resume:
        if not path.exists():
            raise RuntimeError(f"Cannot resume: launch manifest does not exist: {path}")
        manifest = json.loads(path.read_text(encoding="utf-8"))
        checks = {
            "schema": MANIFEST_SCHEMA,
            "branch": branch,
            "flow_group": args.flow_group,
            "stepwise_task": args.stepwise_task,
            "results_task": args.results_task,
            "check_prefix": args.check_prefix,
            "model_source_repo": args.model_source_repo,
            "phase_convergence": args.phase_convergence,
            "launch_mode": "fits-only" if args.fits_only else "full",
            "runtime_packages": runtime_packages(),
            "model_selection_signature": model_selection_signature(models),
        }
        for field, expected in checks.items():
            if manifest.get(field) != expected:
                raise RuntimeError(
                    f"Resume manifest {field} mismatch: expected {expected!r}, "
                    f"found {manifest.get(field)!r}."
                )
        if int(manifest.get("hessian_nsplit") or 0) != int(args.hessian_nsplit):
            raise RuntimeError("Resume manifest uses a different Hessian partition count.")
        expected_overlay = not bool(args.fits_only)
        if manifest.get("hessian_merge_direct_overlay") is not expected_overlay:
            raise RuntimeError("Resume manifest diagnostic-overlay mode does not match.")
        expected_submitter = {
            "host": args.remote_host,
            "user": args.remote_user,
            "base_dir": args.remote_base_dir,
        }
        if manifest.get("submitter") != expected_submitter:
            raise RuntimeError(
                "Resume manifest uses a different submitter host, user, or base directory."
            )
        manifest_steps = [
            str(entry.get("step_id") or "")
            for entry in manifest.get("models", [])
            if isinstance(entry, dict)
        ]
        if manifest_steps != expected_steps:
            raise RuntimeError("Resume manifest contains a different ordered model selection.")
        return manifest

    # A non-resume dry-run is an in-memory preview and must not be blocked by,
    # overwrite, or mutate a real manifest for the same flow group.
    if path.exists() and not args.dry_run:
        raise RuntimeError(
            f"Launch manifest already exists: {path}. Use --resume or choose a new --flow-group."
        )
    fits_only = bool(args.fits_only)
    expected_job_counts = {
        "fits": len(models),
        "hessians": 0 if fits_only else len(models) * args.hessian_nsplit,
        "hessian_merges": 0 if fits_only else len(models),
        "hessian_attaches": 0,
        "results": 0 if fits_only else 1,
        "total": len(models) if fits_only else len(models) * (2 + args.hessian_nsplit) + 1,
    }
    manifest = {
        "schema": MANIFEST_SCHEMA,
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "branch": branch,
        "model_source_repo": args.model_source_repo,
        "phase_convergence": args.phase_convergence,
        "launch_mode": "fits-only" if fits_only else "full",
        "runtime_packages": runtime_packages(),
        "model_selection_signature": model_selection_signature(models),
        "flow_group": args.flow_group,
        "stepwise_task": args.stepwise_task,
        "results_task": args.results_task,
        "check_prefix": args.check_prefix,
        "hessian_nsplit": args.hessian_nsplit,
        "hessian_merge_direct_overlay": not fits_only,
        "results_parent_stage": "none" if fits_only else "hessian_merge",
        "expected_job_counts": expected_job_counts,
        "submitter": {
            "host": args.remote_host,
            "user": args.remote_user,
            "base_dir": args.remote_base_dir,
        },
        "models": [{"step_id": row["step_id"]} for row in models],
    }
    # Reserve the recovery file before the first API submission. The
    # exclusive create prevents two launcher processes from racing past the
    # existence check and duplicating the same full launch graph.
    if not args.dry_run:
        write_manifest(path, manifest, exclusive=True)
    return manifest


def manifest_entry(manifest: dict[str, Any], step_id: str) -> dict[str, Any]:
    for entry in manifest.get("models", []):
        if isinstance(entry, dict) and entry.get("step_id") == step_id:
            return entry
    raise RuntimeError(f"Launch manifest has no record for selected model {step_id!r}.")


def job_number(entry: dict[str, Any], key: str) -> str:
    value = entry.get(key)
    if not isinstance(value, dict):
        return ""
    return str(value.get("job_number") or "").strip()


def hessian_part_map(entry: dict[str, Any], nsplit: int) -> dict[int, dict[str, Any]]:
    records = entry.get("hessian_parts")
    if records in (None, ""):
        return {}
    if not isinstance(records, list):
        raise RuntimeError("hessian_parts must be a list in the launch manifest.")
    mapped: dict[int, dict[str, Any]] = {}
    for index, record in enumerate(records, start=1):
        if not isinstance(record, dict):
            raise RuntimeError("Every hessian_parts record must be an object.")
        try:
            part = int(record.get("part") or index)
        except (TypeError, ValueError) as exc:
            raise RuntimeError("Invalid Hessian part number in launch manifest.") from exc
        ref = str(record.get("job_number") or "").strip()
        if part < 1 or part > nsplit or not ref or part in mapped:
            raise RuntimeError("Invalid, empty, or duplicate Hessian part in launch manifest.")
        mapped[part] = record
    return mapped


def emit_dry_run(task: str, payload: dict[str, Any]) -> None:
    print(json.dumps({"task": task, "payload": payload}, sort_keys=True))


def dry_run_job_number(task: str, payload: dict[str, Any]) -> str:
    metadata = payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {}
    selector = str(metadata.get("model_selector") or "").strip()
    part = str(metadata.get("hessian_part") or "").strip()
    suffix = "-".join(value for value in (selector, part) if value)
    return f"DRY-{task}" + (f"-{suffix}" if suffix else "")


def submit_or_preview(
    base_url: str,
    token: str,
    task: str,
    payload: dict[str, Any],
    dry_run: bool,
) -> dict[str, Any]:
    if dry_run:
        emit_dry_run(task, payload)
        return {
            "job_number": dry_run_job_number(task, payload),
            "job_id": "",
            "status": "dry-run",
        }
    return submitted_job(api_json("POST", f"{base_url}/api/job/{task}", token, payload), task)


def parse_args() -> argparse.Namespace:
    date_label = dt.date.today().strftime("%Y%m%d")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument("--stepwise-task", default=DEFAULT_STEPWISE_TASK)
    parser.add_argument("--results-task", default=DEFAULT_RESULTS_TASK)
    parser.add_argument("--check-prefix", default=DEFAULT_CHECK_PREFIX)
    parser.add_argument("--model-source-repo", default=DEFAULT_MODEL_REPO)
    parser.add_argument("--branch", default=DEFAULT_BRANCH)
    parser.add_argument("--models", default="", help="Optional comma-separated subset of explicit step IDs.")
    parser.add_argument("--limit", type=int, default=0, help="Cap the ordered selection for a small launch/test.")
    parser.add_argument("--flow-group", default=f"bet-2026-{GRID_CODE}-{date_label}")
    parser.add_argument("--hessian-nsplit", default="auto", choices=("auto", "1", "2"))
    parser.add_argument(
        "--phase-convergence",
        default="-4",
        help=(
            "MFCL convergence exponent for phases 10/11 and the matched "
            "phase-12 refinement (default: -4 for sensitivity screening; use "
            "-5 for shortlisted production reruns)."
        ),
    )
    parser.add_argument("--remote-host", default=DEFAULT_SUVA_HOST)
    parser.add_argument("--remote-user", default=DEFAULT_SUVA_USER)
    parser.add_argument("--remote-base-dir", default=DEFAULT_SUVA_BASE_DIR)
    parser.add_argument("--manifest", default="", help="Launch manifest; defaults under ignored work/.")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument(
        "--fits-only",
        action="store_true",
        help="Submit only model fits; do not submit Hessians, merges, or results.",
    )
    parser.add_argument("--skip-remote-branch-check", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.limit < 0:
        raise SystemExit("--limit must be non-negative.")
    branch = str(args.branch or DEFAULT_BRANCH).strip()
    models = configured_models(args.models)
    if args.limit:
        models = models[: args.limit]
    if not models:
        raise SystemExit("No models selected for the sensitivity launch.")
    try:
        args.hessian_nsplit = resolve_hessian_nsplit(len(models), args.hessian_nsplit)
    except (TypeError, ValueError) as exc:
        raise SystemExit(str(exc)) from exc

    base_url = args.kflow_url.rstrip("/")
    token = os.environ.get("KFLOW_API_TOKEN", "")
    if not args.dry_run:
        if not token:
            raise SystemExit("Set KFLOW_API_TOKEN before submitting Kflow jobs.")
        if not args.skip_remote_branch_check:
            verify_remote_branch(branch)
        tasks = [args.stepwise_task]
        if not args.fits_only:
            tasks.extend(
                (
                    f"{args.check_prefix}-hessian",
                    f"{args.check_prefix}-hessian-merge",
                    args.results_task,
                )
            )
        for task in tasks:
            report_exists(base_url, token, task)

    manifest_path = (
        Path(args.manifest).expanduser()
        if args.manifest
        else default_manifest_path(args.flow_group)
    )
    if not manifest_path.is_absolute():
        manifest_path = ROOT / manifest_path
    manifest = load_or_create_manifest(manifest_path, args, branch, models)

    errors: list[str] = []
    for row in models:
        step = row["step_id"]
        entry = manifest_entry(manifest, step)
        try:
            fit_ref = job_number(entry, "fit")
            if not fit_ref:
                entry["fit"] = submit_or_preview(
                    base_url,
                    token,
                    args.stepwise_task,
                    fit_payload(row, args, branch),
                    args.dry_run,
                )
                fit_ref = job_number(entry, "fit")
                if not args.dry_run:
                    print(f"submitted fit {step}: job {fit_ref}")
                persist_manifest(manifest_path, manifest, dry_run=args.dry_run)

            if args.fits_only:
                continue

            parts = hessian_part_map(entry, args.hessian_nsplit)
            for part in range(1, args.hessian_nsplit + 1):
                if part in parts:
                    continue
                submitted = submit_or_preview(
                    base_url,
                    token,
                    f"{args.check_prefix}-hessian",
                    hessian_payload(row, args, branch, fit_ref, part),
                    args.dry_run,
                )
                submitted["part"] = part
                parts[part] = submitted
                entry["hessian_parts"] = [parts[key] for key in sorted(parts)]
                if not args.dry_run:
                    print(
                        f"submitted Hessian {part}/{args.hessian_nsplit} "
                        f"{step}: job {submitted['job_number']}"
                    )
                persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
            hessian_refs = [str(parts[part]["job_number"]) for part in sorted(parts)]

            merge_ref = job_number(entry, "hessian_merge")
            if not merge_ref:
                predecessor = ""
                if not args.dry_run:
                    predecessor = latest_attached_output_job_for_slot(
                        base_url,
                        token,
                        fit_ref,
                        f"diagnostics:{step}:hessian",
                    )
                entry["hessian_merge"] = submit_or_preview(
                    base_url,
                    token,
                    f"{args.check_prefix}-hessian-merge",
                    hessian_merge_payload(
                        row,
                        args,
                        branch,
                        fit_ref,
                        hessian_refs,
                        previous_attached_output_job=predecessor,
                    ),
                    args.dry_run,
                )
                merge_ref = job_number(entry, "hessian_merge")
                if not args.dry_run:
                    print(f"submitted Hessian merge {step}: job {merge_ref}")
                persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
        except Exception as exc:  # Keep independent model chains launchable.
            entry.setdefault("errors", []).append(str(exc))
            errors.append(f"{step}: {exc}")
            persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
            print(f"ERROR {step}: {exc}", file=sys.stderr)

    if args.fits_only:
        manifest["updated_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
        manifest["selected_model_count"] = len(models)
        manifest["hessian_nsplit"] = args.hessian_nsplit
        manifest["expected_total_job_count"] = len(models)
        persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
        print(
            f"OPR terminal-penalty/LF fit-only launch: {len(models)} models, "
            f"convergence=1e{args.phase_convergence}, manifest={manifest_path}"
            f"{' (preview only)' if args.dry_run else ''}"
        )
        if errors:
            print(
                f"{len(errors)} fit submission(s) had errors; rerun with --resume "
                "and the same --manifest.",
                file=sys.stderr,
            )
            return 1
        return 0

    result_parent_refs = [
        job_number(manifest_entry(manifest, row["step_id"]), "hessian_merge")
        for row in models
    ]
    missing_parent_steps = [
        row["step_id"]
        for row, ref in zip(models, result_parent_refs)
        if not ref
    ]
    duplicate_parent_refs = sorted(
        {ref for ref in result_parent_refs if ref and result_parent_refs.count(ref) > 1}
    )
    complete_fan_in = (
        not missing_parent_steps
        and not duplicate_parent_refs
        and len(result_parent_refs) == len(models)
    )
    if complete_fan_in and not job_number(manifest, "results"):
        try:
            manifest.pop("results_pending", None)
            manifest["results"] = submit_or_preview(
                base_url,
                token,
                args.results_task,
                results_payload(models, args, result_parent_refs),
                args.dry_run,
            )
            if not args.dry_run:
                print(f"submitted BET results bundle: job {job_number(manifest, 'results')}")
            persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
        except Exception as exc:
            errors.append(f"results: {exc}")
            manifest.setdefault("results_errors", []).append(str(exc))
            persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
            print(f"ERROR results: {exc}", file=sys.stderr)
    elif not complete_fan_in:
        pending = {
            "parent_type": "hessian_merge",
            "missing_parent_steps": missing_parent_steps,
            "duplicate_parent_job_refs": duplicate_parent_refs,
            "resolved_parent_count": sum(bool(ref) for ref in result_parent_refs),
            "expected_parent_count": len(models),
        }
        manifest["results_pending"] = pending
        details = []
        if missing_parent_steps:
            details.append("missing Hessian merges for " + ", ".join(missing_parent_steps))
        if duplicate_parent_refs:
            details.append("duplicate merge refs " + ", ".join(duplicate_parent_refs))
        message = "results fan-in incomplete: " + "; ".join(details)
        errors.append(message)
        print(f"PENDING {message}; rerun with --resume after repair.", file=sys.stderr)

    manifest["updated_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
    manifest["selected_model_count"] = len(models)
    manifest["hessian_nsplit"] = args.hessian_nsplit
    manifest["expected_total_job_count"] = len(models) * (2 + args.hessian_nsplit) + 1
    persist_manifest(manifest_path, manifest, dry_run=args.dry_run)
    print(
        f"OPR terminal-penalty/LF launch: {len(models)} models, "
        f"Hessian parts/model={args.hessian_nsplit}, "
        f"BET results={job_number(manifest, 'results') or 'not-submitted'}, "
        f"manifest={manifest_path}{' (preview only)' if args.dry_run else ''}"
    )
    if errors:
        print(
            f"{len(errors)} submission chain(s) had errors; rerun with --resume "
            "and the same --manifest.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
