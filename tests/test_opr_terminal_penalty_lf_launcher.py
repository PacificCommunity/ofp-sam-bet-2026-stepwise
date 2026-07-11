import argparse
import contextlib
import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
LAUNCH_SCRIPT = ROOT / "scripts" / "launch_opr_terminal_penalty_lf_sensitivity.py"
REGISTER_SCRIPT = ROOT / "scripts" / "register_opr_terminal_penalty_lf_task.py"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


launcher = load_module("opr_terminal_penalty_lf_launcher_test", LAUNCH_SCRIPT)
registration = load_module("opr_terminal_penalty_lf_registration_test", REGISTER_SCRIPT)


def model_row(step: str = "12s01-control") -> dict[str, str]:
    return {
        "step_id": step,
        "model_label": f"Model {step}",
        "job_title": f"Sensitivity {step}",
        "job_key": step.lower(),
        "major_step": "12-OPRTerminalPenaltyLF",
        "substep": "12s01",
        "change_axis": "Test one documented sensitivity axis.",
        "run_mode": "doitall",
        "kflow_memory": "8GB",
    }


def launch_args(**overrides):
    values = {
        "branch": launcher.DEFAULT_BRANCH,
        "check_prefix": launcher.DEFAULT_CHECK_PREFIX,
        "dry_run": False,
        "flow_group": "test-opr-terminal-penalty-lf",
        "fits_only": False,
        "hessian_nsplit": 2,
        "kflow_url": "https://kflow.test",
        "limit": 0,
        "manifest": "",
        "model_source_repo": launcher.DEFAULT_MODEL_REPO,
        "models": "",
        "phase_convergence": "-4",
        "remote_base_dir": launcher.DEFAULT_SUVA_BASE_DIR,
        "remote_host": launcher.DEFAULT_SUVA_HOST,
        "remote_user": launcher.DEFAULT_SUVA_USER,
        "results_task": launcher.DEFAULT_RESULTS_TASK,
        "resume": False,
        "skip_remote_branch_check": False,
        "stepwise_task": launcher.DEFAULT_STEPWISE_TASK,
    }
    values.update(overrides)
    return argparse.Namespace(**values)


class SplitPolicyTests(unittest.TestCase):
    def test_queue_policy_uses_two_parts_through_50_models(self):
        self.assertEqual(launcher.resolve_hessian_nsplit(1), 2)
        self.assertEqual(launcher.resolve_hessian_nsplit(50), 2)
        self.assertEqual(launcher.resolve_hessian_nsplit(51), 1)

    def test_contradictory_partition_override_is_rejected(self):
        with self.assertRaises(ValueError):
            launcher.resolve_hessian_nsplit(20, "1")
        with self.assertRaises(ValueError):
            launcher.resolve_hessian_nsplit(51, "2")


class SelectionSafetyTests(unittest.TestCase):
    def test_real_config_resolves_all_74_controls_and_thin_steps(self):
        rows = launcher.configured_models("")

        self.assertEqual(len(rows), 74)
        self.assertEqual(rows[0]["step_id"], "11-TimeVaryingCV")
        self.assertTrue(rows[1]["step_id"].startswith("12p"))
        self.assertIn("Benchmark", rows[-1]["step_id"])
        self.assertEqual(len({row["step_id"] for row in rows}), 74)
        self.assertEqual(launcher.resolve_hessian_nsplit(len(rows)), 1)

    def test_all_selector_is_not_a_valid_explicit_sensitivity_override(self):
        completed = SimpleNamespace(
            stdout=(
                '"step_id","model_label","job_title","job_key","major_step",'
                '"substep","change_axis","run_mode","kflow_memory"\n'
                '"01-Diag2023","main","main","main","main","01",'
                '"main","doitall","8GB"\n'
            ),
            stderr="",
        )
        with mock.patch.object(launcher.subprocess, "run", return_value=completed):
            with self.assertRaisesRegex(RuntimeError, "explicit sensitivity step IDs"):
                launcher.configured_models("all")


