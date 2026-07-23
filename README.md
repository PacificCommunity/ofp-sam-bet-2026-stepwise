# BET 2026 Stepwise

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

Public, reproducible configuration for the 2026 bigeye tuna (BET) MFCL
stepwise analysis. It contains 17 scientific groups and 22 independently
runnable model rows. Nineteen models form the selected carry-forward path.

## Run Contract

- Each `STEP_SELECT` value maps to one self-contained
  `steps/<STEP_SELECT>/model/` folder. A row does not consume its parent's run
  output.
- `scientific_parent_id` records the model used for scientific comparison. It
  is provenance, not a scheduler dependency.
- All 22 rows can run independently and in parallel through Kflow.
- `selected = TRUE` identifies the adopted BET 2026 route. `carry_status` is
  `carry` when later rows inherit that model, `stop` for an unselected sibling,
  and `final` for the terminal model.
- `STEP_SELECT=all` runs all 22 rows, including sibling alternatives. Any row
  can be run alone, for example `STEP_SELECT=15-SelectivityUpdate`.
- Every row has a unique `STEP_SELECT`, `job_key`, `job_title`, and
  `model_label`, plus explicit CPU, memory, disk, expected-output, and artifact
  metadata in `job-config.R`.
- Native `doitall` runs auto-detect the final MFCL `.par`; the compact output
  contract also includes `model_payload.rds`. Outputs are identified by the
  row's unique `output_artifact` value.

The selected route follows the numbered chain except at sibling branches:
`09c-SUB075` and `17b-DMG8Nmax25` are carried forward. Step 17b is the final
selected model.

## Step Map

| Group | `STEP_SELECT` | Scientific parent | Selection / carry | Scientific change |
| --- | --- | --- | --- | --- |
| 01 | `01-Diag2023` | `external-2023-diagnostic-archive` | selected / carry | Rerun the 2023 diagnostic anchor. |
| 02a | `02a-NewExe1003` | `01-Diag2023` | selected / carry | Change only executable invocation/safety while retaining the Step 01 inputs and scientific controls, including CPUE flag-92 and global `2/94` value `10`. |
| 02b | `02b-Ini1007` | `02a-NewExe1003` | selected / carry | Convert the ini layout from 1003 to 1007. |
| 02c | `02c-LengthWeight` | `02b-Ini1007` | selected / carry | Apply the BET 2026 bias-corrected length-weight parameters. |
| 03 | `03-FixM` | `02c-LengthWeight` | selected / carry | Fix natural mortality from the `mgc=-5` diagnostic fit. |
| 04 | `04-NewStructure` | `03-FixM` | selected / carry | Adopt the five-region, 33-fishery structure. |
| 05 | `05-ConvertToLength` | `04-NewStructure` | selected / carry | Convert existing weight compositions to length. |
| 06 | `06-AddLengthData` | `05-ConvertToLength` | selected / carry | Add the additional length-composition data. |
| 07 | `07-DataTo2024` | `06-AddLengthData` | selected / carry | Extend data through 2024 and integrate the latest RRPTTP26 reporting-rate penalties. |
| 08 | `08-RegionalCPUE` | `07-DataTo2024` | selected / carry | Replace the FRQ with the authoritative regional CPUE source and add its likelihood plus REGW100; the source has two fewer F32 1952 quarterly records and receives no transform. |
| 09a | `09a-BASE075` | `08-RegionalCPUE` | alternative / stop | Apply BASE075 composition weighting. |
| 09b | `09b-REG075` | `08-RegionalCPUE` | alternative / stop | Apply REG075 composition weighting. |
| 09c | `09c-SUB075` | `08-RegionalCPUE` | selected / carry | Apply the selected SUB075 composition weighting. |
| 10 | `10-MIX015` | `09c-SUB075` | selected / carry | Apply the MIX015 tag-mixing setting. |
| 11 | `11-TAGF2ON` | `10-MIX015` | selected / carry | Exclude reporting-rate effects during each release group's configured mixing periods. |
| 12 | `12-TimeVaryingCV` | `11-TAGF2ON` | selected / carry | Apply normalized time-varying CPUE relative-variance multipliers. |
| 13 | `13-EffortCreep` | `12-TimeVaryingCV` | selected / carry | Apply the BET 2026 effort-creep series. |
| 14 | `14-CPUESigma` | `13-EffortCreep` | selected / carry | Apply common index-specific CPUE MLE sigma values. |
| 15 | `15-SelectivityUpdate` | `14-CPUESigma` | selected / carry | Apply the intended broad bundle: unshare F15-F28, set fleet-specific terminal/dome controls, apply F25/F26 seven-node/tail controls, and separate F29-F33. |
| 16 | `16-DOMDiv200` | `15-SelectivityUpdate` | selected / carry | Apply DOM divisor 200 to F21-F23. |
| 17a | `17a-Francis` | `16-DOMDiv200` | alternative / stop | Replace all Step 16 LF divisors with Francis values, including F21-F23 `114/398/705`. |
| 17b | `17b-DMG8Nmax25` | `16-DOMDiv200` | selected / final | Apply the DM likelihood and G8 PSSET grouping with `Nmax=25`, calibrated from the fishery-level Francis ESS diagnostics underlying Step 17a. Steps 17a and 17b are sibling likelihood alternatives, not sequential fits. |

