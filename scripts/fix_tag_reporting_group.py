#!/usr/bin/env python3
"""Fix one grouped MFCL tag reporting rate without rewriting the full PAR."""

from __future__ import annotations

import argparse
from pathlib import Path


N_RELEASE_ROWS = 99
N_FISHERIES = 33
EXPECTED_GROUP = 29
EXPECTED_CELLS = 74
EXPECTED_ROWS = set(range(62, 99))
EXPECTED_FISHERIES = {25, 27}


def matrix(lines: list[str], marker: str) -> tuple[list[list[str]], list[int]]:
    marker_hits = [i for i, line in enumerate(lines) if line.strip() == marker]
    if len(marker_hits) != 1:
        raise ValueError(f"Expected one {marker!r} marker; found {len(marker_hits)}")

    values: list[list[str]] = []
    line_indices: list[int] = []
    i = marker_hits[0] + 1
    while i < len(lines) and len(values) < N_RELEASE_ROWS:
        stripped = lines[i].strip()
        if stripped and not stripped.startswith("#"):
            row = stripped.split()
            if len(row) != N_FISHERIES:
                raise ValueError(
                    f"{marker!r} row {len(values) + 1} has {len(row)} "
                    f"values, expected {N_FISHERIES}"
                )
            values.append(row)
            line_indices.append(i)
        i += 1

    if len(values) != N_RELEASE_ROWS:
        raise ValueError(
            f"{marker!r} has {len(values)} rows, expected {N_RELEASE_ROWS}"
        )
    return values, line_indices


def locate_group(
    groups: list[list[str]], group: int
) -> list[tuple[int, int]]:
    cells = [
        (row, fishery)
        for row in range(N_RELEASE_ROWS)
        for fishery in range(N_FISHERIES)
        if int(groups[row][fishery]) == group
    ]
    rows = {row + 1 for row, _ in cells}
    fisheries = {fishery + 1 for _, fishery in cells}
    if (
        group != EXPECTED_GROUP
        or len(cells) != EXPECTED_CELLS
        or rows != EXPECTED_ROWS
        or fisheries != EXPECTED_FISHERIES
    ):
        raise ValueError(
            "Reporting-rate group geometry is not the verified Job 18518 "
            f"configuration: group={group}, cells={len(cells)}, "
            f"rows={sorted(rows)}, fisheries={sorted(fisheries)}"
        )
    return cells


def read_par(path: Path):
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    rates, rate_lines = matrix(lines, "# tag fish rep")
    groups, _ = matrix(lines, "# tag fish rep group flags")
    active, active_lines = matrix(lines, "# tag_fish_rep active flags")
    penalties, penalty_lines = matrix(lines, "# tag_fish_rep penalty")
    cells = locate_group(groups, EXPECTED_GROUP)
    return lines, rates, rate_lines, active, active_lines, penalties, penalty_lines, cells


def source_checks(rates, active, penalties, cells) -> None:
    source_rates = {float(rates[row][fishery]) for row, fishery in cells}
    source_active = {int(active[row][fishery]) for row, fishery in cells}
    source_penalties = {float(penalties[row][fishery]) for row, fishery in cells}
    if len(source_rates) != 1 or not (0.001 <= next(iter(source_rates)) < 0.001001):
        raise ValueError(f"Unexpected source group-29 rates: {sorted(source_rates)}")
    if source_active != {1}:
        raise ValueError(f"Unexpected source group-29 active flags: {source_active}")
    if source_penalties != {1.0}:
        raise ValueError(
            f"Unexpected source group-29 reporting penalties: {source_penalties}"
        )


def fixed_checks(rates, active, penalties, cells) -> None:
    if {float(rates[row][fishery]) for row, fishery in cells} != {0.0}:
        raise ValueError("Reporting-rate group 29 is not fixed at zero.")
    if {int(active[row][fishery]) for row, fishery in cells} != {0}:
        raise ValueError("Reporting-rate group 29 still has active estimation cells.")
    if {float(penalties[row][fishery]) for row, fishery in cells} != {0.0}:
        raise ValueError("Reporting-rate group 29 still has an active prior penalty.")


def write_matrix_rows(lines, values, line_indices, touched_rows) -> None:
    for row in sorted(touched_rows):
        lines[line_indices[row]] = " " + " ".join(values[row]) + "\n"


def apply_fix(source: Path, output: Path) -> None:
    (
        lines,
        rates,
        rate_lines,
        active,
        active_lines,
        penalties,
        penalty_lines,
        cells,
    ) = read_par(source)
    source_checks(rates, active, penalties, cells)

    touched_rows = set()
    for row, fishery in cells:
        rates[row][fishery] = "0"
        active[row][fishery] = "0"
        penalties[row][fishery] = "0"
        touched_rows.add(row)

    write_matrix_rows(lines, rates, rate_lines, touched_rows)
    write_matrix_rows(lines, active, active_lines, touched_rows)
    write_matrix_rows(lines, penalties, penalty_lines, touched_rows)
    output.write_text("".join(lines), encoding="utf-8")

    fixed = read_par(output)
    fixed_checks(fixed[1], fixed[3], fixed[5], fixed[7])
    print(
        "Fixed reporting-rate group 29 at zero in 74 cells "
        "(release rows 62-98; fisheries 25 and 27); "
        "disabled its estimation and prior penalty."
    )


def check_fix(path: Path) -> None:
    parsed = read_par(path)
    fixed_checks(parsed[1], parsed[3], parsed[5], parsed[7])
    print(
        "Verified reporting-rate group 29: rate=0, active flag=0, "
        "prior penalty=0 in all 74 cells."
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    apply_parser = subparsers.add_parser("apply")
    apply_parser.add_argument("source", type=Path)
    apply_parser.add_argument("output", type=Path)

    check_parser = subparsers.add_parser("check")
    check_parser.add_argument("par", type=Path)

    args = parser.parse_args()
    if args.command == "apply":
        apply_fix(args.source, args.output)
    else:
        check_fix(args.par)


if __name__ == "__main__":
    main()
