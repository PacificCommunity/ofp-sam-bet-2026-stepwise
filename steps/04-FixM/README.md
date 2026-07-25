# 04 Diagnostic natural-mortality estimate fixed

Step 03 1007 INI baseline with Lorenzen natural-mortality scaling fixed to the 2023 diagnostic-model estimate.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/04-FixM/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Inherits the diagnostic-side 2023 assessment replication model from `03-Ini1007`. |
| 2 | Applies the FixM M-scale row from the 01-Diag2023 mgc=-5 diagnostic final par with value -2.54930339768360e+00 |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `steps/03-Ini1007/model/bet.frq` |
| `.ini` | `steps/03-Ini1007/model/bet.ini`; Lorenzen natural-mortality scaling fixed to the 2023 diagnostic-model estimate from the 01-Diag2023 mgc=-5 diagnostic final par |
| `.tag` | `steps/03-Ini1007/model/bet.tag` |
| `.age_length` | `steps/03-Ini1007/model/bet.age_length` |
| `input_manifest.csv` | machine-readable source/input notes with source commits |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.ini` | Uses the 2023 diagnostic-model estimate for Lorenzen natural-mortality scaling and retains the length exponent `-1`; both are fixed in later fits. | All other `03-Ini1007` ini controls. |
| `.frq/.tag/.age_length` | No generated edit. | Inherited from `03-Ini1007`. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `5b2fb60` | Document SC22-IP10 mixing-period implementation |
| `ofp-sam-2026-BET-YFT-tag-prep` | `6d66dc3` | update RR groupings |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The current MFCL executable configured by the runtime is used. |
| 2 | MFCL 1007 `# tag flags` supply tag mixing periods; the inherited `-9999 1 2` doitall override is removed. |
| 3 | The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs. |
| 4 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Checks

| # | Check |
| --- | --- |
| 1 | Compare directly with 03-Ini1007 to isolate this substep's change. |
| 2 | No fishery, tag, CAAL, or CPUE update is intended in this step. |
