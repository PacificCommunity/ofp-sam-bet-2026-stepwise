# 16 Revised fishery-specific selectivity

Revise fishery-specific selectivity sharing, terminal ages, and F25/F26 shape settings for the 33-fishery structure, remove six superseded legacy controls, and set flag 16 to 0 for all 14 applicable fisheries so all weighting comparisons use the selected Job 14363 setting.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/16-SelectivityUpdate/model` |
| Status | Prepared input snapshot; model fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Revise fishery-specific selectivity sharing, terminal ages, and F25/F26 shape settings for the 33-fishery structure, remove six superseded legacy controls, and set flag 16 to 0 for all 14 applicable fisheries so all weighting comparisons use the selected Job 14363 setting. |
| 2 | Scientific rationale: represent fishery-specific size availability without imposing unnecessary older-age shape constraints before comparing composition weighting. |
| 3 | Held constant: data, fixed natural mortality, growth, CPUE settings, tag reporting-rate mapping, and every non-selectivity control. |
| 4 | The Step 15b parent has 15 active flag-16 penalties. The revised structure changes the applicable fishery set: superseded F20/F28 controls are removed and F15 is introduced. |
| 5 | For the resulting F12, F13, F15-F19, and F21-F27 set, flag 16 is 0 (form penalty off); fishery-specific terminal ages, spline-node counts, and youngest-age tails are retained. |
| 6 | Status: selected Job 14363 selectivity setting, carried forward to all Step 20 weighting comparisons. |
| 7 | Scientific parent: '15b-SUB075'. |
| 8 | The model folder is rebuilt from source inputs plus the complete cumulative edit set. |

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
| `.frq` | Uses the selected source without additional scientific transformation. | All non-effort FRQ values. |
| `.ini` | rrpttp26 reporting-rate matrices; tag_flags(:,2)=0 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `Step-specific change` | Revise fishery-specific selectivity sharing, terminal ages, and F25/F26 shape settings for the 33-fishery structure, remove six superseded legacy controls, and set flag 16 to 0 for all 14 applicable fisheries so all weighting comparisons use the selected Job 14363 setting. | All previously selected controls; no OPR or length-bin selectivity. |

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
|  1 | Regional CPUE indices use the configured stationary-catchability/likelihood groups. |
|  2 | Regional-scaling weight is 100. |
|  3 | Length-frequency parest flag 313 is 1, activating 1% tail aggregation; flags 311/301 remain 1 and weight-frequency flag 303 remains 0. |
|  4 | F29-F33 use separate selectivity coefficient-sharing groups from staged MFCL run 5. |
|  5 | The intended selectivity bundle unshares F15-F28 and applies fishery-specific terminal/dome and youngest-age-tail controls; F25/F26 each use seven nodes, terminal age 25, dome flag 2, and youngest-tail flag 0. |
|  6 | The selected Job 14363 revised fishery-specific specification sets flag 16 to 0 for all 14 applicable fisheries, so the dome/old-age-tail form penalty is off. |
|  7 | F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data. |
|  8 | Fixed CPUE observation-error scales (flag 92 integer percentages): 35, 24, 21, 24, 23. |
|  9 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 10 | No OPR or length-bin selectivity controls are generated. |
| 11 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |
| 2 | cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
