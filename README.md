# BET 2026 Stepwise

<p align="right">
  <a href="model-development-report/kflow.yaml"><img src="kflow-ready.svg" alt="Kflow report-only task"></a>
</p>

Public, reproducible configuration for the 2026 bigeye tuna (BET) MFCL
stepwise analysis. It contains 22 numbered scientific groups and 26
independently runnable model rows. Twenty models form the selected
carry-forward path; Steps 21 and 22 contain post-selection sensitivities.

## Run Contract

- Each `STEP_SELECT` value maps to one self-contained
  `steps/<STEP_SELECT>/model/` folder. A row does not consume its parent's run
  output.
- `scientific_parent_id` records the model used for scientific comparison. It
  is provenance, not a scheduler dependency.
- All 26 rows can run independently and in parallel through Kflow.
- `selected = TRUE` identifies the adopted BET 2026 route. `carry_status` is
  `carry` when later rows inherit that model, `stop` for an unselected sibling,
  and `final` for the terminal model.
- `STEP_SELECT=all` runs all 26 development rows, including sibling
  alternatives. Any row can be run alone, for example
  `STEP_SELECT=16-SelectivityUpdate`.
- Every row has a unique `STEP_SELECT`, `job_key`, `job_title`, and
  `model_label`, plus explicit CPU, memory, disk, expected-output, and artifact
  metadata in `job-config.R`.
- Native `doitall` runs auto-detect the final MFCL `.par`; the compact output
  contract also includes `model_payload.rds`. Outputs are identified by the
  row's unique `output_artifact` value.

## Publication HTML

The report-only task is defined in
[`model-development-report/kflow.yaml`](model-development-report/kflow.yaml).
With `STEPWISE_MODEL_JOBS=""`, it renders a self-contained HTML containing the
publication methods text, DAG and caption, the 26-row configuration table, and
separate tables for the selected Dirichlet-multinomial configuration and its
eight fishery groups. Each section can be copied to Word or LaTeX. Supplying an
explicit step-to-job map later adds fitted-model results without changing the
pathway record.

The root [`kflow.yaml`](kflow.yaml) is the separate 26-model MFCL fitting task;
do not use it when only the HTML report is required.

## Pinned INI Source

All INIs sourced from the 2026 build-ini repository are taken from
`PacificCommunity/ofp-sam-2026-BET-YFT-build-ini` branch
`SC22-IP10-based` at commit `5b2fb60`, not from `main`. This includes
`bet.2023.new.structure.ini` for Steps 06–09, `bet.2026.ini` for Steps 10–21,
the SC22-IP10 Appendix A `bet.2026.mix-0.15.ini` from Step 17 onward, and
`bet.2026.mix-0.05.ini` for the Step 21b sensitivity.
Steps 01–05 intentionally retain the historical 2023 diagnostic INI pathway.
For a rebuild, point `BET_2026_INI_REPO_ROOT` to a checkout of
`SC22-IP10-based`; the provenance lock verifies the exact base and MIX015
file hashes.

The selected route is
`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15b → 16 → 17 → 18 → 19 → 20c`.
At the two comparison points, `15b-SUB075` and `20c-DMG8Nmax25` are carried
forward. Step 20c is the final selected model and retains the Job 14363
revised fishery-specific selectivity choice with form penalties off.

## Step Map

Reader-facing names are used in this table and the diagram; stable internal IDs
remain available for reproducible runs. CPUE means catch per unit effort, DOM
identifies the domestic-fishery composition series, and
Dirichlet-multinomial is abbreviated DM in technical settings.
For reports and papers, use the compact DAG for the development flow and this
table for the functional explanation and implementation detail of each step.

