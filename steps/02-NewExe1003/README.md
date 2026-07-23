# 02 Updated executable

Step 01 inputs and scientific controls run with the current MFCL executable while keeping the MFCL 1003 ini.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/02-NewExe1003/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the generated Step 01 model files, sourced from `ofp-sam-bet-2023-diagnostic/MFCL`, as the exact comparison baseline. |
| 2 | Keeps `bet.ini` as version 1003 and retains every Step 01 scientific control so this is an executable-only comparison. |
| 3 | Preserves Step 01 F33-F41 CPUE flag-92 values `88, 53, 130, 109, 76, 93, 121, 77, 23` and global `2 94 1 2 128 10`. |
| 4 | Retains the `-9999 1 2` doitall tag-mixing override because MFCL 1003 inputs do not contain an explicit `# tag flags` block. |
| 5 | Only modernizes executable invocation/safety with `set -eu` and a PROGRAM_PATH guard; the existing PHASE 10/11 switch is retained and reporting-only `1 246 1` compatibility is added. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | exact Step 01 diagnostic `.frq`; 9 regions, 41 fisheries, terminal year 2021 |
| `.ini` | exact Step 01 diagnostic `.ini`; MFCL 1003, no explicit tag flags |
| `.tag` | exact Step 01 diagnostic `.tag` |
| `.age_length` | exact Step 01 diagnostic `.age_length` |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.ini` | No generated input edit; MFCL 1003 layout is retained. | Step 01 diagnostic ini values. |
| `.frq` | No generated edit. | Step 01 diagnostic source file. |
| `.tag` | No generated edit. | Step 01 diagnostic source file. |
| `.age_length` | No generated edit. | Step 01 diagnostic source file. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `d48e396` | Reject conflicting tag reporting-rate priors |
| `ofp-sam-2026-BET-YFT-tag-prep` | `471b2fd` | Correct RR group init values |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The current MFCL executable configured by the runtime is used. |
| 2 | This substep changes the executable invocation, not scientific controls, before changing the ini layout. |
| 3 | The reporting-only `1 246 1` control requests `indepvar.rpt` and does not alter the fit. |
| 4 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 01-Diag2023 to isolate only the historical versus current executable. |
| 2 | Do not interpret this as a 1007 ini test; that is isolated in 03-Ini1007. |
