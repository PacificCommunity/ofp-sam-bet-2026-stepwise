# 20c DM weighting

Branch directly from Step 19 and use a Dirichlet-multinomial length-composition likelihood with G8 grouping and Nmax 25, without DOM divisor 200 or Francis weighting.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/20c-DMG8Nmax25/model` |
| Status | Prepared selected-model snapshot; model fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Branch directly from Step 19 and use a Dirichlet-multinomial length-composition likelihood with G8 grouping and Nmax 25, without DOM divisor 200 or Francis weighting. |
| 2 | Scientific rationale: estimate composition information internally with Nmax=25 as the asymptotic effective-sample-size upper bound. The value lies just above the 22.22-23.81 range of 95th-percentile composition-level Francis effective sample sizes across 2,399 positive LF compositions in matched robust-normal fits. |
| 3 | Held constant: all Step 19 data, biology, Job 14363 revised fishery-specific selectivity with form penalties off, CPUE, and tag settings; neither the 20a divisor nor 20b Francis weights are inherited. Flag 313 is reset to 0 because the DM likelihood does not read that percentage threshold and to avoid unrelated percentage-tail preprocessing; flag 320=5 controls DM support and the resulting numeric controls match Job 14363. |
| 4 | Status: selected final model. |
| 5 | Scientific parent: '19-EffortCreep'. |
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
| `.ini` | rrpttp26 reporting-rate matrices; bet.2026.mix-0.15.ini copied only into tag_flags(:,1); tag_flags(:,2)=1 | All unlisted INI fields and cumulative RR/tag controls. |
| `.tag` | Uses the selected TAG source without rollback or replacement. | All tag release and recapture records. |
| `.age_length` | Preserves the exact heterogeneous age-length variant. | Age-length records and variant-specific structure. |
| `Step-specific change` | Branch directly from Step 19 and use a Dirichlet-multinomial length-composition likelihood with G8 grouping and Nmax 25, without DOM divisor 200 or Francis weighting. | All previously selected controls; no OPR or length-bin selectivity. |

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
