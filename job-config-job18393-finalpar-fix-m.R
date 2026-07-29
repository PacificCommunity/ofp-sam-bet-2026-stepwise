## Continue the exact Job 18393 final PAR and fix the fitted Lorenzen natural-
## mortality intercept (age_pars(5)) at its Job 18393 maximum-likelihood value.
stepwise_models <- data.frame(
  step_id = "F14-Y5-REC01",
  STEP_SELECT = "F14-Y5-REC01",
  enabled = TRUE,
  major_step = "Job18393FinalParFixM",
  substep = "FinalPar-FixEstimatedM",
  scientific_parent = "Job 18393",
  scientific_parent_mode = "par-input",
  independent_fit = FALSE,
  change_axis = paste(
    "Continue the checksum-verified Job 18393 final PAR.",
    "Fix only its fitted age_pars(5) Lorenzen M intercept at",
    "-2.44602044920584 by changing parest flag 121 from 1 to 0,",
    "then re-optimise all remaining active parameters at MGC 1e-4."
  ),
  control_notes = paste(
    "Attach only Job 18393. Retain its F15 <70 cm and DOM midpoint >90 cm",
    "FRQ, F14/F15 youngest-five-age controls, standard recruitment, rec and",
    "movement penalties 0.1, Nmax=25, common estimated tag tau, K=0.15,",
    "and default parest 387=0. The only model change is fixing M at its",
    "Job 18393 fitted value."
  ),
  model_label = "Job 18393 final PAR | M fixed at estimated value",
  job_title = "Job 18393 final PAR | fix M=-2.44602044920584",
  job_key = "job18393-finalpar-fix-estimated-m",
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
  run_script = "continue-job18393-fix-m.sh",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  region_count = 5L,
  kflow_cpus = 2L,
  kflow_memory = "8GB",
  kflow_disk = "8GB",
  mfcl_program_path = "/home/mfcl/mfclo64",
  input_par = "",
  frq = "bet.frq",
  output_par = "final.par",
  par_source_job = "18393",
  kflow_input_jobs = "18393",
  expected_source_par_sha256 =
    "542190593c28f904a32ebab1262726d8d61a2b40b6b1df1f6ac74819aba3baf5",
  job_par_max_evaluations = "10000",
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F14-Y5-REC01",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job18393-finalpar-fix-estimated-m-20260729",
  trigger_next = FALSE
)
