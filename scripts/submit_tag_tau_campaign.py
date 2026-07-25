#!/usr/bin/env python3
"""Submit the frozen 10 x 3 BET tag-dispersion campaign to Kflow."""

from __future__ import annotations

import csv
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "kflow-tag-tau-campaign.yaml"
SCENARIOS = ROOT / "config" / "tag-tau-scenarios.csv"
LOWERS = ROOT / "config" / "tag-tau-lower-bounds.csv"


def api_json(method: str, url: str, token: str, payload: dict) -> dict:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: HTTP {exc.code}: {detail}") from exc


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def main() -> int:
    token = os.environ.get("KFLOW_API_TOKEN", "")
    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before submitting the campaign.")
    base_url = os.environ.get("KFLOW_URL", "http://127.0.0.1:8089").rstrip("/")
    config = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))
    task_name = str(config["name"])
    task_path = urllib.parse.quote(task_name, safe="")
    resources = config["resources"]
    scenarios = read_rows(SCENARIOS)
    lowers = read_rows(LOWERS)

    payloads: list[tuple[str, dict]] = []
    for scenario in scenarios:
        scenario_id = scenario["scenario"]
        short_id = scenario_id.replace("g0", "G0").replace("g10", "G10")
        for lower in lowers:
            lower_value = lower["tau_lower"]
            lower_x100 = lower["lower_x100"]
            label = f"Tag tau | {short_id} | lower {lower_value}"
            description = (
                "Independent full native-MFCL doitall sensitivity from the "
                "Job 15989 specification. Estimate "
                f"{scenario['estimated_tau']} negative-binomial tag-recapture "
                f"tau parameter(s) using {scenario['recapture_fishery_strata']}; "
                f"tau lower bound {lower_value}, start {lower['tau_start']}. "
                "Fixed Lorenzen M, SC22-IP10 K=0.15 mixing, reporting-rate "
                "groups/priors/penalties, DM G8 Nmax25, data, and the Job 15984 "
                "selectivity grouping are unchanged. No fixed tag-likelihood "
                "multiplier is applied."
            )
            env = {
                **config["env"],
                "TAG_TAU_SCENARIO": scenario_id,
                "TAG_TAU_LOWER_X100": lower_x100,
                "JOB_TITLE": f"BET 2026 tag-recapture dispersion | {short_id}, lower {lower_value}",
                "JOB_DESCRIPTION": description,
                "MODEL_LABEL": label,
                "JOB_KEY": f"tag-tau-{scenario_id}-lb{lower_value}",
            }
            payload = {
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
                    **config["tags"],
                    "tau_scenario": scenario_id,
                    "tau_lower": lower_value,
                },
                "metadata": {
                    **config["metadata"],
                    "tau_scenario": scenario_id,
                    "estimated_tau_count": int(scenario["estimated_tau"]),
                    "tau_lower": int(lower_value),
                    "tau_start": int(lower["tau_start"]),
                    "recapture_fishery_strata": scenario["recapture_fishery_strata"],
                    "purpose": scenario["purpose"],
                    "inputs_frozen": True,
                    "independent_fit": True,
                },
                "triggers": {},
            }
            payloads.append((f"{scenario_id}-lb{lower_value}", payload))

    results: list[dict] = []
    failures: list[str] = []
    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = {
            executor.submit(
                api_json,
                "POST",
                f"{base_url}/api/job/{task_path}",
                token,
                payload,
            ): key
            for key, payload in payloads
        }
        for future in as_completed(futures):
            key = futures[future]
            try:
                response = future.result()
                job = response.get("job", response)
                results.append(
                    {
                        "key": key,
                        "job_number": job.get("job_number"),
                        "status": job.get("status"),
                    }
                )
            except Exception as exc:
                failures.append(f"{key}: {exc}")

    results.sort(key=lambda row: row["key"])
    print(json.dumps({"submitted": results, "failures": failures}, indent=2))
    if failures or len(results) != 30:
        raise SystemExit("Campaign submission was incomplete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
