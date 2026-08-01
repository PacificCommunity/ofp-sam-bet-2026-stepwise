# BET 2026 final stepwise pathway — 02 Aug

This branch contains the revised BET 2026 stepwise pathway as 20
self-contained model folders representing 19 cumulative changes. No model
uses another step's fitted `.par` at runtime.

The selected path introduces the Job 18718 selectivity update and the weak
F10 non-decreasing penalty used by Kflow Job 19325 together at Step 15, then
carries both controls through Step 19:

- K = 0.20 region-mean tag-mixing periods.
- Original 2023 negative-binomial tag likelihood; tau is not estimated.
- Flexible fishery-specific selectivity from Job 18718: F1-F28 are independent,
  F29-F33 separate in staged run 5, flexible spline forms are retained, and
  the youngest five ages remain fixed at zero for F14 and F15.
  The exact Step 14b-to-Step 15 changes are listed in
  [the selectivity-update note](docs/selectivity-update.md).
- Dirichlet-multinomial length-composition likelihood, G8, `Nmax=25`.
- `fish_pars(22)` is written as 7 before Phase 1 and fixed with flag 69=0;
  grouped `fish_pars(23)` is estimated from Phase 2.
- F10 fish flag 16=1 with penalty weight flag 56=10000.
- Lorenzen natural-mortality intercept fixed at `-2.54930339768360`.

The final FRQ, TAG, age-length, regional-scaling, CFG and INI inputs are
byte-identical to both public Job 18718 and deterministic Job 19325. Step 15
adds executable fishery controls 16 and 56 together with the selectivity
update, and Steps 16-19 retain them. Every step uses the ordinary MFCL
`-makepar` start: no jitter, perturbation or promoted
seed-23 PAR from Job 19835 is used. The fishery and reporting-rate audit maps
retain the same numerical groups while using the agreed current 2026 fishery
labels, including `DOM` in place of the source-table label `MISC`.

## Step sequence

| Step | Folder | Change | Status |
| --- | --- | --- | --- |
| 01 | `01-Diag2023` | Refit the 2023 diagnostic model. | Selected |
| 02 | `02-NewExeIni1007` | Move to the 2.2.7.9-based executable and INI 1007 together. | Selected |
| 03 | `03-FixM` | Fix Lorenzen natural-mortality scaling to the diagnostic estimate. | Selected |
| 04 | `04-LengthWeight` | Apply the BET 2026 bias-corrected length-weight parameters. | Selected |
| 05 | `05-NewStructure` | Adopt the five-region, 33-fishery structure and remap the current reporting-rate controls. | Selected |
| 06 | `06-ConvertToLength` | Replace reweighted weight compositions with weight-as-length data through 2021. | Selected |
| 07 | `07-AddLengthData` | Add observed lengths where coverage exceeds weight samples. | Selected |
| 08 | `08-DataTo2024` | Extend data through 2024, except CAAL. | Selected |
| 09 | `09-SizeDataQC` | Apply PH/ID and domestic mixed-gear size-data rules. | Selected |
| 10 | `10-RegionalCPUE` | Use regional CPUE indices and the regional-scaling prior. | Selected |
| 11 | `11-TimeVaryingCV` | Apply time-varying CPUE uncertainty. | Selected |
| 12 | `12-CPUEErrorCalibration` | Fix R1-R5 log-scale SDs at 0.35, 0.24, 0.21, 0.24 and 0.23. | Selected |
| 13 | `13-NewAgeData` | Add new CAAL data with weight 0.75. | Selected |
| 14a | `14a-REG075` | Apply all-five-region CAAL reweighting. | Alternative |
| 14b | `14b-SUB075` | Apply selected sub-basin CAAL reweighting, combining regions 3 and 4. | Selected |
| 15 | `15-SelectivityUpdate` | Apply the selectivity update, including the weak F10 non-decreasing penalty (flags 16=1 and 56=10000). | Selected |
| 16 | `16-MIX020` | Apply release-group-specific K=0.20 mixing periods. | Selected |
| 17 | `17-TagReportingExclusion` | Exclude reporting rates within pre-mixing windows. | Selected |
| 18 | `18-EffortCreep` | Apply effort creep to regional CPUE indices. | Selected |
| 19 | `19-DMG8Nmax25` | Apply DM-noRE composition weighting, G8 and `Nmax=25`, with concentration fixed at 7. | Final |

