import importlib.util
import json
import tempfile
import unittest
from unittest import mock
from pathlib import Path
from types import SimpleNamespace


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "launch_terminal_recruitment_sensitivity.py"
KFLOW_CONFIG = SCRIPT.parents[1] / "kflow.yaml"
SPEC = importlib.util.spec_from_file_location("terminal_recruitment_launcher", SCRIPT)
launcher = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(launcher)


def launch_args(**overrides):
    values = {
        "attach_hessians": True,
        "attach_task": launcher.DEFAULT_ATTACH_TASK,
        "flow_group": "test-terminal-grid",
        "hessian_nsplit": 2,
        "model_source_repo": launcher.DEFAULT_MODEL_REPO,
        "remote_base_dir": launcher.DEFAULT_SUVA_BASE_DIR,
        "remote_host": launcher.DEFAULT_SUVA_HOST,
        "remote_user": launcher.DEFAULT_SUVA_USER,
        "results_task": launcher.DEFAULT_RESULTS_TASK,
        "resume": False,
        "stepwise_task": launcher.DEFAULT_STEPWISE_TASK,
    }
    values.update(overrides)
    return SimpleNamespace(**values)


class HessianMergePayloadTests(unittest.TestCase):
    def test_merge_consumes_fit_and_hessian_jobs_and_overlays_fit(self):
        args = launch_args()
        payload = launcher.hessian_merge_payload(
            {"step_id": "12-test"},
            args,
            launcher.DEFAULT_BRANCH,
            "3001",
            ["3002", "3003"],
        )

        self.assertEqual(payload["input_jobs"], ["3001", "3002", "3003"])
        self.assertEqual(payload["metadata"]["input_jobs"], payload["input_jobs"])
        self.assertEqual(payload["metadata"]["base_job"], "3001")
        self.assertEqual(payload["metadata"]["attached_work_parent_job"], "3001")
        self.assertTrue(payload["metadata"]["attached_work_latest"])
        self.assertTrue(payload["metadata"]["attached_output_overlay"])
        self.assertTrue(payload["metadata"]["attached_output_overlay_preserve_payload"])
        self.assertEqual(
            payload["metadata"]["attached_output_overlay_replace_names"], ["hessian"]
        )
        self.assertEqual(
            payload["metadata"]["attached_work_slot"],
            "diagnostics:12-test:hessian",
        )
        self.assertEqual(payload["metadata"]["previous_attached_output_job"], "")
        self.assertEqual(payload["metadata"]["same_slot_predecessor_job"], "")
        self.assertEqual(payload["metadata"]["check_input_jobs"], ["3002", "3003"])
        self.assertEqual(payload["env"]["CHECK_INPUT_JOBS"], "3002 3003")
        self.assertEqual(payload["env"]["ATTACH_OUTPUT_MODE"], "delta")
        self.assertEqual(payload["env"]["MODEL_BASE_INPUT_JOB"], "3001")
        self.assertEqual(payload["env"]["BASE_MODEL_JOB"], "3001")
        self.assertEqual(payload["env"]["MODEL_ORIGINAL_BASE_INPUT_JOB"], "3001")

    def test_merge_uses_only_same_slot_predecessor_for_atomic_retry(self):
        payload = launcher.hessian_merge_payload(
            {"step_id": "12-test"},
            launch_args(hessian_nsplit=1),
            launcher.DEFAULT_BRANCH,
            "3001",
            ["3002"],
            previous_attached_output_job="#2999",
        )

        self.assertEqual(payload["metadata"]["previous_attached_output_job"], "2999")
        self.assertEqual(payload["metadata"]["same_slot_predecessor_job"], "2999")
        self.assertEqual(payload["metadata"]["attached_work_slot"], "diagnostics:12-test:hessian")
        self.assertEqual(payload["metadata"]["check_input_jobs"], ["3002"])
        self.assertEqual(payload["input_jobs"], ["3001", "3002"])

    def test_no_attach_hessians_keeps_full_merge_without_overlay_metadata(self):
        args = launch_args(attach_hessians=False, hessian_nsplit=1)
        payload = launcher.hessian_merge_payload(
            {"step_id": "12-test"},
            args,
            launcher.DEFAULT_BRANCH,
            "3001",
            ["3002"],
        )

        self.assertEqual(payload["env"]["ATTACH_OUTPUT_MODE"], "full")
        self.assertNotIn("attached_work_parent_job", payload["metadata"])
        self.assertNotIn("attached_output_overlay", payload["metadata"])

    def test_merge_rejects_duplicate_or_empty_input_references(self):
        args = launch_args(hessian_nsplit=1)
        with self.assertRaises(ValueError):
            launcher.hessian_merge_payload(
                {"step_id": "12-test"}, args, launcher.DEFAULT_BRANCH, "3001", ["3001"]
            )
        with self.assertRaises(ValueError):
            launcher.hessian_merge_payload(
                {"step_id": "12-test"}, args, launcher.DEFAULT_BRANCH, "", ["3002"]
            )


