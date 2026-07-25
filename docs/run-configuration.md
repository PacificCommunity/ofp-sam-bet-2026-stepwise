# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-stepwise-pathway` | Kflow group label used to connect stepwise, results, and report jobs. |
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
| `01-Diag2023` | `TRUE` | 01-Diagnostic | 01 | rerun the 2023 diagnostic anchor | 2023 diagnostic rerun | 01 2023 diagnostic rerun | `01-diag2023` | `doitall` | /home/mfcl/mfclo64_2023_diagnostic_2.2.2.0 | `blank` | `bet.frq` | `blank` |
| `02-NewExe1003` | `TRUE` | 02-Compatibility | 02 | run the current MFCL executable against the exact Step 01 scientific controls and 1003 ini | Updated executable | 02 Current executable with ini 1003 | `02-newexe1003` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `03-Ini1007` | `TRUE` | 03-Compatibility | 03 | convert the ini layout from 1003 to 1007 | Updated INI format | 03 MFCL ini format 1007 | `03-ini1007` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `04-FixM` | `TRUE` | 04-FixM | 04 | fix Lorenzen natural-mortality scaling to the 2023 diagnostic-model estimate | Diagnostic natural-mortality estimate fixed | 04 Fix natural mortality to diagnostic estimate | `04-fixm` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `05-LengthWeight` | `TRUE` | 05-LengthWeight | 05 | update the BET 2026 bias-corrected length-weight parameters | Length-weight update | 05 Updated length-weight relationship | `05-lengthweight` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `06-NewStructure` | `TRUE` | 06-NewStructure | 06 | adopt the five-region and 33-fishery structure | Five-region structure | 06 Five-region assessment structure | `06-newstructure` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `07-ConvertToLength` | `TRUE` | 07-ConvertToLength | 07 | replace the mixed size-composition input with the reweighted weight-as-length length-frequency dataset | Weight-as-length LF input | 07 Reweighted weight-as-length LF input | `07-converttolength` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `08-AddLengthData` | `TRUE` | 08-AddLengthData | 08 | use observed length compositions where their catch coverage exceeds that of weight samples | Observed-length supplementation | 08 Weight-as-length plus observed-length compositions | `08-addlengthdata` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `09-TailCompression1Pct` | `TRUE` | 09-TailCompression | 09 | activate 1% length-frequency tail aggregation by changing parest flag 313 from 0 to 1 | 1% tail compression | 09 Activate 1% LF tail compression | `09-tail-compression-1pct` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `10-DataTo2024` | `TRUE` | 10-DataTo2024 | 10 | extend data through 2024 and remap the carried RRPTTP26 reporting-rate specification to the updated tag releases | Data through 2024 | 10 Data through 2024 and updated tag reporting rates | `10-datato2024-rrpttp26` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `11-RegionalCPUE` | `TRUE` | 11-RegionalCPUE | 11 | add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty | Regional CPUE | 11 Regional CPUE likelihood and weighting | `11-regional-cpue-regw100` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `12-TimeVaryingCV` | `TRUE` | 12-TimeVaryingCV | 12 | apply normalized time-varying CPUE relative-variance multipliers | Time-varying CPUE uncertainty | 12 Time-varying CPUE uncertainty | `12-timevarying-cpue-uncertainty` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `13-CPUEErrorCalibration` | `TRUE` | 13-CPUEErrorCalibration | 13 | set the five regional CPUE observation-error scales to maximum-likelihood estimates | CPUE observation-error calibration | 13 CPUE observation-error calibration | `13-cpue-observation-error-calibration` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `14-NewAgeData` | `TRUE` | 14-AgeData | 14 | add the new conditional age-at-length data with a weighting factor of 0.75 from the 2023 BET assessment | New conditional age-at-length data | 14 New conditional age-at-length data (weight 0.75) | `14-new-age-data-base075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `15a-REG075` | `TRUE` | 15-AgeLengthWeighting | 15a | apply the REG075 composition-weighting alternative | Regional age weighting | 15a Regional age-length weighting | `15a-reg075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `15b-SUB075` | `TRUE` | 15-AgeLengthWeighting | 15b | apply the selected SUB075 composition weighting | Sub-basin age weighting | 15b Sub-basin age-length weighting | `15b-sub075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `16-SelectivityUpdate` | `TRUE` | 16-SelectivityUpdate | 16 | revise fishery-specific selectivity for the 33-fishery structure with dome/old-age-tail form penalties off for all 14 applicable fisheries | Revised fishery-specific selectivity | 16 Revised fishery-specific selectivity | `16-selectivity-update` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `17-MIX015` | `TRUE` | 17-TagMixing | 17 | apply release-group-specific MIX015 tag-mixing periods | Release-group-specific tag mixing periods | 17 Release-group-specific tag-mixing periods | `17-mix015` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `18-TagReportingExclusion` | `TRUE` | 18-TagReportingExclusion | 18 | exclude reporting rates only during each release group's configured tag-mixing period | Tag reporting rates omitted in pre-mixing window | 18 Tag reporting rates omitted in pre-mixing window | `18-tag-reporting-exclusion` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `19-EffortCreep` | `TRUE` | 19-EffortCreep | 19 | apply the BET 2026 effort-creep series | Effort creep | 19 Effort-creep adjustment | `19-effortcreep` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `20a-DOMDiv200` | `TRUE` | 20-CompositionWeighting | 20a | apply divisor 200 to length compositions from the three domestic fisheries F21-F23 | Three domestic fisheries downweighted | 20a F21-F23 length-composition downweighting | `20a-dom-f21-f23-div200` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `20b-Francis` | `TRUE` | 20-CompositionWeighting | 20b | apply the independent Francis composition-data weighting comparison | Francis reweighting | 20b Francis length-composition reweighting | `20b-francis` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `20c-DMG8Nmax25` | `TRUE` | 20-CompositionWeighting | 20c | branch directly from Step 19 and use a Dirichlet-multinomial likelihood with G8 grouping and Nmax 25 | DM weighting | 20c Final DM weighting model (Job 14363 settings) | `20c-dm-length-composition-weighting` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `21a-R1F2F3F29Shared-MIX015` | `TRUE` | 21-SelectivityMixingSensitivity | 21a | apply the Job 15984 R1 selectivity grouping with SC22-IP10 K=0.15 mixing periods | R1 grouped selectivity; K=0.15 | 21a Final DM sensitivity \| R1 F2/F3/F29 shared, SC22 K=0.15 | `21a-r1-f2-f3-f29-shared-mix015` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `21b-R1F2F3F29Shared-MIX005` | `TRUE` | 21-SelectivityMixingSensitivity | 21b | retain the Job 15984 R1 selectivity grouping and change only SC22-IP10 mixing periods from K=0.15 to K=0.05 | R1 grouped selectivity; K=0.05 | 21b Final DM sensitivity \| R1 F2/F3/F29 shared, SC22 K=0.05 | `21b-r1-f2-f3-f29-shared-mix005` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `22-TagTauSensitivity` | `TRUE` | 22-TagDispersionSensitivity | 22 | estimate negative-binomial tag-recapture dispersion under hierarchical recapture-fishery groupings | Estimated tag-recapture dispersion | 22 Tag-recapture dispersion sensitivity | `22-tag-tau-sensitivity` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag2023` | `steps/01-Diag2023/model` | `exists` |
| `02-NewExe1003` | `steps/02-NewExe1003/model` | `exists` |
| `03-Ini1007` | `steps/03-Ini1007/model` | `exists` |
| `04-FixM` | `steps/04-FixM/model` | `exists` |
| `05-LengthWeight` | `steps/05-LengthWeight/model` | `exists` |
| `06-NewStructure` | `steps/06-NewStructure/model` | `exists` |
| `07-ConvertToLength` | `steps/07-ConvertToLength/model` | `exists` |
| `08-AddLengthData` | `steps/08-AddLengthData/model` | `exists` |
| `09-TailCompression1Pct` | `steps/09-TailCompression1Pct/model` | `exists` |
| `10-DataTo2024` | `steps/10-DataTo2024/model` | `exists` |
| `11-RegionalCPUE` | `steps/11-RegionalCPUE/model` | `exists` |
| `12-TimeVaryingCV` | `steps/12-TimeVaryingCV/model` | `exists` |
| `13-CPUEErrorCalibration` | `steps/13-CPUEErrorCalibration/model` | `exists` |
| `14-NewAgeData` | `steps/14-NewAgeData/model` | `exists` |
| `15a-REG075` | `steps/15a-REG075/model` | `exists` |
| `15b-SUB075` | `steps/15b-SUB075/model` | `exists` |
| `16-SelectivityUpdate` | `steps/16-SelectivityUpdate/model` | `exists` |
| `17-MIX015` | `steps/17-MIX015/model` | `exists` |
| `18-TagReportingExclusion` | `steps/18-TagReportingExclusion/model` | `exists` |
| `19-EffortCreep` | `steps/19-EffortCreep/model` | `exists` |
| `20a-DOMDiv200` | `steps/20a-DOMDiv200/model` | `exists` |
| `20b-Francis` | `steps/20b-Francis/model` | `exists` |
| `20c-DMG8Nmax25` | `steps/20c-DMG8Nmax25/model` | `exists` |
| `21a-R1F2F3F29Shared-MIX015` | `steps/21a-R1F2F3F29Shared-MIX015/model` | `exists` |
| `21b-R1F2F3F29Shared-MIX005` | `steps/21b-R1F2F3F29Shared-MIX005/model` | `exists` |
| `22-TagTauSensitivity` | `steps/22-TagTauSensitivity/model` | `exists` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `20c-DMG8Nmax25` | Run the selected final model folder. |
| `STEP_SELECT` | `15a-REG075,15b-SUB075` | Run the Step 15 age-weighting alternatives. Step 14 is their common BASE075 reference. |
| `STEP_SELECT` | `all` | Run every enabled row. |
| `MFCL_LIVE_LOG` | `true` | Stream MFCL output into the Kflow log. |
| `RUN_MODE` | `job_par` | Rerun from a previous Kflow job output `.par`. Use this with `PAR_SOURCE_JOB` and `KFLOW_INPUT_JOBS`. |
| `PAR_SOURCE_JOB` | `354` | Previous same-step job number to search for `outputs/models/<step_id>/final.par`. |
| `KFLOW_INPUT_JOBS` | `354` | Previous job number to attach as an input archive for the rerun. Usually the same value as `PAR_SOURCE_JOB`. |
| `INPUT_PAR` | `123.par` | Continue from one specific `.par` already in the selected model folder; if it is missing, the runner logs that and falls back to `doitall`. |
| `STEPWISE_COMMIT_FINAL_PARS` | `false` | Optional legacy path to commit final `.par` files back to this repo. Keep off for parallel Kflow runs. |
| `STEPWISE_PUSH_FINAL_PARS` | `false` | Optional legacy path to push the `.par` commit to GitHub. Keep off for parallel Kflow runs. |
| `TRIGGER_NEXT` | `false` | Stop after stepwise; do not launch results/report. |
| `FLOW_GROUP` | `bet-2026-stepwise-pathway` | Shared label for the chain. |

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
