# 18a F22 form relaxed

Retain the Step 16c model and remove the dome/old-age-tail selectivity-form penalty for F22 only.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/18a-F22FormRelaxed/model` |
| Status | Prepared sensitivity snapshot; model fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Retain the Step 16c model and remove the dome/old-age-tail selectivity-form penalty for F22 only. |
| 2 | Scientific rationale: test sensitivity to the specified selectivity-form constraint. |
| 3 | Held constant: every Step 16c input and control except the named fishery flag-16 relaxation. |
| 4 | Status: alternative sensitivity comparison; not carried forward. |
| 5 | Scientific parent: '16c-DMG8Nmax25'. |
| 6 | The model folder is rebuilt from source inputs plus the complete cumulative edit set. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq |
| `.ini` | bet.2026.ini |
| `.tag` | bet.2026.low.recaps.removed.tag |
| `.age_length` | bet.2026.sub.basin.0.75.age_length |
| `input_manifest.csv` | machine-readable source and generated-edit provenance |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | Changes only positive F29-F33 effort using the agreed creep schedule. | All non-effort FRQ values. |
| `.ini` | rrpttp26 reporting-rate matrices; MIX015 copied only into tag_flags(:,1); tag_flags(:,2)=1 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `doitall.sh` | Retain the Step 16c model and remove the dome/old-age-tail selectivity-form penalty for F22 only. | All previously selected controls; no OPR or length-bin selectivity. |

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
|  1 | Regional CPUE indices use the configured stationary-catchability/likelihood groups. |
|  2 | Regional-scaling weight is 100. |
|  3 | F29-F33 use separate selectivity coefficient-sharing groups from staged MFCL run 5. |
|  4 | The intended Step 15 bundle unshares F15-F28 and applies fleet-specific terminal/dome and youngest-age-tail controls; F25/F26 each use seven nodes, terminal age 25, dome flag 2, and youngest-tail flag 0. |
|  5 | F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data. |
|  6 | Fixed CPUE observation-error scales (flag 92 integer percentages): 35, 24, 21, 24, 23. |
|  7 | G8PSSET DM likelihood with effective-sample-size upper asymptote Nmax=25. |
|  8 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
|  9 | No OPR or length-bin selectivity controls are generated. |
| 10 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |
| 2 | cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, CPUE MLE sigma values, and executed flag-92 values. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
