# 21b R1 shared selectivity with SC22 K=0.05 mixing

Use the same final DM model and exact Job 15984 selectivity map as Step 21a, changing only tag_flags(:,1) from the SC22 K=0.15 periods to the SC22 K=0.05 periods.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/21b-R1F2F3F29Shared-MIX005/model` |
| Status | Prepared independent K=0.05 mixing-period sensitivity snapshot. |

## Changes

| # | Change |
| --- | --- |
| 1 | Use the same final DM model and exact Job 15984 selectivity map as Step 21a, changing only tag_flags(:,1) from the SC22 K=0.15 periods to the SC22 K=0.05 periods. |
| 2 | Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12. |
| 3 | Mixing-period source: ofp-sam-2026-BET-YFT-build-ini SC22-IP10-based commit 5b2fb6053e34a58ef61275a68d8a67ec988833c1, K=0.05. |
| 4 | Held constant relative to Step 21a: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets, penalties, CPUE controls, data and every doitall control. |
| 5 | Scientific parent: '21a-R1F2F3F29Shared-MIX015'. |
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
| `.ini` | rrpttp26 reporting-rate matrices; bet.2026.mix-0.05.ini copied only into tag_flags(:,1); tag_flags(:,2)=1 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `Step-specific change` | Use the same final DM model and exact Job 15984 selectivity map as Step 21a, changing only tag_flags(:,1) from the SC22 K=0.15 periods to the SC22 K=0.05 periods. | All previously selected controls; no OPR or length-bin selectivity. |

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
|  3 | Length-frequency parest flag 313 is reset to 0 because the DM likelihood does not read the percentage threshold; this also avoids unrelated percentage-tail preprocessing, while parest flag 320 controls DM support. |
|  4 | F29-F33 use separate selectivity coefficient-sharing groups from staged MFCL run 5. |
|  5 | The intended selectivity bundle unshares F15-F28 and applies fishery-specific terminal/dome and youngest-age-tail controls; F25/F26 each use seven nodes, terminal age 25, dome flag 2, and youngest-tail flag 0. |
|  6 | The selected Job 14363 revised fishery-specific specification sets flag 16 to 0 for all 14 applicable fisheries, so the dome/old-age-tail form penalty is off. |
|  7 | F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data. |
|  8 | Fixed CPUE observation-error scales (flag 92 integer percentages): 35, 24, 21, 24, 23. |
|  9 | G8PSSET DM likelihood with effective-sample-size upper asymptote Nmax=25. |
| 10 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 11 | No OPR or length-bin selectivity controls are generated. |
| 12 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |
| 2 | cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
