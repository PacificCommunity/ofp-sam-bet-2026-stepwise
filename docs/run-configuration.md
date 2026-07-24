# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-stepwise-2307-corrected` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `false` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360` | Docker image used by Kflow and local Docker runs. |
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
| `01-Diag2023` | `TRUE` | 01-Diagnostic | 01 | rerun the 2023 diagnostic anchor | Diagnostic rerun | 01 2023 diagnostic rerun | `01-diag2023` | `doitall` | /home/mfcl/mfclo64_2023_diagnostic_2.2.2.0 | `blank` | `bet.frq` | `blank` |
| `02a-NewExe1003` | `TRUE` | 02-Executable | 02a | run the current MFCL executable against the exact Step 01 scientific controls and 1003 ini | Updated executable | 02a Current executable with ini 1003 | `02a-newexe1003` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `02b-Ini1007` | `TRUE` | 02-Executable | 02b | convert the ini layout from 1003 to 1007 | Updated INI format | 02b MFCL ini format 1007 | `02b-ini1007` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `02c-LengthWeight` | `TRUE` | 02-Executable | 02c | apply BET 2026 bias-corrected length-weight parameters | Length-weight update | 02c Updated length-weight relationship | `02c-lengthweight` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `03-FixM` | `TRUE` | 03-FixM | 03 | fix natural mortality at -2.54930339768360 on the M scale | Fixed natural mortality | 03 Fixed natural mortality | `03-fixm` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `04-NewStructure` | `TRUE` | 04-NewStructure | 04 | adopt the five-region and 33-fishery structure | Five-region structure | 04 Five-region assessment structure | `04-newstructure` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `05-ConvertToLength` | `TRUE` | 05-ConvertToLength | 05 | convert the existing weight compositions to length | Length conversion | 05 Convert weight to length compositions | `05-converttolength` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `06-AddLengthData` | `TRUE` | 06-AddLengthData | 06 | add the additional length-composition data | Additional length data | 06 Add length-composition data | `06-addlengthdata` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `07-DataTo2024` | `TRUE` | 07-DataTo2024 | 07 | extend data through 2024 and integrate the latest RRPTTP26 reporting-rate penalties | Data through 2024 | 07 Data through 2024 and updated tag reporting rates | `07-datato2024-rrpttp26` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `08-RegionalCPUE` | `TRUE` | 08-RegionalCPUE | 08 | add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty | Regional CPUE | 08 Regional CPUE likelihood and weighting | `08-regional-cpue-regw100` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `09a-BASE075` | `TRUE` | 09-CompositionWeighting | 09a | apply the BASE075 composition-weighting alternative | Common age weighting | 09a Baseline age-length weighting | `09a-base075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `09b-REG075` | `TRUE` | 09-CompositionWeighting | 09b | apply the REG075 composition-weighting alternative | Regional age weighting | 09b Regional age-length weighting | `09b-reg075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `09c-SUB075` | `TRUE` | 09-CompositionWeighting | 09c | apply the selected SUB075 composition weighting | Sub-basin age weighting | 09c Sub-basin age-length weighting | `09c-sub075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `10-MIX015` | `TRUE` | 10-TagMixing | 10 | apply the MIX015 tag-mixing setting | Tag mixing | 10 Tag-mixing periods | `10-mix015` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `11-TAGF2ON` | `TRUE` | 11-TagFlags | 11 | set tag-flag column 2 to 1 so reporting-rate effects are excluded for each release group throughout its configured mixing periods | Tag reporting rates | 11 Reporting-rate mixing-period treatment | `11-tagf2on-col2` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `12-TimeVaryingCV` | `TRUE` | 12-TimeVaryingCV | 12 | apply normalized time-varying CPUE relative-variance multipliers from the frequency data | Time-varying CV | 12 Time-varying CPUE uncertainty | `12-timevaryingcv` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `13-EffortCreep` | `TRUE` | 13-EffortCreep | 13 | apply the BET 2026 effort-creep series | Effort creep | 13 Effort-creep adjustment | `13-effortcreep` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `14-CPUESigma` | `TRUE` | 14-CPUESigma | 14 | fix index-specific CPUE observation-error scales calibrated from preliminary MLE fits | CPUE sigma | 14 Fixed CPUE observation-error calibration | `14-fixed-cpue-observation-error` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `15-SelectivityUpdate` | `TRUE` | 15-SelectivityUpdate | 15 | apply the intended broad selectivity bundle across F15-F33 | Selectivity update | 15 Fleet-specific selectivity update | `15-selectivity-update` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `16a-DOMDiv200` | `TRUE` | 16-CompositionWeighting | 16a | apply the assessment-specific DOM divisor 200 to F21-F23 | DOM downweighting | 16a F21-F23 length-composition downweighting | `16a-dom-f21-f23-div200` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `16b-Francis` | `TRUE` | 16-CompositionWeighting | 16b | inherit 16a and replace all LF divisors with the Francis composition-data weighting comparison | Francis weighting | 16b Francis length-composition weighting | `16b-francis` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `16c-DMG8Nmax25` | `TRUE` | 16-CompositionWeighting | 16c | branch directly from Step 15 and use a Dirichlet-multinomial likelihood with G8 grouping and Nmax 25 | Dirichlet-multinomial | 16c DM length-composition weighting | `16c-dm-length-composition-weighting` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `17a-F15FormRelaxed` | `TRUE` | 17-SelectivityFormSensitivity | 17a | remove the F15 HL.PH.2 dome/old-age-tail selectivity-form penalty | F15 form relaxed | BET 2026 selectivity-form sensitivity \| F15 | `17a-f15-selectivity-form-relaxed` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `17b-F22FormRelaxed` | `TRUE` | 17-SelectivityFormSensitivity | 17b | remove the F22 DOM.PH.2 dome/old-age-tail selectivity-form penalty | F22 form relaxed | BET 2026 selectivity-form sensitivity \| F22 | `17b-f22-selectivity-form-relaxed` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `17c-F15F22FormRelaxed` | `TRUE` | 17-SelectivityFormSensitivity | 17c | remove the F15 HL.PH.2 and F22 DOM.PH.2 dome/old-age-tail selectivity-form penalties | F15/F22 forms relaxed | BET 2026 selectivity-form sensitivity \| F15 + F22 | `17c-f15-f22-selectivity-form-relaxed` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `17d-AllSelectivityFormRelaxed` | `TRUE` | 17-SelectivityFormSensitivity | 17d | remove every active fishery-specific dome/old-age-tail selectivity-form penalty | All forms relaxed | BET 2026 selectivity-form boundary sensitivity \| all fisheries | `17d-all-selectivity-form-relaxed` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `18-GroupedSelectivityRobustness` | `TRUE` | 18-SelectivityRobustness | 18 | share regional-index selectivity with matched extraction fisheries and reduce selected spline dimensions | Grouped selectivity robustness | BET 2026 selectivity robustness sensitivity \| grouped regional index selectivity | `18-grouped-selectivity-robustness` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `19a-R1F2F3F29SharedSelectivity` | `TRUE` | 19-SelectivityRobustness | 19a | share one four-node Region 1 selectivity among F2, F3 and F29 while retaining independent index catchability | R1 F2/F3/F29 selectivity shared | BET 2026 selectivity robustness sensitivity \| R1 F2/F3/F29 shared | `19a-r1-f2-f3-f29-selectivity-shared` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `19-GroupedSelectivityEstimatedM` | `TRUE` | 19-NaturalMortalitySensitivity | 19 | estimate the Lorenzen natural-mortality intercept from Phase 10 | Grouped selectivity + estimated M | BET 2026 grouped-selectivity sensitivity \| estimated Lorenzen M from -2.5 | `19-grouped-selectivity-estimated-m` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag2023` | `steps/01-Diag2023/model` | `exists` |
| `02a-NewExe1003` | `steps/02a-NewExe1003/model` | `exists` |
| `02b-Ini1007` | `steps/02b-Ini1007/model` | `exists` |
| `02c-LengthWeight` | `steps/02c-LengthWeight/model` | `exists` |
| `03-FixM` | `steps/03-FixM/model` | `exists` |
| `04-NewStructure` | `steps/04-NewStructure/model` | `exists` |
| `05-ConvertToLength` | `steps/05-ConvertToLength/model` | `exists` |
| `06-AddLengthData` | `steps/06-AddLengthData/model` | `exists` |
| `07-DataTo2024` | `steps/07-DataTo2024/model` | `exists` |
| `08-RegionalCPUE` | `steps/08-RegionalCPUE/model` | `exists` |
| `09a-BASE075` | `steps/09a-BASE075/model` | `exists` |
| `09b-REG075` | `steps/09b-REG075/model` | `exists` |
| `09c-SUB075` | `steps/09c-SUB075/model` | `exists` |
| `10-MIX015` | `steps/10-MIX015/model` | `exists` |
| `11-TAGF2ON` | `steps/11-TAGF2ON/model` | `exists` |
| `12-TimeVaryingCV` | `steps/12-TimeVaryingCV/model` | `exists` |
| `13-EffortCreep` | `steps/13-EffortCreep/model` | `exists` |
| `14-CPUESigma` | `steps/14-CPUESigma/model` | `exists` |
| `15-SelectivityUpdate` | `steps/15-SelectivityUpdate/model` | `exists` |
| `16a-DOMDiv200` | `steps/16a-DOMDiv200/model` | `exists` |
| `16b-Francis` | `steps/16b-Francis/model` | `exists` |
| `16c-DMG8Nmax25` | `steps/16c-DMG8Nmax25/model` | `exists` |
| `17a-F15FormRelaxed` | `steps/17a-F15FormRelaxed/model` | `exists` |
| `17b-F22FormRelaxed` | `steps/17b-F22FormRelaxed/model` | `exists` |
| `17c-F15F22FormRelaxed` | `steps/17c-F15F22FormRelaxed/model` | `exists` |
| `17d-AllSelectivityFormRelaxed` | `steps/17d-AllSelectivityFormRelaxed/model` | `exists` |
| `18-GroupedSelectivityRobustness` | `steps/18-GroupedSelectivityRobustness/model` | `exists` |
| `19a-R1F2F3F29SharedSelectivity` | `steps/19a-R1F2F3F29SharedSelectivity/model` | `exists` |
| `19-GroupedSelectivityEstimatedM` | `steps/19-GroupedSelectivityEstimatedM/model` | `exists` |


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
