# Run configuration

Operational settings are generated from `job-config.R` and `kflow.yaml`.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-final-stepwise` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `false` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360` | Docker image used by Kflow and local Docker runs. |
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
| `01-Diag2023` | `TRUE` | 01-Diagnostic | 01 | refit the 2023 diagnostic model | 2023 diagnostic-model refit | 01 2023 diagnostic-model refit | `01-diag2023` | `doitall` | /home/mfcl/mfclo64_2023_diagnostic_2.2.2.0 | `blank` | `bet.frq` | `blank` |
| `02-NewExeIni1007` | `TRUE` | 02-ExecutableIni | 02 | update MFCL executable and INI format together | New executable and INI 1007 | 02 New executable and INI 1007 | `02-new-exe-ini1007` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `03-FixM` | `TRUE` | 03-FixM | 03 | fix Lorenzen natural-mortality scaling | Natural mortality fixed | 03 Fix natural mortality | `03-fix-m` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `04-LengthWeight` | `TRUE` | 04-LengthWeight | 04 | update bias-corrected BET length-weight parameters | Length-weight update | 04 BET 2026 length-weight update | `04-length-weight` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `05-NewStructure` | `TRUE` | 05-NewStructure | 05 | adopt the five-region, 33-fishery structure and remap current reporting-rate controls | Five-region structure | 05 Five-region, 33-fishery structure | `05-new-structure` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `06-ConvertToLength` | `TRUE` | 06-ConvertToLength | 06 | replace weight compositions with reweighted weight-as-length data through 2021 | Weight-as-length compositions | 06 Convert weight data to length | `06-convert-to-length` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `07-AddLengthData` | `TRUE` | 07-AddLengthData | 07 | add observed length compositions where coverage exceeds weight samples | Observed-length supplementation | 07 Add observed length data | `07-add-length-data` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `08-DataTo2024` | `TRUE` | 08-DataTo2024 | 08 | extend data through 2024 except CAAL | Data through 2024 | 08 Update data through 2024 | `08-data-to-2024` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `09-SizeDataQC` | `TRUE` | 09-SizeDataQC | 09 | apply PH/ID and domestic mixed-gear size-data rules | PH/ID and domestic size-data rules | 09 PH/ID and domestic size-data rules | `09-size-data-qc` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `10-RegionalCPUE` | `TRUE` | 10-RegionalCPUE | 10 | use separate regional CPUE indices and regional scaling | Regional CPUE and scaling | 10 Regional CPUE and scaling | `10-regional-cpue` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `11-TimeVaryingCV` | `TRUE` | 11-TimeVaryingCV | 11 | apply time-varying CPUE uncertainty | Time-varying CPUE uncertainty | 11 Time-varying CPUE uncertainty | `11-time-varying-cv` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `12-CPUEErrorCalibration` | `TRUE` | 12-CPUEErrorCalibration | 12 | fix regional CPUE log-scale observation-error SDs | Fixed regional CPUE SDs | 12 Fix regional CPUE SDs | `12-cpue-error-sd` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `13-NewAgeData` | `TRUE` | 13-AgeData | 13 | add new CAAL data with weight 0.75 | New CAAL data | 13 New CAAL data, weight 0.75 | `13-new-age-data` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `14a-REG075` | `TRUE` | 14-AgeWeighting | 14a | apply regional CAAL reweighting | Regional CAAL reweighting | 14a Regional CAAL reweighting | `14a-reg075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `14b-SUB075` | `TRUE` | 14-AgeWeighting | 14b | apply selected regions 3-and-4 combined CAAL reweighting | Sub-basin CAAL reweighting | 14b Sub-basin CAAL reweighting | `14b-sub075` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `15-SelectivityUpdate` | `TRUE` | 15-SelectivityUpdate | 15 | revise fishery-specific selectivity | Selectivity update | 15 Selectivity update | `15-selectivity-update` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `16-MIX020` | `TRUE` | 16-TagMixing | 16 | apply release-group-specific K=0.20 mixing periods | K=0.20 tag mixing periods | 16 K=0.20 release-group tag mixing | `16-mix020` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `17-TagReportingExclusion` | `TRUE` | 17-TagReportingExclusion | 17 | exclude reporting rates during pre-mixing windows | Pre-mixing reporting-rate exclusion | 17 Pre-mixing reporting-rate exclusion | `17-tag-reporting-exclusion` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `18-EffortCreep` | `TRUE` | 18-EffortCreep | 18 | apply effort-creep adjustment to CPUE indices | Effort-creep adjustment | 18 Effort-creep adjustment | `18-effort-creep` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |
| `19-DMG8Nmax25` | `TRUE` | 19-CompositionWeighting | 19 | apply Dirichlet-multinomial composition weighting | DM composition weighting | 19 DM composition weighting, G8 Nmax 25 | `19-dm-g8-nmax25` | `doitall` | /home/mfcl/mfclo64 | `blank` | `bet.frq` | `blank` |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `01-Diag2023` | `steps/01-Diag2023/model` | `exists` |
| `02-NewExeIni1007` | `steps/02-NewExeIni1007/model` | `exists` |
| `03-FixM` | `steps/03-FixM/model` | `exists` |
| `04-LengthWeight` | `steps/04-LengthWeight/model` | `exists` |
| `05-NewStructure` | `steps/05-NewStructure/model` | `exists` |
| `06-ConvertToLength` | `steps/06-ConvertToLength/model` | `exists` |
| `07-AddLengthData` | `steps/07-AddLengthData/model` | `exists` |
| `08-DataTo2024` | `steps/08-DataTo2024/model` | `exists` |
| `09-SizeDataQC` | `steps/09-SizeDataQC/model` | `exists` |
| `10-RegionalCPUE` | `steps/10-RegionalCPUE/model` | `exists` |
| `11-TimeVaryingCV` | `steps/11-TimeVaryingCV/model` | `exists` |
| `12-CPUEErrorCalibration` | `steps/12-CPUEErrorCalibration/model` | `exists` |
| `13-NewAgeData` | `steps/13-NewAgeData/model` | `exists` |
| `14a-REG075` | `steps/14a-REG075/model` | `exists` |
| `14b-SUB075` | `steps/14b-SUB075/model` | `exists` |
| `15-SelectivityUpdate` | `steps/15-SelectivityUpdate/model` | `exists` |
| `16-MIX020` | `steps/16-MIX020/model` | `exists` |
| `17-TagReportingExclusion` | `steps/17-TagReportingExclusion/model` | `exists` |
| `18-EffortCreep` | `steps/18-EffortCreep/model` | `exists` |
| `19-DMG8Nmax25` | `steps/19-DMG8Nmax25/model` | `exists` |


## Submission

Validate without fitting MFCL:

```bash
make validate
```

Submit one frozen model:

```bash
make kflow STEP_SELECT=19-DMG8Nmax25
```

The Kflow task is fixed to Suva and the immutable tuna-flow v2.5 image digest.
Each row points to a self-contained `steps/<step_id>/model` folder. Parallel
campaign submission must override `STEP_SELECT`, `JOB_TITLE`, `MODEL_LABEL`
and `JOB_KEY` per row; it must not use a previous step's `.par`.

`STEPWISE_SAVE_FINAL_PAR`, `STEPWISE_COMMIT_FINAL_PARS`, and
`STEPWISE_PUSH_FINAL_PARS` remain false so parallel jobs cannot write fitted
outputs back to this public input branch.

## Outputs

Kflow archives the selected model inputs, compact payload, final `.par`, logs
and model index under `outputs/models/<step_id>/`. No fitted outputs are
committed in this repository.