There is no separate tail-compression step and no DOM or Francis weighting
branch in this pathway.

## Important controls

Step 02 deliberately updates the executable and required INI compatibility
controls together. The archived flag-92 penalty vector for F33-F41
(`88/53/130/109/76/93/121/77/23`) becomes the 2.2.7.9 CV vector
(`24/31/20/21/26/23/20/25/47`). Global age flag 128 changes from 10 to 100,
preserving the intended initial-Z multiplier of 1.0 under the new reader.
The regional recruitment-distribution penalty also uses the final-exploration default
of 0.1, represented by runtime age flag 110=0.

Step 09 sets F15 bins below 70 cm to zero without renormalisation and removes
F21-F23 intervals with midpoint above 90 cm. The committed CSV files beside
each affected FRQ record the exact removals.

Step 05 is the first step that uses the current reporting-rate specification.
The group IDs, active flags, initial values, targets and penalties are rebuilt
for the 33-fishery structure because the preceding 41-fishery matrices cannot
be transferred unchanged. This reporting-rate remapping is treated as part of
the structural transition and is retained cumulatively thereafter.

Step 16 copies only `tag_flags(:,1)` from
`SC22-IP10-regionMean@efe3107`:
`BET/ini.mix-period/bet.2026.mix-0.2.ini`. Step 17 changes only
`tag_flags(:,2)` from 0 to 1. The five reporting-rate matrices are unchanged
within each data family and from Step 08 through the final model.

`bet.reg_scaling` is the headerless 20 × 5 numeric file required by the
v2.5 executable. `bet.reg_scaling.full` is retained only as an audit/source
matrix.

## Rebuild and validate

The public model folders are already committed. To regenerate them, clone the
four public source repositories at the commits recorded in
`config/public-run-provenance.csv`, then set:

```bash
export BET_2026_INPUT_ROOT=/path/to/source-repositories
export BET_2026_INI_REPO_ROOT=/path/to/ofp-sam-2026-BET-YFT-build-ini
export BET_2026_TAG_REPO_ROOT=/path/to/ofp-sam-2026-BET-YFT-tag-prep
export BET_2026_AGE_REPO_ROOT=/path/to/ofp-sam-2026-BET-YFT-age-length-build
make prepare
```

Read-only validation does not run MFCL:

```bash
make validate
```

The validator checks the full parent graph, all manifests and transition
isolation, fixed M, size-data edits, reporting rates, K=0.20 mixing, tau mode,
the selectivity update, DM controls, the headerless v2.5 scaling file, the
Job 18718 core-input hashes, and the deterministic Job 19325 F10 penalty from
Step 15 through Step 19.

## Kflow runtime

`kflow.yaml` is fixed to Suva and the immutable tuna-flow v2.5 image digest.
The `bet-2026-final-stepwise-02aug` task registers the complete 20-model
pathway, retaining Steps 01-14b and replacing the selected path from Step 15.
The main executable is `/home/mfcl/mfclo64`; Step 01 selects the archived
2.2.2.0 diagnostic executable. `mfclkit` and `mfclshiny` are installed at
runtime from the pinned working commits in `kflow.yaml`, so a later campaign
can update those references without rebuilding the model inputs.

Submit one model:

```bash
make kflow STEP_SELECT=19-DMG8Nmax25
```

Submit the configured campaign only after validation and an explicit launch
decision. The repository itself contains inputs and controls, not fitted
outputs.

## Audit files

- `config/public-run-provenance.csv`: public repository, commit, path and SHA
  locks, including the Job 18718 core-input target.
- `docs/input-source-audit.md`: source-to-step input changes.
- `docs/tag-reporting-groups.md`: reporting-rate and tag-flag treatment.
- `MFCL_CONTROL_NOTES.md`: concise MFCL control interpretation.
- `DM_NMAX_RATIONALE.md`: final DM parameterisation.
