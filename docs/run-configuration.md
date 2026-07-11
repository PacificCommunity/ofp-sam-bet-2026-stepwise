# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `all` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-stepwise-v2` | Kflow group label used to connect stepwise, results, and report jobs. |
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
| `12p001-Y73-E1-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p001 | Tests 73 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 0. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR73-01-50-50 E1 weight 0; reviewed group-consistent LF controls | Sensitivity Y73-E1-W000-FGroup | `12p001-y73-e1-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p002-Y73-E1-W025-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p002 | Tests 73 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 25. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR73-01-50-50 E1 weight 25; reviewed group-consistent LF controls | Sensitivity Y73-E1-W025-FGroup | `12p002-y73-e1-w025-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p003-Y73-E1-W050-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p003 | Tests 73 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 50. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR73-01-50-50 E1 weight 50; reviewed group-consistent LF controls | Sensitivity Y73-E1-W050-FGroup | `12p003-y73-e1-w050-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p004-Y73-E1-W100-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p004 | Tests 73 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 100. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR73-01-50-50 E1 weight 100; reviewed group-consistent LF controls | Sensitivity Y73-E1-W100-FGroup | `12p004-y73-e1-w100-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p005-Y73-E1-W200-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p005 | Tests 73 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 200. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR73-01-50-50 E1 weight 200; reviewed group-consistent LF controls | Sensitivity Y73-E1-W200-FGroup | `12p005-y73-e1-w200-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p006-Y72-E1-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p006 | Tests 72 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 0. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR72-01-50-50 E1 weight 0; reviewed group-consistent LF controls | Sensitivity Y72-E1-W000-FGroup | `12p006-y72-e1-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p007-Y72-E1-W025-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p007 | Tests 72 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 25. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR72-01-50-50 E1 weight 25; reviewed group-consistent LF controls | Sensitivity Y72-E1-W025-FGroup | `12p007-y72-e1-w025-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p008-Y72-E1-W050-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p008 | Tests 72 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 50. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR72-01-50-50 E1 weight 50; reviewed group-consistent LF controls | Sensitivity Y72-E1-W050-FGroup | `12p008-y72-e1-w050-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p009-Y72-E1-W100-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p009 | Tests 72 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 100. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR72-01-50-50 E1 weight 100; reviewed group-consistent LF controls | Sensitivity Y72-E1-W100-FGroup | `12p009-y72-e1-w100-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p010-Y72-E1-W200-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p010 | Tests 72 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 200. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR72-01-50-50 E1 weight 200; reviewed group-consistent LF controls | Sensitivity Y72-E1-W200-FGroup | `12p010-y72-e1-w200-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p011-Y71-E1-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p011 | Tests 71 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 0. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR71-01-50-50 E1 weight 0; reviewed group-consistent LF controls | Sensitivity Y71-E1-W000-FGroup | `12p011-y71-e1-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p012-Y71-E1-W025-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p012 | Tests 71 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 25. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR71-01-50-50 E1 weight 25; reviewed group-consistent LF controls | Sensitivity Y71-E1-W025-FGroup | `12p012-y71-e1-w025-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p013-Y71-E1-W050-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p013 | Tests 71 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 50. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR71-01-50-50 E1 weight 50; reviewed group-consistent LF controls | Sensitivity Y71-E1-W050-FGroup | `12p013-y71-e1-w050-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p014-Y71-E1-W100-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p014 | Tests 71 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 100. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR71-01-50-50 E1 weight 100; reviewed group-consistent LF controls | Sensitivity Y71-E1-W100-FGroup | `12p014-y71-e1-w100-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p015-Y71-E1-W200-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p015 | Tests 71 annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight 200. The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control. | OPR71-01-50-50 E1 weight 200; reviewed group-consistent LF controls | Sensitivity Y71-E1-W200-FGroup | `12p015-y71-e1-w200-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p016-Y72-E2-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p016 | Tests 72 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 0. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR72-01-50-50 E2 weight 0; reviewed group-consistent LF controls | Sensitivity Y72-E2-W000-FGroup | `12p016-y72-e2-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p017-Y72-E2-W100-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p017 | Tests 72 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 100. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR72-01-50-50 E2 weight 100; reviewed group-consistent LF controls | Sensitivity Y72-E2-W100-FGroup | `12p017-y72-e2-w100-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p018-Y72-E2-W200-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p018 | Tests 72 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 200. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR72-01-50-50 E2 weight 200; reviewed group-consistent LF controls | Sensitivity Y72-E2-W200-FGroup | `12p018-y72-e2-w200-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p019-Y71-E2-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p019 | Tests 71 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 0. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR71-01-50-50 E2 weight 0; reviewed group-consistent LF controls | Sensitivity Y71-E2-W000-FGroup | `12p019-y71-e2-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p020-Y71-E2-W100-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p020 | Tests 71 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 100. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR71-01-50-50 E2 weight 100; reviewed group-consistent LF controls | Sensitivity Y71-E2-W100-FGroup | `12p020-y71-e2-w100-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p021-Y71-E2-W200-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p021 | Tests 71 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 200. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR71-01-50-50 E2 weight 200; reviewed group-consistent LF controls | Sensitivity Y71-E2-W200-FGroup | `12p021-y71-e2-w200-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p022-Y71-E3-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p022 | Tests 71 annual OPR coefficients with a 3-calendar-year endpoint and penalty weight 0. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR71-01-50-50 E3 weight 0; reviewed group-consistent LF controls | Sensitivity Y71-E3-W000-FGroup | `12p022-y71-e3-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p023-Y71-E3-W100-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p023 | Tests 71 annual OPR coefficients with a 3-calendar-year endpoint and penalty weight 100. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR71-01-50-50 E3 weight 100; reviewed group-consistent LF controls | Sensitivity Y71-E3-W100-FGroup | `12p023-y71-e3-w100-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p024-Y71-E3-W200-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p024 | Tests 71 annual OPR coefficients with a 3-calendar-year endpoint and penalty weight 200. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter. | OPR71-01-50-50 E3 weight 200; reviewed group-consistent LF controls | Sensitivity Y71-E3-W200-FGroup | `12p024-y71-e3-w200-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p025-Y73-E0-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p025 | Uses 73 annual OPR coefficients with no annual terminal endpoint and component endpoint flags set to -1. This is the direct no-endpoint control; the terminal-recruitment penalty is necessarily off. | OPR73-01-50-50 E0 weight 0; reviewed group-consistent LF controls | Sensitivity Y73-E0-W000-FGroup | `12p025-y73-e0-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p026-Y72-E0-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p026 | Uses 72 annual OPR coefficients with no annual terminal endpoint and component endpoint flags set to -1. This is the direct no-endpoint control; the terminal-recruitment penalty is necessarily off. | OPR72-01-50-50 E0 weight 0; reviewed group-consistent LF controls | Sensitivity Y72-E0-W000-FGroup | `12p026-y72-e0-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p027-Y71-E0-W000-FGroup` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p027 | Uses 71 annual OPR coefficients with no annual terminal endpoint and component endpoint flags set to -1. This is the direct no-endpoint control; the terminal-recruitment penalty is necessarily off. | OPR71-01-50-50 E0 weight 0; reviewed group-consistent LF controls | Sensitivity Y71-E0-W000-FGroup | `12p027-y71-e0-w000-fgroup` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p028-Y73-E1-W100-FBase` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p028 | Restores the current Step 12 LF controls at OPR73/E1/W100 to measure the net effect of the reviewed group-consistent changes. | OPR73-01-50-50 E1 weight 100; current LF controls | Sensitivity Y73-E1-W100-FBase | `12p028-y73-e1-w100-fbase` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p029-Y73-E1-W100-FExact` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p029 | Applies only the exact five listed fishery changes at OPR73/E1/W100. This deliberately omits F27/F18 propagation and is a flag-grouping diagnostic, not the source-consistent default. | OPR73-01-50-50 E1 weight 100; exact five-fishery-only LF controls | Sensitivity Y73-E1-W100-FExact | `12p029-y73-e1-w100-fexact` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p030-Y72-E1-W100-FBase` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p030 | Restores the current Step 12 LF controls at OPR72/E1/W100 to measure the net effect of the reviewed group-consistent changes. | OPR72-01-50-50 E1 weight 100; current LF controls | Sensitivity Y72-E1-W100-FBase | `12p030-y72-e1-w100-fbase` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p031-Y72-E1-W100-FExact` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p031 | Applies only the exact five listed fishery changes at OPR72/E1/W100. This deliberately omits F27/F18 propagation and is a flag-grouping diagnostic, not the source-consistent default. | OPR72-01-50-50 E1 weight 100; exact five-fishery-only LF controls | Sensitivity Y72-E1-W100-FExact | `12p031-y72-e1-w100-fexact` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p032-Y71-E1-W100-FBase` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p032 | Restores the current Step 12 LF controls at OPR71/E1/W100 to measure the net effect of the reviewed group-consistent changes. | OPR71-01-50-50 E1 weight 100; current LF controls | Sensitivity Y71-E1-W100-FBase | `12p032-y71-e1-w100-fbase` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p033-Y71-E1-W100-FExact` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p033 | Applies only the exact five listed fishery changes at OPR71/E1/W100. This deliberately omits F27/F18 propagation and is a flag-grouping diagnostic, not the source-consistent default. | OPR71-01-50-50 E1 weight 100; exact five-fishery-only LF controls | Sensitivity Y71-E1-W100-FExact | `12p033-y71-e1-w100-fexact` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p034-Y73-E1-W100-FTail` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p034 | Isolates the large-fish tail controls for fisheries sharing the F20/F27 selectivity group and fishery 28. | OPR73-01-50-50 E1 weight 100; isolated large-fish-tail controls | Sensitivity Y73-E1-W100-FTail | `12p034-y73-e1-w100-ftail` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p035-Y73-E1-W100-FYoung` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p035 | Isolates zero young-age selectivity where fisheries 12 and 26 have no observed catch in the affected age classes. | OPR73-01-50-50 E1 weight 100; isolated young-age controls | Sensitivity Y73-E1-W100-FYoung | `12p035-y73-e1-w100-fyoung` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p036-Y73-E1-W100-F17` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p036 | Isolates the earlier upper-age control for fisheries 17 and 18, which share a selectivity group. | OPR73-01-50-50 E1 weight 100; isolated F17/F18 upper-age controls | Sensitivity Y73-E1-W100-F17 | `12p036-y73-e1-w100-f17` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p037-Y73-E1-W100-FGroup-LenDiv40` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p037 | Sets fish flag(49) to a uniform length-composition divisor of 40 for every fishery at OPR73/E1/W100. This is the moderate Step-15-style downweight. Weight-composition flag(50) remains unchanged. | OPR73-01-50-50 E1 weight 100; uniform length divisor 40 | Sensitivity Y73-E1-W100-FGroup-LenDiv40 | `12p037-y73-e1-w100-fgroup-lendiv40` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p038-Y73-E1-W100-FGroup-LenDiv80` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p038 | Sets fish flag(49) to a uniform length-composition divisor of 80 for every fishery at OPR73/E1/W100. This strong case gives every LF record half the effective sample size of the uniform-40 case. Weight-composition flag(50) remains unchanged. | OPR73-01-50-50 E1 weight 100; uniform length divisor 80 | Sensitivity Y73-E1-W100-FGroup-LenDiv80 | `12p038-y73-e1-w100-fgroup-lendiv80` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p039-Y72-E1-W100-FGroup-LenDiv40` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p039 | Sets fish flag(49) to a uniform length-composition divisor of 40 for every fishery at OPR72/E1/W100. This is the moderate Step-15-style downweight. Weight-composition flag(50) remains unchanged. | OPR72-01-50-50 E1 weight 100; uniform length divisor 40 | Sensitivity Y72-E1-W100-FGroup-LenDiv40 | `12p039-y72-e1-w100-fgroup-lendiv40` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p040-Y72-E1-W100-FGroup-LenDiv80` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p040 | Sets fish flag(49) to a uniform length-composition divisor of 80 for every fishery at OPR72/E1/W100. This strong case gives every LF record half the effective sample size of the uniform-40 case. Weight-composition flag(50) remains unchanged. | OPR72-01-50-50 E1 weight 100; uniform length divisor 80 | Sensitivity Y72-E1-W100-FGroup-LenDiv80 | `12p040-y72-e1-w100-fgroup-lendiv80` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p041-Y71-E1-W100-FGroup-LenDiv40` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p041 | Sets fish flag(49) to a uniform length-composition divisor of 40 for every fishery at OPR71/E1/W100. This is the moderate Step-15-style downweight. Weight-composition flag(50) remains unchanged. | OPR71-01-50-50 E1 weight 100; uniform length divisor 40 | Sensitivity Y71-E1-W100-FGroup-LenDiv40 | `12p041-y71-e1-w100-fgroup-lendiv40` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p042-Y71-E1-W100-FGroup-LenDiv80` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p042 | Sets fish flag(49) to a uniform length-composition divisor of 80 for every fishery at OPR71/E1/W100. This strong case gives every LF record half the effective sample size of the uniform-40 case. Weight-composition flag(50) remains unchanged. | OPR71-01-50-50 E1 weight 100; uniform length divisor 80 | Sensitivity Y71-E1-W100-FGroup-LenDiv80 | `12p042-y71-e1-w100-fgroup-lendiv80` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p043-Y73-E1-W100-FGroup-TrendOff` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p043 | Separates the OPR trend penalty from the terminal-mean penalty with parest_flag(153)=-1 (off). | OPR73-01-50-50 E1 weight 100; trend flag -1 | Sensitivity Y73-E1-W100-FGroup-TrendOff | `12p043-y73-e1-w100-fgroup-trendoff` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p044-Y73-E1-W100-FGroup-Trend010` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p044 | Separates the OPR trend penalty from the terminal-mean penalty with parest_flag(153)=1 (weight 0.1). | OPR73-01-50-50 E1 weight 100; trend flag 1 | Sensitivity Y73-E1-W100-FGroup-Trend010 | `12p044-y73-e1-w100-fgroup-trend010` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p045-P73-TagWt0300` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p045 | Scales only the tag likelihood to 0.30 with parest_flag(177)=300 while retaining reporting-rate priors. The three-point response tests whether the recent recruitment signal changes continuously with tag influence. | OPR73-01-50-50 E1 weight 100; tag likelihood weight 0.30 | Sensitivity P73-TagWt0300 | `12p045-p73-tagwt0300` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p046-P73-TagWt0100` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p046 | Scales only the tag likelihood to 0.10 with parest_flag(177)=100 while retaining reporting-rate priors. The three-point response tests whether the recent recruitment signal changes continuously with tag influence. | OPR73-01-50-50 E1 weight 100; tag likelihood weight 0.10 | Sensitivity P73-TagWt0100 | `12p046-p73-tagwt0100` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p047-P73-TagWt0030` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p047 | Scales only the tag likelihood to 0.03 with parest_flag(177)=30 while retaining reporting-rate priors. The three-point response tests whether the recent recruitment signal changes continuously with tag influence. | OPR73-01-50-50 E1 weight 100; tag likelihood weight 0.03 | Sensitivity P73-TagWt0030 | `12p047-p73-tagwt0030` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p048-P73-TagCond` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p048 | Uses parest_flag(249)=1 so tag information is conditioned on total recaptures and primarily informs their relative distribution. It is an alternative observation model, not an automatic preferred case. | OPR73-01-50-50 E1 weight 100; recaptures-conditioned tags | Sensitivity P73-TagCond | `12p048-p73-tagcond` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p049-P73-TagDisp` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p049 | Estimates one pooled direct-tau negative-binomial dispersion parameter. Because this also changes the dispersion parameterisation, it is retained as a structural diagnostic rather than a final-candidate shortcut. | OPR73-01-50-50 E1 weight 100; estimated pooled tag overdispersion | Sensitivity P73-TagDisp | `12p049-p73-tagdisp` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p050-U73-TagDrop60` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p050 | Removes only release group 60 and synchronises TAG, FRQ, MFCL 1007 tag sections, and reporting maps. This is a cohort-attribution diagnostic; objectives are not directly comparable because the data differ. | OPR73-01-50-50 E1 weight 0; dominant 2021 release removed | Sensitivity U73-TagDrop60 | `12p050-u73-tagdrop60` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p051-U73-TagMixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p051 | Sets tag_flags(:,2)=1 for every release so reporting-rate corrections are excluded during pre-mixing periods, following the source/manual treatment. | OPR73-01-50-50 E1 weight 0; all-release mixing reporting correction | Sensitivity U73-TagMixAll | `12p051-u73-tagmixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p052-P73-TagDrop60` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p052 | Removes only release group 60 and synchronises TAG, FRQ, MFCL 1007 tag sections, and reporting maps. This is a cohort-attribution diagnostic; objectives are not directly comparable because the data differ. | OPR73-01-50-50 E1 weight 100; dominant 2021 release removed | Sensitivity P73-TagDrop60 | `12p052-p73-tagdrop60` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p053-P73-TagMixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p053 | Sets tag_flags(:,2)=1 for every release so reporting-rate corrections are excluded during pre-mixing periods, following the source/manual treatment. | OPR73-01-50-50 E1 weight 100; all-release mixing reporting correction | Sensitivity P73-TagMixAll | `12p053-p73-tagmixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p054-P73-TagDrop2021` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p054 | Removes release groups 18 and 60 together and synchronises TAG, FRQ, every MFCL 1007 tag section, and reporting maps. This reproduces the full 2021-release deletion as an attribution upper bound; it is not a default data treatment. | OPR73-01-50-50 E1 weight 100; both 2021 releases removed | Sensitivity P73-TagDrop2021 | `12p054-p73-tagdrop2021` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p055-P73-RRCampaign` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p055 | Adds one reporting-rate parameter for the two 2021 campaign releases across fisheries 25-28, retaining target 0.52015 and penalty 485.2. This tests campaign-specific reporting without deleting observations. | OPR73-01-50-50 E1 weight 100; separate 2021 campaign reporting rate | Sensitivity P73-RRCampaign | `12p055-p73-rrcampaign` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p056-P73-RRCampaignMixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p056 | Combines the externally informed 2021 campaign reporting-rate parameter (target 0.52015, penalty 485.2) with tag_flags(:,2)=1. It is shortlisted only if likelihood components, population scale, gradients, and Hessian diagnostics remain stable at stricter convergence. | OPR73-01-50-50 E1 weight 100; central 2021 campaign reporting rate plus mixing correction | Sensitivity P73-RRCampaignMixAll | `12p056-p73-rrcampaignmixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p057-P73-RRCampaignWideMixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p057 | Combines all-release pre-mixing correction with the same 0.52015 campaign target but relaxes the reporting-rate penalty to 48.52 (prior SD about 0.10). This is a prior-conflict diagnostic, not a preferred fit selected by recruitment shape. | OPR73-01-50-50 E1 weight 100; wider 2021 campaign prior plus mixing correction | Sensitivity P73-RRCampaignWideMixAll | `12p057-p73-rrcampaignwidemixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p058-P73-RR60MixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p058 | Estimates a separate reporting rate only for release group 60 at target 0.52015 and penalty 485.2 while applying tag_flags(:,2)=1 to every release. Comparison with the campaign grouping diagnoses reporting-rate/recruitment confounding. | OPR73-01-50-50 E1 weight 100; dominant-release reporting rate plus mixing correction | Sensitivity P73-RR60MixAll | `12p058-p73-rr60mixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p059-P73-TagMix60Q2` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p059 | Sets tag_flags(60,2)=1 and the dominant 2021 release mixing period to 2 quarters. This brackets plausible pre-mixing duration without suppressing later recaptures. | OPR73-01-50-50 E1 weight 100; dominant-release mixing period 2 quarters | Sensitivity P73-TagMix60Q2 | `12p059-p73-tagmix60q2` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p060-P73-TagMix60Q4` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p060 | Sets tag_flags(60,2)=1 and the dominant 2021 release mixing period to 4 quarters. This brackets plausible pre-mixing duration without suppressing later recaptures. | OPR73-01-50-50 E1 weight 100; dominant-release mixing period 4 quarters | Sensitivity P73-TagMix60Q4 | `12p060-p73-tagmix60q4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p061-P73-TagGammaRob` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p061 | Uses robust binned gamma with a one-recapture censor and 0.05 mixture fraction. This is a targeted outlier sensitivity and its objective is not directly comparable with negative-binomial cases. | OPR73-01-50-50 E1 weight 100; robust binned-gamma tags | Sensitivity P73-TagGammaRob | `12p061-p73-taggammarob` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p062-P72-RRCampaignMixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p062 | Combines the central campaign reporting-rate prior and all-release pre-mixing correction at this annual OPR count. This is a shortlisted structural comparison across 73, 72, and 71 annual coefficients. | OPR72-01-50-50 E1 weight 100; central 2021 campaign reporting rate plus mixing correction | Sensitivity P72-RRCampaignMixAll | `12p062-p72-rrcampaignmixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p063-P72-TagDrop60` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p063 | Removes only release group 60 at this annual OPR count to check whether cohort attribution is stable across 73, 72, and 71 coefficients. | OPR72-01-50-50 E1 weight 100; dominant 2021 release removed | Sensitivity P72-TagDrop60 | `12p063-p72-tagdrop60` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p064-P71-RRCampaignMixAll` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p064 | Combines the central campaign reporting-rate prior and all-release pre-mixing correction at this annual OPR count. This is a shortlisted structural comparison across 73, 72, and 71 annual coefficients. | OPR71-01-50-50 E1 weight 100; central 2021 campaign reporting rate plus mixing correction | Sensitivity P71-RRCampaignMixAll | `12p064-p71-rrcampaignmixall` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p065-P71-TagDrop60` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p065 | Removes only release group 60 at this annual OPR count to check whether cohort attribution is stable across 73, 72, and 71 coefficients. | OPR71-01-50-50 E1 weight 100; dominant 2021 release removed | Sensitivity P71-TagDrop60 | `12p065-p71-tagdrop60` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11p001-Free` | `FALSE` | 11-StandardTerminalTag | 11p001 | Uses ordinary quarter-specific recruitment deviations and estimates every terminal recruitment deviation with the parent tag likelihood and data. The reviewed controls are propagated across shared selectivity groups so this is a source-consistent structural control for the OPR response. | Standard recruitment: estimates every terminal recruitment deviation with the parent tag likelihood and data | Sensitivity Free | `11p001-free` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11p002-Fix4` | `FALSE` | 11-StandardTerminalTag | 11p002 | Uses ordinary quarter-specific recruitment deviations and fixes the last four quarterly deviations to the historical arithmetic-mean treatment. The reviewed controls are propagated across shared selectivity groups so this is a source-consistent structural control for the OPR response. | Standard recruitment: fixes the last four quarterly deviations to the historical arithmetic-mean treatment | Sensitivity Fix4 | `11p002-fix4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11p003-Fix8` | `FALSE` | 11-StandardTerminalTag | 11p003 | Uses ordinary quarter-specific recruitment deviations and fixes the last eight quarterly deviations to the historical arithmetic-mean treatment. The reviewed controls are propagated across shared selectivity groups so this is a source-consistent structural control for the OPR response. | Standard recruitment: fixes the last eight quarterly deviations to the historical arithmetic-mean treatment | Sensitivity Fix8 | `11p003-fix8` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11p004-FreeDrop60` | `FALSE` | 11-StandardTerminalTag | 11p004 | Uses ordinary quarter-specific recruitment deviations and estimates every terminal deviation after removing dominant 2021 release group 60. The reviewed controls are propagated across shared selectivity groups so this is a source-consistent structural control for the OPR response. | Standard recruitment: estimates every terminal deviation after removing dominant 2021 release group 60 | Sensitivity FreeDrop60 | `11p004-freedrop60` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `11p005-FreeTagWt0100` | `FALSE` | 11-StandardTerminalTag | 11p005 | Uses ordinary quarter-specific recruitment deviations and estimates every terminal deviation with tag likelihood weight 0.1. The reviewed controls are propagated across shared selectivity groups so this is a source-consistent structural control for the OPR response. | Standard recruitment: estimates every terminal deviation with tag likelihood weight 0.1 | Sensitivity FreeTagWt0100 | `11p005-freetagwt0100` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p066-Y71-E3-W000-FBase-P221-00` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p066 | Matched compatibility control for the supplied OPR71/end3 setup, with parest_flag(221)=0. Public ongoing-dev treats flag 221 as obsolete; compare only with the paired flag-71 row. | OPR71-01-50-50 E3 weight 0; current LF controls; parest flag 221=0 | Sensitivity Y71-E3-W000-FBase-P221-00 | `12p066-y71-e3-w000-fbase-p221-00` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p067-Y71-E3-W000-FBase-P221-71` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p067 | Reproduces the supplied OPR settings 155=71, 221=71, 216=50, 217=1, and 202=3 while retaining the parent interaction count 218=50. A difference from the paired flag-zero row would identify assessment-executable behaviour not present in public ongoing-dev. | OPR71-01-50-50 E3 weight 0; current LF controls; parest flag 221=71 | Sensitivity Y71-E3-W000-FBase-P221-71 | `12p067-y71-e3-w000-fbase-p221-71` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p068-Benchmark-OPR69-E2-W100-FBase` | `FALSE` | 12-OPRTerminalPenaltyLFTag | 12p068 | Reproduces the supplied OPR69-01-50-50, two-calendar-year endpoint, terminal-penalty weight 100, and 1,000-evaluation protocol from a newly fitted branch-local 11.par. It is a numerical benchmark only; the curated candidate grid uses 73, 72, and 71 annual coefficients. | Supplied benchmark: OPR69-01-50-50 E2 weight 100; current LF controls | Sensitivity Benchmark-OPR69-E2-W100-FBase | `12p068-benchmark-opr69-e2-w100-fbase` | `doitall` | blank | `blank` | `bet.frq` | `blank` |


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
| `12p001-Y73-E1-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p002-Y73-E1-W025-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p003-Y73-E1-W050-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p004-Y73-E1-W100-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p005-Y73-E1-W200-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p006-Y72-E1-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p007-Y72-E1-W025-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p008-Y72-E1-W050-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p009-Y72-E1-W100-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p010-Y72-E1-W200-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p011-Y71-E1-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p012-Y71-E1-W025-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p013-Y71-E1-W050-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p014-Y71-E1-W100-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p015-Y71-E1-W200-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p016-Y72-E2-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p017-Y72-E2-W100-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p018-Y72-E2-W200-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p019-Y71-E2-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p020-Y71-E2-W100-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p021-Y71-E2-W200-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p022-Y71-E3-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p023-Y71-E3-W100-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p024-Y71-E3-W200-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p025-Y73-E0-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p026-Y72-E0-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p027-Y71-E0-W000-FGroup` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p028-Y73-E1-W100-FBase` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p029-Y73-E1-W100-FExact` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p030-Y72-E1-W100-FBase` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p031-Y72-E1-W100-FExact` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p032-Y71-E1-W100-FBase` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p033-Y71-E1-W100-FExact` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p034-Y73-E1-W100-FTail` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p035-Y73-E1-W100-FYoung` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p036-Y73-E1-W100-F17` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p037-Y73-E1-W100-FGroup-LenDiv40` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p038-Y73-E1-W100-FGroup-LenDiv80` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p039-Y72-E1-W100-FGroup-LenDiv40` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p040-Y72-E1-W100-FGroup-LenDiv80` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p041-Y71-E1-W100-FGroup-LenDiv40` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p042-Y71-E1-W100-FGroup-LenDiv80` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p043-Y73-E1-W100-FGroup-TrendOff` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p044-Y73-E1-W100-FGroup-Trend010` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p045-P73-TagWt0300` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p046-P73-TagWt0100` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p047-P73-TagWt0030` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p048-P73-TagCond` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p049-P73-TagDisp` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p050-U73-TagDrop60` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p051-U73-TagMixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p052-P73-TagDrop60` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p053-P73-TagMixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p054-P73-TagDrop2021` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p055-P73-RRCampaign` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p056-P73-RRCampaignMixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p057-P73-RRCampaignWideMixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p058-P73-RR60MixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p059-P73-TagMix60Q2` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p060-P73-TagMix60Q4` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p061-P73-TagGammaRob` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p062-P72-RRCampaignMixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p063-P72-TagDrop60` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p064-P71-RRCampaignMixAll` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p065-P71-TagDrop60` | `steps/12-OrthogonalPoly/model` | `exists` |
| `11p001-Free` | `steps/11-TimeVaryingCV/model` | `exists` |
| `11p002-Fix4` | `steps/11-TimeVaryingCV/model` | `exists` |
| `11p003-Fix8` | `steps/11-TimeVaryingCV/model` | `exists` |
| `11p004-FreeDrop60` | `steps/11-TimeVaryingCV/model` | `exists` |
| `11p005-FreeTagWt0100` | `steps/11-TimeVaryingCV/model` | `exists` |
| `12p066-Y71-E3-W000-FBase-P221-00` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p067-Y71-E3-W000-FBase-P221-71` | `steps/12-OrthogonalPoly/model` | `exists` |
| `12p068-Benchmark-OPR69-E2-W100-FBase` | `steps/12-OrthogonalPoly/model` | `exists` |


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
