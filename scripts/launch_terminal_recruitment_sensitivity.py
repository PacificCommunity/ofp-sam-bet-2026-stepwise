#!/usr/bin/env python3
"""Submit the terminal-recruitment grid and its dependent Hessian checks.

One fit job is submitted for each selected model. Each Hessian job depends on
its corresponding fit, and its merge consumes both that fit and the Hessian
result. The merge publishes a delta overlay directly onto the original fit,
so the Hessian card appears on that model's Kflow job page without a separate
attachment job. The merge jobs also feed the established BET Kflow results
task. Failed parent archives are deliberately passed through so an incomplete
Hessian is recorded rather than disappearing.

This keeps the normal main-branch Kflow task untouched and never turns a
104-model grid into multiple Hessian shards per model. The complete launch is
104 fits + 104 Hessians + 104 merges + one results job (313 jobs total).

Examples:
  python3 scripts/launch_terminal_recruitment_sensitivity.py --dry-run
  python3 scripts/launch_terminal_recruitment_sensitivity.py
  python3 scripts/launch_terminal_recruitment_sensitivity.py \
    --models 12-OrthogonalPoly,12f001-OPR73-01-50-50-Y0-CFree --hessian-nsplit auto
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
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
DEFAULT_STEPWISE_TASK = "ofp-sam-bet-2026-stepwise-terminal-recruitment-717273"
DEFAULT_RESULTS_TASK = "ofp-sam-bet-2026-results"
DEFAULT_CHECK_PREFIX = "ofp-sam-bet-2026-check"
DEFAULT_ATTACH_TASK = "ofp-sam-bet-2026-check-attach-checks"
DEFAULT_MODEL_REPO = "PacificCommunity/ofp-sam-bet-2026-stepwise"
DEFAULT_BRANCH = "experiment/step12-terminal-recruitment-71-73"
GRID_CODE = "terminal-recruitment-717273"
GRID_LABEL = "OPR 71/72/73 terminal recruitment"
EXPECTED_FULL_MODEL_COUNT = 104
EXPECTED_FULL_JOB_COUNT = 313
MANIFEST_SCHEMA_V1 = "bet-2026-terminal-recruitment-717273-launch-v1"
MANIFEST_SCHEMA_V2 = "bet-2026-terminal-recruitment-717273-launch-v2"
DEFAULT_MFCLKIT_REF = "ac9a2c26f51ec6e6ad95593e3372e4928ca117a8"
DEFAULT_MFCLSHINY_REF = "1d7cced723190967ebd33cff6f1b7126aff56780"
DEFAULT_SUVA_HOST = "suvofpsubmit.corp.spc.int"
DEFAULT_SUVA_USER = "kyuhank"
DEFAULT_SUVA_BASE_DIR = "/home/kyuhank/KflowOutput"


def split_values(value: str) -> list[str]:
    return [part.strip() for part in str(value or "").replace("\n", ",").split(",") if part.strip()]


def current_branch() -> str:
    result = subprocess.run(
        ["git", "branch", "--show-current"],
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    branch = result.stdout.strip()
    if not branch:
        raise RuntimeError("A checked-out branch is required for the sensitivity launch.")
    return branch


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
    expression = r'''
source("R/stepwise_config_helpers.R")
source_stepwise_config("job-config.R")
selection <- Sys.getenv("TERMINAL_SENSITIVITY_SELECTOR", "")
if (!nzchar(selection)) selection <- stepwise_value("terminal_sensitivity_step_select")
rows <- stepwise_selected_models(selection)
needed <- c("step_id", "model_label", "job_title", "job_key", "major_step", "substep", "change_axis", "run_mode", "kflow_memory")
for (name in setdiff(needed, names(rows))) rows[[name]] <- ""
utils::write.csv(rows[, needed, drop = FALSE], row.names = FALSE, quote = TRUE)
'''
    env = dict(os.environ)
    env["TERMINAL_SENSITIVITY_SELECTOR"] = selector
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
        raise RuntimeError("No terminal-recruitment model rows were resolved from job-config.R.")
    rows = [{key: str(value or "") for key, value in row.items()} for row in rows]
    step_ids = [row["step_id"] for row in rows]
    duplicate_steps = sorted({step for step in step_ids if step_ids.count(step) > 1})
    job_keys = [row["job_key"] for row in rows if row["job_key"]]
    duplicate_job_keys = sorted({key for key in job_keys if job_keys.count(key) > 1})
    if duplicate_steps or duplicate_job_keys:
        details = []
        if duplicate_steps:
            details.append("duplicate step IDs: " + ", ".join(duplicate_steps))
        if duplicate_job_keys:
            details.append("duplicate job keys: " + ", ".join(duplicate_job_keys))
        raise RuntimeError("Invalid terminal-recruitment selection; " + "; ".join(details))
    requested = split_values(selector)
    if requested and not any(value.lower() in {"all", "*"} for value in requested):
        missing_requested = [value for value in requested if value not in step_ids]
        if missing_requested:
            raise RuntimeError("Unknown selected model(s): " + ", ".join(missing_requested))
    missing = [row["step_id"] for row in rows if not (ROOT / "steps" / row["step_id"] / "model" / "doitall.sh").is_file()]
    if missing:
        raise RuntimeError("Selected model folder(s) are missing: " + ", ".join(missing))
    return rows


def api_json(method: str, url: str, token: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
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
    """Fetch one Kflow job, preserving API failures for safe CAS handling."""
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
    """Resolve the completed predecessor for exactly one diagnostic slot.

    Different diagnostics deliberately use different slots.  Concurrent
    Hessian and jitter attachments can therefore compare-and-swap their own
    map entries without serializing or replacing each other.  If this is the
    first attachment in the requested slot, the returned predecessor is the
    explicit empty string expected by Kflow.
    """
    normalized_base = str(base_job or "").strip().lstrip("#")
    slot_key = attached_work_slot_key(slot)
    if not normalized_base or not slot_key:
        raise ValueError("A base job and diagnostic slot are required for predecessor lookup.")

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
    job_id = job.get("id") or ""
    if number in (None, "", "?"):
        raise RuntimeError(f"Kflow task {task!r} did not return a job number: {job}")
    return {"job_number": str(number), "job_id": str(job_id), "status": str(job.get("status") or "")}


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


def fit_payload(row: dict[str, str], args: argparse.Namespace, branch: str) -> dict[str, Any]:
    step = row["step_id"]
    base_title = row["job_title"] or step
    title = f"OPR 71/72/73: {base_title}"
    description = row["change_axis"] or f"OPR 71/72/73 terminal-recruitment sensitivity {step}."
    memory = row["kflow_memory"] or "8GB"
    env = {
        "STEP_SELECT": step,
        # The grid rows are deliberately disabled for the ordinary `all`
        # workflow. The runner accepts this only with explicit STEP_SELECT.
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
            "terminal_recruitment_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "model_selector": step,
            "job_title": title,
            "job_description": description,
            "hessian_nsplit": args.hessian_nsplit,
            "trigger_next": False,
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


def check_runtime_env(row: dict[str, str], args: argparse.Namespace, branch: str, check_type: str, title: str, description: str) -> dict[str, str]:
    grid_code = str(getattr(args, "sensitivity_grid_code", GRID_CODE) or GRID_CODE)
    return {
        "CHECK_TYPE": check_type,
        "MODEL_SELECTOR": row["step_id"],
        "MODEL_SOURCE_REPO": args.model_source_repo,
        "MODEL_SOURCE_REF": branch,
        "PROGRAM_PATH": "/home/mfcl/mfclo64",
        "FLOW_GROUP": args.flow_group,
        "KFLOW_JOB_TITLE": title,
        "KFLOW_JOB_DESCRIPTION": description,
        "JOB_KEY": f"{grid_code}-{check_type.replace('_', '-')}-{row['step_id'].lower()}",
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


def hessian_payload(row: dict[str, str], args: argparse.Namespace, branch: str, fit_job: str, part: int) -> dict[str, Any]:
    title = f"OPR 71/72/73 Hessian {part}/{args.hessian_nsplit}: {row['step_id']}"
    description = f"One-part-per-model Hessian diagnostic for {GRID_LABEL} sensitivity {row['step_id']}."
    env = check_runtime_env(row, args, branch, "hessian", title, description)
    env.update(
        {
            "HESSIAN_NSPLIT": str(args.hessian_nsplit),
            "HESSIAN_PARTS": str(part),
            "HESSIAN_PART": str(part),
            "HESSIAN_COMPACT": "true",
            # A non-PD/failed Hessian must remain visibly failed rather than
            # being merged into an apparently normal diagnostic bundle.
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
            "terminal_recruitment_sensitivity": True,
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
    title = f"OPR 71/72/73 Hessian merge: {row['step_id']}"
    description = f"Merge Hessian output for {GRID_LABEL} sensitivity {row['step_id']}."
    input_jobs = list(
        dict.fromkeys(
            str(job).strip()
            for job in [fit_job, *hessian_jobs]
            if job is not None and str(job).strip()
        )
    )
    if not str(fit_job or "").strip() or len(input_jobs) != len(hessian_jobs) + 1:
        raise ValueError("Hessian merge requires one fit job and unique, non-empty Hessian job references.")
    hessian_job_refs = [str(job).strip().lstrip("#") for job in hessian_jobs]
    predecessor = str(previous_attached_output_job or "").strip().lstrip("#")
    env = check_runtime_env(row, args, branch, "hessian_merge", title, description)
    env.update(
        {
            "HESSIAN_NSPLIT": str(args.hessian_nsplit),
            "HESSIAN_MERGE_RUN": "true",
            "HESSIAN_MERGE_EIGEN": "true",
            "HESSIAN_KEEP_MATRIX": "false",
            # The merge rebuilds a complete model/check payload from the fit
            # plus Hessian units, then publishes only its diagnostic delta.
            "ATTACH_OUTPUT_MODE": "delta" if args.attach_hessians else "full",
            "MODEL_BASE_INPUT_JOB": fit_job,
            "BASE_MODEL_JOB": fit_job,
            "MODEL_ORIGINAL_BASE_INPUT_JOB": fit_job,
            # Keep the merge's diagnostic inputs independent from the base
            # fit and from concurrently attached jitter/retro/etc. outputs.
            "CHECK_INPUT_JOBS": " ".join(hessian_job_refs),
            "ATTACH_CHECK_TYPES": "hessian",
            "ATTACH_UPDATED_CHECK_TYPES": "hessian",
        }
    )
    overlay_metadata: dict[str, Any] = {}
    if args.attach_hessians:
        overlay_metadata = {
            "attached_work_parent_job": fit_job,
            "attached_work_latest": True,
            "attached_output_overlay": True,
            # Independent diagnostic overlays retain the compact base payload;
            # MFCL Shiny collects every attached diagnostic directory at load.
            "attached_output_overlay_preserve_payload": True,
            "attached_output_overlay_replace_names": ["hessian"],
            "attached_work_group": f"{args.flow_group}:{row['step_id']}:diagnostics",
            "attached_work_slot": f"diagnostics:{row['step_id']}:hessian",
            # This is only the predecessor from the same Hessian slot. Other
            # diagnostic slots may update the fit concurrently without being
            # serialized behind, or overwritten by, this merge.
            "previous_attached_output_job": predecessor,
            "same_slot_predecessor_job": predecessor,
            "attached_work_headline": "Diagnostics",
            "attached_work_label": f"{row['step_id']} Hessian",
            "attached_work_summary": "Merged Hessian diagnostic overlay for the originating sensitivity fit.",
            "attached_work_role": "diagnostic overlay",
            "auto_attach": True,
        }
    return {
        **submitter_fields(args),
        "checkout": {"mode": "full"},
        "input_jobs": input_jobs,
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "terminal_recruitment_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "check_type": "hessian-merge",
            "merged_check_type": "hessian",
            "model_selector": row["step_id"],
            "base_job": fit_job,
            "check_input_jobs": hessian_job_refs,
            "attach_check_types": ["hessian"],
            "attached_check_types": ["hessian"],
            "input_jobs": input_jobs,
            "input_jobs_override": True,
            # A failed Hessian part still writes an archive with its failure
            # metadata.  The merge turns that into an explicit
            # incomplete_parts/stitch_failed status for MFCL Shiny instead of
            # being dependency-blocked before it can publish any result.
            "allow_failed_input_jobs": True,
            "hessian_nsplit": args.hessian_nsplit,
            "parallel_units": False,
            "independent_diagnostic_merge": True,
            **overlay_metadata,
        },
        "tags": {
            "stage": "checks",
            "flow": args.flow_group,
            "experiment": GRID_CODE,
            "check_type": "hessian-merge",
            "merge_for": "hessian",
            "model": row["step_id"],
        },
    }


def hessian_attach_payload(
    row: dict[str, str],
    args: argparse.Namespace,
    branch: str,
    fit_job: str,
    hessian_merge_job: str,
    previous_attached_output_job: str = "",
) -> dict[str, Any]:
    """Attach a legacy merged Hessian as an independent delta overlay.

    Kflow only renders Diagnostics on a model job after a follow-up output is
    explicitly attached.  A dependency edge alone is intentionally not enough:
    it gives the scheduler an input relationship but does not replace the fit
    job's visible output bundle.
    """
    grid_code = str(getattr(args, "sensitivity_grid_code", GRID_CODE) or GRID_CODE)
    grid_label = str(getattr(args, "sensitivity_grid_label", GRID_LABEL) or GRID_LABEL)
    title = f"{grid_label} Hessian attach: {row['step_id']}"
    description = (
        f"Attach the merged Hessian diagnostic to the original {grid_label} "
        f"fit for {row['step_id']}."
    )
    env = check_runtime_env(row, args, branch, "attach-checks", title, description)
    predecessor = str(previous_attached_output_job or "").strip().lstrip("#")
    env.update(
        {
            "MODEL_BASE_INPUT_JOB": fit_job,
            "BASE_MODEL_JOB": fit_job,
            "MODEL_ORIGINAL_BASE_INPUT_JOB": fit_job,
            "CHECK_INPUT_JOBS": hessian_merge_job,
            "ATTACH_CHECK_TYPES": "hessian",
            "ATTACH_OUTPUT_MODE": "delta",
            "ATTACH_UPDATED_CHECK_TYPES": "hessian",
        }
    )
    input_jobs = [fit_job, hessian_merge_job]
    return {
        **submitter_fields(args),
        "checkout": {"mode": "full"},
        "title": title,
        "description": description,
        "input_jobs": input_jobs,
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "terminal_recruitment_sensitivity": True,
            "sensitivity_grid": grid_code,
            "check_type": "attach-checks",
            "model_selector": row["step_id"],
            "base_job": fit_job,
            "input_jobs": input_jobs,
            "check_input_jobs": [hessian_merge_job],
            "attach_check_types": ["hessian"],
            "attach_output_mode": "delta",
            "attached_output_overlay": True,
            "attached_output_overlay_preserve_payload": True,
            "attached_output_overlay_replace_names": ["hessian"],
            # Make the updated output an attached-work revision of the fit so
            # Kflow's job-page Diagnostics card can show its Hessian state.
            "attached_work_parent_job": fit_job,
            "attached_work_latest": True,
            "attached_work_group": f"{args.flow_group}:{row['step_id']}:diagnostics",
            "attached_work_slot": f"diagnostics:{row['step_id']}:hessian",
            "previous_attached_output_job": predecessor,
            "same_slot_predecessor_job": predecessor,
            "attached_work_headline": "Diagnostics",
            "attached_work_label": f"{row['step_id']} Hessian",
            "attached_work_summary": "Merged Hessian attached to the originating sensitivity fit.",
            "attached_work_role": "updated output",
            "independent_diagnostic_attachment": True,
            "auto_attach": True,
            # A non-PD or incomplete Hessian remains a factual diagnostic
            # result; attachment must publish that state rather than vanish.
            "allow_failed_input_jobs": True,
        },
        "tags": {
            "stage": "checks",
            "flow": args.flow_group,
            "experiment": grid_code,
            "check_type": "attach-checks",
            "merge_for": "hessian",
            "model": row["step_id"],
            "base_job": fit_job,
        },
    }


def results_payload(
    models: list[dict[str, str]],
    args: argparse.Namespace,
    model_jobs: list[str],
) -> dict[str, Any]:
    # One merge output per model gives results the rebuilt fitted model plus
    # its Hessian sidecar without duplicate fit/merge model keys.
    if len(model_jobs) != len(models) or any(not str(job).strip() for job in model_jobs):
        raise ValueError("Results require one non-empty Hessian merge job reference per selected model.")
    input_jobs = list(dict.fromkeys(str(job).strip() for job in model_jobs))
    if len(input_jobs) != len(models):
        raise ValueError("Results require unique Hessian merge job references for every selected model.")
    title = f"BET OPR 71/72/73 terminal-recruitment results ({len(models)} models)"
    description = (
        "Build the standard BET results/MFCL Shiny bundle from per-model "
        "Hessian merge outputs, preserving PDH, Non-PDH, and incomplete statuses."
    )
    env = {
        "TRIGGER_NEXT": "false",
        "FLOW_GROUP": args.flow_group,
        "JOB_TITLE": title,
        "JOB_DESCRIPTION": description,
        "JOB_KEY": "terminal-recruitment-717273-results",
        "PLOT_TITLE": "BET 2026 OPR 71/72/73 terminal-recruitment results",
        "MFCLSHINY_INTERACTIVE_VIEWER_TITLE": "BET 2026 OPR 71/72/73 terminal-recruitment viewer",
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
        # Figure generation and the portable viewer can be materially larger
        # than a normal one-model results job. Leave CPU/memory to Kflow's
        # results-input scaler, but reserve enough artifact space.
        "disk": "60GB",
        "input_jobs": input_jobs,
        "env": env,
        "metadata": {
            "flow_group": args.flow_group,
            "terminal_recruitment_sensitivity": True,
            "sensitivity_grid": GRID_CODE,
            "stage": "results",
            "model_count": len(models),
            "model_selectors": [row["step_id"] for row in models],
            "input_jobs": input_jobs,
            "input_jobs_override": True,
            # The standard results task accepts failed merge archives too. A
            # non-PD or incomplete merge still publishes its factual merged
            # model payload for MFCL Shiny review.
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
        # The canonical results task normally triggers the formal report. A
        # large sensitivity screen is intentionally review-only for now.
        "triggers": {},
    }


def default_manifest_path(flow_group: str) -> Path:
    safe = "".join(character if character.isalnum() or character in "-_." else "-" for character in flow_group)
    return ROOT / "work" / f"{safe}-launch.json"


def write_manifest(path: Path, manifest: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def load_or_create_manifest(path: Path, args: argparse.Namespace, branch: str, models: list[dict[str, str]]) -> dict[str, Any]:
    if args.resume and path.exists():
        manifest = json.loads(path.read_text(encoding="utf-8"))
        expected_steps = [row["step_id"] for row in models]
        manifest_steps = [str(entry.get("step_id") or "") for entry in manifest.get("models", [])]
        if manifest.get("schema") not in {MANIFEST_SCHEMA_V1, MANIFEST_SCHEMA_V2}:
            raise RuntimeError("The resume manifest has the wrong schema for the 71/72/73 grid.")
        if manifest.get("branch") != branch:
            raise RuntimeError("The resume manifest belongs to a different source branch.")
        if manifest.get("flow_group") != args.flow_group:
            raise RuntimeError("The resume manifest belongs to a different Kflow flow group.")
        if manifest.get("stepwise_task") != args.stepwise_task or manifest.get("results_task") != args.results_task:
            raise RuntimeError("The resume manifest belongs to different Kflow tasks.")
        if int(manifest.get("hessian_nsplit") or 0) != int(args.hessian_nsplit):
            raise RuntimeError("The resume manifest uses a different Hessian partition count.")
        if manifest_steps != expected_steps:
            raise RuntimeError("The resume manifest contains a different ordered model selection.")
        if (
            manifest.get("schema") == MANIFEST_SCHEMA_V2
            and bool(manifest.get("attach_hessians", True)) != bool(args.attach_hessians)
        ):
            raise RuntimeError(
                "The resume manifest uses a different direct Hessian-overlay setting."
            )
        return manifest
    return {
        "schema": MANIFEST_SCHEMA_V2,
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "branch": branch,
        "flow_group": args.flow_group,
        "stepwise_task": args.stepwise_task,
        "results_task": args.results_task,
        "hessian_nsplit": args.hessian_nsplit,
        "expected_job_counts": {
            "fits": len(models),
            "hessians": len(models) * args.hessian_nsplit,
            "hessian_merges": len(models),
            "hessian_attaches": 0,
            "results": 1,
            "total": len(models) * (2 + args.hessian_nsplit) + 1,
        },
        "attach_hessians": bool(args.attach_hessians),
        "hessian_merge_direct_overlay": bool(args.attach_hessians),
        "results_parent_stage": "hessian_merge",
        # Retained only so old manifests can still use the explicit backfill
        # command. New launches do not submit this task.
        "legacy_attach_task": args.attach_task,
        "submitter": {
            "host": args.remote_host,
            "user": args.remote_user,
            "base_dir": args.remote_base_dir,
        },
        "models": [{"step_id": row["step_id"]} for row in models],
    }


def manifest_entry(manifest: dict[str, Any], step_id: str) -> dict[str, Any]:
    for entry in manifest.get("models", []):
        if entry.get("step_id") == step_id:
            return entry
    entry = {"step_id": step_id}
    manifest.setdefault("models", []).append(entry)
    return entry


def job_number(entry: dict[str, Any], key: str) -> str:
    value = entry.get(key)
    if not isinstance(value, dict):
        return ""
    return str(value.get("job_number") or "").strip()


def emit_dry_run(task: str, payload: dict[str, Any]) -> None:
    print(json.dumps({"task": task, "payload": payload}, sort_keys=True))


def dry_run_job_number(task: str, payload: dict[str, Any]) -> str:
    metadata = payload.get("metadata") if isinstance(payload.get("metadata"), dict) else {}
    selector = str(metadata.get("model_selector") or "").strip()
    part = str(metadata.get("hessian_part") or "").strip()
    suffix = "-".join(value for value in (selector, part) if value)
    return f"DRY-{task}" + (f"-{suffix}" if suffix else "")


def submit_or_preview(base_url: str, token: str, task: str, payload: dict[str, Any], dry_run: bool) -> dict[str, str]:
    if dry_run:
        emit_dry_run(task, payload)
        return {"job_number": dry_run_job_number(task, payload), "job_id": "", "status": "dry-run"}
    return submitted_job(api_json("POST", f"{base_url}/api/job/{task}", token, payload), task)


def backfill_hessian_attachments(args: argparse.Namespace) -> int:
    """Attach Hessian merges recorded by a pre-attachment launch manifest.

    Earlier terminal-sensitivity manifests predate the explicit Kflow
    attached-output stage.  Their fit, Hessian and merge jobs are still valid;
    this routine adds only the missing child attachment jobs.  It deliberately
    does *not* resubmit fits, Hessians, merges, or an existing results job.
    """
    if not args.manifest:
        raise SystemExit("--backfill-hessian-attaches requires --manifest.")
    manifest_path = Path(args.manifest).expanduser()
    if not manifest_path.is_absolute():
        manifest_path = ROOT / manifest_path
    if not manifest_path.is_file():
        raise SystemExit(f"Launch manifest was not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    schema = str(manifest.get("schema") or "")
    if not schema.startswith("bet-2026-terminal-recruitment"):
        raise SystemExit("The supplied manifest is not a terminal-recruitment sensitivity launch manifest.")
    branch = str(manifest.get("branch") or args.branch).strip()
    flow_group = str(manifest.get("flow_group") or args.flow_group).strip()
    if not branch or not flow_group:
        raise SystemExit("The launch manifest must contain both branch and flow_group.")

    # Keep the original manifest's run context, including its submitter when
    # it was recorded.  The branch comes from the manifest rather than the
    # checked-out branch, so old 69 and newer 71/72/73 grids can both be fixed.
    args.branch = branch
    args.flow_group = flow_group
    args.hessian_nsplit = int(manifest.get("hessian_nsplit") or 1)
    is_717273_grid = "717273" in flow_group or "717273" in str(manifest.get("stepwise_task") or "")
    args.sensitivity_grid_code = GRID_CODE if is_717273_grid else "terminal-recruitment"
    args.sensitivity_grid_label = GRID_LABEL if is_717273_grid else "Terminal recruitment"
    submitter = manifest.get("submitter") if isinstance(manifest.get("submitter"), dict) else {}
    args.remote_host = str(submitter.get("host") or args.remote_host)
    args.remote_user = str(submitter.get("user") or args.remote_user)
    args.remote_base_dir = str(submitter.get("base_dir") or args.remote_base_dir)

    entries = manifest.get("models") if isinstance(manifest.get("models"), list) else []
    if not entries:
        raise SystemExit("The launch manifest contains no model records.")
    invalid_entries: list[str] = []
    fit_refs: list[str] = []
    merge_refs: list[str] = []
    for entry in entries:
        if not isinstance(entry, dict):
            invalid_entries.append("<invalid entry>")
            continue
        step = str(entry.get("step_id") or "").strip()
        fit_ref = job_number(entry, "fit")
        merge_ref = job_number(entry, "hessian_merge")
        if not step or not fit_ref or not merge_ref:
            invalid_entries.append(step or "<unnamed model>")
            continue
        fit_refs.append(fit_ref)
        merge_refs.append(merge_ref)
    if invalid_entries:
        raise SystemExit(
            "Cannot backfill attachments: missing fit or Hessian-merge references for "
            + ", ".join(invalid_entries)
        )
    duplicate_fits = sorted({ref for ref in fit_refs if fit_refs.count(ref) > 1})
    duplicate_merges = sorted({ref for ref in merge_refs if merge_refs.count(ref) > 1})
    if duplicate_fits or duplicate_merges:
        details = []
        if duplicate_fits:
            details.append("duplicate fit refs " + ", ".join(duplicate_fits))
        if duplicate_merges:
            details.append("duplicate merge refs " + ", ".join(duplicate_merges))
        raise SystemExit("Cannot backfill attachments: " + "; ".join(details))

    base_url = args.kflow_url.rstrip("/")
    token = os.environ.get("KFLOW_API_TOKEN", "")
    if not args.dry_run:
        if not token:
            raise SystemExit("Set KFLOW_API_TOKEN before submitting Kflow jobs.")
        if not args.skip_remote_branch_check:
            verify_remote_branch(branch)
        report_exists(base_url, token, args.attach_task)

    submitted = 0
    skipped = 0
    errors: list[str] = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        step = str(entry.get("step_id") or "").strip()
        if job_number(entry, "hessian_attach"):
            skipped += 1
            continue
        fit_ref = job_number(entry, "fit")
        merge_ref = job_number(entry, "hessian_merge")
        try:
            row = {"step_id": step}
            same_slot_predecessor = ""
            if not args.dry_run:
                same_slot_predecessor = latest_attached_output_job_for_slot(
                    base_url,
                    token,
                    fit_ref,
                    f"diagnostics:{step}:hessian",
                )
            attachment = submit_or_preview(
                base_url,
                token,
                args.attach_task,
                hessian_attach_payload(
                    row,
                    args,
                    branch,
                    fit_ref,
                    merge_ref,
                    previous_attached_output_job=same_slot_predecessor,
                ),
                args.dry_run,
            )
            if args.dry_run:
                submitted += 1
                continue
            entry["hessian_attach"] = attachment
            submitted += 1
            write_manifest(manifest_path, manifest)
            print(f"submitted Hessian attach {step}: job {attachment['job_number']}")
        except Exception as exc:  # Independent attachments must not block others.
            entry.setdefault("hessian_attach_errors", []).append(str(exc))
            errors.append(f"{step}: {exc}")
            if not args.dry_run:
                write_manifest(manifest_path, manifest)
            print(f"ERROR {step}: {exc}", file=sys.stderr)

    if not args.dry_run:
        manifest["hessian_attachment_backfill"] = {
            "updated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            "attach_task": args.attach_task,
            "submitted": submitted,
            "already_recorded": skipped,
            "errors": len(errors),
        }
        write_manifest(manifest_path, manifest)
    mode = "previewed" if args.dry_run else "submitted"
    print(
        f"Hessian attachment backfill: {mode}={submitted}, already-recorded={skipped}, "
        f"errors={len(errors)}, manifest={manifest_path}"
    )
    return 1 if errors else 0


def parse_args() -> argparse.Namespace:
    date_label = dt.date.today().strftime("%Y%m%d")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument("--stepwise-task", default=DEFAULT_STEPWISE_TASK)
    parser.add_argument("--results-task", default=DEFAULT_RESULTS_TASK)
    parser.add_argument("--check-prefix", default=DEFAULT_CHECK_PREFIX)
    parser.add_argument("--attach-task", default=DEFAULT_ATTACH_TASK)
    parser.add_argument(
        "--attach-hessians",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Publish each Hessian merge as a delta overlay on its fit job "
            "(default: true; no separate attachment job is submitted)."
        ),
    )
    parser.add_argument("--model-source-repo", default=DEFAULT_MODEL_REPO)
    parser.add_argument("--branch", default=DEFAULT_BRANCH, help="Source branch for the focused 71/72/73 grid.")
    parser.add_argument("--models", default="", help="Optional comma-separated subset of step IDs.")
    parser.add_argument("--limit", type=int, default=0, help="Optional cap after model selection (for a small test launch).")
    parser.add_argument("--flow-group", default=f"bet-2026-terminal-recruitment-717273-{date_label}")
    parser.add_argument("--hessian-nsplit", default="auto", choices=("auto", "1", "2"))
    parser.add_argument("--phase-convergence", default="-5", help="MFCL phase 10/11 convergence criterion.")
    parser.add_argument("--remote-host", default=DEFAULT_SUVA_HOST)
    parser.add_argument("--remote-user", default=DEFAULT_SUVA_USER)
    parser.add_argument("--remote-base-dir", default=DEFAULT_SUVA_BASE_DIR)
    parser.add_argument("--manifest", default="", help="JSON launch manifest; defaults under ignored work/.")
    parser.add_argument("--resume", action="store_true", help="Reuse submitted job references recorded in --manifest.")
    parser.add_argument(
        "--backfill-hessian-attaches",
        action="store_true",
        help="Legacy only: submit missing explicit Hessian attachment jobs from an old manifest.",
    )
    parser.add_argument("--skip-remote-branch-check", action="store_true")
    parser.add_argument("--dry-run", action="store_true", help="Validate the grid and print API payloads without submitting.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.backfill_hessian_attaches:
        return backfill_hessian_attachments(args)
    if args.limit < 0:
        raise SystemExit("--limit must be non-negative.")
    branch = args.branch or current_branch()
    models = configured_models(args.models)
    if args.limit:
        models = models[: args.limit]
    if not models:
        raise SystemExit("No models selected for the terminal-recruitment sensitivity launch.")
    if not args.models and not args.limit and len(models) != EXPECTED_FULL_MODEL_COUNT:
        raise SystemExit(
            f"Expected the full 71/72/73 grid to contain {EXPECTED_FULL_MODEL_COUNT} models; "
            f"resolved {len(models)}."
        )

    if args.hessian_nsplit == "auto":
        args.hessian_nsplit = 1 if len(models) > 50 else 2
    else:
        args.hessian_nsplit = int(args.hessian_nsplit)
    if len(models) > 50 and args.hessian_nsplit != 1:
        raise SystemExit("More than 50 selected models require --hessian-nsplit 1 (one Hessian job per model).")

    manifest_path = Path(args.manifest).expanduser() if args.manifest else default_manifest_path(args.flow_group)
    if not manifest_path.is_absolute():
        manifest_path = ROOT / manifest_path
    manifest = load_or_create_manifest(manifest_path, args, branch, models)

    base_url = args.kflow_url.rstrip("/")
    token = os.environ.get("KFLOW_API_TOKEN", "")
    if not args.dry_run:
        if not token:
            raise SystemExit("Set KFLOW_API_TOKEN before submitting Kflow jobs.")
        if not args.skip_remote_branch_check:
            verify_remote_branch(branch)
        for task in (
            args.stepwise_task,
            f"{args.check_prefix}-hessian",
            f"{args.check_prefix}-hessian-merge",
            args.results_task,
        ):
            report_exists(base_url, token, task)

    errors: list[str] = []
    for row in models:
        step = row["step_id"]
        entry = manifest_entry(manifest, step)
        try:
            fit_ref = job_number(entry, "fit")
            if not fit_ref:
                entry["fit"] = submit_or_preview(
                    base_url, token, args.stepwise_task, fit_payload(row, args, branch), args.dry_run
                )
                fit_ref = job_number(entry, "fit")
                if not args.dry_run:
                    print(f"submitted fit {step}: job {fit_ref}")
                write_manifest(manifest_path, manifest)

            parts = entry.get("hessian_parts") if isinstance(entry.get("hessian_parts"), list) else []
            hessian_refs = [str(part.get("job_number") or "") for part in parts if isinstance(part, dict)]
            if len(hessian_refs) != args.hessian_nsplit or any(not ref for ref in hessian_refs):
                parts = []
                for part in range(1, args.hessian_nsplit + 1):
                    submitted = submit_or_preview(
                        base_url,
                        token,
                        f"{args.check_prefix}-hessian",
                        hessian_payload(row, args, branch, fit_ref, part),
                        args.dry_run,
                    )
                    parts.append(submitted)
                    if not args.dry_run:
                        print(f"submitted Hessian {part}/{args.hessian_nsplit} {step}: job {submitted['job_number']}")
                    entry["hessian_parts"] = parts
                    write_manifest(manifest_path, manifest)
                hessian_refs = [part["job_number"] for part in parts]

            merge_ref = job_number(entry, "hessian_merge")
            if not merge_ref:
                same_slot_predecessor = ""
                if args.attach_hessians and not args.dry_run:
                    same_slot_predecessor = latest_attached_output_job_for_slot(
                        base_url,
                        token,
                        fit_ref,
                        f"diagnostics:{row['step_id']}:hessian",
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
                        previous_attached_output_job=same_slot_predecessor,
                    ),
                    args.dry_run,
                )
                merge_ref = job_number(entry, "hessian_merge")
                if not args.dry_run:
                    print(f"submitted Hessian merge {step}: job {merge_ref}")
                write_manifest(manifest_path, manifest)

        except Exception as exc:  # Keep the remaining independent models launchable.
            entry.setdefault("errors", []).append(str(exc))
            errors.append(f"{step}: {exc}")
            write_manifest(manifest_path, manifest)
            print(f"ERROR {step}: {exc}", file=sys.stderr)

    # New launches fan results directly into the merge jobs. For a resumed v1
    # manifest, preserve an already-recorded explicit attachment reference;
    # missing legacy attachments are never created implicitly here.
    result_parent_refs = []
    for row in models:
        entry = manifest_entry(manifest, row["step_id"])
        legacy_attach_ref = (
            job_number(entry, "hessian_attach")
            if manifest.get("schema") == MANIFEST_SCHEMA_V1
            else ""
        )
        result_parent_refs.append(legacy_attach_ref or job_number(entry, "hessian_merge"))
    missing_parent_steps = [
        row["step_id"] for row, parent_ref in zip(models, result_parent_refs) if not parent_ref
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
            write_manifest(manifest_path, manifest)
        except Exception as exc:
            errors.append(f"results: {exc}")
            manifest.setdefault("results_errors", []).append(str(exc))
            write_manifest(manifest_path, manifest)
            print(f"ERROR results: {exc}", file=sys.stderr)
    elif not complete_fan_in:
        pending = {
            "parent_type": "hessian_merge_or_legacy_attach",
            "missing_parent_steps": missing_parent_steps,
            "duplicate_parent_job_refs": duplicate_parent_refs,
            "resolved_parent_count": sum(bool(ref) for ref in result_parent_refs),
            "expected_parent_count": len(models),
        }
        manifest["results_pending"] = pending
        details = []
        if missing_parent_steps:
            details.append("missing Hessian merge jobs for " + ", ".join(missing_parent_steps))
        if duplicate_parent_refs:
            details.append("duplicate Hessian merge refs " + ", ".join(duplicate_parent_refs))
        message = "results fan-in incomplete: " + "; ".join(details)
        errors.append(message)
        print(f"PENDING {message}; rerun with --resume after repairing those chains.", file=sys.stderr)

    manifest["updated_at"] = dt.datetime.now(dt.timezone.utc).isoformat()
    manifest["selected_model_count"] = len(models)
    manifest["hessian_nsplit"] = args.hessian_nsplit
    if manifest.get("schema") == MANIFEST_SCHEMA_V2:
        manifest["attach_hessians"] = bool(args.attach_hessians)
        manifest["hessian_merge_direct_overlay"] = bool(args.attach_hessians)
        manifest["results_parent_stage"] = "hessian_merge"
        manifest["legacy_attach_task"] = args.attach_task
        manifest["expected_total_job_count"] = len(models) * (2 + args.hessian_nsplit) + 1
        manifest["expected_job_counts"] = {
            "fits": len(models),
            "hessians": len(models) * args.hessian_nsplit,
            "hessian_merges": len(models),
            "hessian_attaches": 0,
            "results": 1,
            "total": manifest["expected_total_job_count"],
        }
        if len(models) == EXPECTED_FULL_MODEL_COUNT and args.hessian_nsplit == 1:
            manifest["expected_full_grid_job_count"] = EXPECTED_FULL_JOB_COUNT
    write_manifest(manifest_path, manifest)
    print(
        f"terminal-recruitment launch: {len(models)} models, Hessian parts/model={args.hessian_nsplit}, "
        f"BET results={job_number(manifest, 'results') or 'not-submitted'}, "
        f"manifest={manifest_path}"
    )
    if errors:
        print(f"{len(errors)} model submission chain(s) had errors; rerun with --resume and the same --manifest.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
