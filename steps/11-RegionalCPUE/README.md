# 11 Regional CPUE likelihood and weighting

Add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/11-RegionalCPUE/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty. |
| 2 | The authoritative regional CPUE replacement has two fewer F32 1952 quarterly records than Step 10; the source FRQ is copied without transformation. |
| 3 | Scientific parent: '10-DataTo2024'. |
| 4 | The model folder is rebuilt from source inputs plus the complete cumulative edit set. |

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
| `Step-specific change` | Add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty. | All previously selected controls; no OPR or length-bin selectivity. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `d48e396` | Reject conflicting tag reporting-rate priors |
| `ofp-sam-2026-BET-YFT-tag-prep` | `6d66dc3` | update RR groupings |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | Regional CPUE indices use the configured stationary-catchability/likelihood groups. |
| 2 | Regional-scaling weight is 100. |
| 3 | Length-frequency parest flag 313 is 1, activating 1% tail aggregation; flags 311/301 remain 1 and weight-frequency flag 303 remains 0. |
| 4 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 5 | No OPR or length-bin selectivity controls are generated. |
| 6 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
