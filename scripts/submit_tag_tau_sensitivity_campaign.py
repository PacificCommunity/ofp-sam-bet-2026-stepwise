#!/usr/bin/env python3
"""Validate and submit the 116-job BET tag-dispersion sensitivity campaign."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "kflow.yaml"
EXPECTED_IMAGE = (
    "ghcr.io/pacificcommunity/tuna-flow@sha256:"
    "7b9dc95f535025a42109ac958c4faa3af96592cd19510ac0be15af4478eccf27"
)
EXPECTED_PACKAGE_REFS = {
    "MFCLKIT_GITHUB_REF": "a0fe04baa9c119353123367e5a652bb73d909b84",
    "MFCLSHINY_GITHUB_REF": "46149215507e4bf74e1de673dd02ee948b9029ca",
}
EXPECTED_INI_SHA256 = (
    "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a"
)
EXPECTED_REG_SCALING_SHA256 = (
    "6330fb6a36d63424c18f81cbc620c1d9607c2a5c43d0308d19941f12938ec9a1"
)
CAMPAIGN_STEPS = (
    "S03-CommonTagTau-MIX015",
    "S04-CommonTagTauSpline-MIX015",
    "S05-CommonTagTauOPR-MIX015",
    "S06-CommonTagTauSplineOPR-MIX015",
)
SUPPLEMENTAL_F33_FIVE_NODE_STEP = "S07-CommonTagTauF335Node-MIX015"


def api_json(
    method: str,
    url: str,
    token: str,
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {token}"}
    if body is not None:
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: HTTP {exc.code}: {detail}") from exc
    return json.loads(raw.decode("utf-8")) if raw else {}


def load_config() -> dict[str, Any]:
    config = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    if not isinstance(config, dict):
        raise ValueError("kflow.yaml must contain a mapping.")
    return config


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_science_inputs(
    steps: tuple[str, ...] = CAMPAIGN_STEPS,
) -> None:
    for step in steps:
        model = ROOT / "steps" / step / "model"
        ini = model / "bet.ini"
        reg_scaling = model / "bet.reg_scaling"
        doitall = model / "doitall.sh"
        for path in (ini, reg_scaling, doitall):
            if not path.is_file():
                raise ValueError(f"Missing campaign input: {path.relative_to(ROOT)}")
        if sha256_file(ini) != EXPECTED_INI_SHA256:
            raise ValueError(
                f"{step} does not retain the frozen SC22-IP10 K=0.15/RR INI."
            )
        if sha256_file(reg_scaling) != EXPECTED_REG_SCALING_SHA256:
            raise ValueError(f"{step} regional-scaling input has drifted.")
        first_line = reg_scaling.read_text(
            encoding="utf-8", errors="strict"
        ).splitlines()[0].strip()
        if first_line != "1965 2 1969 11":
            raise ValueError(f"{step} regional-scaling calendar header is invalid.")
        subprocess.run(["sh", "-n", str(doitall)], check=True)

    validation = subprocess.run(
        ["Rscript", "--vanilla", "R/validate_stepwise_inputs.R"],
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if validation.returncode != 0:
        raise ValueError(
            "Repository input validation failed before submission:\n"
            + validation.stdout
        )


def build_grid() -> list[dict[str, str]]:
    model_rows = (
        {
            "step": "S03-CommonTagTau-MIX015",
            "recruitment": "standard",
            "selectivity": "f33-asymptotic",
            "nmax_values": ("25",),
        },
        {
            "step": "S04-CommonTagTauSpline-MIX015",
            "recruitment": "standard",
            "selectivity": "f33-spline",
            "nmax_values": ("25",),
        },
        {
            "step": "S05-CommonTagTauOPR-MIX015",
            "recruitment": "opr-72-01-50-50-end2",
            "selectivity": "f33-asymptotic",
            "nmax_values": ("25", "default"),
        },
        {
            "step": "S06-CommonTagTauSplineOPR-MIX015",
            "recruitment": "opr-72-01-50-50-end2",
            "selectivity": "f33-spline",
            "nmax_values": ("25", "default"),
        },
    )
    tau_rows = (
        {
            "tau_key": "common-default",
            "tau_grouping": "common",
            "tau_lower": "default",
            "tau_count": "1",
        },
        {
            "tau_key": "common-lb2",
            "tau_grouping": "common",
            "tau_lower": "2",
            "tau_count": "1",
        },
        {
            "tau_key": "program-informed-default",
            "tau_grouping": "program-informed",
            "tau_lower": "default",
            "tau_count": "3",
        },
    )
    rows: list[dict[str, str]] = []
    for model in model_rows:
        for recpen in ("0.1", "0.2"):
            for nmax in model["nmax_values"]:
                for tau in tau_rows:
                    for estimate_m in ("false", "true"):
                        rows.append(
                            {
                                **{key: str(value) for key, value in model.items()
                                   if key != "nmax_values"},
                                **tau,
                                "recpen": recpen,
                                "nmax": nmax,
                                "m_mode": "late-estimated" if estimate_m == "true" else "fixed",
                                "estimate_m": estimate_m,
                                "tag_weight": "full",
                                "matched_full_weight_id": "",
                            }
                        )
    half_weight_rows = [
        {
            **row,
            "tag_weight": "500",
            "matched_full_weight_id": str(index),
        }
        for index, row in enumerate(rows, start=1)
        if row["nmax"] == "25" and row["estimate_m"] == "false"
    ]
    rows.extend(half_weight_rows)

    model_by_step = {str(model["step"]): model for model in model_rows}
    no_tau_specs = (
        ("S03-CommonTagTau-MIX015", "0.1", "25"),
        ("S03-CommonTagTau-MIX015", "0.2", "25"),
        ("S04-CommonTagTauSpline-MIX015", "0.1", "25"),
        ("S04-CommonTagTauSpline-MIX015", "0.2", "25"),
        ("S05-CommonTagTauOPR-MIX015", "0.1", "25"),
        ("S05-CommonTagTauOPR-MIX015", "0.2", "25"),
        ("S06-CommonTagTauSplineOPR-MIX015", "0.1", "25"),
        ("S06-CommonTagTauSplineOPR-MIX015", "0.2", "25"),
        ("S05-CommonTagTauOPR-MIX015", "0.1", "default"),
        ("S06-CommonTagTauSplineOPR-MIX015", "0.1", "default"),
    )
    for step, recpen, nmax in no_tau_specs:
        model = model_by_step[step]
        full_id = len(rows) + 1
        base = {
            **{
                key: str(value)
                for key, value in model.items()
                if key != "nmax_values"
            },
            "tau_key": "not-estimated",
            "tau_grouping": "off",
            "tau_lower": "default",
            "tau_count": "0",
            "recpen": recpen,
            "nmax": nmax,
            "m_mode": "fixed",
            "estimate_m": "false",
        }
        rows.append(
            {
                **base,
                "tag_weight": "full",
                "matched_full_weight_id": "",
            }
        )
        rows.append(
            {
                **base,
                "tag_weight": "500",
                "matched_full_weight_id": str(full_id),
            }
        )
    for index, row in enumerate(rows, start=1):
        row["sensitivity_id"] = str(index)
    validate_grid(rows)
    return rows


def supplemental_f33_five_node_rows() -> list[dict[str, str]]:
    fixed = {
        "step": SUPPLEMENTAL_F33_FIVE_NODE_STEP,
        "recruitment": "standard",
        "selectivity": "f33-spline-5node",
        "tau_key": "common-default",
        "tau_grouping": "common",
        "tau_lower": "default",
        "tau_count": "1",
        "recpen": "0.1",
        "nmax": "25",
        "m_mode": "fixed",
        "estimate_m": "false",
        "tag_weight": "full",
        "matched_full_weight_id": "",
        "sensitivity_id": "117",
    }
    return [
        fixed,
        {
            **fixed,
            "m_mode": "late-estimated",
            "estimate_m": "true",
            "sensitivity_id": "118",
        },
    ]


def validate_grid(rows: list[dict[str, str]]) -> None:
    if len(rows) != 116:
        raise ValueError(f"Expected 116 sensitivity rows; found {len(rows)}.")
    ids = [row["sensitivity_id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise ValueError("Sensitivity identifiers are not unique.")
    if ids != [str(index) for index in range(1, 117)]:
        raise ValueError("Sensitivity identifiers must run consecutively from 1 to 116.")
    signatures = [
        tuple(row[key] for key in (
            "step", "recpen", "nmax", "tau_grouping", "tau_lower", "estimate_m",
            "tag_weight"
        ))
        for row in rows
    ]
    if len(signatures) != len(set(signatures)):
        raise ValueError("The sensitivity grid contains duplicate configurations.")
    for row in rows:
        is_opr = row["recruitment"].startswith("opr")
        if row["nmax"] == "default" and not is_opr:
            raise ValueError("Default Nmax is restricted to OPR sensitivities.")
        if row["tau_grouping"] == "program-informed" and row["tau_lower"] != "default":
            raise ValueError("Program-informed tau must use the native MFCL lower bound.")
        if row["tau_grouping"] == "common" and row["tau_lower"] not in {"default", "2"}:
            raise ValueError("Common tau must use the native bound or lower bound 2.")
        if row["tau_grouping"] == "off" and (
            row["tau_count"] != "0" or row["tau_lower"] != "default"
        ):
            raise ValueError("No-estimation tau rows must request zero tau and no bound.")
        if row["tag_weight"] not in {"full", "500"}:
            raise ValueError("Tag likelihood weight must be full or 500.")
        if row["tag_weight"] == "500" and row["tau_grouping"] != "off" and (
            row["nmax"] != "25" or row["estimate_m"] != "false"
        ):
            raise ValueError(
                "Estimated-tau half-weight sensitivities must use Nmax 25 and fixed M."
            )
    primary_full_rows = [
        row for row in rows
        if row["tag_weight"] == "full" and row["tau_grouping"] != "off"
    ]
    tau_half_rows = [
        row for row in rows
        if row["tag_weight"] == "500" and row["tau_grouping"] != "off"
    ]
    no_tau_full_rows = [
        row for row in rows
        if row["tag_weight"] == "full" and row["tau_grouping"] == "off"
    ]
    no_tau_half_rows = [
        row for row in rows
        if row["tag_weight"] == "500" and row["tau_grouping"] == "off"
    ]
    observed_counts = tuple(
        len(group) for group in (
            primary_full_rows, tau_half_rows, no_tau_full_rows, no_tau_half_rows
        )
    )
    if observed_counts != (72, 24, 10, 10):
        raise ValueError(
            "Expected 72 primary, 24 estimated-tau half-weight, and 10/10 "
            f"no-tau-estimation paired rows; found {observed_counts}."
        )
    full_rows = primary_full_rows + no_tau_full_rows
    half_rows = tau_half_rows + no_tau_half_rows
    by_id = {row["sensitivity_id"]: row for row in full_rows}
    comparison_fields = (
        "step", "recruitment", "selectivity", "tau_key", "tau_grouping",
        "tau_lower", "tau_count", "recpen", "nmax", "m_mode", "estimate_m",
    )
    for row in half_rows:
        parent = by_id.get(row["matched_full_weight_id"])
        if parent is None:
            raise ValueError(
                f"Half-weight row {row['sensitivity_id']} has no full-weight match."
            )
        if any(row[field] != parent[field] for field in comparison_fields):
            raise ValueError(
                f"Half-weight row {row['sensitivity_id']} differs from matched "
                f"row {parent['sensitivity_id']} by more than tag weight."
            )
    if any(row["estimate_m"] != "false" for row in no_tau_full_rows + no_tau_half_rows):
        raise ValueError("No-tau-estimation comparisons must retain fixed M.")
    fixed = sum(row["estimate_m"] == "false" for row in primary_full_rows)
    estimated = sum(row["estimate_m"] == "true" for row in primary_full_rows)
    if (fixed, estimated) != (36, 36):
        raise ValueError(f"Expected 36 fixed-M and 36 late-M rows; found {fixed}/{estimated}.")
    pair_keys: dict[tuple[str, ...], set[str]] = {}
    for row in primary_full_rows:
        key = tuple(row[field] for field in (
            "step", "recpen", "nmax", "tau_grouping", "tau_lower"
        ))
        pair_keys.setdefault(key, set()).add(row["estimate_m"])
    if any(values != {"false", "true"} for values in pair_keys.values()):
        raise ValueError("Every scientific configuration must have fixed- and late-M pairs.")
    long_labels = [
        scenario_label(row) for row in rows if len(scenario_label(row)) > 140
    ]
    if long_labels:
        raise ValueError("Scenario labels must fit Kflow's 140-character title limit.")


def validate_task_config(config: dict[str, Any]) -> None:
    if config.get("docker_image") != EXPECTED_IMAGE:
        raise ValueError("kflow.yaml is not pinned to the approved tuna-flow v2.6 digest.")
    if str(config.get("remote_host", "")).lower() != "suva":
        raise ValueError("The campaign must submit through the Suva submitter.")
    resources = config.get("resources", {})
    if resources.get("cpus") != 2 or str(resources.get("memory")) != "8GB":
        raise ValueError("The campaign must request 2 CPUs and 8GB memory per fit.")
    env = config.get("env", {})
    for name, expected in EXPECTED_PACKAGE_REFS.items():
        if env.get(name) != expected:
            raise ValueError(f"{name} is not pinned to the validated latest main commit.")
    if str(env.get("KFLOW_REPORT_PUSH_GENERATED", "")).lower() != "false":
        raise ValueError("Parallel fits must not push generated report changes.")
    if config.get("triggers"):
        raise ValueError("Sensitivity fits must be independent and have no triggers.")


def describe(row: dict[str, str]) -> str:
    if row["tau_grouping"] == "off":
        tau = "negative-binomial tau retained at inherited values and not estimated"
        lower = "tau bounds not active"
    elif row["tau_grouping"] == "common":
        tau = "one common recapture-fishery tau"
        lower = (
            "native MFCL bound (effective tau >= 1.0067)"
            if row["tau_lower"] == "default"
            else "tau lower bound 2"
        )
    else:
        tau = (
            "three program-informed recapture-fishery tau strata "
            "(JPTP-dominant F1/F12/F13, PTTP Region 4-dominant F25-F28, remainder)"
        )
        lower = "native MFCL bound (effective tau >= 1.0067)"
    mortality = (
        "M fixed at -2.54930339768360"
        if row["estimate_m"] == "false"
        else "M fixed through Phase 10 and estimated in Phases 11-12"
    )
    nmax = "MFCL default Nmax 1000" if row["nmax"] == "default" else "Nmax 25"
    tag_weight = (
        "full tag-recapture likelihood weight"
        if row["tag_weight"] == "full"
        else (
            "tag-recapture likelihood multiplied by 0.50 "
            f"(parest flag 177=500; matched primary fit "
            f"{row['matched_full_weight_id']})"
        )
    )
    return (
        f"{row['sensitivity_id']}. Independent full native-MFCL doitall fit; "
        f"{tau}; {lower}; {row['selectivity']}; "
        f"{row['recruitment']} recruitment; regional recruitment coefficient "
        f"{row['recpen']}; {nmax}; {mortality}; {tag_weight}. "
        "SC22-IP10 K=0.15 mixing, "
        "reporting-rate priors, DM G8 grouping, CPUE settings and all data are fixed."
    )


def scenario_label(row: dict[str, str]) -> str:
    recruitment = (
        "Standard"
        if row["recruitment"] == "standard"
        else "OPR 72-01-50-50 end2"
    )
    selectivity_labels = {
        "f33-asymptotic": "F33 logistic",
        "f33-spline": "F33 4-node",
        "f33-spline-5node": "F33 5-node spline",
    }
    selectivity = selectivity_labels[row["selectivity"]]
    if row["tau_grouping"] == "program-informed":
        tau = "tau 3 strata/native"
    elif row["tau_grouping"] == "off":
        tau = "tau not estimated"
    elif row["tau_lower"] == "2":
        tau = "tau common/lower 2"
    else:
        tau = "tau common/native"
    nmax = "Nmax1000" if row["nmax"] == "default" else "Nmax25"
    mortality = (
        "M fixed"
        if row["estimate_m"] == "false"
        else "M est P11-12"
    )
    tag_weight = (
        "tag likelihood 100%"
        if row["tag_weight"] == "full"
        else "tag likelihood 50%"
    )
    return (
        f"{row['sensitivity_id']}. {recruitment} | {selectivity} | {tau} | "
        f"rec penalty {row['recpen']} | {nmax} | {mortality} | "
        f"{tag_weight}"
    )


def payload_for(config: dict[str, Any], row: dict[str, str]) -> dict[str, Any]:
    resources = config["resources"]
    label = scenario_label(row)
    env = {
        **config["env"],
        "STEP_SELECT": row["step"],
        "TAG_TAU_GROUPING": row["tau_grouping"],
        "TAG_TAU_LOWER_BOUND": row["tau_lower"],
        "REGIONAL_RECRUITMENT_PENALTY": row["recpen"],
        "DM_NMAX": row["nmax"],
        "ESTIMATE_M_FINAL": row["estimate_m"],
        "TAG_LIKELIHOOD_WEIGHT": "0" if row["tag_weight"] == "full" else "500",
        "JOB_KEY": row["sensitivity_id"],
        "JOB_TITLE": label,
        "MODEL_LABEL": label,
        "JOB_DESCRIPTION": describe(row),
    }
    return {
        "docker_image": config["docker_image"],
        "remote_host": config["remote_host"],
        "remote_user": config["remote_user"],
        "remote_base_dir": config["remote_base_dir"],
        "slot_requirements": config["slot_requirements"],
        "cpus": resources["cpus"],
        "memory": resources["memory"],
        "disk": resources["disk"],
        "batch_name": config["env"]["FLOW_GROUP"],
        "output_patterns": config["output_patterns"],
        "input_jobs": [],
        "env": env,
        "tags": {
            "species": "BET",
            "stage": "sensitivity",
            "run_mode": "doitall",
            "engine": "mfcl",
            "sensitivity_id": row["sensitivity_id"],
            "selectivity": row["selectivity"],
            "recruitment": row["recruitment"],
            "recpen": row["recpen"],
            "nmax": row["nmax"],
            "tau_grouping": row["tau_grouping"],
            "tau_lower": row["tau_lower"],
            "m_mode": row["m_mode"],
            "tag_likelihood_weight": row["tag_weight"],
            "matched_full_weight_id": row["matched_full_weight_id"],
        },
        "metadata": {
            "sensitivity_id": row["sensitivity_id"],
            "scenario_label": label,
            "scientific_settings": row,
            "estimated_tau_count": int(row["tau_count"]),
            "mixing_period": "SC22-IP10 K=0.15",
            "mortality_fixed_value": -2.54930339768360,
            "independent_fit": True,
            "inputs_frozen": True,
            "campaign_size": 116,
            "supplemental_sensitivity": row["sensitivity_id"] in {"117", "118"},
            "container": "tuna-flow v2.6",
            "mfcl_sha256": (
                "13f5b1b6a8873cfd9afc850b3bdcb46d5bb62d28dcc70604362e4c89b29fb682"
            ),
            "mfclkit_ref": EXPECTED_PACKAGE_REFS["MFCLKIT_GITHUB_REF"],
            "mfclshiny_ref": EXPECTED_PACKAGE_REFS["MFCLSHINY_GITHUB_REF"],
        },
        "triggers": {},
    }


def existing_keys(base_url: str, token: str, task_path: str) -> set[str]:
    keys: set[str] = set()
    for page in range(1, 20):
        response = api_json(
            "GET", f"{base_url}/api/jobs/{task_path}/?page={page}", token
        )
        jobs = response.get("jobs", [])
        if not jobs:
            break
        for job in jobs:
            env = job.get("env") or job.get("env_json") or {}
            metadata = job.get("metadata") or job.get("metadata_json") or {}
            key = str(
                job.get("job_key")
                or metadata.get("job_key")
                or env.get("JOB_KEY")
                or ""
            )
            if key:
                keys.add(key)
    return keys


def verify_job(
    base_url: str,
    token: str,
    task_name: str,
    number: int,
    row: dict[str, str],
) -> None:
    response = api_json("GET", f"{base_url}/api/job/{number}/", token)
    job = response.get("job", response)
    if job.get("report_code") != task_name:
        raise ValueError(f"Job {number} is attached to the wrong Kflow task.")
    if job.get("docker_image") != EXPECTED_IMAGE:
        raise ValueError(f"Job {number} does not use the approved tuna-flow v2.6 digest.")
    if job.get("cpus") != 2 or str(job.get("memory")) != "8GB":
        raise ValueError(f"Job {number} has unexpected resources.")
    env = job.get("env") or job.get("env_json") or {}
    expected_env = {
        "STEP_SELECT": row["step"],
        "TAG_TAU_GROUPING": row["tau_grouping"],
        "TAG_TAU_LOWER_BOUND": row["tau_lower"],
        "REGIONAL_RECRUITMENT_PENALTY": row["recpen"],
        "DM_NMAX": row["nmax"],
        "ESTIMATE_M_FINAL": row["estimate_m"],
        "TAG_LIKELIHOOD_WEIGHT": (
            "0" if row["tag_weight"] == "full" else "500"
        ),
        **EXPECTED_PACKAGE_REFS,
    }
    bad = {
        key: (env.get(key), value)
        for key, value in expected_env.items()
        if str(env.get(key)) != str(value)
    }
    if bad:
        raise ValueError(f"Job {number} environment mismatch: {bad}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--max-workers", type=int, default=12)
    parser.add_argument(
        "--supplemental-f33-5node",
        action="store_true",
        help=(
            "Submit sensitivities 117-118: job 16594 settings with F33 changed "
            "from logistic to an independent five-node cubic spline, paired "
            "with fixed and late-estimated M."
        ),
    )
    args = parser.parse_args()

    config = load_config()
    validate_task_config(config)
    if args.supplemental_f33_5node:
        validate_science_inputs((SUPPLEMENTAL_F33_FIVE_NODE_STEP,))
        rows = supplemental_f33_five_node_rows()
    else:
        validate_science_inputs()
        rows = build_grid()
    summary = {
        "total": len(rows),
        "fixed_m": sum(row["estimate_m"] == "false" for row in rows),
        "late_estimated_m": sum(row["estimate_m"] == "true" for row in rows),
        "standard": sum(row["recruitment"] == "standard" for row in rows),
        "opr": sum(row["recruitment"].startswith("opr") for row in rows),
        "common_tau": sum(row["tau_grouping"] == "common" for row in rows),
        "program_informed_tau": sum(
            row["tau_grouping"] == "program-informed" for row in rows
        ),
        "tau_not_estimated": sum(row["tau_grouping"] == "off" for row in rows),
        "full_tag_weight": sum(row["tag_weight"] == "full" for row in rows),
        "half_tag_weight": sum(row["tag_weight"] == "500" for row in rows),
    }
    if args.dry_run:
        print(json.dumps({"summary": summary, "rows": rows}, indent=2))
        return 0

    token = os.environ.get("KFLOW_API_TOKEN", "")
    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before submission.")
    base_url = os.environ.get("KFLOW_URL", "http://127.0.0.1:8089").rstrip("/")
    task_name = str(config["name"])
    task_path = urllib.parse.quote(task_name, safe="")
    already = existing_keys(base_url, token, task_path)
    pending = [
        row for row in rows if row["sensitivity_id"] not in already
    ]

    results: list[dict[str, Any]] = []
    failures: list[str] = []
    with ThreadPoolExecutor(max_workers=max(1, args.max_workers)) as executor:
        futures = {
            executor.submit(
                api_json,
                "POST",
                f"{base_url}/api/job/{task_path}",
                token,
                payload_for(config, row),
            ): row
            for row in pending
        }
        for future in as_completed(futures):
            row = futures[future]
            try:
                response = future.result()
                job = response.get("job", response)
                number = int(job["job_number"])
                results.append(
                    {
                        "sensitivity_id": row["sensitivity_id"],
                        "job_number": number,
                        "status": job.get("status"),
                    }
                )
            except Exception as exc:
                failures.append(f"{row['sensitivity_id']}: {exc}")

    by_id = {row["sensitivity_id"]: row for row in rows}
    for result in results:
        try:
            verify_job(
                base_url,
                token,
                task_name,
                result["job_number"],
                by_id[result["sensitivity_id"]],
            )
        except Exception as exc:
            failures.append(f"{result['sensitivity_id']} verification: {exc}")

    results.sort(key=lambda item: int(item["sensitivity_id"]))
    print(json.dumps(
        {
            "summary": summary,
            "already_present": len(already),
            "submitted": results,
            "failures": failures,
        },
        indent=2,
    ))
    complete = (
        all(
            sensitivity_id in already or any(
                result["sensitivity_id"] == sensitivity_id
                for result in results
            )
            for sensitivity_id in ("117", "118")
        )
        if args.supplemental_f33_5node
        else len(already) + len(results) == 116
    )
    if failures or not complete:
        raise SystemExit("Campaign submission or post-submission verification was incomplete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