class SameSlotPredecessorTests(unittest.TestCase):
    def test_first_hessian_attach_has_empty_predecessor(self):
        parent = {"metadata": {"attached_work_latest_by_slot": {}}}
        with mock.patch.object(launcher, "api_job", return_value=parent):
            predecessor = launcher.latest_attached_output_job_for_slot(
                "https://kflow.test", "token", "3001", "diagnostics:12-test:hessian"
            )
        self.assertEqual(predecessor, "")

    def test_lookup_returns_only_valid_completed_same_slot_output(self):
        jobs = {
            "3001": {
                "metadata": {
                    "attached_work_latest_by_slot": {
                        "diagnostics-12-test-hessian": {"output_job": "2999"},
                        "diagnostics-12-test-jitter": {"output_job": "2998"},
                    }
                }
            },
            "2999": {
                "status": "completed",
                "metadata": {
                    "attached_work_parent_job": "3001",
                    "attached_work_slot": "diagnostics:12-test:hessian",
                },
            },
        }
        with mock.patch.object(
            launcher, "api_job", side_effect=lambda _url, _token, ref: jobs[str(ref)]
        ):
            predecessor = launcher.latest_attached_output_job_for_slot(
                "https://kflow.test", "token", "3001", "diagnostics:12-test:hessian"
            )
        self.assertEqual(predecessor, "2999")

    def test_lookup_rejects_mismatched_or_incomplete_slot_output(self):
        parent = {
            "metadata": {
                "attached_work_latest_by_slot": {
                    "diagnostics-12-test-hessian": {"output_job": "2999"}
                }
            }
        }
        mismatched = {
            "status": "completed",
            "metadata": {
                "attached_work_parent_job": "3001",
                "attached_work_slot": "diagnostics:12-test:jitter",
            },
        }
        with mock.patch.object(launcher, "api_job", side_effect=[parent, mismatched]):
            with self.assertRaises(RuntimeError):
                launcher.latest_attached_output_job_for_slot(
                    "https://kflow.test", "token", "3001", "diagnostics:12-test:hessian"
                )

        incomplete = {
            "status": "running",
            "metadata": {
                "attached_work_parent_job": "3001",
                "attached_work_slot": "diagnostics:12-test:hessian",
            },
        }
        with mock.patch.object(launcher, "api_job", side_effect=[parent, incomplete]):
            with self.assertRaises(RuntimeError):
                launcher.latest_attached_output_job_for_slot(
                    "https://kflow.test", "token", "3001", "diagnostics:12-test:hessian"
                )


