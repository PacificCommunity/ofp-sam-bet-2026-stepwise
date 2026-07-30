# Step 15 selectivity update

This note records the cumulative change from `14b-SUB075` to
`15-SelectivityUpdate`. The Step 15 controls reproduce the selectivity
specification used by Kflow Job 18717.

## Selectivity at the five-region transition

The conversion from 9 regions and 41 fisheries to 5 regions and 33 fisheries
at Step 05 was treated primarily as a structural remapping, rather than as a
new selectivity hypothesis. Selectivity forms, sharing assumptions, and
young- and terminal-age constraints were carried forward from the preceding
model wherever the source-fishery mapping allowed. Fisheries split from the
same source initially shared selectivity, compatible source fisheries retained
their previous grouping, and the five regional index fisheries shared one
curve. This reduced the risk of confounding the effect of the new spatial and
fishery structure with a simultaneous change in selectivity. Step 15 is the
subsequent, explicit revision of the fishery-specific selectivity assumptions.

## Scope

| Item | Step 14b to Step 15 |
| --- | --- |
| Fishery IDs, names and regions | Unchanged |
| Fishery source recipes | Unchanged |
| Tag-recapture groups and labels | Unchanged |
| `.frq`, `.ini`, `.tag`, `.age_length`, regional scaling and reporting-rate map | Unchanged |
| `fishery_map.R` | Only `selectivity_group` and `selectivity_name` change |
| `doitall.sh` | Only the selectivity controls change |

## Selectivity sharing

| Setting | Step 14b | Step 15 |
| --- | --- | --- |
| Number of groups | 25 | 31 |
| Shared extraction fisheries | F14/F15, F17/F18, F19/F25, F20/F27 | F2/F3 and F7/F9 |
| Regional indices F29-F33 | One shared curve | Five separate curves |
| All other fisheries | Separate except for the pairs above | Separate |

## Fishery-specific controls

| Control | Step 15 treatment |
| --- | --- |
| Selectivity-form penalty, flag 16 | Set to 0 for F12, F13, F15-F19 and F21-F27. The legacy explicit entries for F20 and F28 are removed. |
| Terminal spline age, flag 3 | F13=30, F15=25, F16=25, F17=25, F18=25, F21=10, F22=7, F23=6 and F24=25. Legacy explicit F20=30 and F28=30 entries are removed. |
| Cubic-spline nodes, flag 61 | F1, F2, F3, F5 and F29 use 4 nodes; F25 and F26 use 7 nodes. The default remains 5. |
| Selectivity form, flag 57 | F33 changes from the default cubic spline to an independent asymptotic logistic curve. |
| Youngest ages fixed at zero, flag 75 | Add F1=2, F3=2, F6=2, F11=2, F12=2, F13=1 and F29-F33=2; set F25=0 and F26=0 explicitly. |
| Retained young-age controls | F2, F4, F5 and F7-F10 remain at 2; F14 and F15 remain at 5. |
| Legacy non-decreasing constraint | The explicit F5 flag-16=1 entry is removed. |

The `fishery_map.R` change is therefore metadata required to describe the new
selectivity sharing. It does not redefine any fishery or tag-recapture group.

## Scientific rationale

The literature supports the method used to choose and test the controls, but
does not prescribe the exact Step 15 flag values:

- The 2023 independent review recommends defining fisheries from their
  composition data, separating aggregated fisheries when their compositions
  show incompatible shapes, fitting index compositions adequately, and using
  empirical selectivity diagnostics to choose spline knots. It also identifies
  shared regional-index selectivity as potentially problematic.
- The 2026 pre-assessment workshop identifies size-composition conflict as a
  fishery issue, supports separating Indonesian and Philippine handline
  fisheries, and notes that Philippine handline catches are large fish while
  the Indonesian large/small-fish mixture is uncertain.
- The SC22 size-frequency analysis shows fishery- and region-specific
  composition behaviour. It reports multimodal purse-seine compositions,
  different regional-index size trends, sparse Region 5 index compositions,
  and recommends time blocks where longline inputs switch from
  weight-as-length to observed length.

The fishery-based interpretation of the selected controls is:

