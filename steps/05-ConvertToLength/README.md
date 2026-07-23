# 05 Convert weight to length compositions

Convert the existing weight compositions to length.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/05-ConvertToLength/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Convert the existing weight compositions to length. |
| 2 | Scientific parent: '04-NewStructure'. |
| 3 | The model folder is rebuilt from source inputs plus the complete cumulative edit set. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | bet.2023.new-structure.global-cpue.wt-as-len.frq |
| `.ini` | bet.2023.new.structure.ini |
| `.tag` | bet.2023.new.structure-low.recaps.removed.tag |
| `.age_length` | bet.2023.new-structure.age_length |
| `input_manifest.csv` | machine-readable source and generated-edit provenance |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | Uses the selected source without additional scientific transformation. | All non-effort FRQ values. |
| `.ini` | tag_flags(:,2)=0 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Sets only the effective-sample-size row to 0.75. | Age-length records and variant-specific structure. |
| `doitall.sh` | Convert the existing weight compositions to length. | All previously selected controls; no OPR or length-bin selectivity. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `386d169` | Correct RR init values |
| `ofp-sam-2026-BET-YFT-tag-prep` | `471b2fd` | Correct RR group init values |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 2 | No OPR or length-bin selectivity controls are generated. |
| 3 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
