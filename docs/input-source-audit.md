# Input source audit

Exact public repository commits, paths, and SHA256 values are recorded in
`config/public-run-provenance.csv`. Every step also has an
`input_manifest.csv` beside its `model/` folder.

| Steps | Input change |
| --- | --- |
| 01 | Archived 2023 diagnostic FRQ, INI 1003, TAG, CAAL and controls. |
| 02 | INI 1007 plus the 2.2.7.9-compatible flag-92 CV and age-128 scaling controls. |
| 03 | Lorenzen intercept fixed at `-2.54930339768360`. |
| 04 | Length-weight parameters changed to `3.073533e-05 2.932410`. |
| 05 | Five-region, 33-fishery FRQ/INI/TAG/CAAL structure. |
| 06 | Reweighted weight data converted to length frequencies through 2021. |
| 07 | Observed length data added where coverage exceeds weight samples. |
| 08 | FRQ and tag data extended through 2024, except CAAL. |
| 09 | F15 bins below 70 cm zeroed; F21-F23 intervals with midpoint above 90 cm removed. |
| 10 | Regional CPUE FRQ and headerless 20 × 5 regional-scaling input. |
| 11 | No data file change; time-varying CPUE uncertainty is activated in `doitall.sh`. |
| 12 | No core data change; R1-R5 observation-error controls fixed. |
| 13 | New CAAL input at weight 0.75. |
| 14a | All-five-region CAAL reweighting alternative. |
| 14b | Selected sub-basin CAAL reweighting, combining regions 3 and 4. |
| 15 | No data change; Job 18717 parsimonious-selectivity controls and audit map. |
| 16 | Only tag-flag column 1 changes, using region-mean K=0.20 mixing periods. |
| 17 | Only tag-flag column 2 changes from 0 to 1. |
| 18 | Only positive effort for F29-F33 changes according to the effort-creep series. |
| 19 | Only `doitall.sh` changes: DM-noRE G8/Nmax25 with concentration fixed at 7. |

The final core input hashes are locked to Job 18717 on the public
`final-exploration` branch. The validator also checks every parent-to-child
transition against the expected changed-file set.

## Size-data audit

Step 09 and later include four CSV sidecars:

- `f15-lf-qc-summary.csv` and `f15-lf-qc-audit.csv`
- `dom-lf-qc-summary.csv` and `dom-lf-qc-audit.csv`

For the Step 09 global FRQ, F15 removes 1,057 observations from 66 of 135
length-composition rows. F21, F22 and F23 remove 56, 6,146 and 1,702
observations respectively; one empty F21 composition is removed. Catch,
effort and the remaining composition values are not renormalised.

## Regional scaling

`bet.reg_scaling` is deliberately headerless for tuna-flow v2.5. It contains
20 numeric rows and five region columns, SHA256
`5f047ddb4053d1f6df9ace18e85e440b11553de246d024ce8138b427f5f9f7e3`.
The full 292 × 5 source is kept as `bet.reg_scaling.full` for audit only.

## Tag and reporting-rate isolation

The K=0.20 source is:

```text
PacificCommunity/ofp-sam-2026-BET-YFT-build-ini
commit efe3107c72774ee73b5e6dc45e44cf51f0fc20e8
BET/ini.mix-period/bet.2026.mix-0.2.ini
SHA256 1e8c589854274248efcb8b08cc85b476e718d2f5d985e03873e973181ae11e94
```

Only `tag_flags(:,1)` is copied at Step 16. Reporting-rate means, groups,
active flags, targets, and penalties remain unchanged. Step 17 changes only
`tag_flags(:,2)` to exclude reporting rates from predicted recaptures within
the pre-mixing window.
