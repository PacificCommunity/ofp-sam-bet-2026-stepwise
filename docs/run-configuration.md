# Run Configuration

This file keeps the operational Kflow/local-run details out of the root README.

## Current Defaults

<!-- This section is generated from job-config.R. It is refreshed by Makefile targets and the local pre-commit hook once a Makefile target has run. -->

| `setting` | `value` | `meaning` |
| --- | --- | --- |
| `default_step_select` | `13c-LBS-N4` | Model selection used when `STEP_SELECT` is not supplied. |
| `flow_group` | `bet-2026-lbs-sens` | Kflow group label used to connect stepwise, results, and report jobs. |
| `trigger_next` | `true` | Whether command-line Kflow submissions keep the downstream results/report chain. |
| `docker_image` | `ghcr.io/pacificcommunity/tuna-flow:v2.1` | Docker image used by Kflow and local Docker runs. |
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
| `13z-LBS-N7` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13z | length-based selectivity with 7 cubic-spline nodes | LBS N7 | 13z LBS N7 | `13z-lbs-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13aa-LBS-Bound359-1000-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13aa | 5-node length-based selectivity with weak spline lower-bound penalty | LBS bound359 1000 N5 | 13aa LBS bound359 1000 N5 | `13aa-lbs-bound359-1000-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ab-LBS-Bound359-10000-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ab | 5-node length-based selectivity with stronger spline lower-bound penalty | LBS bound359 10000 N5 | 13ab LBS bound359 10000 N5 | `13ab-lbs-bound359-10000-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ac-LBS-Bound359-1000-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ac | 6-node length-based selectivity with weak spline lower-bound penalty | LBS bound359 1000 N6 | 13ac LBS bound359 1000 N6 | `13ac-lbs-bound359-1000-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ad-LBS-Bound359-10000-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ad | 6-node length-based selectivity with stronger spline lower-bound penalty | LBS bound359 10000 N6 | 13ad LBS bound359 10000 N6 | `13ad-lbs-bound359-10000-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ae-LBS-IDXmono-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ae | 6-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N6 | 13ae LBS IDXmono N6 | `13ae-lbs-idxmono-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13af-LBS-IDXmono-N7` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13af | 7-node length-based selectivity with non-decreasing index selectivity | LBS IDXmono N7 | 13af LBS IDXmono N7 | `13af-lbs-idxmono-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ag-LBS-IDXsoft-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ag | 5-node index non-decreasing selectivity with softer penalty | LBS IDX soft mono N5 | 13ag LBS IDX soft mono N5 | `13ag-lbs-idxsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ah-LBS-IDXvsoft-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ah | 5-node index non-decreasing selectivity with very soft penalty | LBS IDX very soft mono N5 | 13ah LBS IDX very soft mono N5 | `13ah-lbs-idxvsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ai-LBS-IDX75-1-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ai | 4-node index non-decreasing selectivity with one young age set to zero | LBS IDX75 1 N4 | 13ai LBS IDX75 1 N4 | `13ai-lbs-idx75-1-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13aj-LBS-IDX75-3-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13aj | 4-node index non-decreasing selectivity with three young ages set to zero | LBS IDX75 3 N4 | 13aj LBS IDX75 3 N4 | `13aj-lbs-idx75-3-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ak-LBS-LLmono-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ak | 5-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N5 | 13ak LBS LLmono N5 | `13ak-lbs-llmono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13al-LBS-LLmono-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13al | 6-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N6 | 13al LBS LLmono N6 | `13al-lbs-llmono-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13am-LBS-LLcoreMono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13am | 4-node non-decreasing selectivity for core adult longline fisheries | LBS LL core mono N4 | 13am LBS LL core mono N4 | `13am-lbs-llcoremono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13an-LBS-LLcoreMono-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13an | 5-node non-decreasing selectivity for core adult longline fisheries | LBS LL core mono N5 | 13an LBS LL core mono N5 | `13an-lbs-llcoremono-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ao-LBS-LLrecentMono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ao | 4-node non-decreasing selectivity for later longline fishery groups | LBS LL recent mono N4 | 13ao LBS LL recent mono N4 | `13ao-lbs-llrecentmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ap-LBS-LLOSmono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ap | 4-node non-decreasing selectivity for oceanic longline groups | LBS LL OS mono N4 | 13ap LBS LL OS mono N4 | `13ap-lbs-llosmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13aq-LBS-LL75-0-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13aq | 4-node length-based selectivity with inherited longline young-zero settings removed | LBS LL75 0 N4 | 13aq LBS LL75 0 N4 | `13aq-lbs-ll75-0-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ar-LBS-LL75-3-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ar | 4-node length-based selectivity with stronger longline young-zero settings | LBS LL75 3 N4 | 13ar LBS LL75 3 N4 | `13ar-lbs-ll75-3-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13as-LBS-HL75-4-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13as | 4-node length-based selectivity with moderately relaxed HL young-zero age count | LBS HL75 4 N4 | 13as LBS HL75 4 N4 | `13as-lbs-hl75-4-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13at-LBS-HL75-2-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13at | 4-node length-based selectivity with strongly relaxed HL young-zero age count | LBS HL75 2 N4 | 13at LBS HL75 2 N4 | `13at-lbs-hl75-2-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13au-LBS-LLIDXmono-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13au | 6-node non-decreasing longline and index selectivity | LBS LL+IDXmono N6 | 13au LBS LL+IDXmono N6 | `13au-lbs-llidxmono-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13av-LBS-LLIDXmono-N7` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13av | 7-node non-decreasing longline and index selectivity | LBS LL+IDXmono N7 | 13av LBS LL+IDXmono N7 | `13av-lbs-llidxmono-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13aw-LBS-LLIDXsoft-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13aw | 5-node non-decreasing longline/index selectivity with softer penalty | LBS LL+IDX soft mono N5 | 13aw LBS LL+IDX soft mono N5 | `13aw-lbs-llidxsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ax-LBS-LLIDXvsoft-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ax | 5-node non-decreasing longline/index selectivity with very soft penalty | LBS LL+IDX very soft mono N5 | 13ax LBS LL+IDX very soft mono N5 | `13ax-lbs-llidxvsoft-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ay-LBS-LLIDXmidsoft-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ay | 4-node non-decreasing longline/index selectivity with intermediate penalty | LBS LL+IDX mid-soft mono N4 | 13ay LBS LL+IDX mid-soft mono N4 | `13ay-lbs-llidxmidsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13az-LBS-LLIDXmidvsoft-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13az | 4-node non-decreasing longline/index selectivity with mid very-soft penalty | LBS LL+IDX mid-very-soft mono N4 | 13az LBS LL+IDX mid-very-soft mono N4 | `13az-lbs-llidxmidvsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ba-LBS-LLcoreIDXmono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ba | 4-node non-decreasing core longline and index selectivity | LBS LL core + IDXmono N4 | 13ba LBS LL core + IDXmono N4 | `13ba-lbs-llcoreidxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bb-LBS-LLOSIDXmono-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bb | 4-node non-decreasing oceanic longline and index selectivity | LBS LL OS + IDXmono N4 | 13bb LBS LL OS + IDXmono N4 | `13bb-lbs-llosidxmono-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bc-LBS-PSdome20-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bc | 4-node length-based selectivity with main purse-seine dome cutoffs set to 20 | LBS PS dome20 N4 | 13bc LBS PS dome20 N4 | `13bc-lbs-psdome20-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bd-LBS-PSdome35-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bd | 4-node length-based selectivity with main purse-seine dome cutoffs set to 35 | LBS PS dome35 N4 | 13bd LBS PS dome35 N4 | `13bd-lbs-psdome35-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13be-LBS-DOMPLdome15-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13be | 4-node length-based selectivity with DOM/PL cutoffs set to 15 | LBS DOM/PL dome15 N4 | 13be LBS DOM/PL dome15 N4 | `13be-lbs-dompldome15-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bf-LBS-DOMPLdome25-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bf | 4-node length-based selectivity with DOM/PL cutoffs set to 25 | LBS DOM/PL dome25 N4 | 13bf LBS DOM/PL dome25 N4 | `13bf-lbs-dompldome25-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bg-LBS-NoPSDome-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bg | 4-node length-based selectivity with PS/JP dome constraints removed | LBS no PS dome N4 | 13bg LBS no PS dome N4 | `13bg-lbs-no-ps-dome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bh-LBS-NoDOMPLDome-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bh | 4-node length-based selectivity with DOM/PL dome constraints removed | LBS no DOM/PL dome N4 | 13bh LBS no DOM/PL dome N4 | `13bh-lbs-no-dompl-dome-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bi-LBS-Surface75-2-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bi | 4-node length-based selectivity with two young ages set to zero for surface/small-fish gears | LBS surface75 2 N4 | 13bi LBS surface75 2 N4 | `13bi-lbs-surface75-2-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bj-LBS-LLIDXsoft-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bj | 6-node non-decreasing longline/index selectivity with softer penalty | LBS LL+IDX soft mono N6 | 13bj LBS LL+IDX soft mono N6 | `13bj-lbs-llidxsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bk-LBS-LLIDXvsoft-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bk | 6-node non-decreasing longline/index selectivity with very soft penalty | LBS LL+IDX very soft mono N6 | 13bk LBS LL+IDX very soft mono N6 | `13bk-lbs-llidxvsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bl-LBS-LLIDXsoft-N3` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bl | 3-node non-decreasing longline/index selectivity with softer penalty | LBS LL+IDX soft mono N3 | 13bl LBS LL+IDX soft mono N3 | `13bl-lbs-llidxsoft-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bm-LBS-LLIDXvsoft-N3` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bm | 3-node non-decreasing longline/index selectivity with very soft penalty | LBS LL+IDX very soft mono N3 | 13bm LBS LL+IDX very soft mono N3 | `13bm-lbs-llidxvsoft-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bn-LBS-IDXsoft-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bn | 4-node index non-decreasing selectivity with softer penalty | LBS IDX soft mono N4 | 13bn LBS IDX soft mono N4 | `13bn-lbs-idxsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bo-LBS-IDXvsoft-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bo | 4-node index non-decreasing selectivity with very soft penalty | LBS IDX very soft mono N4 | 13bo LBS IDX very soft mono N4 | `13bo-lbs-idxvsoft-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bp-LBS-IDXsoft-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bp | 6-node index non-decreasing selectivity with softer penalty | LBS IDX soft mono N6 | 13bp LBS IDX soft mono N6 | `13bp-lbs-idxsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bq-LBS-IDXvsoft-N6` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bq | 6-node index non-decreasing selectivity with very soft penalty | LBS IDX very soft mono N6 | 13bq LBS IDX very soft mono N6 | `13bq-lbs-idxvsoft-n6` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13br-LBS-LLmono-N3` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13br | 3-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N3 | 13br LBS LLmono N3 | `13br-lbs-llmono-n3` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bs-LBS-LLmono-N7` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bs | 7-node length-based selectivity with non-decreasing longline selectivity | LBS LLmono N7 | 13bs LBS LLmono N7 | `13bs-lbs-llmono-n7` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bt-LBS-Bound359-1000-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bt | 4-node adult/index monotone selectivity with weak spline lower-bound penalty | LBS bound359 1000 LL+IDX N4 | 13bt LBS bound359 1000 LL+IDX N4 | `13bt-lbs-bound359-1000-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bu-LBS-Bound359-10000-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bu | 4-node adult/index monotone selectivity with stronger spline lower-bound penalty | LBS bound359 10000 LL+IDX N4 | 13bu LBS bound359 10000 LL+IDX N4 | `13bu-lbs-bound359-10000-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bv-LBS-Bound359-1000-LLIDX-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bv | 5-node adult/index monotone selectivity with weak spline lower-bound penalty | LBS bound359 1000 LL+IDX N5 | 13bv LBS bound359 1000 LL+IDX N5 | `13bv-lbs-bound359-1000-llidx-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bw-LBS-Bound359-10000-LLIDX-N5` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bw | 5-node adult/index monotone selectivity with stronger spline lower-bound penalty | LBS bound359 10000 LL+IDX N5 | 13bw LBS bound359 10000 LL+IDX N5 | `13bw-lbs-bound359-10000-llidx-n5` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bx-LBS-Bound359-1000-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bx | 4-node index monotone selectivity with weak spline lower-bound penalty | LBS bound359 1000 IDX N4 | 13bx LBS bound359 1000 IDX N4 | `13bx-lbs-bound359-1000-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13by-LBS-Bound359-10000-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13by | 4-node index monotone selectivity with stronger spline lower-bound penalty | LBS bound359 10000 IDX N4 | 13by LBS bound359 10000 IDX N4 | `13by-lbs-bound359-10000-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13bz-LBS-NoPSDome-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13bz | 4-node selectivity with PS/JP dome constraints removed and index monotone | LBS no PS dome + IDX N4 | 13bz LBS no PS dome + IDX N4 | `13bz-lbs-no-ps-dome-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ca-LBS-NoDOMPLDome-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ca | 4-node selectivity with DOM/PL dome constraints removed and index monotone | LBS no DOM/PL dome + IDX N4 | 13ca LBS no DOM/PL dome + IDX N4 | `13ca-lbs-no-dompl-dome-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cb-LBS-PSdome20-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cb | 4-node selectivity with main PS dome cutoffs set to 20 and index monotone | LBS PS dome20 + IDX N4 | 13cb LBS PS dome20 + IDX N4 | `13cb-lbs-psdome20-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cc-LBS-PSdome35-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cc | 4-node selectivity with main PS dome cutoffs set to 35 and index monotone | LBS PS dome35 + IDX N4 | 13cc LBS PS dome35 + IDX N4 | `13cc-lbs-psdome35-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cd-LBS-DOMPLdome15-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cd | 4-node selectivity with DOM/PL cutoffs set to 15 and index monotone | LBS DOM/PL dome15 + IDX N4 | 13cd LBS DOM/PL dome15 + IDX N4 | `13cd-lbs-dompldome15-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ce-LBS-DOMPLdome25-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ce | 4-node selectivity with DOM/PL cutoffs set to 25 and index monotone | LBS DOM/PL dome25 + IDX N4 | 13ce LBS DOM/PL dome25 + IDX N4 | `13ce-lbs-dompldome25-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cf-LBS-NoDome-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cf | 4-node selectivity with all inherited dome constraints removed and adult/index monotone | LBS no dome + LL+IDX N4 | 13cf LBS no dome + LL+IDX N4 | `13cf-lbs-nodome-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cg-LBS-RelaxLowDome-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cg | 4-node selectivity with low terminal-zero cutoffs relaxed and adult/index monotone | LBS relax low dome + LL+IDX N4 | 13cg LBS relax low dome + LL+IDX N4 | `13cg-lbs-relax-low-dome-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ch-LBS-Surface75-2-IDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ch | 4-node selectivity with surface young-zero 2 and index monotone | LBS surface75 2 + IDX N4 | 13ch LBS surface75 2 + IDX N4 | `13ch-lbs-surface75-2-idx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ci-LBS-Surface75-2-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ci | 4-node selectivity with surface young-zero 2 and adult/index monotone | LBS surface75 2 + LL+IDX N4 | 13ci LBS surface75 2 + LL+IDX N4 | `13ci-lbs-surface75-2-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cj-LBS-LL75-0-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cj | 4-node selectivity with longline young-zero removed and adult/index monotone | LBS LL75 0 + LL+IDX N4 | 13cj LBS LL75 0 + LL+IDX N4 | `13cj-lbs-ll75-0-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13ck-LBS-LL75-1-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13ck | 4-node selectivity with LL young-zero age count relaxed and adult/index monotone | LBS LL75 1 + LL+IDX N4 | 13ck LBS LL75 1 + LL+IDX N4 | `13ck-lbs-ll75-1-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cl-LBS-LL75-3-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cl | 4-node selectivity with stronger LL young-zero settings and adult/index monotone | LBS LL75 3 + LL+IDX N4 | 13cl LBS LL75 3 + LL+IDX N4 | `13cl-lbs-ll75-3-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cm-LBS-HL75-2-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cm | 4-node selectivity with strongly relaxed HL young-zero count and adult/index monotone | LBS HL75 2 + LL+IDX N4 | 13cm LBS HL75 2 + LL+IDX N4 | `13cm-lbs-hl75-2-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cn-LBS-HL75-4-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cn | 4-node selectivity with moderately relaxed HL young-zero count and adult/index monotone | LBS HL75 4 + LL+IDX N4 | 13cn LBS HL75 4 + LL+IDX N4 | `13cn-lbs-hl75-4-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13co-LBS-IDX75-1-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13co | 4-node adult/index monotone selectivity with one young index age set to zero | LBS IDX75 1 + LL+IDX N4 | 13co LBS IDX75 1 + LL+IDX N4 | `13co-lbs-idx75-1-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cp-LBS-IDX75-2-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cp | 4-node adult/index monotone selectivity with two young index ages set to zero | LBS IDX75 2 + LL+IDX N4 | 13cp LBS IDX75 2 + LL+IDX N4 | `13cp-lbs-idx75-2-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |
| `13cq-LBS-IDX75-3-LLIDX-N4` | `FALSE` | 13-LengthBasedSel-Sensitivity | 13cq | 4-node adult/index monotone selectivity with three young index ages set to zero | LBS IDX75 3 + LL+IDX N4 | 13cq LBS IDX75 3 + LL+IDX N4 | `13cq-lbs-idx75-3-llidx-n4` | `doitall` | blank | `blank` | `bet.frq` | `blank` |


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
| `13z-LBS-N7` | `steps/13-LengthBasedSel/model` | `exists` |
| `13aa-LBS-Bound359-1000-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ab-LBS-Bound359-10000-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ac-LBS-Bound359-1000-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ad-LBS-Bound359-10000-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ae-LBS-IDXmono-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13af-LBS-IDXmono-N7` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ag-LBS-IDXsoft-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ah-LBS-IDXvsoft-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ai-LBS-IDX75-1-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13aj-LBS-IDX75-3-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ak-LBS-LLmono-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13al-LBS-LLmono-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13am-LBS-LLcoreMono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13an-LBS-LLcoreMono-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ao-LBS-LLrecentMono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ap-LBS-LLOSmono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13aq-LBS-LL75-0-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ar-LBS-LL75-3-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13as-LBS-HL75-4-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13at-LBS-HL75-2-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13au-LBS-LLIDXmono-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13av-LBS-LLIDXmono-N7` | `steps/13-LengthBasedSel/model` | `exists` |
| `13aw-LBS-LLIDXsoft-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ax-LBS-LLIDXvsoft-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ay-LBS-LLIDXmidsoft-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13az-LBS-LLIDXmidvsoft-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ba-LBS-LLcoreIDXmono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bb-LBS-LLOSIDXmono-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bc-LBS-PSdome20-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bd-LBS-PSdome35-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13be-LBS-DOMPLdome15-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bf-LBS-DOMPLdome25-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bg-LBS-NoPSDome-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bh-LBS-NoDOMPLDome-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bi-LBS-Surface75-2-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bj-LBS-LLIDXsoft-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bk-LBS-LLIDXvsoft-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bl-LBS-LLIDXsoft-N3` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bm-LBS-LLIDXvsoft-N3` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bn-LBS-IDXsoft-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bo-LBS-IDXvsoft-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bp-LBS-IDXsoft-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bq-LBS-IDXvsoft-N6` | `steps/13-LengthBasedSel/model` | `exists` |
| `13br-LBS-LLmono-N3` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bs-LBS-LLmono-N7` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bt-LBS-Bound359-1000-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bu-LBS-Bound359-10000-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bv-LBS-Bound359-1000-LLIDX-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bw-LBS-Bound359-10000-LLIDX-N5` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bx-LBS-Bound359-1000-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13by-LBS-Bound359-10000-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13bz-LBS-NoPSDome-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ca-LBS-NoDOMPLDome-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cb-LBS-PSdome20-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cc-LBS-PSdome35-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cd-LBS-DOMPLdome15-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ce-LBS-DOMPLdome25-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cf-LBS-NoDome-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cg-LBS-RelaxLowDome-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ch-LBS-Surface75-2-IDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ci-LBS-Surface75-2-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cj-LBS-LL75-0-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13ck-LBS-LL75-1-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cl-LBS-LL75-3-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cm-LBS-HL75-2-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cn-LBS-HL75-4-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13co-LBS-IDX75-1-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cp-LBS-IDX75-2-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |
| `13cq-LBS-IDX75-3-LLIDX-N4` | `steps/13-LengthBasedSel/model` | `exists` |


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
