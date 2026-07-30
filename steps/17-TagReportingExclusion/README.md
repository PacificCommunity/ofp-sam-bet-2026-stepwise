# 17 Pre-mixing reporting-rate exclusion

Set tag_flags(:,2)=1 so reporting rates are excluded only in pre-mixing windows.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/17-TagReportingExclusion/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Set tag_flags(:,2)=1 so reporting rates are excluded only in pre-mixing windows. |
| 2 | F15 bins below 70 cm are zeroed without renormalisation. |
| 3 | F21-F23 intervals with midpoint above 90 cm are removed. |
| 4 | F14 and F15 youngest five ages are fixed at zero selectivity. |
| 5 | Tag tau remains not estimated under the original 2023 negative-binomial parameterisation. |
| 6 | Scientific parent: '16-MIX020'. |
| 7 | The model folder is rebuilt from source inputs plus the complete cumulative edit set. |

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
| `.ini` | rrpttp26 reporting-rate matrices; MIX020 copied only into tag_flags(:,1); tag_flags(:,2)=1 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `Step-specific change` | Set tag_flags(:,2)=1 so reporting rates are excluded only in pre-mixing windows. | All previously selected controls; no OPR or length-bin selectivity. |

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
| 1 | Regional CPUE indices use the configured stationary-catchability/likelihood groups. |
| 2 | Regional-scaling weight is 100. |
| 3 | The Job 18717 selectivity update shares F2/F3 and F7/F9, retains four-node curves for F1/F2/F3/F5/F29, uses an independent logistic curve for F33, and keeps the documented F14/F15 youngest-five-age constraints. |
| 4 | F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data. |
| 5 | Fixed CPUE observation-error scales (flag 92 integer percentages): 35, 24, 21, 24, 23. |
| 6 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 7 | No OPR or length-bin selectivity controls are generated. |
| 8 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |
| 2 | The fishery definitions and tag-recapture groups in `fishery_map.R` are unchanged; only its selectivity-group metadata changes. See [the Step 15 comparison](../../docs/selectivity-update.md). |
| 3 | cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