The latest RRPTTP26 reporting-rate penalties are part of
`07-DataTo2024`; there is no standalone reporting-rate model row. Because
`07-DataTo2024` is selected, `08-RegionalCPUE` and every later descendant
inherit that reporting-rate setup.

## Exact Selectivity Controls

All recent selectivity and node changes are introduced together in
`15-SelectivityUpdate`, immediately after `14-CPUESigma`:

| Control | Setting |
| --- | --- |
| F15-F28 sharing | Unshare the fleet selectivity definitions so each fishery has its own coefficient-sharing group. |
| Fleet-specific form | Apply the audited terminal-age, older-age dome, and youngest-age tail controls by fleet. |
| F25/F26 | Use independent groups with terminal age `25`, dome flag `2`, seven spline nodes, and youngest-tail flag `0`. |
| F29-F33 | Separate the five regional-index selectivity groups in staged MFCL run 5. |

These controls are bundled as one scientific update. They are not included in
`08-RegionalCPUE`, and there is no earlier standalone spline-selectivity row.

Persistent structured length-frequency misfit remained for F25 and F26 under
the previous shared, limited-node selectivity structure. F25 and F26 are
spatially distinct associated purse-seine fisheries. They remain together in
the associated-purse-seine G8 DM overdispersion group, but receive independent
selectivities and seven-node cubic splines so different size availability can
be represented while each curve remains smooth.

F29-F33 are regional index fisheries. Their selectivities are separated so a
single selectivity constraint cannot mask regional size-availability
differences, while the fisheries retain their common index-oriented DM group.
The F15-F28 unsharing, fleet-specific terminal/dome settings, F25/F26
seven-node/tail controls, and F29-F33 separation are one assessment-specific
bundle evaluated stepwise; they are not mandated by the selectivity or DM
literature.

Step 17a is a replacement weighting comparison, not a cumulative DOM-plus-
Francis treatment. Its Francis divisors replace every Step 16 flag-49 value;
for F21-F23 the resulting values are `114`, `398`, and `705`, not `200`.

## Final DM Cap Rationale

The DM likelihood is useful because it estimates composition overdispersion
within the model rather than treating the nominal sample size as the effective
amount of information. The fitted overdispersion therefore determines the
effective weight assigned to the length-frequency data, subject to `Nmax`.

Preliminary BET fits showed a clear trade-off: increasing `Nmax` allowed the
length-frequency component to exert more influence and improve its fit, but it
also reduced the fit to CPUE indices. `Nmax` was therefore treated as an upper
bound on composition information, not as a target effective sample size.

