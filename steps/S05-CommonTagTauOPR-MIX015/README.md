# S05 Common tag-overdispersion sensitivity with OPR and F33 asymptotic selectivity

Apply the audited BET 69-01-50-50 orthogonal-polynomial recruitment structure while retaining the F33 asymptotic selectivity and one common tag-overdispersion parameter.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/S05-CommonTagTauOPR-MIX015/model` |
| Status | Prepared OPR common-tau sensitivity snapshot. |

## Changes

| # | Change |
| --- | --- |
| 1 | Apply the audited BET 69-01-50-50 orthogonal-polynomial recruitment structure while retaining the F33 asymptotic selectivity and one common tag-overdispersion parameter. |
| 2 | The OPR controls are introduced in Phase 3. They replace the mean-plus-deviation regional recruitment time series and retain the same data, tag, CPUE, selectivity and composition-likelihood settings. |
| 3 | Age flag 110 remains active under OPR as the coefficient on the difference between OPR-implied mean regional recruitment proportions and the reference regional proportions. |
| 4 | Nmax=25 and the MFCL default Nmax=1000 are launched as paired OPR sensitivities; flag 342=0 invokes the source-code default of 1000. |
| 5 | Tau grouping is set at runtime to one common F1-F28 parameter or three programme-informed recapture-fishery strata; the latter are JPTP and PTTP Region 4 proxies rather than release-programme parameters. |
| 6 | M remains fixed through Phase 10. Paired M sensitivities open only the Lorenzen intercept in Phases 11-12. |
| 7 | Scientific parent: 'S03-CommonTagTau-MIX015'. |
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
| `.frq` | Changes only positive F29-F33 effort using the agreed creep schedule. | All non-effort FRQ values. |
| `.ini` | rrpttp26 reporting-rate matrices; bet.2026.mix-0.15.ini copied only into tag_flags(:,1); tag_flags(:,2)=1 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `Step-specific change` | Apply the audited BET 69-01-50-50 orthogonal-polynomial recruitment structure while retaining the F33 asymptotic selectivity and one common tag-overdispersion parameter. | All previously selected controls; no OPR or length-bin selectivity. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `5b2fb60` | Document SC22-IP10 mixing-period implementation |
| `ofp-sam-2026-BET-YFT-tag-prep` | `44f8043` | update RR groupings |
| `ofp-sam-2026-BET-YFT-age-length-build` | `96a06d2` | add various effective sample sizes |
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
|  6 | F33 remains an independent Region 5 index selectivity and uses the two-parameter asymptotic logistic form; its catchability group and all extraction-index separations are unchanged. |
|  7 | Fishery-specific terminal, dome and youngest-age-tail controls from the revised selectivity bundle are retained; only the documented coefficient-sharing groups change, while Job 15989 spline-node counts are retained. |
|  8 | The selected Job 14363 revised fishery-specific specification sets flag 16 to 0 for all 14 applicable fisheries, so the dome/old-age-tail form penalty is off. |
|  9 | F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data. |
| 10 | Fixed CPUE observation-error scales (flag 92 integer percentages): 35, 24, 21, 24, 23. |
| 11 | G8PSSET DM likelihood with effective-sample-size upper asymptote Nmax=25. |
| 12 | The folder is generated independently from source inputs; its scientific parent is not a runtime dependency. |
| 13 | OPR uses the audited BET 69-01-50-50 orthogonal-polynomial recruitment structure. |
| 14 | INI and TAG inputs are never rolled back to an earlier selected row. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | No preliminary parameter file or scientific-parent model folder is read at runtime. |
| 2 | cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
