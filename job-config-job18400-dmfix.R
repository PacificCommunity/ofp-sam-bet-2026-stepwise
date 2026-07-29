## Continue the exact Job 18400 final PAR and fix the eight grouped
## length-composition DM concentration intercepts at their fitted upper-bound
## values. All other model controls remain unchanged.
stepwise_models <- data.frame(
  step_id = "F14-Y5-REC01",
  STEP_SELECT = "F14-Y5-REC01",
  enabled = TRUE,
  major_step = "Job18400DMFix",
  substep = "FinalPar-DM22Fixed",
  scientific_parent = "Job 18400",
  scientific_parent_mode = "par-input",
  independent_fit = FALSE,
  change_axis = paste(
    "Continue the checksum-verified Job 18400 final PAR.",
    "Set fish flag 69 to zero for every fishery, thereby fixing the eight",
    "grouped fish_pars(22) values at their Job 18400 estimates near 7,",
    "then re-optimise every remaining active parameter at MGC 1e-4."
  ),
  control_notes = paste(
    "Retain DM-noRE, Nmax=25, all fish flag 68 groups, estimation of",
    "fish_pars(23) through flag 89, fixed M, common estimated tag tau,",
    "K=0.15, F14/F15 youngest-five-age controls, rec 0.1 and movement 0.1."
  ),
  model_label = "Job 18400 | DM concentration fixed",
  job_title = "Job 18400 final PAR | fix 8 DM concentration parameters",
  job_key = "job18400-dmfix",
  plot_order = 1L,
  f14_youngest_zero = "5",
  f15_qc_mode = "lt70",
  dom_qc_mode = "gt90_midpoint",
  dm_nmax = "25",
  tau_mode = "estimated-common",
  tag_tau_grouping = "common",
  regional_recruitment_penalty = "0.1",
  movement_prior_penalty = "0.1",
  opr_mode = "off",
  estimate_m_final = "false",
  phase10_11_convergence = "-4",
  run_mode = "job_par_script",
  run_script = "continue-job18400-dmfix.sh",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  region_count = 5L,
  kflow_cpus = 2L,
  kflow_memory = "8GB",
  kflow_disk = "8GB",
  mfcl_program_path = "/home/mfcl/mfclo64",
  input_par = "",
  frq = "bet.frq",
  output_par = "final.par",
  par_source_job = "18400",
  kflow_input_jobs = "18400",
  expected_source_par_sha256 =
    "23f8f45e43369fb5df4b797846f975221dc155113518327498906c424e35b86b",
  job_par_max_evaluations = "10000",
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F14-Y5-REC01",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job18400-dmfix-20260729",
  trigger_next = FALSE
)