| Step | Reader-facing name | Internal ID | Parent | Change and rationale | Held constant | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | 2023 diagnostic rerun | `01-Diag2023` | 2023 diagnostic model | Reproduce the previous diagnostic model as a common reference. | Archived data and scientific controls. | Carried forward. |
| 02 | Updated executable | `02-NewExe1003` | `01-Diag2023` | Change only the executable to isolate software-version effects. | Inputs and scientific controls. | Carried forward. |
| 03 | Updated INI format | `03-Ini1007` | `02-NewExe1003` | Update the INI file from format 1003 to the latest MFCL format, 1007. | Data and scientific assumptions. | Carried forward. |
| 04 | Diagnostic natural-mortality estimate fixed | `04-FixM` | `03-Ini1007` | Fix Lorenzen natural-mortality scaling to the 2023 diagnostic-model estimate to improve stability, as agreed at the pre-assessment workshop. | Data, structure, and other biological settings. | Carried forward. |
| 05 | Length-weight update | `05-LengthWeight` | `04-FixM` | Update the length-weight relationship used to convert size to biomass. | Fixed mortality and all other inputs and controls. | Carried forward. |
| 06 | Five-region structure | `06-NewStructure` | `05-LengthWeight` | Introduce the five-region, 33-fishery structure and the audited tag reporting-rate mapping. | Fixed mortality and preceding biological settings. | Carried forward. |
| 07 | Weight-as-length LF input | `07-ConvertToLength` | `06-NewStructure` | Replace the mixed size-composition input with the reweighted weight-as-length length-frequency (LF) dataset. | Fishery structure, catches, tags, and controls. | Carried forward. |
| 08 | Observed-length supplementation | `08-AddLengthData` | `07-ConvertToLength` | Use observed length compositions where their catch coverage exceeds that of weight samples; weight and length data are not used simultaneously within a fishery and time step. | Model structure and other observations. | Carried forward. |
| 09 | 1% tail compression | `09-TailCompression1Pct` | `08-AddLengthData` | After all compositions are on the length scale, change only parest flag 313 from `0` to `1`. | Flags 311/301 remain `1`, weight-frequency flag 303 remains `0`, and all other inputs and controls are unchanged. The normal-likelihood pathway retains this through Step 20b; Step 20c resets 313 to `0` because DM support is controlled by flag 320. | Carried forward on the normal-likelihood pathway. |
| 10 | Data through 2024 | `10-DataTo2024` | `09-TailCompression1Pct` | Extend observations through 2024 and map the unchanged reporting-rate specification to updated tag releases. | Biological, fishery-structure, and tail-compression settings. | Carried forward. |
| 11 | Regional CPUE | `11-RegionalCPUE` | `10-DataTo2024` | Add regional abundance indices and their regional-scaling likelihood. | Selectivity and other observation models. | Carried forward. |
| 12 | Time-varying CPUE uncertainty | `12-TimeVaryingCV` | `11-RegionalCPUE` | Apply normalized time-varying uncertainty to represent temporal changes in the relative precision of the regional CPUE indices. | CPUE observations, the incoming observation-error scales, model structure, selectivity, and all non-CPUE settings. | Carried forward. |
| 13 | CPUE observation-error calibration | `13-CPUEErrorCalibration` | `12-TimeVaryingCV` | Maximum-likelihood estimates were stable across the explored settings; set the executed R1-R5 scales to `0.35`, `0.24`, `0.21`, `0.24`, and `0.23`. | CPUE observations, time-varying uncertainty, and all non-observation-error settings. | Calibrated values carried forward. |
| 14 | New conditional age-at-length data | `14-NewAgeData` | `13-CPUEErrorCalibration` | Add the new 2026 CAAL data with the 0.75 weighting factor used in the 2023 BET assessment. | Biology, tags, CPUE treatment, and all non-age-data controls. | Carried forward. |
| 15a | Regional age weighting | `15a-REG075` | `14-NewAgeData` | Test regional weighting of the new age data. | The Step 14 data and all non-age-weighting settings. | Alternative comparison. |
| 15b | Sub-basin age weighting | `15b-SUB075` | `14-NewAgeData` | Apply sub-basin weighting to represent finer spatial variation in age-data information. | The Step 14 data and all non-age-weighting settings. | Selected and carried forward. |
| 16 | Revised fishery-specific selectivity | `16-SelectivityUpdate` | `15b-SUB075` | Revise selectivity sharing, terminal ages, and F25/F26 shape settings for the 33-fishery structure, and set flag 16 to `0` (form penalty off) for all 14 applicable fisheries, matching Job 14363. | Data, biology, CPUE, tags, reporting-rate mapping, and all non-selectivity controls. | Carried forward. |
| 17 | Release-group-specific tag mixing periods | `17-MIX015` | `16-SelectivityUpdate` | Apply the release-group-specific mixing period in tag-flag column 1 to limit early recapture bias. | Reporting rates remain active during mixing (`tag_flags(:,2)=0`); reporting-rate values, groups, targets, and penalties are unchanged. | Carried forward. |
| 18 | Tag reporting rates omitted in pre-mixing window | `18-TagReportingExclusion` | `17-MIX015` | Change tag-flag column 2 from `0` to `1`, so reporting rates are not applied to predicted recaptures within each release group's pre-mixing window. | Step 17 mixing periods and all numeric reporting-rate values, groups, targets, penalties, post-mixing treatment, and other settings. | Carried forward. |
| 19 | Effort creep | `19-EffortCreep` | `18-TagReportingExclusion` | Adjust positive index-fishery effort for gradual efficiency change. | Catch, composition, tag settings, biological, selectivity, and CPUE settings. | Carried forward. |
| 20a | Three domestic fisheries downweighted | `20a-DOMDiv200` | `19-EffortCreep` | As an independent comparison, divide the length compositions for the Indonesian, Philippine, and Vietnamese domestic fisheries (F21-F23) by 200. | Step 19 settings and all other composition weights. | Alternative comparison. |
| 20b | Francis reweighting | `20b-Francis` | `19-EffortCreep` | As an independent comparison, apply fishery-specific length-composition divisors calculated from standardized mean-length residuals using method TA1.8 of Francis (2011). | Step 19 settings and the standard composition likelihood; no Step 20a divisor is inherited. | Alternative comparison. |
| 20c | DM weighting | `20c-DMG8Nmax25` | `19-EffortCreep` | Estimate composition information internally using eight fishery groups and `Nmax=25`, the effective-sample-size upper asymptote. | Step 19 settings; no 20a domestic-fishery divisor or 20b Francis weight is inherited. | Selected final model. |
| 21a | Region 1 shared selectivity, K=0.15 | `21a-R1F2F3F29Shared-MIX015` | `20c-DMG8Nmax25` | Apply the exact Job 15984 selectivity map, including one four-node curve shared by F2, F3 and F29. | Fixed M, DM G8 `Nmax=25`, SC22-IP10 K=0.15 mixing periods, reporting rates, data and all non-selectivity controls. | Post-selection sensitivity. |
| 21b | Region 1 shared selectivity, K=0.05 | `21b-R1F2F3F29Shared-MIX005` | `21a-R1F2F3F29Shared-MIX015` | Change only the release-group mixing periods from SC22-IP10 K=0.15 to K=0.05. | Job 15984 selectivity map and every other model input and control. | Post-selection sensitivity. |
| 22 | Estimated tag-recapture dispersion | `22-TagTauSensitivity` | `21a-R1F2F3F29Shared-MIX015` | Estimate negative-binomial tag-recapture dispersion under ten nested recapture-fishery groupings and lower bounds of 2, 3 and 4. | Fixed M, DM G8 `Nmax=25`, SC22-IP10 K=0.15 mixing periods, reporting-rate priors and penalties, Job 15984 selectivity grouping, and all other controls. | Post-selection sensitivity. |