class FitPayloadTests(unittest.TestCase):
    def test_fit_is_one_explicit_compact_model_on_suva(self):
        payload = launcher.fit_payload(model_row(), launch_args(), launcher.DEFAULT_BRANCH)

        self.assertEqual(payload["branch"], launcher.DEFAULT_BRANCH)
        self.assertEqual(payload["remote_host"], launcher.DEFAULT_SUVA_HOST)
        self.assertEqual(payload["env"]["STEP_SELECT"], "12s01-control")
        self.assertEqual(payload["env"]["STEPWISE_ALLOW_DISABLED_SELECTED"], "true")
        self.assertEqual(payload["env"]["STEPWISE_BUILD_PAYLOAD"], "true")
        self.assertEqual(payload["env"]["STEPWISE_SAVE_RAW_MFCL_INPUTS"], "true")
        self.assertEqual(payload["env"]["STEPWISE_SAVE_FINAL_PAR"], "false")
        self.assertEqual(payload["env"]["BET_PHASE10_11_CONVERGENCE"], "-4")
        self.assertEqual(payload["env"]["TRIGGER_NEXT"], "false")
        self.assertEqual(payload["triggers"], {})
        self.assertTrue(payload["metadata"]["raw_mfcl_inputs_saved"])

        strict_payload = launcher.fit_payload(
            model_row(), launch_args(phase_convergence="-5"), launcher.DEFAULT_BRANCH
        )
        self.assertEqual(strict_payload["env"]["BET_PHASE10_11_CONVERGENCE"], "-5")


class HessianPayloadTests(unittest.TestCase):
    def test_each_hessian_part_depends_only_on_its_fit(self):
        args = launch_args(hessian_nsplit=2)
        payload = launcher.hessian_payload(
            model_row(), args, launcher.DEFAULT_BRANCH, "3001", 2
        )

        self.assertEqual(payload["input_jobs"], ["3001"])
        self.assertEqual(payload["env"]["HESSIAN_NSPLIT"], "2")
        self.assertEqual(payload["env"]["HESSIAN_PART"], "2")
        self.assertEqual(payload["metadata"]["hessian_part"], 2)
        self.assertFalse(payload["metadata"]["parallel_units"])
        self.assertEqual(payload["env"]["CHECK_FAIL_ON_FAILED_UNITS"], "true")


class HessianMergePayloadTests(unittest.TestCase):
    def test_merge_directly_attaches_only_the_hessian_delta(self):
        payload = launcher.hessian_merge_payload(
            model_row(),
            launch_args(),
            launcher.DEFAULT_BRANCH,
            "3001",
            ["3002", "3003"],
            previous_attached_output_job="#2999",
        )

        self.assertEqual(payload["input_jobs"], ["3001", "3002", "3003"])
        self.assertEqual(payload["metadata"]["check_input_jobs"], ["3002", "3003"])
        self.assertEqual(payload["env"]["CHECK_INPUT_JOBS"], "3002 3003")
        self.assertEqual(payload["env"]["ATTACH_OUTPUT_MODE"], "delta")
        self.assertEqual(payload["env"]["MODEL_BASE_INPUT_JOB"], "3001")
        self.assertEqual(payload["metadata"]["attached_work_parent_job"], "3001")
        self.assertEqual(
            payload["metadata"]["attached_work_slot"],
            "diagnostics:12s01-control:hessian",
        )
        self.assertEqual(payload["metadata"]["previous_attached_output_job"], "2999")
        self.assertEqual(payload["metadata"]["same_slot_predecessor_job"], "2999")
        self.assertEqual(
            payload["metadata"]["attached_output_overlay_replace_names"], ["hessian"]
        )
        self.assertTrue(payload["metadata"]["attached_output_overlay_preserve_payload"])
        self.assertTrue(payload["metadata"]["attached_output_overlay_replace_payload"])
        self.assertTrue(payload["metadata"]["direct_merge_attach"])
        self.assertEqual(payload["metadata"]["attach_output_mode"], "delta")
        self.assertTrue(payload["metadata"]["allow_failed_input_jobs"])
        self.assertTrue(payload["metadata"]["auto_attach"])

    def test_merge_requires_exact_unique_partition_inputs(self):
        args = launch_args()
        with self.assertRaises(ValueError):
            launcher.hessian_merge_payload(
                model_row(), args, launcher.DEFAULT_BRANCH, "3001", ["3002"]
            )
        with self.assertRaises(ValueError):
            launcher.hessian_merge_payload(
                model_row(), args, launcher.DEFAULT_BRANCH, "3001", ["3002", "3002"]
            )
        with self.assertRaises(ValueError):
            launcher.hessian_merge_payload(
                model_row(), args, launcher.DEFAULT_BRANCH, "", ["3002", "3003"]
            )


