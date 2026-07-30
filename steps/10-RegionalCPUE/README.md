# 10 Regional CPUE and scaling

Use five separate regional CPUE indices and the REGW100 regional-scaling prior.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/10-RegionalCPUE/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Use five separate regional CPUE indices and the REGW100 regional-scaling prior. |
| 2 | F15 bins below 70 cm are zeroed without renormalisation. |
| 3 | F21-F23 intervals with midpoint above 90 cm are removed. |
| 4 | F14 and F15 youngest five ages are fixed at zero selectivity. |
| 5 | Tag tau remains not estimated under the original 2023 negative-binomial parameterisation. |
| 6 | Scientific parent: '09-SizeDataQC'. |
| 7 | The model folder is rebuilt from source inputs plus the complete cumulative edit set. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq |
| `.ini` | bet.2026.ini |
| `.tag` | bet.2026.low.recaps.removed.tag |
| `.age_length` | bet.2023.new-structure.age_length |
| `input_manifest.csv` | machine-readable source and generated-edit provenance |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | Uses the selected source without additional scientific transformation. | All non-effort FRQ values. |
| `.ini` | rrpttp26 reporting-rate matrices; tag_flags(:,2)=0 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Sets only the effective-sample-size row to 0.75. | Age-length records and variant-specific structure. |
| `Step-specific change` | Use five separate regional CPUE indices and the REGW100 regional-scaling prior. | All previously selected controls; no OPR or length-bin selectivity. |

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
| 3 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 4 | No OPR or length-bin selectivity controls are generated. |
| 5 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
