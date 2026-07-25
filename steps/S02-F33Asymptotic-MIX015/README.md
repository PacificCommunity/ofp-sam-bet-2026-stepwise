# S02 F33 asymptotic-selectivity sensitivity with SC22 K=0.15 mixing

Retain the extraction-only selectivity sharing and independent regional indices from S01, and replace only the F33 Region 5 four-node spline with an independent asymptotic logistic selectivity.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/S02-F33Asymptotic-MIX015/model` |
| Status | Prepared independent F33 asymptotic-selectivity sensitivity snapshot. |

## Changes

| # | Change |
| --- | --- |
| 1 | Retain the extraction-only selectivity sharing and independent regional indices from S01, and replace only the F33 Region 5 four-node spline with an independent asymptotic logistic selectivity. |
| 2 | F33 has 24 retained quarterly size compositions from 1965-1996, while its regional CPUE index spans 292 quarters from 1952-2024. Peatman et al. (2026; WCPFC-SC22-2026-SA-IP06) also identify Region 5 index compositions as sparse. |
| 3 | The unconstrained F33 spline fitted an effectively asymptotic curve; the logistic form tests whether removing an unsupported descending limb improves stability without materially degrading fit. |
| 4 | F29-F33 remain independent from extraction fisheries and from each other. F33 catchability, fixed Lorenzen M, DM G8 Nmax25, SC22-IP10 K=0.15 tag settings, reporting-rate priors, CPUE controls, data and all other settings are unchanged. |
| 5 | Runtime: tuna-flow v2.6 uses the MFCL pre-mixing reporting-rate exclusion correction; comparison with earlier-executable runs therefore includes that executable change as well as the F33 form change. |
| 6 | Scientific parent: 'S01-SelectivityStability-MIX015'. |
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
| `Step-specific change` | Retain the extraction-only selectivity sharing and independent regional indices from S01, and replace only the F33 Region 5 four-node spline with an independent asymptotic logistic selectivity. | All previously selected controls; no OPR or length-bin selectivity. |

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
| 13 | No OPR or length-bin selectivity controls are generated. |
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
