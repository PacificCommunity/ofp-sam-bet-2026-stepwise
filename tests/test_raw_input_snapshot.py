from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class RawInputSnapshotTests(unittest.TestCase):
    def test_snapshot_is_taken_after_patch_and_before_mfcl_runs(self) -> None:
        runner = (ROOT / "R" / "run_stepwise.R").read_text(encoding="utf-8")

        patch = runner.index('patch_file <- file.path(step_dir, "patch.R")')
        snapshot = runner.index(
            'raw_mfcl_inputs_snapshot_dir <- file.path(work_dir, "raw-mfcl-inputs", step_id)'
        )
        run = runner.index("old <- setwd(model_dir)", snapshot)
        self.assertLess(patch, snapshot)
        self.assertLess(snapshot, run)

    def test_published_inputs_come_from_the_patch_applied_snapshot(self) -> None:
        runner = (ROOT / "R" / "run_stepwise.R").read_text(encoding="utf-8")

        self.assertIn(
            "copy_raw_mfcl_inputs(raw_mfcl_inputs_snapshot_dir, raw_mfcl_inputs_dir)",
            runner,
        )
        self.assertNotIn(
            "copy_raw_mfcl_inputs(model_source, raw_mfcl_inputs_dir)",
            runner,
        )


if __name__ == "__main__":
    unittest.main()
