# Tag-recapture overdispersion sensitivities

These sensitivities rerun the complete native-MFCL `doitall.sh` sequence from
the Job 15984 configuration. Phase 10 estimates negative-binomial
tag-recapture overdispersion as

\[
\tau = 1 + \exp(\theta),
\]

where `theta` is fishery parameter row 4. Each estimated parameter starts from
`theta = 0` (`tau = 2`). `TAG_TAU_LOWER_X100` selects one of three bounds:

| Control | Tau range | Maximum information relative to Job 15984 |
| --- | --- | --- |
| `200` | 2-100 | approximately 51% |
| `300` | 3-150 | approximately 34% |
| `400` | 4-200 | approximately 26% |

The Job 15984 variance scale is approximately 1.02. All three bounds therefore
force lower tag information. After Phase 9, fishery-parameter row 4 is set in a
new `09.tau.par` so direct tau starts one unit above its selected lower bound
(`tau = 3, 4, or 5`). This avoids a boundary start while leaving Phases 0-9
identical to Job 15984.

## Sensitivity set

| Scenario | Estimated tau strata |
| --- | --- |
| `common` | One common tau for all tag-recapture fisheries |
| `pttp-r4-combined-vs-rest` | F25-F28; all other fisheries |
| `pttp-r4-west-east-vs-rest` | F25/F27; F26/F28; all other fisheries |
| `g19-vs-rest` | F25/F27; all other fisheries |
| `g20-vs-rest` | F26/F28; all other fisheries |
| `longline-vs-other` | F1-F11; F12-F33 |
| `longline-other-index` | F1-F11; F12-F28; F29-F33 |
| `rest-pttp-r4-index` | F1-F24; F25-F28; F29-F33 |
| `longline-other-pttp-r4-index` | F1-F11; F12-F24; F25-F28; F29-F33 |
| `longline-other-g19-g20-index` | F1-F11; F12-F24; F25/F27; F26/F28; F29-F33 |
| `jptp-core-vs-rest` | F1/F12/F13; all other fisheries |
| `jptp-core-pttp-r4-vs-rest` | F1/F12/F13; F25-F28; all other fisheries |
| `jptp-core-pttp-r4-west-east-vs-rest` | F1/F12/F13; F25/F27; F26/F28; all other fisheries |

F25/F27 and F26/F28 correspond to existing tag-recapture parent groups 19
and 20. They contain most recapture records from the influential PTTP Region 4
release groups. The nested groupings distinguish a common overdispersion
response from a PTTP Region 4-specific response without fitting one parameter
for every fishery.

F1/F12/F13 contain 431 of 459 JPTP recaptures (93.9%). The
`jptp-core-vs-rest` sensitivity estimates a separate tau for this concentrated
JPTP recapture process. It does not alter reporting-rate groups, initial
values, prior means, penalties, or bounds. The two combined scenarios estimate
the JPTP-core and PTTP Region 4 overdispersion scales in the same fit.

## Controls held constant

- KS 0.15 release-specific tag-mixing periods and the current reporting-rate
  grouping, means, and penalties
- fixed Lorenzen natural mortality
- Job 15984 F2/F3/F29 Region 1 selectivity sharing and independent index
  catchability
- Dirichlet-multinomial length-composition weighting, G8 grouping, and
  `Nmax = 25`
- all data files and remaining controls

`parest 177 = 0`, so the fixed tag-likelihood multipliers 250 and 500 are not
used. `parest 239 = 0` retains the serial tag likelihood that implements direct
tau, and the standard tag-return path remains active. The constraint on tau is
an information-scale bound, not a fixed likelihood multiplier.

## Execution

The campaign crosses the thirteen `TAG_TAU_SCENARIO` values with
`TAG_TAU_LOWER_X100 = 200, 300, 400`, giving 39 full fits. The script runs from
Phase 0 through Phase 12 with `/home/mfcl/mfclo64`; it does not use `mfclrtmb`
or start from the Job 15984 final parameter file.