class SameSlotPredecessorTests(unittest.TestCase):
    def test_first_overlay_has_no_predecessor(self):
        parent = {"metadata": {"attached_work_latest_by_slot": {}}}
        with mock.patch.object(launcher, "api_job", return_value=parent):
            value = launcher.latest_attached_output_job_for_slot(
                "https://kflow.test",
                "token",
                "3001",
                "diagnostics:12s01-control:hessian",
            )
        self.assertEqual(value, "")

    def test_only_completed_same_slot_output_is_accepted(self):
        jobs = {
            "3001": {
                "metadata": {
                    "attached_work_latest_by_slot": {
                        "diagnostics-12s01-control-hessian": {"output_job": "2999"},
                        "diagnostics-12s01-control-jitter": {"output_job": "2998"},
                    }
                }
            },
            "2999": {
                "status": "completed",
                "metadata": {
                    "attached_work_parent_job": "3001",
                    "attached_work_slot": "diagnostics:12s01-control:hessian",
                },
            },
        }
        with mock.patch.object(
            launcher, "api_job", side_effect=lambda _url, _token, ref: jobs[str(ref)]
        ):
            value = launcher.latest_attached_output_job_for_slot(
                "https://kflow.test",
                "token",
                "3001",
                "diagnostics:12s01-control:hessian",
            )
        self.assertEqual(value, "2999")

    def test_incomplete_or_unrelated_predecessor_is_rejected(self):
        parent = {
            "metadata": {
                "attached_work_latest_by_slot": {
                    "diagnostics-12s01-control-hessian": {"output_job": "2999"}
                }
            }
        }
        unrelated = {
            "status": "completed",
            "metadata": {
                "attached_work_parent_job": "3001",
                "attached_work_slot": "diagnostics:12s01-control:jitter",
            },
        }
        with mock.patch.object(launcher, "api_job", side_effect=[parent, unrelated]):
            with self.assertRaises(RuntimeError):
                launcher.latest_attached_output_job_for_slot(
                    "https://kflow.test",
                    "token",
                    "3001",
                    "diagnostics:12s01-control:hessian",
                )

        incomplete = {
            "status": "running",
            "metadata": {
                "attached_work_parent_job": "3001",
                "attached_work_slot": "diagnostics:12s01-control:hessian",
            },
        }
        with mock.patch.object(launcher, "api_job", side_effect=[parent, incomplete]):
            with self.assertRaises(RuntimeError):
                launcher.latest_attached_output_job_for_slot(
                    "https://kflow.test",
                    "token",
                    "3001",
                    "diagnostics:12s01-control:hessian",
                )


class ResultsPayloadTests(unittest.TestCase):
    def test_results_fans_in_one_unique_merge_per_model(self):
        models = [model_row("12s01-a"), model_row("12s02-b")]
        payload = launcher.results_payload(models, launch_args(), ["3101", "3102"])

        self.assertEqual(payload["input_jobs"], ["3101", "3102"])
        self.assertEqual(payload["metadata"]["model_count"], 2)
        self.assertTrue(payload["metadata"]["allow_failed_input_jobs"])
        self.assertTrue(payload["metadata"]["input_jobs_override"])
        self.assertEqual(payload["triggers"], {})
        self.assertEqual(payload["env"]["KFLOW_REPO_RUNTIME_PACKAGES"], launcher.runtime_packages())

        with self.assertRaises(ValueError):
            launcher.results_payload(models, launch_args(), ["3101", "3101"])


