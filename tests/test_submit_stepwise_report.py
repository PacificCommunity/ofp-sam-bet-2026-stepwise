from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "submit_stepwise_report.py"
SPEC = importlib.util.spec_from_file_location("submit_stepwise_report", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def fake_job(number: int, step: str, parent: str, label: str) -> dict:
    return {
        "job_number": number,
        "status": "completed",
        "report_code": "changing-source-task",
        "tags": {"step": step, "model_label": label},
        "metadata": {"scientific_parent": parent, "change_axis": f"change {label}"},
        "env": {"JOB_TITLE": f"title {label}"},
    }


class DynamicStepwiseSubmissionTests(unittest.TestCase):
    def test_runtime_metadata_drives_jobs_order_and_branch(self) -> None:
        viewer = {
            "job_number": 900,
            "status": "completed",
            "metadata": {
                "source_jobs": [801, 802, 803, 804],
                "source_rows": ["01", "02a", "02b", "03"],
            },
        }
        jobs = [
            fake_job(801, "01-base", "external", "base"),
            fake_job(802, "02a-branch", "01-base", "branch"),
            fake_job(803, "02b-carry", "01-base", "carry"),
            fake_job(804, "03-final", "02b-carry", "final"),
        ]
        records = MODULE.build_source_index(viewer, jobs)
        self.assertEqual([row["job_number"] for row in records], [801, 802, 803, 804])
        self.assertFalse(records[1]["selected"])
        self.assertTrue(records[2]["selected"])

        payload = MODULE.submission_payload(viewer, records)
        self.assertEqual(payload["input_jobs"], [900])
        embedded = json.loads(payload["env"]["STEPWISE_SOURCE_INDEX_JSON"])
        self.assertEqual(embedded, records)

    def test_optional_payload_regeneration_stages_sources(self) -> None:
        viewer = {"job_number": 900}
        records = [{"job_number": 801, "row": "01"}, {"job_number": 802, "row": "02"}]
        payload = MODULE.submission_payload(viewer, records, include_source_jobs=True)
        self.assertEqual(payload["input_jobs"], [900, 801, 802])


if __name__ == "__main__":
    unittest.main()
