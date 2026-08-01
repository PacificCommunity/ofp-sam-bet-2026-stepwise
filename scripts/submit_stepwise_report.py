#!/usr/bin/env python3
"""Submit the dynamic stepwise report from one upstream viewer job."""

from __future__ import annotations

import argparse
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any


DEFAULT_TASK = "ofp-sam-bet-2026-stepwise-report"


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
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed: HTTP {exc.code}: {detail}") from exc
    return json.loads(raw.decode("utf-8")) if raw else {}


def get_job(base_url: str, token: str, reference: str | int) -> dict[str, Any]:
    ref = urllib.parse.quote(str(reference), safe="")
    response = api_json("GET", f"{base_url}/api/job/{ref}", token)
    job = response.get("job", response)
    if not isinstance(job, dict) or not job.get("job_number"):
        raise RuntimeError(f"Kflow job was not found: {reference}")
    return job


def source_job_numbers(viewer: dict[str, Any]) -> list[int]:
    metadata = viewer.get("metadata") if isinstance(viewer.get("metadata"), dict) else {}
    values = metadata.get("source_jobs") or metadata.get("selected_input_jobs") or []
    if isinstance(values, str):
        values = [part.strip() for part in values.replace(";", ",").split(",")]
    numbers: list[int] = []
    for value in values:
        try:
            number = int(str(value).lstrip("#"))
        except (TypeError, ValueError):
            continue
        if number not in numbers:
            numbers.append(number)
    if not numbers:
        raise RuntimeError("The viewer job metadata does not contain source_jobs or selected_input_jobs.")
    return numbers


def first_text(*values: Any) -> str:
    for value in values:
        text = str(value or "").strip()
        if text:
            return text
    return ""


def source_record(job: dict[str, Any], order: int, row: str) -> dict[str, Any]:
    metadata = job.get("metadata") if isinstance(job.get("metadata"), dict) else {}
    tags = job.get("tags") if isinstance(job.get("tags"), dict) else {}
    env = job.get("env") if isinstance(job.get("env"), dict) else {}
    step_id = first_text(tags.get("step"), env.get("STEP_SELECT"), metadata.get("major_step"), row)
    model_label = first_text(tags.get("model_label"), env.get("MODEL_LABEL"), env.get("JOB_TITLE"), step_id)
    return {
        "order": order,
        "row": row.removesuffix("-alt"),
        "step_id": step_id,
        "job_number": int(job["job_number"]),
        "job_title": first_text(env.get("JOB_TITLE"), metadata.get("job_title"), model_label),
        "model_label": model_label,
        "change_axis": first_text(metadata.get("change_axis"), metadata.get("job_description"), model_label),
        "scientific_parent_id": first_text(metadata.get("scientific_parent")),
        "selected": True,
        "task": first_text(job.get("report_code")),
        "status": first_text(job.get("status")),
    }


def mark_selected_path(records: list[dict[str, Any]]) -> None:
    if not records:
        return
    by_step = {record["step_id"]: record for record in records}
    selected: set[str] = set()
    current = records[-1]["step_id"]
    while current and current in by_step and current not in selected:
        selected.add(current)
        current = by_step[current]["scientific_parent_id"]
    # If parent metadata are absent, retain the supplied order as the pathway.
    if len(selected) == 1 and len(records) > 1:
        selected = set(by_step)
    for record in records:
        record["selected"] = record["step_id"] in selected


def build_source_index(
    viewer: dict[str, Any],
    source_jobs: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    metadata = viewer.get("metadata") if isinstance(viewer.get("metadata"), dict) else {}
    rows = metadata.get("source_rows") or []
    if not isinstance(rows, list) or len(rows) != len(source_jobs):
        rows = [str(index) for index in range(1, len(source_jobs) + 1)]
    records = [
        source_record(job, order=index, row=str(rows[index - 1]))
        for index, job in enumerate(source_jobs, start=1)
    ]
    mark_selected_path(records)
    return records


def submission_payload(
    viewer: dict[str, Any],
    records: list[dict[str, Any]],
    include_source_jobs: bool = False,
) -> dict[str, Any]:
    viewer_number = int(viewer["job_number"])
    source_numbers = [int(record["job_number"]) for record in records]
    source_label = ",".join(f"#{job_number}" for job_number in source_numbers)
    job_title = (
        f"BET 2026 stepwise report | viewer #{viewer_number} | models {source_label}"
    )
    input_jobs = [viewer_number]
    if include_source_jobs:
        input_jobs.extend(source_numbers)
    input_jobs = list(dict.fromkeys(input_jobs))
    return {
        "input_jobs": input_jobs,
        "env": {
            "STEPWISE_VIEWER_JOB": str(viewer_number),
            "STEPWISE_SOURCE_INDEX_JSON": json.dumps(records, separators=(",", ":")),
            "STEPWISE_MODEL_JOBS": "",
        },
        "tags": {
            "stage": "stepwise-report",
            "viewer_job": str(viewer_number),
            "model_count": str(len(records)),
            "dynamic_inputs": "true",
        },
        "metadata": {
            "job_key": "dynamic-stepwise-report",
            "job_title": job_title,
            "job_description": (
                "Stepwise report, SC figures, runtime tables, and offline interactive viewer "
                "generated from the selected upstream viewer job."
            ),
            "viewer_job": viewer_number,
            "source_jobs": source_numbers,
            "source_rows": [record["row"] for record in records],
            "model_count": len(records),
            "dynamic_inputs": True,
            "interactive_viewer": True,
            "source_index_embedded": True,
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--viewer-job", required=True, help="Completed upstream viewer job number.")
    parser.add_argument("--task-name", default=DEFAULT_TASK)
    parser.add_argument("--kflow-url", default=os.environ.get("KFLOW_URL", "http://127.0.0.1:8089"))
    parser.add_argument(
        "--include-source-jobs",
        action="store_true",
        help="Also stage fitted-model source archives, enabling plot regeneration if the viewer bundle is absent.",
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    token = os.environ.get("KFLOW_API_TOKEN", "").strip()
    if not token:
        raise SystemExit("Set KFLOW_API_TOKEN before submitting the report.")
    base_url = args.kflow_url.rstrip("/")
    viewer = get_job(base_url, token, args.viewer_job)
    if viewer.get("status") != "completed":
        raise SystemExit(f"Viewer job {viewer['job_number']} is not completed: {viewer.get('status')}")
    numbers = source_job_numbers(viewer)
    jobs = [get_job(base_url, token, number) for number in numbers]
    incomplete = [str(job["job_number"]) for job in jobs if job.get("status") != "completed"]
    if incomplete:
        raise SystemExit("Source jobs are not completed: " + ", ".join(incomplete))
    records = build_source_index(viewer, jobs)
    payload = submission_payload(viewer, records, include_source_jobs=args.include_source_jobs)
    if args.dry_run:
        print(json.dumps(payload, indent=2, sort_keys=True))
        return 0
    task = urllib.parse.quote(args.task_name, safe="")
    response = api_json("POST", f"{base_url}/api/job/{task}", token, payload)
    job = response.get("job", response)
    print(f"submitted dynamic stepwise report: {job.get('job_number', job.get('id', 'submitted'))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