The SC22 BET purse-seine reporting-rate penalties enter with the 33-fishery
structure at `06-NewStructure`. They are carried through steps 07-09 and
remapped to the updated tag-release rows at `10-DataTo2024`. West and East
purse-seine fisheries remain separate reporting-rate groups throughout.

## Exact Selectivity Controls

All recent selectivity and node changes are introduced together in
`16-SelectivityUpdate`, immediately after selected Step `15b-SUB075`:

| Control | Setting |
| --- | --- |
| F15-F28 sharing | Unshare the fleet selectivity definitions so each fishery has its own coefficient-sharing group. |
| Fishery-specific form | Retain the audited terminal ages and youngest-age tails by fishery, with the older-age dome/form penalty switched off (`flag 16=0`) for all 14 applicable fisheries. |
| F25/F26 | Use independent groups with terminal age `25`, form-penalty flag `0`, seven spline nodes, and youngest-tail flag `0`. |
| F29-F33 | Separate the five regional-index selectivity groups in staged MFCL run 5. |

These controls are bundled as one scientific configuration. They are not included in
`11-RegionalCPUE`, and there is no earlier standalone spline-selectivity row.

Persistent structured length-frequency misfit remained for F25 and F26 under
the previous shared, limited-node selectivity structure. F25 and F26 are
spatially distinct associated purse-seine fisheries. They remain together in
the associated-purse-seine G8 DM overdispersion group, but receive independent
selectivities and seven-node cubic splines so different size availability can
be represented while each curve remains smooth.

