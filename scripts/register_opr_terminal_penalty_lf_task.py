#!/usr/bin/env python3
"""Register the isolated Step 12 OPR terminal-penalty/LF Kflow task.

The normal main-branch stepwise task is not modified.  This wrapper reuses the
repository's reviewed kflow.yaml runtime and local-app definition, but pins a
separate task code to the sensitivity branch and Suva submitter.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from launch_opr_terminal_penalty_lf_sensitivity import (  # noqa: E402
    DEFAULT_BRANCH,
    DEFAULT_STEPWISE_TASK,
    DEFAULT_SUVA_BASE_DIR,
    DEFAULT_SUVA_HOST,
    DEFAULT_SUVA_USER,
    GRID_CODE,
    configured_models,
    resolve_hessian_nsplit,
    verify_remote_branch,
)
from register_kflow_task import (  # noqa: E402
    api_json,
    build_payload,
    existing_report,
    read_yaml,
    repo_full_name,
)


EXPECTED_DOCKER_IMAGE = "ghcr.io/pacificcommunity/tuna-flow:v2.2"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--task-name", default=DEFAULT_STEPWISE_TASK)
    parser.add_argument("--repo-full-name", default="")
    parser.add_argument("--branch", default=DEFAULT_BRANCH)
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def registration_payload(args: argparse.Namespace) -> tuple[dict[str, Any], int, int, str]:
    repo_root = (ROOT / args.repo_root).resolve()
    branch = str(args.branch or DEFAULT_BRANCH).strip()
    rows = configured_models("")
    model_count = len(rows)
    hessian_nsplit = resolve_hessian_nsplit(model_count, "auto")
    default_step = rows[0]["step_id"]

    config = read_yaml(repo_root / "kflow.yaml")
    docker_image = str(config.get("docker_image") or "").strip()
    if docker_image != EXPECTED_DOCKER_IMAGE:
        raise RuntimeError(
            f"The isolated task requires {EXPECTED_DOCKER_IMAGE}; kflow.yaml uses "
            f"{docker_image or '<missing>'}."
        )

    env: dict[str, Any] = dict(config.get("env") or {})
    env.update(
        {
            # Keep the Kflow UI default to one model.  The launcher supplies a
            # different explicit selector for every independent fit job.
            "STEP_SELECT": default_step,
            "STEPWISE_ALLOW_DISABLED_SELECTED": "true",
            "STEPWISE_SAVE_RAW_MFCL_INPUTS": "true",
            "JOB_TITLE": "Step 12 OPR terminal-penalty/LF sensitivity control",
            "JOB_DESCRIPTION": (
                f"One-model control for the {model_count}-model isolated sensitivity; "
                "use the dedicated launcher for the complete parallel flow."
            ),
            "MODEL_LABEL": "Step 12 OPR terminal-penalty/LF sensitivity control",
            "JOB_KEY": f"{GRID_CODE}-control",
            "FLOW_GROUP": f"bet-2026-{GRID_CODE}",
            "TRIGGER_NEXT": "false",
            # Broad screening defaults to 1e-4. Kflow or the launcher may
            # override this with -5 for shortlisted production reruns.
            "BET_PHASE10_11_CONVERGENCE": "-4",
        }
    )
    config.update(
        {
            "name": args.task_name,
            "description": (
                f"Isolated {model_count}-model BET 2026 Step 12 OPR terminal-penalty "
                "and LF/selectivity sensitivity runner; the normal task remains on main."
            ),
            "branch": branch,
            "env": env,
            "remote_host": DEFAULT_SUVA_HOST,
            "remote_user": DEFAULT_SUVA_USER,
            "remote_base_dir": DEFAULT_SUVA_BASE_DIR,
            # This task is launched as an explicit fit -> Hessian -> merge ->
            # results graph. Inheriting the ordinary stepwise success trigger
            # would create one unintended results job per fit.
            "triggers": {},
        }
    )
    total_jobs = model_count * (2 + hessian_nsplit) + 1
    metadata = dict(config.get("metadata") or {})
    metadata["opr_terminal_penalty_lf_sensitivity"] = {
        "grid": GRID_CODE,
        "model_count": model_count,
        "fit_job_count": model_count,
        "hessian_job_count": model_count * hessian_nsplit,
        "hessian_merge_job_count": model_count,
        "hessian_attach_job_count": 0,
        "results_job_count": 1,
        "total_job_count": total_jobs,
        "hessian_parts_per_model": hessian_nsplit,
        "hessian_merge_direct_overlay": True,
        "results_parent_stage": "hessian_merge",
        "launch_mode": (
            f"one fit, {hessian_nsplit} Hessian part(s), and one direct-overlay merge "
            "per model, followed by one results fan-in"
        ),
        "normal_stepwise_task_preserved": True,
        "raw_mfcl_inputs_saved": True,
        "automatic_fit_triggers": False,
    }
    config["metadata"] = metadata

    token = os.environ.get("KFLOW_API_TOKEN", "")
    base_url = args.kflow_url.rstrip("/")
    existing = (
        existing_report(base_url, token, args.task_name)
        if token and not args.dry_run
        else {}
    )
    payload_args = SimpleNamespace(
        task_name=args.task_name,
        repo_full_name=args.repo_full_name,
        branch=branch,
    )
    payload = build_payload(config, repo_root, existing, payload_args)
    return payload, model_count, hessian_nsplit, branch


def main() -> int:
    args = parse_args()
    payload, model_count, hessian_nsplit, branch = registration_payload(args)
    if args.dry_run:
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0

    token = os.environ.get("KFLOW_API_TOKEN", "")
    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before registering the Kflow task.")
    verify_remote_branch(branch)
    base_url = args.kflow_url.rstrip("/")
    response = api_json("POST", f"{base_url}/api/report/{args.task_name}", token, payload)
    report = response.get("report", response)
    code = report.get("code", args.task_name) if isinstance(report, dict) else args.task_name
    print(
        f"registered {code}: {repo_full_name((ROOT / args.repo_root).resolve())}@{branch} "
        f"({model_count} models; Hessian nsplit={hessian_nsplit})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