| Consideration | Evidence from preliminary fits | Stepwise decision |
| --- | --- | --- |
| Composition weighting | DM estimated overdispersion and effective composition information internally, avoiding direct use of large nominal sample sizes. | Retain DM as the selected composition likelihood. |
| Integrated-model balance | Larger `Nmax` values increased the influence of length-frequency data and degraded CPUE fit. | Use a finite upper asymptote for DM effective composition information rather than allowing the LF component to dominate the joint objective function. |
| Empirical scale | The upper range of preliminary fishery-level Francis ESS diagnostics provided an independent calibration scale. | Use the rounded value `Nmax=25` as the DM effective-sample-size upper asymptote. |
| Interpretation | Francis diagnostics calibrate the scale but are not clipped by the DM implementation. | State explicitly that MFCL estimates the DM parameter internally and approaches `Nmax=25` smoothly. |

This choice preserves the main advantage of DM weighting while limiting the
ability of a small number of highly informative composition series to dominate
the integrated fit. The G8 PSSET grouping and `Nmax=25` remain
assessment-specific choices evaluated in this stepwise design. A concise
report-ready record is provided in
[`DM_NMAX_RATIONALE.md`](DM_NMAX_RATIONALE.md).

## Method And Assessment Choices

The distinction below is intentional. A general method can be supported by the
assessment literature while its datasets, fleet groupings, constants, and
branch selection remain BET 2026 decisions.

| Group | General or literature method | BET 2026 assessment-specific choice |
| --- | --- | --- |
| 01 | Re-running an earlier model provides a reproducibility anchor. | Use the archived 2023 diagnostic and historical diagnostic executable. |
| 02 | Separating software, input-format, and biological-coefficient changes isolates implementation effects. | Compare executables first with exact Step 01 scientific controls, then change only ini layout to 1007, then apply the BET 2026 bias-corrected length-weight coefficients. |
| 03 | Natural mortality may be fixed while other model parameters are estimated. | Carry the fixed mortality from the `mgc=-5` BET diagnostic result. |
| 04 | Spatial and fleet stratification represents heterogeneous population and fishery processes. | Use five regions and 33 fisheries. |
| 05-07 | Composition-unit conversion, addition of observations, terminal-year updates, and reporting-rate inputs are standard assessment-build operations. | Convert the designated weight data, add the designated BET length data, extend through 2024, and integrate the latest RRPTTP26 penalties at step 07. RRPTTP26 is an assessment input, not a universal reporting-rate method. |
| 08 | Relative-abundance indices enter through an observation likelihood, and likelihood components can be assigned relative weights. | Use the authoritative regional CPUE source as supplied, including two fewer F32 1952 quarterly records, and apply `REGW100`; no FRQ transform or selectivity choice is made in this row. |
| 09 | Composition likelihood weighting controls the influence of composition observations. | Compare BASE075, REG075, and SUB075 as siblings; the `075` design and selected SUB075 branch are assessment choices. |
| 10 | Tag-mixing assumptions control when releases contribute to the tag likelihood. | Apply the fixed `MIX015` setting. |
| 11 | MFCL tag flags activate specified tag-model behavior. | Turn on column 2 only (`TAGF2ON`); do not imply that every tag-flag column is enabled. |
| 12 | Time-varying observation CVs allow index precision to vary through time. | Use the BET 2026 CPUE CV schedule. |
| 13 | Effort-creep corrections account for changing fishing efficiency. | Apply 1%/year for 1952-1976 and 0.5%/year for 1977-2024 to index fisheries F29-F33. |
| 14 | Index-specific observation error controls the relative influence of CPUE series in the integrated fit. | Preliminary fits across alternative configurations gave similar MLE sigma estimates. Fix these common values for all later stepwise comparisons so CPUE weighting remains consistent. |
| 15 | Fleet-specific selectivity avoids forcing unlike fisheries to share one curve, and flexible splines retain smoothness while representing size availability. | Apply one broad bundle: unshare F15-F28, set fleet-specific terminal/dome controls, use terminal age 25/dome flag 2/seven nodes/youngest-tail flag 0 for F25/F26, and separate F29-F33 in staged run 5. DM grouping is unchanged. |
| 16 | Data weighting can alter a likelihood component's influence. | The DOM treatment for F21-F23 and divisor `200` are assessment-specific. No literature-derived claim is made for that divisor. |
| 17 | Francis weighting adjusts fishery-specific composition weights while retaining the normal likelihood; the Dirichlet-multinomial (DM) instead models overdispersion and estimates effective composition information internally. | Compare replacement Francis divisors, including F21-F23 `114/398/705`, with one bundled DM configuration using G8 PSSET and `Nmax=25`. Preliminary Francis diagnostics calibrate the DM scale but are not directly clipped by its implementation. |