F29-F33 are regional index fisheries. Their selectivities are separated so a
single selectivity constraint cannot mask regional size-availability
differences, while the fisheries retain their common index-oriented DM group.
The F15-F28 unsharing, fishery-specific terminal settings, form-penalties-off
flag-16 choice, F25/F26 seven-node/tail controls, and F29-F33 separation are one
assessment-specific bundle evaluated stepwise; they are not mandated by the
selectivity or DM literature.

Steps 20a and 20b are independent sibling comparisons from Step 19, not a
cumulative DOM-plus-Francis treatment. Step 20b applies its Francis divisors
directly; for F21-F23 the values are `114`, `398`, and `705`, while Step 20a
uses `200`, `200`, and `200`.

## Selected DM Grouping

The selected Dirichlet-multinomial (DM) configuration assigns all 33 fisheries
to eight assessment-specific groups. Each group shares a fitted baseline
concentration exponent and a relative-sample-size exponent, sharing information
among broadly similar fishery and data-role strata without requiring separate
terms for all 33 fisheries. Conceptually,
`lambda_i = exp(d_g) * r_i^c_g`, where `r_i` is the relative observed sample
size and `g` is the DM group.

| DM group | Fishery numbers | Fishery series | Grouping basis |
| ---: | --- | --- | --- |
| G1 | F1-F4, F6-F8, F10-F11 | LL.WEST.1; LL.EAST.1; LL.US.1; LL.ALL.2; LL.ARCH.3; LL.WEST.3; LL.EAST.3; LL.ALL.5; LL.AU.5 | Main longline composition process |
| G2 | F5, F9 | LL.OS.2; LL.OS.3 | Offshore longline series with a distinct sampling history |
| G3 | F12, F17-F18 | PS.JP.1; PS.ID.2; PS.PH.2 | Purse-seine series without associated/unassociated set-type separation |
| G4 | F19, F25-F26 | PS.ASS.2; PS.ASS.WEST.3; PS.ASS.EAST.3 | Associated purse-seine series |
| G5 | F20, F27-F28 | PS.UNA.2; PS.UNA.WEST.3; PS.UNA.EAST.3 | Unassociated purse-seine series |
| G6 | F14-F15 | HL.ID.2; HL.PH.2 | Handline series |
| G7 | F13, F16, F21-F24 | PL.JP.1; PL.ALL.2; DOM.ID.2; DOM.PH.2; DOM.VN.2; PL.ALL.WEST.3 | Other extraction fisheries pooled for stable estimation |
| G8 | F29-F33 | Index R1; Index R2; Index R3; Index R4; Index R5 | Regional indices sharing the relative-abundance reweighting procedure |

## Final DM Cap Rationale

The DM likelihood is useful because it estimates composition overdispersion
within the model rather than treating the nominal sample size as the effective
amount of information. The fitted overdispersion therefore determines the
effective sample size (ESS) assigned to the length-frequency data. In the
MFCL no-random-effects DM implementation,
`N_eff = Nmax(1 + lambda)/(Nmax + lambda)`, so `Nmax` is the asymptotic upper
bound approached as the fitted concentration `lambda` increases. It is not the
mean ESS or a fixed weight assigned to every composition. Parest flag 342 sets
this maximum; zero uses the MFCL default of 1,000.

