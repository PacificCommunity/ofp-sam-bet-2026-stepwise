## Continue the exact Job 17805 final PAR and open only the Lorenzen natural-
## mortality intercept (age_pars(5)) while retaining every other model control.
stepwise_models <- data.frame(
  step_id = "F14-Y5-REC01",
  STEP_SELECT = "F14-Y5-REC01",
  enabled = TRUE,
  major_step = "Job17805FinalParEstimateM",
  substep = "FinalPar-EstimateM",
  scientific_parent = "Job 17805",
  scientific_parent_mode = "par-input",
  independent_fit = FALSE,
  change_axis = paste(
    "Continue the checksum-verified Job 17805 final PAR.",
    "Keep its fitted age_pars(5) M intercept as the starting value, open only",
    "that Lorenzen intercept with legacy scaling (parest 387=1), then return",
    "to the current default scaling (parest 387=0) for the final fit."
  ),
  control_notes = paste(
    "Attach only Job 17805. Reproduce its F15 <70 cm plus DOM midpoint >90 cm",
    "FRQ, F14/F15 youngest-five-age controls, standard recruitment, rec and",
    "movement penalties 0.1, Nmax=25, common estimated tag tau, and K=0.15.",
    "Use 387=1 only as the M-opening bridge at MGC 1e-3, then restore 387=0",
    "and finish at MGC 1e-4."
  ),
  model_label = "Job 17805 final PAR | estimate M | 387 bridge to default",
  job_title = "Job 17805 final PAR | estimate M | 387=1 bridge, final 387=0",
  job_key = "job17805-finalpar-estimate-m-scale-bridge",
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
  estimate_m_final = "true",
  phase10_11_convergence = "-4",
  run_mode = "job_par_script",
  run_script = "continue-job17805-estimate-m.sh",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  region_count = 5L,
  kflow_cpus = 2L,
  kflow_memory = "8GB",
  kflow_disk = "8GB",
  mfcl_program_path = "/home/mfcl/mfclo64",
  input_par = "",
  frq = "bet.frq",
  output_par = "final.par",
  par_source_job = "17805",
  kflow_input_jobs = "17805",
  expected_source_par_sha256 =
    "f68bb0eb7441fed6f32151c196fced94a1c19205ec8fd7b8bd750a5355b31a04",
  job_par_max_evaluations = "10000",
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F14-Y5-REC01",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job17805-finalpar-estimate-m-20260729",
  trigger_next = FALSE
)