class ManifestTests(unittest.TestCase):
    def test_fit_only_manifest_records_only_fit_jobs(self):
        args = launch_args(fits_only=True, phase_convergence="-3")
        models = [model_row("12s01-a"), model_row("12s02-b")]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            manifest = launcher.load_or_create_manifest(
                path, args, launcher.DEFAULT_BRANCH, models
            )

        self.assertEqual(manifest["launch_mode"], "fits-only")
        self.assertFalse(manifest["hessian_merge_direct_overlay"])
        self.assertEqual(manifest["results_parent_stage"], "none")
        self.assertEqual(
            manifest["expected_job_counts"],
            {
                "fits": 2,
                "hessians": 0,
                "hessian_merges": 0,
                "hessian_attaches": 0,
                "results": 0,
                "total": 2,
            },
        )

    def test_new_manifest_has_no_attachment_jobs_and_correct_counts(self):
        args = launch_args()
        models = [model_row("12s01-a"), model_row("12s02-b")]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            manifest = launcher.load_or_create_manifest(
                path, args, launcher.DEFAULT_BRANCH, models
            )
            self.assertTrue(path.exists())

        self.assertEqual(manifest["schema"], launcher.MANIFEST_SCHEMA)
        self.assertTrue(manifest["hessian_merge_direct_overlay"])
        self.assertEqual(manifest["results_parent_stage"], "hessian_merge")
        self.assertEqual(manifest["expected_job_counts"]["fits"], 2)
        self.assertEqual(manifest["expected_job_counts"]["hessians"], 4)
        self.assertEqual(manifest["expected_job_counts"]["hessian_merges"], 2)
        self.assertEqual(manifest["expected_job_counts"]["hessian_attaches"], 0)
        self.assertEqual(manifest["expected_job_counts"]["total"], 9)

    def test_non_resume_manifest_is_reserved_exclusively(self):
        args = launch_args(dry_run=False, resume=False)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            launcher.load_or_create_manifest(
                path, args, launcher.DEFAULT_BRANCH, [model_row()]
            )
            with self.assertRaisesRegex(RuntimeError, "already exists"):
                launcher.load_or_create_manifest(
                    path, args, launcher.DEFAULT_BRANCH, [model_row()]
                )

    def test_existing_manifest_requires_explicit_resume_for_real_launch(self):
        args = launch_args(dry_run=False, resume=False)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            path.write_text("{}", encoding="utf-8")
            with self.assertRaises(RuntimeError):
                launcher.load_or_create_manifest(
                    path, args, launcher.DEFAULT_BRANCH, [model_row()]
                )

    def test_resume_validates_branch_flow_tasks_split_and_order(self):
        models = [model_row("12s01-a"), model_row("12s02-b")]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            create_args = launch_args()
            manifest = launcher.load_or_create_manifest(
                path, create_args, launcher.DEFAULT_BRANCH, models
            )
            launcher.write_manifest(path, manifest)
            resumed = launcher.load_or_create_manifest(
                path,
                launch_args(resume=True),
                launcher.DEFAULT_BRANCH,
                models,
            )
            self.assertEqual(resumed["schema"], launcher.MANIFEST_SCHEMA)

            with self.assertRaises(RuntimeError):
                launcher.load_or_create_manifest(
                    path,
                    launch_args(resume=True, flow_group="different"),
                    launcher.DEFAULT_BRANCH,
                    models,
                )
            with self.assertRaises(RuntimeError):
                launcher.load_or_create_manifest(
                    path,
                    launch_args(resume=True, fits_only=True),
                    launcher.DEFAULT_BRANCH,
                    models,
                )
            with self.assertRaises(RuntimeError):
                launcher.load_or_create_manifest(
                    path,
                    launch_args(resume=True),
                    launcher.DEFAULT_BRANCH,
                    list(reversed(models)),
                )
            with self.assertRaises(RuntimeError):
                launcher.load_or_create_manifest(
                    path,
                    launch_args(resume=True, remote_host="different-submit-host"),
                    launcher.DEFAULT_BRANCH,
                    models,
                )
            with self.assertRaises(RuntimeError):
                launcher.load_or_create_manifest(
                    path,
                    launch_args(resume=True, phase_convergence="-3"),
                    launcher.DEFAULT_BRANCH,
                    models,
                )

    def test_partial_hessian_records_are_preserved_by_part_number(self):
        entry = {
            "hessian_parts": [
                {"part": 2, "job_number": "3003"},
                {"part": 1, "job_number": "3002"},
            ]
        }
        parts = launcher.hessian_part_map(entry, 2)
        self.assertEqual(parts[1]["job_number"], "3002")
        self.assertEqual(parts[2]["job_number"], "3003")


