# S06 Common tag-overdispersion sensitivity with OPR and F33 spline

Apply the BET 2026 72-01-50-50 orthogonal-polynomial recruitment structure while retaining the independent F33 four-node spline and one common tag-overdispersion parameter.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/S06-CommonTagTauSplineOPR-MIX015/model` |
| Status | Prepared OPR F33-spline common-tau sensitivity snapshot. |

## Changes

| # | Change |
| --- | --- |
| 1 | Apply the BET 2026 72-01-50-50 orthogonal-polynomial recruitment structure while retaining the independent F33 four-node spline and one common tag-overdispersion parameter. |
| 2 | This configuration differs from S05 only in F33 selectivity form: the independent four-node cubic spline replaces the asymptotic logistic curve. |
| 3 | Age flag 110 remains active under OPR as the coefficient on the difference between OPR-implied mean regional recruitment proportions and the reference regional proportions. |
| 4 | Nmax=25 and the MFCL default Nmax=1000 are launched as paired OPR sensitivities. M remains fixed through Phase 10 and is opened only in Phases 11-12 for the paired M-estimation runs. |
| 5 | Tau grouping is set at runtime to one common F1-F28 parameter or three programme-informed recapture-fishery strata; F29-F33 remain inactive because the regional index fisheries have no tag recaptures. |
| 6 | Scientific parent: 'S04-CommonTagTauSpline-MIX015'. |
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
| `.frq` | Changes only positive F29-F33 effort using the agreed creep schedule. | All non-effort FRQ values. |
| `.ini` | rrpttp26 reporting-rate matrices; bet.2026.mix-0.15.ini copied only into tag_flags(:,1); tag_flags(:,2)=1 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `Step-specific change` | Apply the BET 2026 72-01-50-50 orthogonal-polynomial recruitment structure while retaining the independent F33 four-node spline and one common tag-overdispersion parameter. | All previously selected controls; no OPR or length-bin selectivity. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `5b2fb60` | Document SC22-IP10 mixing-period implementation |
| `ofp-sam-2026-BET-YFT-tag-prep` | `44f8043` | update RR groupings |
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
|  5 | The selectivity-stability sensitivity shares F2/F3 and F7/F9; F19, F25, F26 and F29-F33 remain independent. The Job 15989 node settings are retained, including seven nodes for F25/F26. |
|  6 | Fishery-specific terminal, dome and youngest-age-tail controls from the revised selectivity bundle are retained; only the documented coefficient-sharing groups change, while Job 15989 spline-node counts are retained. |
|  7 | The selected Job 14363 revised fishery-specific specification sets flag 16 to 0 for all 14 applicable fisheries, so the dome/old-age-tail form penalty is off. |
|  8 | F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data. |
|  9 | Fixed CPUE observation-error scales (flag 92 integer percentages): 35, 24, 21, 24, 23. |
| 10 | G8PSSET DM likelihood with effective-sample-size upper asymptote Nmax=25. |
| 11 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 12 | OPR uses the BET 2026 72-01-50-50 orthogonal-polynomial recruitment structure with a two-real-year end window. |
| 13 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |
| 2 | cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
