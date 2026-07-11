# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `12c-LBS-N4` | Model selection used when `STEP_SELECT` is not supplied. |
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
| `12-LengthBasedSel` | `TRUE` | 12-LengthBasedSel | 12a | length-based selectivity before OPR | Length-based selectivity | 12 Length-based selectivity | `12-lengthbasedsel` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13-OrthogonalPoly` | `TRUE` | 13-OrthogonalPoly | 13a | orthogonal-polynomial recruitment after length-based selectivity | Orthogonal polynomial | 13 Orthogonal polynomial | `13-orthogonalpoly` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `14-EffortCreep` | `TRUE` | 14-EffortCreep | 14a | effort creep | Effort creep | 14 Effort creep | `14-effortcreep` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `15-DataWeighting` | `TRUE` | 15-DataWeighting | 15a | data weighting | Data weighting | 15 Data weighting | `15-dataweighting` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12a-LBS-Base` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12a | Step 12 length-based selectivity baseline with 5 cubic-spline nodes | LBS base N5 | 12a LBS base N5 | `12a-lbs-base` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12b-LBS-N3` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12b | length-based selectivity with 3 cubic-spline nodes | LBS N3 | 12b LBS N3 | `12b-lbs-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12c-LBS-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12c | length-based selectivity with 4 cubic-spline nodes | LBS N4 | 12c LBS N4 | `12c-lbs-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12d-LBS-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12d | length-based selectivity with 6 cubic-spline nodes | LBS N6 | 12d LBS N6 | `12d-lbs-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12e-LBS-IDXmono-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12e | baseline 5-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N5 | 12e LBS IDXmono N5 | `12e-lbs-idxmono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12f-LBS-IDXmono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12f | 4-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N4 | 12f LBS IDXmono N4 | `12f-lbs-idxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12g-LBS-IDXmono-N3` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12g | 3-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N3 | 12g LBS IDXmono N3 | `12g-lbs-idxmono-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12h-LBS-LLmono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12h | 4-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N4 | 12h LBS LLmono N4 | `12h-lbs-llmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12i-LBS-LLIDXmono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12i | 4-node length-based selectivity with non-decreasing longline and index selectivity | LBS LL+IDXmono N4 | 12i LBS LL+IDXmono N4 | `12i-lbs-llidxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12j-LBS-LLIDXmono-N3` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12j | 3-node length-based selectivity with non-decreasing longline and index selectivity | LBS LL+IDXmono N3 | 12j LBS LL+IDXmono N3 | `12j-lbs-llidxmono-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12k-LBS-LLIDXmono-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12k | baseline 5-node length-based selectivity with non-decreasing longline and index selectivity | LBS LL+IDXmono N5 | 12k LBS LL+IDXmono N5 | `12k-lbs-llidxmono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12l-LBS-LLIDXsoft-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12l | 4-node non-decreasing longline/index selectivity with a softer monotone penalty | LBS LL+IDX soft mono N4 | 12l LBS LL+IDX soft mono N4 | `12l-lbs-llidxsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12m-LBS-LLIDXvsoft-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12m | 4-node non-decreasing longline/index selectivity with a very soft monotone penalty | LBS LL+IDX very soft mono N4 | 12m LBS LL+IDX very soft mono N4 | `12m-lbs-llidxvsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12n-LBS-NoDome-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12n | 4-node length-based selectivity with Step 12 dome/terminal-zero constraints removed | LBS no dome N4 | 12n LBS no dome N4 | `12n-lbs-nodome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12o-LBS-RelaxLowDome-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12o | 4-node length-based selectivity with low terminal-zero cutoffs relaxed | LBS relax low dome N4 | 12o LBS relax low dome N4 | `12o-lbs-relax-low-dome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12p-LBS-RelaxDOMPL-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12p | 4-node length-based selectivity with DOM/PL terminal-zero cutoffs relaxed | LBS relax DOM/PL N4 | 12p LBS relax DOM/PL N4 | `12p-lbs-relax-dompl-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12q-LBS-RelaxPS-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12q | 4-node length-based selectivity with PS and JP terminal-zero cutoffs relaxed | LBS relax PS N4 | 12q LBS relax PS N4 | `12q-lbs-relax-ps-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12r-LBS-DomeMid-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12r | 4-node length-based selectivity with a common mid terminal-zero cutoff | LBS dome mid N4 | 12r LBS dome mid N4 | `12r-lbs-dome-mid-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12s-LBS-NoLowDome-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12s | 4-node length-based selectivity with low dome constraints removed and index monotone | LBS no low dome + IDX N4 | 12s LBS no low dome + IDX N4 | `12s-lbs-no-low-dome-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12t-LBS-YoungZero-PSPLDOM-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12t | 4-node length-based selectivity with age-1 zero selectivity for PS/PL/DOM gears | LBS young-zero PS/PL/DOM N4 | 12t LBS young-zero PS/PL/DOM N4 | `12t-lbs-youngzero-pspldom-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12u-LBS-IDXyoungzero-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12u | 4-node length-based selectivity with monotone index selectivity and young-index zero selectivity | LBS IDX young-zero N4 | 12u LBS IDX young-zero N4 | `12u-lbs-idx-youngzero-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12v-LBS-HL75-3-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12v | 4-node length-based selectivity with HL young-zero age count relaxed | LBS HL75 3 N4 | 12v LBS HL75 3 N4 | `12v-lbs-hl75-3-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12w-LBS-LL75-1-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12w | 4-node length-based selectivity with LL young-zero age count relaxed | LBS LL75 1 N4 | 12w LBS LL75 1 N4 | `12w-lbs-ll75-1-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12x-LBS-Bound359-1000-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12x | 4-node length-based selectivity with spline lower-bound penalty 359 = 1000 | LBS bound359 1000 N4 | 12x LBS bound359 1000 N4 | `12x-lbs-bound359-1000-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12y-LBS-Bound359-10000-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12y | 4-node length-based selectivity with spline lower-bound penalty 359 = 10000 | LBS bound359 10000 N4 | 12y LBS bound359 10000 N4 | `12y-lbs-bound359-10000-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12z-LBS-N7` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12z | length-based selectivity with 7 cubic-spline nodes | LBS N7 | 12z LBS N7 | `12z-lbs-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12aa-LBS-Bound359-1000-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12aa | 5-node length-based selectivity with weak spline lower-bound penalty | LBS bound359 1000 N5 | 12aa LBS bound359 1000 N5 | `12aa-lbs-bound359-1000-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ab-LBS-Bound359-10000-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ab | 5-node length-based selectivity with stronger spline lower-bound penalty | LBS bound359 10000 N5 | 12ab LBS bound359 10000 N5 | `12ab-lbs-bound359-10000-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ac-LBS-Bound359-1000-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ac | 6-node length-based selectivity with weak spline lower-bound penalty | LBS bound359 1000 N6 | 12ac LBS bound359 1000 N6 | `12ac-lbs-bound359-1000-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ad-LBS-Bound359-10000-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ad | 6-node length-based selectivity with stronger spline lower-bound penalty | LBS bound359 10000 N6 | 12ad LBS bound359 10000 N6 | `12ad-lbs-bound359-10000-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ae-LBS-IDXmono-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ae | 6-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N6 | 12ae LBS IDXmono N6 | `12ae-lbs-idxmono-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12af-LBS-IDXmono-N7` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12af | 7-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N7 | 12af LBS IDXmono N7 | `12af-lbs-idxmono-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ag-LBS-IDXsoft-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ag | 5-node index non-decreasing selectivity with softer penalty | LBS IDX soft mono N5 | 12ag LBS IDX soft mono N5 | `12ag-lbs-idxsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ah-LBS-IDXvsoft-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ah | 5-node index non-decreasing selectivity with very soft penalty | LBS IDX very soft mono N5 | 12ah LBS IDX very soft mono N5 | `12ah-lbs-idxvsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ai-LBS-IDX75-1-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ai | 4-node index non-decreasing selectivity with one young age set to zero | LBS IDX75 1 N4 | 12ai LBS IDX75 1 N4 | `12ai-lbs-idx75-1-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12aj-LBS-IDX75-3-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12aj | 4-node index non-decreasing selectivity with three young ages set to zero | LBS IDX75 3 N4 | 12aj LBS IDX75 3 N4 | `12aj-lbs-idx75-3-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ak-LBS-LLmono-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ak | 5-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N5 | 12ak LBS LLmono N5 | `12ak-lbs-llmono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12al-LBS-LLmono-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12al | 6-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N6 | 12al LBS LLmono N6 | `12al-lbs-llmono-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12am-LBS-LLcoreMono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12am | 4-node non-decreasing selectivity for core adult longline fisheries | LBS LL core mono N4 | 12am LBS LL core mono N4 | `12am-lbs-llcoremono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12an-LBS-LLcoreMono-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12an | 5-node non-decreasing selectivity for core adult longline fisheries | LBS LL core mono N5 | 12an LBS LL core mono N5 | `12an-lbs-llcoremono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ao-LBS-LLrecentMono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ao | 4-node non-decreasing selectivity for later longline fishery groups | LBS LL recent mono N4 | 12ao LBS LL recent mono N4 | `12ao-lbs-llrecentmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ap-LBS-LLOSmono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ap | 4-node non-decreasing selectivity for oceanic longline groups | LBS LL OS mono N4 | 12ap LBS LL OS mono N4 | `12ap-lbs-llosmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12aq-LBS-LL75-0-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12aq | 4-node length-based selectivity with inherited longline young-zero settings removed | LBS LL75 0 N4 | 12aq LBS LL75 0 N4 | `12aq-lbs-ll75-0-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ar-LBS-LL75-3-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ar | 4-node length-based selectivity with stronger longline young-zero settings | LBS LL75 3 N4 | 12ar LBS LL75 3 N4 | `12ar-lbs-ll75-3-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12as-LBS-HL75-4-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12as | 4-node length-based selectivity with moderately relaxed HL young-zero age count | LBS HL75 4 N4 | 12as LBS HL75 4 N4 | `12as-lbs-hl75-4-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12at-LBS-HL75-2-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12at | 4-node length-based selectivity with strongly relaxed HL young-zero age count | LBS HL75 2 N4 | 12at LBS HL75 2 N4 | `12at-lbs-hl75-2-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12au-LBS-LLIDXmono-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12au | 6-node non-decreasing longline and index selectivity | LBS LL+IDXmono N6 | 12au LBS LL+IDXmono N6 | `12au-lbs-llidxmono-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12av-LBS-LLIDXmono-N7` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12av | 7-node non-decreasing longline and index selectivity | LBS LL+IDXmono N7 | 12av LBS LL+IDXmono N7 | `12av-lbs-llidxmono-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12aw-LBS-LLIDXsoft-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12aw | 5-node non-decreasing longline/index selectivity with softer penalty | LBS LL+IDX soft mono N5 | 12aw LBS LL+IDX soft mono N5 | `12aw-lbs-llidxsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ax-LBS-LLIDXvsoft-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ax | 5-node non-decreasing longline/index selectivity with very soft penalty | LBS LL+IDX very soft mono N5 | 12ax LBS LL+IDX very soft mono N5 | `12ax-lbs-llidxvsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ay-LBS-LLIDXmidsoft-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ay | 4-node non-decreasing longline/index selectivity with intermediate penalty | LBS LL+IDX mid-soft mono N4 | 12ay LBS LL+IDX mid-soft mono N4 | `12ay-lbs-llidxmidsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12az-LBS-LLIDXmidvsoft-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12az | 4-node non-decreasing longline/index selectivity with mid very-soft penalty | LBS LL+IDX mid-very-soft mono N4 | 12az LBS LL+IDX mid-very-soft mono N4 | `12az-lbs-llidxmidvsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ba-LBS-LLcoreIDXmono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ba | 4-node non-decreasing core longline and index selectivity | LBS LL core + IDXmono N4 | 12ba LBS LL core + IDXmono N4 | `12ba-lbs-llcoreidxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bb-LBS-LLOSIDXmono-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bb | 4-node non-decreasing oceanic longline and index selectivity | LBS LL OS + IDXmono N4 | 12bb LBS LL OS + IDXmono N4 | `12bb-lbs-llosidxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bc-LBS-PSdome20-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bc | 4-node length-based selectivity with main purse-seine dome cutoffs set to 20 | LBS PS dome20 N4 | 12bc LBS PS dome20 N4 | `12bc-lbs-psdome20-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bd-LBS-PSdome35-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bd | 4-node length-based selectivity with main purse-seine dome cutoffs set to 35 | LBS PS dome35 N4 | 12bd LBS PS dome35 N4 | `12bd-lbs-psdome35-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12be-LBS-DOMPLdome15-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12be | 4-node length-based selectivity with DOM/PL cutoffs set to 15 | LBS DOM/PL dome15 N4 | 12be LBS DOM/PL dome15 N4 | `12be-lbs-dompldome15-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bf-LBS-DOMPLdome25-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bf | 4-node length-based selectivity with DOM/PL cutoffs set to 25 | LBS DOM/PL dome25 N4 | 12bf LBS DOM/PL dome25 N4 | `12bf-lbs-dompldome25-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bg-LBS-NoPSDome-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bg | 4-node length-based selectivity with PS/JP dome constraints removed | LBS no PS dome N4 | 12bg LBS no PS dome N4 | `12bg-lbs-no-ps-dome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bh-LBS-NoDOMPLDome-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bh | 4-node length-based selectivity with DOM/PL dome constraints removed | LBS no DOM/PL dome N4 | 12bh LBS no DOM/PL dome N4 | `12bh-lbs-no-dompl-dome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bi-LBS-Surface75-2-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bi | 4-node length-based selectivity with two young ages set to zero for surface/small-fish gears | LBS surface75 2 N4 | 12bi LBS surface75 2 N4 | `12bi-lbs-surface75-2-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bj-LBS-LLIDXsoft-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bj | 6-node non-decreasing longline/index selectivity with softer penalty | LBS LL+IDX soft mono N6 | 12bj LBS LL+IDX soft mono N6 | `12bj-lbs-llidxsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bk-LBS-LLIDXvsoft-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bk | 6-node non-decreasing longline/index selectivity with very soft penalty | LBS LL+IDX very soft mono N6 | 12bk LBS LL+IDX very soft mono N6 | `12bk-lbs-llidxvsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bl-LBS-LLIDXsoft-N3` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bl | 3-node non-decreasing longline/index selectivity with softer penalty | LBS LL+IDX soft mono N3 | 12bl LBS LL+IDX soft mono N3 | `12bl-lbs-llidxsoft-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bm-LBS-LLIDXvsoft-N3` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bm | 3-node non-decreasing longline/index selectivity with very soft penalty | LBS LL+IDX very soft mono N3 | 12bm LBS LL+IDX very soft mono N3 | `12bm-lbs-llidxvsoft-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bn-LBS-IDXsoft-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bn | 4-node index non-decreasing selectivity with softer penalty | LBS IDX soft mono N4 | 12bn LBS IDX soft mono N4 | `12bn-lbs-idxsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bo-LBS-IDXvsoft-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bo | 4-node index non-decreasing selectivity with very soft penalty | LBS IDX very soft mono N4 | 12bo LBS IDX very soft mono N4 | `12bo-lbs-idxvsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bp-LBS-IDXsoft-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bp | 6-node index non-decreasing selectivity with softer penalty | LBS IDX soft mono N6 | 12bp LBS IDX soft mono N6 | `12bp-lbs-idxsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bq-LBS-IDXvsoft-N6` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bq | 6-node index non-decreasing selectivity with very soft penalty | LBS IDX very soft mono N6 | 12bq LBS IDX very soft mono N6 | `12bq-lbs-idxvsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12br-LBS-LLmono-N3` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12br | 3-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N3 | 12br LBS LLmono N3 | `12br-lbs-llmono-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bs-LBS-LLmono-N7` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bs | 7-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N7 | 12bs LBS LLmono N7 | `12bs-lbs-llmono-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bt-LBS-Bound359-1000-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bt | 4-node adult/index monotone selectivity with weak spline lower-bound penalty | LBS bound359 1000 LL+IDX N4 | 12bt LBS bound359 1000 LL+IDX N4 | `12bt-lbs-bound359-1000-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bu-LBS-Bound359-10000-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bu | 4-node adult/index monotone selectivity with stronger spline lower-bound penalty | LBS bound359 10000 LL+IDX N4 | 12bu LBS bound359 10000 LL+IDX N4 | `12bu-lbs-bound359-10000-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bv-LBS-Bound359-1000-LLIDX-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bv | 5-node adult/index monotone selectivity with weak spline lower-bound penalty | LBS bound359 1000 LL+IDX N5 | 12bv LBS bound359 1000 LL+IDX N5 | `12bv-lbs-bound359-1000-llidx-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bw-LBS-Bound359-10000-LLIDX-N5` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bw | 5-node adult/index monotone selectivity with stronger spline lower-bound penalty | LBS bound359 10000 LL+IDX N5 | 12bw LBS bound359 10000 LL+IDX N5 | `12bw-lbs-bound359-10000-llidx-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bx-LBS-Bound359-1000-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bx | 4-node index monotone selectivity with weak spline lower-bound penalty | LBS bound359 1000 IDX N4 | 12bx LBS bound359 1000 IDX N4 | `12bx-lbs-bound359-1000-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12by-LBS-Bound359-10000-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12by | 4-node index monotone selectivity with stronger spline lower-bound penalty | LBS bound359 10000 IDX N4 | 12by LBS bound359 10000 IDX N4 | `12by-lbs-bound359-10000-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12bz-LBS-NoPSDome-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12bz | 4-node selectivity with PS/JP dome constraints removed and index monotone | LBS no PS dome + IDX N4 | 12bz LBS no PS dome + IDX N4 | `12bz-lbs-no-ps-dome-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ca-LBS-NoDOMPLDome-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ca | 4-node selectivity with DOM/PL dome constraints removed and index monotone | LBS no DOM/PL dome + IDX N4 | 12ca LBS no DOM/PL dome + IDX N4 | `12ca-lbs-no-dompl-dome-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cb-LBS-PSdome20-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cb | 4-node selectivity with main PS dome cutoffs set to 20 and index monotone | LBS PS dome20 + IDX N4 | 12cb LBS PS dome20 + IDX N4 | `12cb-lbs-psdome20-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cc-LBS-PSdome35-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cc | 4-node selectivity with main PS dome cutoffs set to 35 and index monotone | LBS PS dome35 + IDX N4 | 12cc LBS PS dome35 + IDX N4 | `12cc-lbs-psdome35-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cd-LBS-DOMPLdome15-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cd | 4-node selectivity with DOM/PL cutoffs set to 15 and index monotone | LBS DOM/PL dome15 + IDX N4 | 12cd LBS DOM/PL dome15 + IDX N4 | `12cd-lbs-dompldome15-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ce-LBS-DOMPLdome25-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ce | 4-node selectivity with DOM/PL cutoffs set to 25 and index monotone | LBS DOM/PL dome25 + IDX N4 | 12ce LBS DOM/PL dome25 + IDX N4 | `12ce-lbs-dompldome25-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cf-LBS-NoDome-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cf | 4-node selectivity with all inherited dome constraints removed and adult/index monotone | LBS no dome + LL+IDX N4 | 12cf LBS no dome + LL+IDX N4 | `12cf-lbs-nodome-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cg-LBS-RelaxLowDome-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cg | 4-node selectivity with low terminal-zero cutoffs relaxed and adult/index monotone | LBS relax low dome + LL+IDX N4 | 12cg LBS relax low dome + LL+IDX N4 | `12cg-lbs-relax-low-dome-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ch-LBS-Surface75-2-IDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ch | 4-node selectivity with surface young-zero 2 and index monotone | LBS surface75 2 + IDX N4 | 12ch LBS surface75 2 + IDX N4 | `12ch-lbs-surface75-2-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ci-LBS-Surface75-2-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ci | 4-node selectivity with surface young-zero 2 and adult/index monotone | LBS surface75 2 + LL+IDX N4 | 12ci LBS surface75 2 + LL+IDX N4 | `12ci-lbs-surface75-2-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cj-LBS-LL75-0-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cj | 4-node selectivity with longline young-zero removed and adult/index monotone | LBS LL75 0 + LL+IDX N4 | 12cj LBS LL75 0 + LL+IDX N4 | `12cj-lbs-ll75-0-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12ck-LBS-LL75-1-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12ck | 4-node selectivity with LL young-zero age count relaxed and adult/index monotone | LBS LL75 1 + LL+IDX N4 | 12ck LBS LL75 1 + LL+IDX N4 | `12ck-lbs-ll75-1-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cl-LBS-LL75-3-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cl | 4-node selectivity with stronger LL young-zero settings and adult/index monotone | LBS LL75 3 + LL+IDX N4 | 12cl LBS LL75 3 + LL+IDX N4 | `12cl-lbs-ll75-3-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cm-LBS-HL75-2-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cm | 4-node selectivity with strongly relaxed HL young-zero count and adult/index monotone | LBS HL75 2 + LL+IDX N4 | 12cm LBS HL75 2 + LL+IDX N4 | `12cm-lbs-hl75-2-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cn-LBS-HL75-4-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cn | 4-node selectivity with moderately relaxed HL young-zero count and adult/index monotone | LBS HL75 4 + LL+IDX N4 | 12cn LBS HL75 4 + LL+IDX N4 | `12cn-lbs-hl75-4-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12co-LBS-IDX75-1-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12co | 4-node adult/index monotone selectivity with one young index age set to zero | LBS IDX75 1 + LL+IDX N4 | 12co LBS IDX75 1 + LL+IDX N4 | `12co-lbs-idx75-1-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cp-LBS-IDX75-2-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cp | 4-node adult/index monotone selectivity with two young index ages set to zero | LBS IDX75 2 + LL+IDX N4 | 12cp LBS IDX75 2 + LL+IDX N4 | `12cp-lbs-idx75-2-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `12cq-LBS-IDX75-3-LLIDX-N4` | `FALSE` | 12-LengthBasedSel-Sensitivity | 12cq | 4-node adult/index monotone selectivity with three young index ages set to zero | LBS IDX75 3 + LL+IDX N4 | 12cq LBS IDX75 3 + LL+IDX N4 | `12cq-lbs-idx75-3-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |


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
| `12-LengthBasedSel` | `steps/12-LengthBasedSel/model` | `exists` |
| `13-OrthogonalPoly` | `steps/13-OrthogonalPoly/model` | `exists` |
| `14-EffortCreep` | `steps/14-EffortCreep/model` | `exists` |
| `15-DataWeighting` | `steps/15-DataWeighting/model` | `exists` |
| `12a-LBS-Base` | `steps/12-LengthBasedSel/model` | `exists` |
| `12b-LBS-N3` | `steps/12-LengthBasedSel/model` | `exists` |
| `12c-LBS-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12d-LBS-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12e-LBS-IDXmono-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12f-LBS-IDXmono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12g-LBS-IDXmono-N3` | `steps/12-LengthBasedSel/model` | `exists` |
| `12h-LBS-LLmono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12i-LBS-LLIDXmono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12j-LBS-LLIDXmono-N3` | `steps/12-LengthBasedSel/model` | `exists` |
| `12k-LBS-LLIDXmono-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12l-LBS-LLIDXsoft-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12m-LBS-LLIDXvsoft-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12n-LBS-NoDome-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12o-LBS-RelaxLowDome-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12p-LBS-RelaxDOMPL-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12q-LBS-RelaxPS-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12r-LBS-DomeMid-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12s-LBS-NoLowDome-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12t-LBS-YoungZero-PSPLDOM-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12u-LBS-IDXyoungzero-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12v-LBS-HL75-3-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12w-LBS-LL75-1-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12x-LBS-Bound359-1000-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12y-LBS-Bound359-10000-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12z-LBS-N7` | `steps/12-LengthBasedSel/model` | `exists` |
| `12aa-LBS-Bound359-1000-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ab-LBS-Bound359-10000-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ac-LBS-Bound359-1000-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ad-LBS-Bound359-10000-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ae-LBS-IDXmono-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12af-LBS-IDXmono-N7` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ag-LBS-IDXsoft-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ah-LBS-IDXvsoft-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ai-LBS-IDX75-1-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12aj-LBS-IDX75-3-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ak-LBS-LLmono-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12al-LBS-LLmono-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12am-LBS-LLcoreMono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12an-LBS-LLcoreMono-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ao-LBS-LLrecentMono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ap-LBS-LLOSmono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12aq-LBS-LL75-0-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ar-LBS-LL75-3-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12as-LBS-HL75-4-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12at-LBS-HL75-2-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12au-LBS-LLIDXmono-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12av-LBS-LLIDXmono-N7` | `steps/12-LengthBasedSel/model` | `exists` |
| `12aw-LBS-LLIDXsoft-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ax-LBS-LLIDXvsoft-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ay-LBS-LLIDXmidsoft-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12az-LBS-LLIDXmidvsoft-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ba-LBS-LLcoreIDXmono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bb-LBS-LLOSIDXmono-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bc-LBS-PSdome20-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bd-LBS-PSdome35-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12be-LBS-DOMPLdome15-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bf-LBS-DOMPLdome25-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bg-LBS-NoPSDome-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bh-LBS-NoDOMPLDome-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bi-LBS-Surface75-2-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bj-LBS-LLIDXsoft-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bk-LBS-LLIDXvsoft-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bl-LBS-LLIDXsoft-N3` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bm-LBS-LLIDXvsoft-N3` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bn-LBS-IDXsoft-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bo-LBS-IDXvsoft-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bp-LBS-IDXsoft-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bq-LBS-IDXvsoft-N6` | `steps/12-LengthBasedSel/model` | `exists` |
| `12br-LBS-LLmono-N3` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bs-LBS-LLmono-N7` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bt-LBS-Bound359-1000-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bu-LBS-Bound359-10000-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bv-LBS-Bound359-1000-LLIDX-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bw-LBS-Bound359-10000-LLIDX-N5` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bx-LBS-Bound359-1000-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12by-LBS-Bound359-10000-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12bz-LBS-NoPSDome-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ca-LBS-NoDOMPLDome-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cb-LBS-PSdome20-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cc-LBS-PSdome35-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cd-LBS-DOMPLdome15-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ce-LBS-DOMPLdome25-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cf-LBS-NoDome-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cg-LBS-RelaxLowDome-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ch-LBS-Surface75-2-IDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ci-LBS-Surface75-2-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cj-LBS-LL75-0-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12ck-LBS-LL75-1-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cl-LBS-LL75-3-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cm-LBS-HL75-2-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cn-LBS-HL75-4-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12co-LBS-IDX75-1-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cp-LBS-IDX75-2-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |
| `12cq-LBS-IDX75-3-LLIDX-N4` | `steps/12-LengthBasedSel/model` | `exists` |


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