class MainFlowTests(unittest.TestCase):
    def test_fit_only_preview_submits_all_74_fits_and_nothing_else(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preview.json"
            args = launch_args(
                dry_run=True,
                fits_only=True,
                hessian_nsplit="auto",
                manifest=str(path),
                phase_convergence="-3",
            )
            calls = []

            def submit(_url, _token, task, payload, _dry_run):
                calls.append((task, payload))
                return {"job_number": f"DRY-{len(calls)}", "status": "dry-run"}

            with (
                mock.patch.object(launcher, "parse_args", return_value=args),
                mock.patch.object(launcher, "submit_or_preview", side_effect=submit),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                status = launcher.main()

        self.assertEqual(status, 0)
        self.assertFalse(path.exists())
        self.assertEqual(len(calls), 74)
        self.assertEqual({task for task, _payload in calls}, {launcher.DEFAULT_STEPWISE_TASK})
        self.assertTrue(
            all(payload["env"]["BET_PHASE10_11_CONVERGENCE"] == "-3" for _, payload in calls)
        )
        self.assertTrue(
            all(payload["metadata"]["launch_mode"] == "fits-only" for _, payload in calls)
        )

    def test_real_74_model_preview_builds_only_independent_fit_hessian_merge_chains(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preview.json"
            args = launch_args(
                dry_run=True,
                hessian_nsplit="auto",
                manifest=str(path),
            )
            calls = []

            def submit(_url, _token, task, payload, _dry_run):
                calls.append((task, payload))
                return {"job_number": f"DRY-{len(calls)}", "status": "dry-run"}

            with (
                mock.patch.object(launcher, "parse_args", return_value=args),
                mock.patch.object(launcher, "submit_or_preview", side_effect=submit),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                status = launcher.main()

        self.assertEqual(status, 0)
        self.assertFalse(path.exists())
        self.assertEqual(len(calls), 223)
        fits = [item for item in calls if item[0] == launcher.DEFAULT_STEPWISE_TASK]
        hessians = [
            item
            for item in calls
            if item[0] == f"{launcher.DEFAULT_CHECK_PREFIX}-hessian"
        ]
        merges = [
            item
            for item in calls
            if item[0] == f"{launcher.DEFAULT_CHECK_PREFIX}-hessian-merge"
        ]
        results = [item for item in calls if item[0] == launcher.DEFAULT_RESULTS_TASK]
        self.assertEqual((len(fits), len(hessians), len(merges), len(results)), (74, 74, 74, 1))
        self.assertFalse(any("attach" in task for task, _payload in calls))

        fit_refs = {
            payload["metadata"]["model_selector"]: f"DRY-{index}"
            for index, (task, payload) in enumerate(calls, start=1)
            if task == launcher.DEFAULT_STEPWISE_TASK
        }
        hessian_refs = {}
        for index, (task, payload) in enumerate(calls, start=1):
            if task != f"{launcher.DEFAULT_CHECK_PREFIX}-hessian":
                continue
            step = payload["metadata"]["model_selector"]
            self.assertEqual(payload["input_jobs"], [fit_refs[step]])
            self.assertEqual(payload["metadata"]["hessian_nsplit"], 1)
            hessian_refs[step] = f"DRY-{index}"

        merge_refs = []
        for index, (task, payload) in enumerate(calls, start=1):
            if task != f"{launcher.DEFAULT_CHECK_PREFIX}-hessian-merge":
                continue
            step = payload["metadata"]["model_selector"]
            self.assertEqual(payload["input_jobs"], [fit_refs[step], hessian_refs[step]])
            self.assertTrue(payload["metadata"]["direct_merge_attach"])
            merge_refs.append(f"DRY-{index}")

        self.assertEqual(results[0][1]["input_jobs"], merge_refs)
        self.assertEqual(results[0][1]["metadata"]["model_count"], 74)

    def test_dry_run_limit_one_emits_five_jobs_and_writes_no_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "preview.json"
            args = launch_args(
                dry_run=True,
                hessian_nsplit="auto",
                limit=1,
                manifest=str(path),
            )
            output = io.StringIO()
            with (
                mock.patch.object(launcher, "parse_args", return_value=args),
                mock.patch.object(launcher, "configured_models", return_value=[model_row()]),
                mock.patch.object(launcher, "api_json") as api,
                mock.patch.object(launcher, "verify_remote_branch") as verify,
                contextlib.redirect_stdout(output),
            ):
                status = launcher.main()

            payloads = [
                json.loads(line)
                for line in output.getvalue().splitlines()
                if line.startswith("{")
            ]
            self.assertEqual(status, 0)
            self.assertEqual(len(payloads), 5)
            self.assertEqual(
                [item["task"] for item in payloads],
                [
                    launcher.DEFAULT_STEPWISE_TASK,
                    f"{launcher.DEFAULT_CHECK_PREFIX}-hessian",
                    f"{launcher.DEFAULT_CHECK_PREFIX}-hessian",
                    f"{launcher.DEFAULT_CHECK_PREFIX}-hessian-merge",
                    launcher.DEFAULT_RESULTS_TASK,
                ],
            )
            self.assertFalse(path.exists())
            api.assert_not_called()
            verify.assert_not_called()

    def test_resume_submits_only_missing_hessian_part_merge_and_results(self):
        row = model_row()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "launch.json"
            create_args = launch_args(manifest=str(path))
            manifest = launcher.load_or_create_manifest(
                path, create_args, launcher.DEFAULT_BRANCH, [row]
            )
            entry = manifest["models"][0]
            entry["fit"] = {"job_number": "3001"}
            entry["hessian_parts"] = [{"part": 1, "job_number": "3002"}]
            launcher.write_manifest(path, manifest)

            args = launch_args(
                dry_run=True,
                resume=True,
                manifest=str(path),
                hessian_nsplit="auto",
            )
            calls = []

            def submit(_url, _token, task, payload, _dry_run):
                calls.append((task, payload))
                return {"job_number": f"NEW-{len(calls)}", "status": "dry-run"}

            with (
                mock.patch.object(launcher, "parse_args", return_value=args),
                mock.patch.object(launcher, "configured_models", return_value=[row]),
                mock.patch.object(launcher, "submit_or_preview", side_effect=submit),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                status = launcher.main()

            self.assertEqual(status, 0)
            self.assertEqual(
                [task for task, _payload in calls],
                [
                    f"{launcher.DEFAULT_CHECK_PREFIX}-hessian",
                    f"{launcher.DEFAULT_CHECK_PREFIX}-hessian-merge",
                    launcher.DEFAULT_RESULTS_TASK,
                ],
            )
            self.assertEqual(calls[0][1]["metadata"]["hessian_part"], 2)
            self.assertEqual(calls[1][1]["input_jobs"], ["3001", "3002", "NEW-1"])
            # Previewing a resume must not alter the real recovery manifest.
            unchanged = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(len(unchanged["models"][0]["hessian_parts"]), 1)


class RegistrationTests(unittest.TestCase):
    def test_registration_payload_is_isolated_v22_suva_and_has_no_attach_jobs(self):
        rows = [model_row("12s01-a"), model_row("12s02-b")]
        args = SimpleNamespace(
            repo_root=".",
            task_name=registration.DEFAULT_STEPWISE_TASK,
            repo_full_name="PacificCommunity/ofp-sam-bet-2026-stepwise",
            branch=registration.DEFAULT_BRANCH,
            kflow_url="https://kflow.test",
            dry_run=True,
        )
        with (
            mock.patch.object(registration, "configured_models", return_value=rows),
            mock.patch.dict(os.environ, {"KFLOW_API_TOKEN": "not-used-in-dry-run"}, clear=True),
            mock.patch.object(registration, "api_json") as api,
            mock.patch.object(registration, "existing_report") as existing,
        ):
            payload, count, nsplit, branch = registration.registration_payload(args)

        self.assertEqual(count, 2)
        self.assertEqual(nsplit, 2)
        self.assertEqual(branch, registration.DEFAULT_BRANCH)
        self.assertEqual(payload["name"], registration.DEFAULT_STEPWISE_TASK)
        self.assertEqual(payload["branch"], registration.DEFAULT_BRANCH)
        self.assertEqual(payload["docker_image"], registration.EXPECTED_DOCKER_IMAGE)
        self.assertEqual(payload["remote_host"], registration.DEFAULT_SUVA_HOST)
        self.assertEqual(payload["env"]["STEP_SELECT"], "12s01-a")
        self.assertEqual(payload["env"]["STEPWISE_ALLOW_DISABLED_SELECTED"], "true")
        self.assertEqual(payload["env"]["STEPWISE_SAVE_RAW_MFCL_INPUTS"], "true")
        self.assertEqual(payload["env"]["BET_PHASE10_11_CONVERGENCE"], "-4")
        self.assertEqual(payload["env"]["TRIGGER_NEXT"], "false")
        self.assertEqual(payload["triggers"], {})
        meta = payload["metadata"]["opr_terminal_penalty_lf_sensitivity"]
        self.assertEqual(meta["fit_job_count"], 2)
        self.assertEqual(meta["hessian_job_count"], 4)
        self.assertEqual(meta["hessian_merge_job_count"], 2)
        self.assertEqual(meta["hessian_attach_job_count"], 0)
        self.assertEqual(meta["results_job_count"], 1)
        self.assertEqual(meta["total_job_count"], 9)
        self.assertTrue(meta["hessian_merge_direct_overlay"])
        self.assertFalse(meta["automatic_fit_triggers"])
        api.assert_not_called()
        existing.assert_not_called()

    def test_real_registration_counts_74_models_and_one_hessian_each(self):
        args = SimpleNamespace(
            repo_root=".",
            task_name=registration.DEFAULT_STEPWISE_TASK,
            repo_full_name="PacificCommunity/ofp-sam-bet-2026-stepwise",
            branch=registration.DEFAULT_BRANCH,
            kflow_url="https://kflow.test",
            dry_run=True,
        )

        payload, count, nsplit, _branch = registration.registration_payload(args)

        self.assertEqual(count, 74)
        self.assertEqual(nsplit, 1)
        meta = payload["metadata"]["opr_terminal_penalty_lf_sensitivity"]
        self.assertEqual(meta["fit_job_count"], 74)
        self.assertEqual(meta["hessian_job_count"], 74)
        self.assertEqual(meta["hessian_merge_job_count"], 74)
        self.assertEqual(meta["hessian_attach_job_count"], 0)
        self.assertEqual(meta["results_job_count"], 1)
        self.assertEqual(meta["total_job_count"], 223)
        self.assertEqual(payload["triggers"], {})


if __name__ == "__main__":
    unittest.main()