Preliminary BET fits showed a clear trade-off: increasing `Nmax` allowed the
length-frequency component to exert more influence and improve its fit, but it
also reduced the fit to CPUE indices. `Nmax` was therefore treated as an upper
bound on composition information, not as a target effective sample size.

| Consideration | Evidence from preliminary fits | Stepwise decision |
| --- | --- | --- |
| Composition weighting | DM estimated overdispersion and effective composition information internally, avoiding direct use of large nominal sample sizes. | Retain DM as the selected composition likelihood. |
| Integrated-model balance | Larger `Nmax` values increased the influence of length-frequency data and degraded CPUE fit. | Use a finite upper asymptote for DM effective composition information rather than allowing the LF component to dominate the joint objective function. |
| Empirical scale | Across 2,399 positive LF compositions in matched robust-normal fits, the 95th percentile of composition-level Francis ESS ranged from 22.22 to 23.81. | Set `Nmax=25`, just above the Francis ESS upper-tail range. |
| Interpretation | The cap limits the result of the internal DM information estimate; it does not define a Francis model. | State explicitly that MFCL estimates the DM parameter internally and approaches `Nmax=25` smoothly. |

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
| 01-03 | Re-running an earlier model provides a reproducibility anchor, and separating software from input-format changes isolates implementation effects. | Use the archived 2023 diagnostic, compare executables with exact Step 01 scientific controls, then change only the ini layout to 1007 in Step 03. |
| 04 | Lorenzen natural mortality scales with length as `M_a = c l_a^b`. | Fix the log-scale coefficient `c` from the `mgc=-5` BET diagnostic result while retaining `b=-1`, before the length-weight update. |
| 05 | Length-weight coefficients convert modeled length to biomass. | Apply the BET 2026 bias-corrected length-weight coefficients after fixed M is established. |
| 06 | Spatial and fleet stratification represents heterogeneous population and fishery processes. External tag-seeding analyses can inform reporting-rate penalties. | Use five regions and 33 fisheries, with the BET means and penalties reported by Peatman et al. (2026, SC22-SA-IP05). |
| 07-08 | Composition-unit conversion and the choice between alternative size observations can be evaluated sequentially. | First convert weight-frequency compositions to length-frequency, then use observed lengths where they provide superior catch coverage before activating tail aggregation. |
| 09 | Tail aggregation can reduce sparse-bin influence after observations share a common scale. | Change only LF parest flag 313 from `0` to `1`; keep flags 311/301 at `1` and WF flag 303 at `0`. Retain it through Step 20b, then reset it for the DM branch. |
| 10 | Extending the terminal year is a standard assessment-build operation. | Extend through 2024 and remap the carried reporting-rate specification to the updated tag releases. |
| 11 | Relative-abundance indices enter through an observation likelihood, and likelihood components can be assigned relative weights. | Use the authoritative regional CPUE source as supplied, including two fewer F32 1952 quarterly records, and apply `REGW100`; no selectivity choice is made in this row. |
| 12 | Time-varying observation CVs allow the relative precision of an index to vary through time. | Apply the BET 2026 time-varying CPUE uncertainty schedule without simultaneously changing the observation-error scale. |
| 13 | Index-specific observation-error scales control relative CPUE influence. | Fix common production values from stable maximum-likelihood estimates so later comparisons retain consistent CPUE weighting. |
| 14 | Adding new conditional age-at-length observations extends the evidence available for growth estimation. | Apply the 2023 BET assessment weighting factor of 0.75 to the new CAAL data before comparing spatial weighting treatments. |
| 15 | Age-data weighting controls the relative influence of age compositions. | Compare regional and sub-basin treatments against the Step 14 reference and carry `SUB075` forward. |
| 16 | Fishery-specific selectivity avoids forcing unlike fisheries to share one curve. Once curves are specified for the revised fishery structure, additional form penalties can impose unnecessary older-age shape constraints. | Revise selectivity sharing, terminal ages, and F25/F26 shape settings, and use the Job 14363 setting with flag-16 form penalties off for all 14 applicable fisheries. |
| 17 | Tag-mixing assumptions control when individual release groups contribute to the tag likelihood. | Apply the release-group-specific `MIX015` periods while retaining reporting rates during mixing. |
| 18 | Reporting rates can be poorly determined or assumed during the pre-mixing reconstruction. | Change only tag-flag column 2 from `0` to `1`, as recommended in the MULTIFAN-CL manual; reporting rates continue to apply after the mixing period. |
| 19 | Effort-creep corrections account for changing fishing efficiency. | Apply 1%/year for 1952-1976 and 0.5%/year for 1977-2024 to index fisheries F29-F33. |
| 20 | Francis reweighting adjusts fishery-specific composition weights while retaining the normal likelihood; the Dirichlet-multinomial instead models overdispersion internally. | Compare three independent Step 19 children: 20a downweighting of three domestic fisheries, 20b Francis reweighting, and selected 20c Dirichlet-multinomial weighting with G8 PSSET and `Nmax=25`. |

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
effort-creep schedule, DOM divisor, observation-error calibration, G8 grouping,
or Nmax.

