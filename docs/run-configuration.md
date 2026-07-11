# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `13c-LBS-N4` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-lbs-sens` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.2` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |
| `stepwise_save_final_par` | `false` | Optional: copy the final `.par` back into `steps/<step_id>/model/`. Off by default; Kflow outputs always include `outputs/models/<step_id>/final.par`. |
| `stepwise_save_raw_mfcl_inputs` | `true` | Preserve the full raw MFCL input folder under `outputs/models/<step_id>/mfcl-inputs/` for native-style auditability. |
| `stepwise_commit_final_pars` | `false` | Optional: create a narrow KflowBot commit containing saved final `.par` files. Off by default to avoid concurrent job push conflicts. |
| `stepwise_push_final_pars` | `false` | Optional: push the saved final `.par` commit to the current branch. Off by default. |
| `par_source_job` | `blank` | Optional previous Kflow job number/reference used with `RUN_MODE=job_par`. |
| `stepwise_par_source_dir` | `blank` | Optional local folder to search for previous output `.par` files when testing `RUN_MODE=job_par` outside Kflow. |
| `kflow_input_jobs` | `blank` | Optional Kflow input job number(s) to attach. For `.par` reruns, set this to the same previous same-step job as `PAR_SOURCE_JOB`. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `major_step` | `substep` | `change_axis` | `model_label` | `job_title` | `job_key` | `run_mode` | `mfcl_program_path` | `input_par` | `frq` | `output_par` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `01-Diag2023` | `TRUE` | 01-Diagnostic | 01a | historical diagnostic | Diag2023 | 01 Diag2023 | `01-diag2023` | `doitall` | /home/mfcl/mfclo64_2023_diagnostic_2.2.2.0 | `blank` | `bet.frq` | `blank` |
| `02a-NewExe` | `TRUE` | 02-Executable | 02a | current MFCL executable with 1003 ini | NewExe 1003 | 02a NewExe 1003 | `02a-newexe` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `02b-Ini1007` | `TRUE` | 02-Executable | 02b | promote diagnostic ini to 1007 | Ini 1007 | 02b Ini 1007 | `02b-ini1007` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `02c-LengthWeight` | `TRUE` | 02-Executable | 02c | bias-corrected 2026 length-weight parameters | Length-weight | 02c Length-weight | `02c-lengthweight` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `03-FixM` | `TRUE` | 03-FixM | 03a | fixed natural mortality from mgc=-5 diagnostic after 02c | FixM | 03 FixM | `03-fixm` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `04-NewStructure` | `TRUE` | 04-NewStructure | 04 | 5-region structure with global CPUE | New structure | 04 New structure | `04-newstructure` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `05-ConvertToLength` | `TRUE` | 05-ConvertToLength | 05a | convert weight compositions to length | Convert to length | 05 Convert to length | `05-converttolength` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `06-LengthPlusLength` | `TRUE` | 06-LengthPlusLength | 06a | add additional length compositions | Length plus length | 06 Length plus length | `06-lengthpluslength` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `07-DataTo2024` | `TRUE` | 07-DataTo2024 | 07a | 2024 data with global CPUE | Data to 2024 | 07 Data to 2024 | `07-datato2024` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `08-RegionalCPUE` | `TRUE` | 08-RegionalCPUE | 08a | regional CPUE and regional-scaling prior | Regional CPUE | 08 Regional CPUE | `08-regionalcpue` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `09-NewOtoliths` | `TRUE` | 09-NewOtoliths | 09a | new otolith/CAAL input | New otoliths | 09 New otoliths | `09-newotoliths` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `10-TagMixingKS` | `TRUE` | 10-TagMixing | 10a | release-specific tag mixing periods | Tag mixing KS | 10 Tag mixing KS | `10-tagmixingks` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11-TimeVaryingCV` | `TRUE` | 11-TimeVaryingCV | 11a | time-varying CPUE CV | Time-varying CV | 11 Time-varying CV | `11-timevaryingcv` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12-OrthogonalPoly` | `TRUE` | 12-OrthogonalPoly | 12a | orthogonal-polynomial recruitment | Orthogonal polynomial | 12 Orthogonal polynomial | `12-orthogonalpoly` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13-LengthBasedSel` | `TRUE` | 13-LengthBasedSel | 13a | length-based selectivity | Length-based selectivity | 13 Length-based selectivity | `13-lengthbasedsel` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `14-EffortCreep` | `TRUE` | 14-EffortCreep | 14a | effort creep | Effort creep | 14 Effort creep | `14-effortcreep` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `15-DataWeighting` | `TRUE` | 15-DataWeighting | 15a | data weighting | Data weighting | 15 Data weighting | `15-dataweighting` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13b-LBS-N3` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13b | length-based selectivity with 3 cubic-spline nodes | LBS N3 | 13b LBS N3 | `13b-lbs-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13c-LBS-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13c | length-based selectivity with 4 cubic-spline nodes | LBS N4 | 13c LBS N4 | `13c-lbs-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13d-LBS-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13d | length-based selectivity with 6 cubic-spline nodes | LBS N6 | 13d LBS N6 | `13d-lbs-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13e-LBS-IDXmono-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13e | baseline 5-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N5 | 13e LBS IDXmono N5 | `13e-lbs-idxmono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13f-LBS-IDXmono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13f | 4-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N4 | 13f LBS IDXmono N4 | `13f-lbs-idxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13g-LBS-IDXmono-N3` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13g | 3-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N3 | 13g LBS IDXmono N3 | `13g-lbs-idxmono-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13h-LBS-LLmono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13h | 4-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N4 | 13h LBS LLmono N4 | `13h-lbs-llmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13i-LBS-LLIDXmono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13i | 4-node length-based selectivity with non-decreasing longline and index selectivity | LBS LL+IDXmono N4 | 13i LBS LL+IDXmono N4 | `13i-lbs-llidxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13j-LBS-LLIDXmono-N3` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13j | 3-node length-based selectivity with non-decreasing longline and index selectivity | LBS LL+IDXmono N3 | 13j LBS LL+IDXmono N3 | `13j-lbs-llidxmono-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13k-LBS-LLIDXmono-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13k | baseline 5-node length-based selectivity with non-decreasing longline and index selectivity | LBS LL+IDXmono N5 | 13k LBS LL+IDXmono N5 | `13k-lbs-llidxmono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13l-LBS-LLIDXsoft-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13l | 4-node non-decreasing longline/index selectivity with a softer monotone penalty | LBS LL+IDX soft mono N4 | 13l LBS LL+IDX soft mono N4 | `13l-lbs-llidxsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13m-LBS-LLIDXvsoft-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13m | 4-node non-decreasing longline/index selectivity with a very soft monotone penalty | LBS LL+IDX very soft mono N4 | 13m LBS LL+IDX very soft mono N4 | `13m-lbs-llidxvsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13n-LBS-NoDome-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13n | 4-node length-based selectivity with Step 13 dome/terminal-zero constraints removed | LBS no dome N4 | 13n LBS no dome N4 | `13n-lbs-nodome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13o-LBS-RelaxLowDome-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13o | 4-node length-based selectivity with low terminal-zero cutoffs relaxed | LBS relax low dome N4 | 13o LBS relax low dome N4 | `13o-lbs-relax-low-dome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13p-LBS-RelaxDOMPL-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13p | 4-node length-based selectivity with DOM/PL terminal-zero cutoffs relaxed | LBS relax DOM/PL N4 | 13p LBS relax DOM/PL N4 | `13p-lbs-relax-dompl-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13q-LBS-RelaxPS-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13q | 4-node length-based selectivity with PS and JP terminal-zero cutoffs relaxed | LBS relax PS N4 | 13q LBS relax PS N4 | `13q-lbs-relax-ps-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13r-LBS-DomeMid-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13r | 4-node length-based selectivity with a common mid terminal-zero cutoff | LBS dome mid N4 | 13r LBS dome mid N4 | `13r-lbs-dome-mid-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13s-LBS-NoLowDome-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13s | 4-node length-based selectivity with low dome constraints removed and index monotone | LBS no low dome + IDX N4 | 13s LBS no low dome + IDX N4 | `13s-lbs-no-low-dome-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13t-LBS-YoungZero-PSPLDOM-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13t | 4-node length-based selectivity with age-1 zero selectivity for PS/PL/DOM gears | LBS young-zero PS/PL/DOM N4 | 13t LBS young-zero PS/PL/DOM N4 | `13t-lbs-youngzero-pspldom-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13u-LBS-IDXyoungzero-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13u | 4-node length-based selectivity with monotone index selectivity and young-index zero selectivity | LBS IDX young-zero N4 | 13u LBS IDX young-zero N4 | `13u-lbs-idx-youngzero-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13v-LBS-HL75-3-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13v | 4-node length-based selectivity with HL young-zero age count relaxed | LBS HL75 3 N4 | 13v LBS HL75 3 N4 | `13v-lbs-hl75-3-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13w-LBS-LL75-1-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13w | 4-node length-based selectivity with LL young-zero age count relaxed | LBS LL75 1 N4 | 13w LBS LL75 1 N4 | `13w-lbs-ll75-1-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13x-LBS-Bound359-1000-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13x | 4-node length-based selectivity with spline lower-bound penalty 359 = 1000 | LBS bound359 1000 N4 | 13x LBS bound359 1000 N4 | `13x-lbs-bound359-1000-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13y-LBS-Bound359-10000-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13y | 4-node length-based selectivity with spline lower-bound penalty 359 = 10000 | LBS bound359 10000 N4 | 13y LBS bound359 10000 N4 | `13y-lbs-bound359-10000-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag2023` | `steps/01-Diag2023/model` | `exists` |
| `02a-NewExe` | `steps/02a-NewExe/model` | `exists` |
| `02b-Ini1007` | `steps/02b-Ini1007/model` | `exists` |
| `02c-LengthWeight` | `steps/02c-LengthWeight/model` | `exists` |
| `03-FixM` | `steps/03-FixM/model` | `exists` |
| `04-NewStructure` | `steps/04-NewStructure/model` | `exists` |
| `05-ConvertToLength` | `steps/05-ConvertToLength/model` | `exists` |
| `06-LengthPlusLength` | `steps/06-LengthPlusLength/model` | `exists` |
| `07-DataTo2024` | `steps/07-DataTo2024/model` | `exists` |
| `08-RegionalCPUE` | `steps/08-RegionalCPUE/model` | `exists` |
| `09-NewOtoliths` | `steps/09-NewOtoliths/model` | `exists` |
| `10-TagMixingKS` | `steps/10-TagMixingKS/model` | `exists` |
| `11-TimeVaryingCV` | `steps/11-TimeVaryingCV/model` | `exists` |
| `12-OrthogonalPoly` | `steps/12-OrthogonalPoly/model` | `exists` |
| `13-LengthBasedSel` | `steps/13-LengthBasedSel/model` | `exists` |
| `14-EffortCreep` | `steps/14-EffortCreep/model` | `exists` |
| `15-DataWeighting` | `steps/15-DataWeighting/model` | `exists` |
| `13b-LBS-N3` | `steps/13-LengthBasedSel/model` | `exists` |
| `13c-LBS-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13d-LBS-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13e-LBS-IDXmono-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13f-LBS-IDXmono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13g-LBS-IDXmono-N3` | `steps/13-LengthBasedSel/model` | `exists` |
| `13h-LBS-LLmono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13i-LBS-LLIDXmono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13j-LBS-LLIDXmono-N3` | `steps/13-LengthBasedSel/model` | `exists` |
| `13k-LBS-LLIDXmono-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13l-LBS-LLIDXsoft-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13m-LBS-LLIDXvsoft-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13n-LBS-NoDome-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13o-LBS-RelaxLowDome-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13p-LBS-RelaxDOMPL-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13q-LBS-RelaxPS-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13r-LBS-DomeMid-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13s-LBS-NoLowDome-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13t-LBS-YoungZero-PSPLDOM-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13u-LBS-IDXyoungzero-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13v-LBS-HL75-3-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13w-LBS-LL75-1-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13x-LBS-Bound359-1000-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13y-LBS-Bound359-10000-N4` | `steps/13-LengthBasedSel/model` | `exists` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `15-DataWeighting` | Run one model folder. |
| `STEP_SELECT` | `08-RegionalCPUE,09-NewOtoliths` | Run selected model folders. |
| `STEP_SELECT` | `all` | Run every enabled row. |
| `MFCL_LIVE_LOG` | `true` | Stream MFCL output into the Kflow log. |
| `RUN_MODE` | `job_par` | Rerun from a previous Kflow job output `.par`. Use this with `PAR_SOURCE_JOB` and `KFLOW_INPUT_JOBS`. |
| `PAR_SOURCE_JOB` | `354` | Previous same-step job number to search for `outputs/models/<step_id>/final.par`. |
| `KFLOW_INPUT_JOBS` | `354` | Previous job number to attach as an input archive for the rerun. Usually the same value as `PAR_SOURCE_JOB`. |
| `INPUT_PAR` | `123.par` | Continue from one specific `.par` already in the selected model folder; if it is missing, the runner logs that and falls back to `doitall`. |
| `STEPWISE_COMMIT_FINAL_PARS` | `false` | Optional legacy path to commit final `.par` files back to this repo. Keep off for parallel Kflow runs. |
| `STEPWISE_PUSH_FINAL_PARS` | `false` | Optional legacy path to push the `.par` commit to GitHub. Keep off for parallel Kflow runs. |
| `TRIGGER_NEXT` | `false` | Stop after stepwise; do not launch results/report. |
| `FLOW_GROUP` | `bet-2026-base` | Shared label for the chain. |

## Outputs

Saved artifacts include compact plot payloads plus the raw MFCL input folder
used for the run:

```text
outputs/model-index.csv
outputs/selected-steps.csv
outputs/saved-pars.csv
outputs/region-map/<project-map>.geojson
outputs/models/<step_id>/model_payload.rds
outputs/models/<step_id>/model_payload_manifest.json
outputs/models/<step_id>/final.par
outputs/models/<step_id>/mfcl-inputs/
outputs/models/<step_id>/bet.region_map.geojson
```

Final `.par` files are archived in the Kflow output as
`outputs/models/<step_id>/final.par`. For a later rerun, set `RUN_MODE=job_par`,
set `PAR_SOURCE_JOB` to the previous same-step job number, and attach that same
job with `KFLOW_INPUT_JOBS`.

The raw MFCL inputs are preserved under
`outputs/models/<step_id>/mfcl-inputs/` so files such as `.frq`, `.tag`,
`.age_length`, and `.reg_scaling` can be audited exactly as read by native MFCL.

Region-map assets are copied from `assets/maps/`. The root `outputs/region-map/`
folder stores shared project-specific GeoJSON files, and each model output also
gets `bet.region_map.geojson` beside its payload.
