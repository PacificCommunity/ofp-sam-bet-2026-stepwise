#!/usr/bin/env python3
"""Register the isolated Kflow task for the terminal-recruitment grid.

The normal ``ofp-sam-bet-2026-stepwise`` task intentionally remains on main.
This wrapper reuses its proven runtime/local-app definition but registers it
under a separate task code and the current sensitivity branch.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from register_kflow_task import (  # noqa: E402
    api_json,
    build_payload,
    existing_report,
    read_yaml,
    repo_full_name,
    run_git,
)


DEFAULT_TASK = "ofp-sam-bet-2026-stepwise-terminal-recruitment-717273"
DEFAULT_BRANCH = "experiment/step12-terminal-recruitment-71-73"
EXPECTED_MODEL_COUNT = 104


def sensitivity_count(repo_root: Path) -> int:
    command = (
        "source('R/step12_terminal_sensitivity_config.R'); "
        "cat(length(terminal_sensitivity_run_step_ids()))"
    )
    result = subprocess.run(
        ["Rscript", "-e", command],
        cwd=repo_root,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return int(result.stdout.strip())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="Repository root used for git metadata.")
    parser.add_argument("--task-name", default=DEFAULT_TASK, help="Separate Kflow task code to register.")
    parser.add_argument("--repo-full-name", default="", help="Override GitHub owner/repo.")
    parser.add_argument("--branch", default=DEFAULT_BRANCH, help="Sensitivity source branch.")
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument("--dry-run", action="store_true", help="Print the registration payload without changing Kflow.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = (ROOT / args.repo_root).resolve()
    branch = args.branch or run_git(repo_root, "branch", "--show-current") or DEFAULT_BRANCH
    count = sensitivity_count(repo_root)
    if count != EXPECTED_MODEL_COUNT:
        raise SystemExit(
            f"Expected {EXPECTED_MODEL_COUNT} focused 71/72/73 models, but job-config resolved {count}."
        )

    config = read_yaml(repo_root / "kflow.yaml")
    env: dict[str, Any] = dict(config.get("env") or {})
    # Do not make the UI's default one serial 104-model run. The dedicated
    # launcher sends one explicit STEP_SELECT per independent Kflow job.
    env.update(
        {
            "STEP_SELECT": "12-OrthogonalPoly",
            "JOB_TITLE": "OPR 71/72/73 terminal recruitment control",
            "JOB_DESCRIPTION": (
                f"One-model control run for the {count}-model terminal-recruitment grid; "
                "use scripts/launch_terminal_recruitment_sensitivity.py for the parallel flow."
            ),
            "MODEL_LABEL": "OPR 71/72/73 terminal recruitment control",
            "JOB_KEY": "terminal-recruitment-717273-control",
            "FLOW_GROUP": "bet-2026-terminal-recruitment-717273",
            "TRIGGER_NEXT": "false",
            "BET_PHASE10_11_CONVERGENCE": "-5",
        }
    )
    config.update(
        {
            "name": args.task_name,
            "description": (
                f"Isolated {count}-model BET 2026 OPR 71/72/73 terminal-recruitment runner. "
                "The normal stepwise task remains on main."
            ),
            "branch": branch,
            "env": env,
            # Keep the normal task's original submitter untouched. This
            # isolated task and its manual UI reruns always target Suva.
            "remote_host": "suvofpsubmit.corp.spc.int",
            "remote_user": "kyuhank",
            "remote_base_dir": "/home/kyuhank/KflowOutput",
        }
    )
    metadata = dict(config.get("metadata") or {})
    metadata["terminal_recruitment_sensitivity"] = {
        "grid": "terminal-recruitment-717273",
        "model_count": count,
        "fit_job_count": count,
        "hessian_job_count": count,
        "hessian_merge_job_count": count,
        "hessian_attach_job_count": count,
        "results_job_count": 1,
        "total_job_count": 4 * count + 1,
        "hessian_parts_per_model": 1,
        "launch_mode": (
            "one fit, one Hessian, one Hessian merge, and one Hessian attachment "
            "per model, then one results job"
        ),
        "normal_stepwise_task_preserved": True,
    }
    config["metadata"] = metadata

    base_url = args.kflow_url.rstrip("/")
    token = os.environ.get("KFLOW_API_TOKEN", "")
    existing = existing_report(base_url, token, args.task_name) if token else {}
    payload_args = SimpleNamespace(
        task_name=args.task_name,
        repo_full_name=args.repo_full_name,
        branch=branch,
    )
    payload = build_payload(config, repo_root, existing, payload_args)

    if args.dry_run:
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0
    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before registering the Kflow task.")

    response = api_json("POST", f"{base_url}/api/report/{args.task_name}", token, payload)
    report = response.get("report", response)
    code = report.get("code", args.task_name) if isinstance(report, dict) else args.task_name
    print(f"registered {code}: {repo_full_name(repo_root)}@{branch} ({count} models)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
