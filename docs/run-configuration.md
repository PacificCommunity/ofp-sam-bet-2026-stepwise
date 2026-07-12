# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-opr-phase-placement` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `false` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.2` | Docker image used by Kflow and local Docker runs. |
| `program_path` | `/home/mfcl/mfclo64` | MFCL executable path inside the Docker image. |
| `stepwise_save_final_par` | `false` | Optional: copy the final `.par` back into `steps/<step_id>/model/`. Off by default; Kflow outputs always include `outputs/models/<step_id>/final.par`. |
| `stepwise_save_raw_mfcl_inputs` | `true` | Preserve the full raw MFCL input folder under `outputs/models/<step_id>/mfcl-inputs/` for native-style auditability. |
| `stepwise_commit_final_pars` | `false` | Optional: create a narrow KflowBot commit containing saved final `.par` files. Off by default to avoid concurrent job push conflicts. |
| `stepwise_push_final_pars` | `false` | Optional: push the saved final `.par` commit to the current branch. Off by default. |
| `par_source_job` | `blank` | Optional previous Kflow job number/reference used with `RUN_MODE=job_par` or `RUN_MODE=doitall_job_par`. |
| `par_source_step_id` | `blank` | Optional source model/step identifier within that job. Defaults to the current step when unset. |
| `stepwise_par_source_dir` | `blank` | Optional local folder to search for previous output `.par` files when testing a job-PAR mode outside Kflow. |
| `kflow_input_jobs` | `blank` | Optional Kflow input job number(s) to attach when a job-PAR mode is used. |


## Model Rows

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `enabled` | `major_step` | `substep` | `change_axis` | `model_label` | `job_title` | `job_key` | `run_mode` | `run_script` | `mfcl_program_path` | `input_par` | `par_source_step_id` | `frq` | `output_par` | `expected_final_par` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `11-Standard-Fix6` | `TRUE` | 11-StandardReference | 11r | PDH-rebuild standard Step-11 Fix6 reference | Standard Fix6 | 11 Standard reference (Fix6) | `11-standard-fix6` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | 11.par |
| `12a-OPR-Phase3-P0` | `TRUE` | 12-OPRPhasePlacement | 12a | OPR conversion at Phase 3 without terminal penalty | OPR Phase 3 P0 | 12a OPR switch Phase 3 P0 | `12a-opr-phase3-p0` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | final.par |
| `12b-OPR-Phase3-P100` | `TRUE` | 12-OPRPhasePlacement | 12b | OPR conversion at Phase 3 with terminal penalty | OPR Phase 3 P100 | 12b OPR switch Phase 3 P100 | `12b-opr-phase3-p100` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | final.par |
| `12c-OPR-Phase8-P0` | `TRUE` | 12-OPRPhasePlacement | 12c | OPR conversion at Phase 8 without terminal penalty | OPR Phase 8 P0 | 12c OPR switch Phase 8 P0 | `12c-opr-phase8-p0` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | final.par |
| `12d-OPR-Phase8-P100` | `TRUE` | 12-OPRPhasePlacement | 12d | OPR conversion at Phase 8 with terminal penalty | OPR Phase 8 P100 | 12d OPR switch Phase 8 P100 | `12d-opr-phase8-p100` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | final.par |
| `12e-OPR-Phase10-P0` | `TRUE` | 12-OPRPhasePlacement | 12e | OPR conversion at Phase 10 without terminal penalty | OPR Phase 10 P0 | 12e OPR switch Phase 10 P0 | `12e-opr-phase10-p0` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | final.par |
| `12f-OPR-Phase10-P100` | `TRUE` | 12-OPRPhasePlacement | 12f | OPR conversion at Phase 10 with terminal penalty | OPR Phase 10 P100 | 12f OPR switch Phase 10 P100 | `12f-opr-phase10-p100` | `doitall` | doitall.sh | blank | `blank` | blank | `bet.frq` | `blank` | final.par |


## Folder Checks

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `step_id` | `expected_source_folder` | `status` |
| --- | --- | --- |
| `11-Standard-Fix6` | `steps/11-Standard-Fix6/model` | `exists` |
| `12a-OPR-Phase3-P0` | `steps/12a-OPR-Phase3-P0/model` | `exists` |
| `12b-OPR-Phase3-P100` | `steps/12b-OPR-Phase3-P100/model` | `exists` |
| `12c-OPR-Phase8-P0` | `steps/12c-OPR-Phase8-P0/model` | `exists` |
| `12d-OPR-Phase8-P100` | `steps/12d-OPR-Phase8-P100/model` | `exists` |
| `12e-OPR-Phase10-P0` | `steps/12e-OPR-Phase10-P0/model` | `exists` |
| `12f-OPR-Phase10-P100` | `steps/12f-OPR-Phase10-P100/model` | `exists` |


## Useful Kflow Config

| Field | Typical value | Purpose |
| --- | --- | --- |
| `STEP_SELECT` | `15-DataWeighting` | Run one model folder. |
| `STEP_SELECT` | `08-RegionalCPUE,09-NewOtoliths` | Run selected model folders. |
| `STEP_SELECT` | `all` | Run every enabled row. |
| `MFCL_LIVE_LOG` | `true` | Stream MFCL output into the Kflow log. |
| `RUN_MODE` | `job_par` | Rerun from a previous Kflow job output `.par`. Use this with `PAR_SOURCE_JOB` and `KFLOW_INPUT_JOBS`. |
| `PAR_SOURCE_JOB` | `354` | Previous job number to search for a saved final `.par`. |
| `PAR_SOURCE_STEP_ID` | `11-Reference-Fix6` | Optional source model identifier when the prior `.par` belongs to a different row. |
| `KFLOW_INPUT_JOBS` | `354` | Previous job number to attach as an input archive for the rerun. |
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
