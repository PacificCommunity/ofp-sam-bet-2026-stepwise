#!/usr/bin/env python3
"""Create or verify the 12 Job-15062-based selectivity variants."""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EXPLORATIONS = ROOT / "explorations"
CANONICAL = ROOT / "provenance" / "job-15062" / "doitall.sh"
CANONICAL_SHA256 = "11fc97e3d3798df7ca766229bcb7187cc6c78753d772afaf28e312eab5e2d15e"
SCENARIOS = ("K005", "K010", "K015", "K020", "K025", "K030")
TAU_MODES = ("estimated", "not-estimated")
SELECTIVITY_FLAGS = {3, 16, 24, 26, 57, 61, 75}
POST_BLOCK_CONTROLS_TO_REMOVE = {
    (-1, 61, 4),
    (-2, 61, 4),
    (-3, 61, 4),
    (-5, 61, 4),
    (-29, 61, 4),
    (-33, 57, 1),
}
F14_YOUNGEST_FIVE_CONTROL = (
    "  -14 75 5  # F14 HL.ID.2 youngest age classes fixed at zero selectivity\n"
)
F14_YOUNGEST_FIVE_NOTE = (
    "# Final exploration applies the youngest-five-age constraint to both split fisheries.\n"
)
F15_YOUNGEST_FIVE_CONTROL = (
    "  -15 75 5  # F15 youngest age classes fixed at zero selectivity\n"
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def replace_block(
    target: str,
    source: str,
    start_marker: str,
    end_marker: str,
) -> str:
    target_start = target.index(start_marker)
    target_end = target.index(end_marker, target_start)
    source_start = source.index(start_marker)
    source_end = source.index(end_marker, source_start)
    return (
        target[:target_start]
        + source[source_start:source_end]
        + target[target_end:]
    )


def selectivity_signature(script: str) -> tuple[tuple[int, int, int, int], ...]:
    phase = -1
    controls: list[tuple[int, int, int, int]] = []
    for line in script.splitlines():
        phase_match = re.match(r"#  PHASE ([0-9]+)", line)
        if phase_match:
            phase = int(phase_match.group(1))
        if phase not in {1, 5}:
            continue
        fields = line.split("#", 1)[0].split()
        for offset in range(0, len(fields) - 2, 3):
            try:
                fishery, flag, value = map(int, fields[offset : offset + 3])
            except ValueError:
                continue
            if -999 <= fishery <= -1 and flag in SELECTIVITY_FLAGS:
                controls.append((phase, fishery, flag, value))
    return tuple(controls)


def derived_doitall(base_script: str, canonical_script: str) -> str:
    result = replace_block(
        base_script,
        canonical_script,
        "# Selectivity settings\n",
        "# Turn on weighted spline for calculating maturity at age\n",
    )
    result = replace_block(
        result,
        canonical_script,
        "# STAGED MFCL RUN 5: separate the five regional-index selectivity-sharing groups.\n",
        "PHASE5\n",
    )
    if result.count(F15_YOUNGEST_FIVE_CONTROL) != 1:
        raise RuntimeError("Could not locate the Job 15062 F15 age constraint.")
    if F14_YOUNGEST_FIVE_CONTROL in result:
        raise RuntimeError("Job 15062 unexpectedly already contains the F14 constraint.")
    result = result.replace(
        F15_YOUNGEST_FIVE_CONTROL,
        F14_YOUNGEST_FIVE_NOTE
        + F14_YOUNGEST_FIVE_CONTROL
        + F15_YOUNGEST_FIVE_CONTROL,
    )
    filtered_lines: list[str] = []
    removed: set[tuple[int, int, int]] = set()
    for line in result.splitlines():
        fields = line.split("#", 1)[0].split()
        control: tuple[int, int, int] | None = None
        if len(fields) == 3:
            try:
                control = tuple(map(int, fields))  # type: ignore[assignment]
            except ValueError:
                control = None
        if control in POST_BLOCK_CONTROLS_TO_REMOVE:
            removed.add(control)
            continue
        filtered_lines.append(line)
    if removed != POST_BLOCK_CONTROLS_TO_REMOVE:
        raise RuntimeError(
            "Could not remove every post-20c selectivity control from the base script."
        )
    result = "\n".join(filtered_lines) + "\n"
    canonical_signature = selectivity_signature(canonical_script)
    result_signature = selectivity_signature(result)
    if len(canonical_signature) != 93:
        raise RuntimeError(
            f"Expected 93 archived 20c selectivity controls; found {len(canonical_signature)}."
        )
    expected_signature = list(canonical_signature)
    f15_index = expected_signature.index((1, -15, 75, 5))
    expected_signature.insert(f15_index, (1, -14, 75, 5))
    if result_signature != tuple(expected_signature):
        raise RuntimeError(
            "Derived controls do not match Job 15062 plus the deliberate F14 constraint."
        )
    return result


def derived_readme(base_readme: str, base_model: str, target_model: str) -> str:
    lines = base_readme.splitlines()
    lines[0] = f"{lines[0]} — 20c selectivity"
    body = "\n".join(lines).replace(
        f"MODEL={base_model}",
        f"MODEL={target_model}",
    )
    return (
        body.rstrip()
        + "\n\n"
        + "## Selectivity treatment\n\n"
        + "This variant changes only the fishery-selectivity controls. It uses the\n"
        + "Phase 1 and Phase 5 settings in the actual Job 15062 `20c-DMG8Nmax25`\n"
        + "`doitall.sh`, with one deliberate addition: both F14 and F15 use fishery\n"
        + "flag 75=5 because neither fishery has observations below 70 cm in the\n"
        + "retained length-frequency data. All data, mixing, tau, DM, M,\n"
        + "reporting-rate, and regional-scaling settings remain those of the\n"
        + "corresponding base exploration.\n"
    )


def manifest_content(files: dict[str, bytes], manifest_names: list[str]) -> bytes:
    lines = [f"{sha256(files[name])}  {name}" for name in manifest_names]
    return ("\n".join(lines) + "\n").encode()


def expected_files(
    base_dir: Path,
    base_model: str,
    target_model: str,
    canonical_script: str,
) -> dict[str, bytes]:
    files = {
        path.name: path.read_bytes()
        for path in base_dir.iterdir()
        if path.is_file() and path.name != "MANIFEST.sha256"
    }
    files["doitall.sh"] = derived_doitall(
        files["doitall.sh"].decode(),
        canonical_script,
    ).encode()
    files["README.md"] = derived_readme(
        files["README.md"].decode(),
        base_model,
        target_model,
    ).encode()
    manifest_names = [
        line.split(maxsplit=1)[1]
        for line in (base_dir / "MANIFEST.sha256").read_text().splitlines()
    ]
    files["MANIFEST.sha256"] = manifest_content(files, manifest_names)
    return files


def check_target(target_dir: Path, expected: dict[str, bytes]) -> list[str]:
    errors: list[str] = []
    observed_names = {path.name for path in target_dir.iterdir() if path.is_file()}
    if observed_names != set(expected):
        errors.append(
            f"{target_dir.name}: file set differs "
            f"(expected {sorted(expected)}, observed {sorted(observed_names)})"
        )
        return errors
    for name, expected_data in expected.items():
        if (target_dir / name).read_bytes() != expected_data:
            errors.append(f"{target_dir.name}/{name}: generated content differs")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify committed variants without writing files",
    )
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="refresh existing generated variants in place",
    )
    args = parser.parse_args()
    if args.check and args.refresh:
        parser.error("--check and --refresh are mutually exclusive")

    canonical_bytes = CANONICAL.read_bytes()
    if sha256(canonical_bytes) != CANONICAL_SHA256:
        raise RuntimeError("Archived Job 15062 doitall.sh checksum changed.")
    canonical_script = canonical_bytes.decode()

    errors: list[str] = []
    for scenario in SCENARIOS:
        for tau_mode in TAU_MODES:
            base_model = f"{scenario}-tau-{tau_mode}"
            target_model = f"{base_model}-sel20c"
            base_dir = EXPLORATIONS / base_model
            target_dir = EXPLORATIONS / target_model
            expected = expected_files(
                base_dir,
                base_model,
                target_model,
                canonical_script,
            )
            if args.check:
                if not target_dir.is_dir():
                    errors.append(f"{target_model}: directory is missing")
                else:
                    errors.extend(check_target(target_dir, expected))
                continue
            if target_dir.exists() and not args.refresh:
                raise RuntimeError(f"Refusing to overwrite {target_dir}.")
            if not target_dir.exists():
                shutil.copytree(base_dir, target_dir)
            for name, data in expected.items():
                (target_dir / name).write_bytes(data)

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    action = "Verified" if args.check else ("Refreshed" if args.refresh else "Created")
    print(f"{action} 12 Job-15062-based selectivity exploration variants.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