Useful method references:

- Francis, R.I.C.C. (2011), [Data weighting in statistical fisheries stock
  assessment models](https://doi.org/10.1139/f2011-025).
- Thorson, J.T., Johnson, K.F., Methot, R.D., and Taylor, I.G. (2017),
  [Model-based estimates of effective sample size in stock assessment models
  using the Dirichlet-multinomial distribution](https://doi.org/10.1016/j.fishres.2016.06.005).
- Maunder, M.N. and Punt, A.E. (2013), [A review of integrated analysis in
  fisheries stock assessment](https://doi.org/10.1016/j.fishres.2012.07.025),
  for the broader integrated-assessment context.

The references motivate general methods only. They do not determine the BET
fleet numbers, reporting-rate source, spline node count, weighting codes,
effort-creep schedule, DOM divisor, sigma calibration, G8 grouping, or Nmax.

## CPUE MLE Sigma

Index-specific CPUE sigma values were estimated by maximum likelihood in a
range of preliminary model configurations. The estimates were similar across
those fits, indicating that the observation-error scale was not sensitive to
the preliminary structural choices. Step 14 therefore fixes sigma at the
common values selected from the preliminary fits. This keeps CPUE weighting constant in all later
stepwise comparisons and avoids confounding selectivity or composition-
likelihood changes with simultaneous reweighting of the abundance indices.

| CPUE MLE sigma setting | R1 | R2 | R3 | R4 | R5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| CPUE MLE sigma | 0.354 | 0.237 | 0.212 | 0.239 | 0.225 |
| Applied fish flag 92 | 35 | 24 | 21 | 24 | 23 |

The archived fitted input is the controlling implementation record for these common
production values.

## DOM Naming

`DOM` is the assessment's short scenario name for the F21-F23 treatment. It is
not the name of a general statistical method. The divisor `200` is a BET 2026
assessment-specific choice and is not implied by the name or prescribed by the
literature.

## Final Model Provenance

`17b-DMG8Nmax25` is the terminal selected model. Its fitted model matches Job
`13328`, and its Hessian merge is Job `13432`. These job numbers are provenance
references only; this repository does not submit, fetch, or merge jobs as part
of `job-config.R`.

## Resources And Outputs

| Rows | Regions | CPUs | Memory | Disk | Run mode | Expected output |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| 01-03 | 9 | 2 | 12 GB | 8 GB | native MFCL `doitall` | auto-detected final `.par` plus `model_payload.rds` |
| 04-17 | 5 | 2 | 8 GB | 8 GB | native MFCL `doitall` | auto-detected final `.par` plus `model_payload.rds` |

Step 01 alone pins the historical diagnostic executable. All other rows use
the current container MFCL executable. `BET_PHASE10_11_CONVERGENCE` remains a
run-time convergence control and can be overridden without changing model
inputs.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `job-config.R` | Public 22-row run matrix and row metadata. |
| `steps/<STEP_SELECT>/README.md` | Model-specific scientific and input notes. |
| `steps/<STEP_SELECT>/input_manifest.csv` | Source-input provenance. |
| `steps/<STEP_SELECT>/model/` | Self-contained MFCL run folder. |
| `docs/run-configuration.md` | Kflow and local-run behavior. |
| `R/prepare_bet_2026_step_inputs.R` | Reproducible model-input preparation. |
