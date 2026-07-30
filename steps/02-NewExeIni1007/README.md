# 02 New executable and INI 1007

Step 01 input data promoted to INI 1007 and run with the 2.2.7.9-based executable.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02-NewExeIni1007/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the generated Step 01 model files, sourced from `ofp-sam-bet-2023-diagnostic/MFCL`, as the exact comparison baseline. |
| 2 | Promotes `bet.ini` from format 1003 to 1007 in the same compatibility step. |
| 3 | Converts F33-F41 CPUE flag-92 values from legacy penalty units to `24, 31, 20, 21, 26, 23, 20, 25, 47`. |
| 4 | Changes global `2 94 1 2 128 10` to `2 94 1 2 128 100`; the 2.2.7.9-based code divides by 100, preserving initial Z = 1.0*M. |
| 5 | Reads tag mixing periods from the INI 1007 tag-flags block. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | exact Step 01 diagnostic `.frq`; 9 regions, 41 fisheries, terminal year 2021 |
| `.ini` | Step 01 diagnostic values promoted to MFCL 1007 |
| `.tag` | exact Step 01 diagnostic `.tag` |
| `.age_length` | exact Step 01 diagnostic `.age_length` |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.ini` | Promoted to MFCL 1007 with explicit tag flags. | Step 01 diagnostic numeric values. |
| `.frq` | No generated edit. | Step 01 diagnostic source file. |
| `.tag` | No generated edit. | Step 01 diagnostic source file. |
| `.age_length` | No generated edit. | Step 01 diagnostic source file. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `efe3107` | Use five-region mean for Region 1 mixing periods |
| `ofp-sam-2026-BET-YFT-tag-prep` | `44f8043` | update RR groupings |
| `ofp-sam-2026-BET-YFT-age-length-build` | `96a06d2` | add various effective sample sizes |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The current MFCL executable configured by the runtime is used. |
| 2 | This step deliberately combines the executable and required INI-format update. |
| 3 | The reporting-only `1 246 1` control requests `indepvar.rpt` and does not alter the fit. |
| 4 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 01-Diag2023 for the combined executable/format transition. |
| 2 | The CPUE and age_flags(128) conversions preserve the legacy scientific interpretation. |