class LegacyAttachmentPayloadTests(unittest.TestCase):
    def test_legacy_backfill_is_an_independent_hessian_delta(self):
        args = launch_args()
        payload = launcher.hessian_attach_payload(
            {"step_id": "12-test"},
            args,
            launcher.DEFAULT_BRANCH,
            "3001",
            "3003",
            previous_attached_output_job="2999",
        )

        self.assertEqual(payload["env"]["ATTACH_OUTPUT_MODE"], "delta")
        self.assertEqual(payload["metadata"]["attach_output_mode"], "delta")
        self.assertEqual(payload["metadata"]["check_input_jobs"], ["3003"])
        self.assertEqual(payload["metadata"]["attached_work_parent_job"], "3001")
        self.assertEqual(payload["metadata"]["attached_work_slot"], "diagnostics:12-test:hessian")
        self.assertEqual(payload["metadata"]["previous_attached_output_job"], "2999")
        self.assertEqual(payload["metadata"]["attached_output_overlay_replace_names"], ["hessian"])

    def test_backfill_resolves_live_same_slot_predecessor_before_submit(self):
        manifest = {
            "schema": launcher.MANIFEST_SCHEMA_V1,
            "branch": launcher.DEFAULT_BRANCH,
            "flow_group": "legacy-grid",
            "hessian_nsplit": 1,
            "models": [{
                "step_id": "12-test",
                "fit": {"job_number": "3001"},
                "hessian_merge": {"job_number": "3003"},
            }],
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            args = launch_args(
                manifest=str(path),
                kflow_url="https://kflow.test",
                dry_run=False,
                skip_remote_branch_check=True,
                branch=launcher.DEFAULT_BRANCH,
            )
            captured = {}

            def submit(_url, _token, _task, payload, _dry_run):
                captured.update(payload)
                return {"job_number": "3004", "job_id": "", "status": "queued"}

            with (
                mock.patch.dict("os.environ", {"KFLOW_API_TOKEN": "token"}),
                mock.patch.object(launcher, "report_exists"),
                mock.patch.object(
                    launcher,
                    "latest_attached_output_job_for_slot",
                    return_value="2999",
                ) as predecessor_lookup,
                mock.patch.object(launcher, "submit_or_preview", side_effect=submit),
            ):
                status = launcher.backfill_hessian_attachments(args)

        self.assertEqual(status, 0)
        predecessor_lookup.assert_called_once_with(
            "https://kflow.test",
            "token",
            "3001",
            "diagnostics:12-test:hessian",
        )
        self.assertEqual(captured["metadata"]["previous_attached_output_job"], "2999")
        self.assertEqual(captured["metadata"]["attach_output_mode"], "delta")


class ResultsPayloadTests(unittest.TestCase):
    def test_results_override_both_reviewed_runtime_package_refs(self):
        payload = launcher.results_payload(
            [{"step_id": "12-test"}], launch_args(), ["3003"]
        )
        env = payload["env"]
        self.assertEqual(env["KFLOW_REPO_RUNTIME_PACKAGES"], launcher.runtime_packages())
        self.assertIn(launcher.DEFAULT_MFCLKIT_REF, env["KFLOW_REPO_RUNTIME_PACKAGES"])
        self.assertIn(launcher.DEFAULT_MFCLSHINY_REF, env["KFLOW_REPO_RUNTIME_PACKAGES"])
        self.assertEqual(env["MFCLKIT_GITHUB_REF"], launcher.DEFAULT_MFCLKIT_REF)
        self.assertEqual(env["MFCLSHINY_GITHUB_REF"], launcher.DEFAULT_MFCLSHINY_REF)


class LaunchManifestTests(unittest.TestCase):
    def test_runtime_package_refs_include_independent_diagnostic_support(self):
        self.assertEqual(
            launcher.DEFAULT_MFCLKIT_REF,
            "dfb70989557d5afd6f7eed06e247b8347f7a2767",
        )
        self.assertEqual(
            launcher.DEFAULT_MFCLSHINY_REF,
            "815d6bbb7768ff67881bc110e1aa2057e7b279ba",
        )

    def test_static_and_local_app_configs_pin_both_reviewed_packages(self):
        config = KFLOW_CONFIG.read_text(encoding="utf-8")
        self.assertGreaterEqual(config.count(launcher.DEFAULT_MFCLKIT_REF), 3)
        self.assertGreaterEqual(config.count(launcher.DEFAULT_MFCLSHINY_REF), 3)
        self.assertIn('"mfclkit", "ofp-sam-mfclkit"', config)
        self.assertIn('Sys.getenv("MFCLKIT_GITHUB_REF", "main")', config)

    def test_new_manifest_uses_direct_overlay_schema_and_no_attach_jobs(self):
        args = launch_args()
        models = [{"step_id": "12-a"}, {"step_id": "12-b"}]
        manifest = launcher.load_or_create_manifest(
            Path("unused.json"), args, launcher.DEFAULT_BRANCH, models
        )

        self.assertEqual(manifest["schema"], launcher.MANIFEST_SCHEMA_V2)
        self.assertTrue(manifest["hessian_merge_direct_overlay"])
        self.assertEqual(manifest["results_parent_stage"], "hessian_merge")
        self.assertEqual(manifest["expected_job_counts"]["hessian_attaches"], 0)
        self.assertEqual(manifest["expected_job_counts"]["total"], 9)

    def test_resume_accepts_legacy_v1_manifest(self):
        args = launch_args(resume=True)
        models = [{"step_id": "12-a"}]
        legacy = {
            "schema": launcher.MANIFEST_SCHEMA_V1,
            "branch": launcher.DEFAULT_BRANCH,
            "flow_group": args.flow_group,
            "stepwise_task": args.stepwise_task,
            "results_task": args.results_task,
            "hessian_nsplit": args.hessian_nsplit,
            "models": models,
        }
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "legacy.json"
            path.write_text(json.dumps(legacy), encoding="utf-8")
            resumed = launcher.load_or_create_manifest(
                path, args, launcher.DEFAULT_BRANCH, models
            )

        self.assertEqual(resumed["schema"], launcher.MANIFEST_SCHEMA_V1)


if __name__ == "__main__":
    unittest.main()