| Fisheries | Fishery characteristic and diagnostic evidence | Rationale for the Step 15 control |
| --- | --- | --- |
| F2/F3 | Region 1 longline extraction fisheries; independently fitted curves had an age-selectivity RMS difference of 0.091. | Share one four-node curve as a targeted stability constraint supported by compatible gear/spatial definitions and similar fitted curves. |
| F7/F9 | Region 3-West longline extraction fisheries; independently fitted curves had an RMS difference of 0.074. | Share one curve for the same gear, spatial stratum and catch-weighted composition process. |
| F14/F15 | Indonesian and Philippine handline fisheries; the workshop supports separating them and identifies Philippine handline as a large-fish fishery. | Keep independent curves. Both lack effective support below 70 cm after Step 09, so the youngest five ages remain fixed at zero. |
| F21-F23 | Indonesian, Philippine and Vietnamese domestic mixed-gear fisheries. `DOM` is the agreed label for the fisheries called `MISC` in the source table. | Observations above 90 cm are excluded at Step 09; fishery-specific terminal ages limit inference in the unsupported older-age tail. |
| F25/F26 | Spatially distinct associated-school purse-seine fisheries in Regions 3 and 4; structured length-frequency misfit remained under the earlier shared, limited-node treatment. | Use independent seven-node curves to represent different size availability while retaining smooth splines; flag 75=0 allows young fish to remain available. |
| F29-F33 | Five regional longline CPUE index fisheries, whose compositions are abundance-weighted rather than catch-weighted and show different regional size trends. | Keep selectivity and catchability independent so an extraction fishery or another region cannot determine an index curve. |
| F33 | Region 5 index; only 24 quarterly compositions from 1965-1996 inform a 292-quarter CPUE series, and the fitted spline was already effectively asymptotic. | Replace weakly informed terminal spline flexibility with an independent two-parameter asymptotic logistic curve. |
| F1/F2/F3/F5 and F29 | Selected longline and index curves. | Four-node splines are lower-dimensional stability settings; their adequacy must be confirmed from composition fit rather than assumed from gear name alone. |
| Remaining fisheries | Distinct fleet, gear or regional definitions in the 33-fishery structure. | Separate curves avoid carrying forward sharing created by the previous aggregation unless both fishery definition and fitted-curve similarity support it. |

Thus, the main defence is consistency between the revised fishery definitions,
the observed size range and the amount of selectivity flexibility assigned to
each fishery. The sharing assumptions are narrower than in Step 14b, while
strong young- or old-age constraints are used where the retained observations
do not support those tails.

These are structural and biological reasons for testing the update, not a
claim that it is superior before fitting. Scientific acceptance should be
based on the Step 14b versus Step 15 change in likelihood components,
selectivity curves, residuals, parameter-at-bound behaviour and uncertainty.

The SC22 size-frequency paper specifically recommends testing selectivity time
blocks where a longline fishery switches from weight-as-length to observed
length. Step 15 does not add time blocks, so the current comparison isolates
the selected grouping and shape controls; time blocking remains a separate
sensitivity.

## References

- Punt, A. E., Maunder, M. N., and Ianelli, J. N. (2023).
  [Independent review of recent WCPO yellowfin tuna assessment
  (SC19-SA-WP-01)](https://meetings.wcpfc.int/node/18561).
- Hamer, P. (2026). [Summary Report from the SPC Pre-assessment Workshop -
  March 2026 (WCPFC-SC22-2026-SA-IP01)](https://meetings.wcpfc.int/node/32266).
- Peatman, T. et al. (2026). [Analysis of size frequency data for the 2026
  bigeye and yellowfin assessments
  (WCPFC-SC22-2026-SA-IP06)](https://meetings.wcpfc.int/node/32346).
- Model-diagnostic provenance:
  [selectivity-stability sensitivity](https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise/blob/sensitivity/selectivity-stability-sc22-k015-20260725/SELECTIVITY_STABILITY_SENSITIVITY.md)
  and [Region 5 index sensitivity](https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise/blob/sensitivity/independent-index-f33-logistic-20260726/F33_ASYMPTOTIC_SENSITIVITY.md).