## CPUE Observation-Error Calibration

Index-specific CPUE observation-error scales were estimated by maximum
likelihood in a
range of preliminary model configurations. The estimates were similar across
those fits, indicating that the observation-error scale was not sensitive to
the preliminary structural choices. Step 12 applies time-varying CPUE
uncertainty; Step 13 then updates the observation-error scales to the calibrated
production values selected from the preliminary fits. The calibrated values
are retained in every later step, avoiding confounding selectivity or
composition-likelihood changes with simultaneous reweighting of the abundance
indices.

| CPUE observation-error setting | R1 | R2 | R3 | R4 | R5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Preliminary maximum-likelihood estimate | 0.354 | 0.237 | 0.212 | 0.239 | 0.225 |
| Applied fish flag 92 | 35 | 24 | 21 | 24 | 23 |

The archived fitted input is the controlling implementation record for these common
production values.

## DOM Naming

`DOM` is the assessment's short scenario name for the F21-F23 treatment. It is
not the name of a general statistical method. The divisor `200` is a BET 2026
assessment-specific choice and is not implied by the name or prescribed by the
literature.

## Final Model Provenance

`20c-DMG8Nmax25` is the terminal selected model. Its revised fishery-specific,
form-penalties-off selectivity choice and downstream G8/Nmax25 DM configuration reproduce the setting fitted
as Job `14363`. Step 20c explicitly resets Step 09 flag `313` to `0` because
MFCL's DM branch does not use that percentage threshold; flag `320=5` controls
DM support. The resulting numeric controls match the Job 14363 input, while
the inline comment makes the otherwise inactive 313 setting unambiguous.
The job number is a provenance reference only; this repository does not
submit, fetch, or merge jobs as part of `job-config.R`.

## Resources And Outputs

| Rows | Regions | CPUs | Memory | Disk | Run mode | Expected output |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| 01-05 | 9 | 2 | 12 GB | 8 GB | native MFCL `doitall` | auto-detected final `.par` plus `model_payload.rds` |
| 06-21 | 5 | 2 | 8 GB | 8 GB | native MFCL `doitall` | auto-detected final `.par` plus `model_payload.rds` |

Step 01 alone pins the historical diagnostic executable. All other rows use
the current container MFCL executable. `BET_PHASE10_11_CONVERGENCE` remains a
run-time convergence control and can be overridden without changing model
inputs.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `job-config.R` | Public 25-row development matrix and cumulative-state metadata. |
| `steps/<STEP_SELECT>/README.md` | Model-specific scientific and input notes. |
| `steps/<STEP_SELECT>/input_manifest.csv` | Source-input provenance. |
| `steps/<STEP_SELECT>/model/` | Self-contained MFCL run folder. |
| `docs/run-configuration.md` | Kflow and local-run behavior. |
| `R/prepare_bet_2026_step_inputs.R` | Reproducible model-input preparation. |
