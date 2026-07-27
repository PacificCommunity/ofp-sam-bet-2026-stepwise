## Job 17227 convergence and regional recruitment-penalty diagnostics.
##
## Row 1 continues from the verified Job 17227 final PAR and changes only the
## final MGC target from 1e-4 to 1e-5.
## Row 2 is an independent doitall fit from the same frozen source inputs,
## retaining the F15 <70 cm QC and Nmax=25 while changing the regional
## recruitment-distribution penalty from its default 0.1 to 0.2.

stepwise_models <- data.frame(
  step_id = c(
    "F15-LT70-NMAX25",
    "F15-LT70-NMAX25-REC02"
  ),
  STEP_SELECT = c(
    "F15-LT70-NMAX25",
    "F15-LT70-NMAX25-REC02"
  ),
  enabled = c(TRUE, TRUE),
  major_step = c(
    "Job17227HessianFollowup",
    "Job17227HessianFollowup"
  ),
  substep = c(
    "FinalPar-MGC1e5-Rec01",
    "Doitall-MGC1e4-Rec02"
  ),
  scientific_parent = c(
    "Job 17227",
    "Job 17227"
  ),
  scientific_parent_mode = c(
    "par-input",
    "metadata-only"
  ),
  independent_fit = c(FALSE, TRUE),
  change_axis = c(
    "Continue the exact Job 17227 final PAR to MGC 1e-5; retain regional recruitment-distribution penalty 0.1.",
    "Independent doitall from frozen Job 17227 inputs; change only regional recruitment-distribution penalty 0.1 to 0.2; retain MGC 1e-4."
  ),
  control_notes = c(
    paste(
      "Attach only Job 17227. Require its verified final PAR SHA256.",
      "Continue with parest flag 50=-5 and age flag 110=0.",
      "Retain fixed M, Nmax=25, F15 <70 cm QC, common estimated tag tau,",
      "SC22-IP10 K=0.15 mixing, and all remaining flags."
    ),
    paste(
      "Do not attach or reuse Job 17227 PAR. Run doitall from bet.ini and the",
      "frozen source files. Apply the deterministic F15 <70 cm QC, Nmax=25,",
      "parest flag 50=-4, and age flag 110=2 (penalty 0.2). Retain fixed M,",
      "common estimated tag tau, SC22-IP10 K=0.15 mixing, and all other controls."
    )
  ),
  model_label = c(
    "01. Job17227 final PAR | rec penalty 0.1 | MGC 1e-5",
    "02. Job17227 inputs doitall | rec penalty 0.2 | MGC 1e-4"
  ),
  job_title = c(
    "01. Job17227 final PAR continuation | rec 0.1 | MGC 1e-5",
    "02. Job17227-input doitall sensitivity | rec 0.2 | MGC 1e-4"
  ),
  job_key = c(
    "job17227-finalpar-rec01-mgc1e5",
    "job17227-doitall-rec02-mgc1e4"
  ),
  plot_order = c(1L, 2L),
  f15_qc_mode = c("lt70", "lt70"),
  dm_nmax = c("25", "25"),
  tau_mode = c("estimated-common", "estimated-common"),
  tag_tau_grouping = c("common", "common"),
  regional_recruitment_penalty = c("0.1", "0.2"),
  phase10_11_convergence = c("-5", "-4"),
  run_mode = c("job_par_script", "doitall"),
  run_script = c("continue-job17227-final-par.sh", "doitall.sh"),
  source_dir = c(
    "steps/S03-CommonTagTau-MIX015/model",
    "steps/S03-CommonTagTau-MIX015/model"
  ),
  region_count = c(5L, 5L),
  kflow_cpus = c(2L, 2L),
  kflow_memory = c("8GB", "8GB"),
  kflow_disk = c("8GB", "8GB"),
  mfcl_program_path = c("/home/mfcl/mfclo64", "/home/mfcl/mfclo64"),
  input_par = c("", ""),
  frq = c("bet.frq", "bet.frq"),
  output_par = c("final.par", ""),
  par_source_job = c("17227", ""),
  kflow_input_jobs = c("17227", ""),
  expected_source_par_sha256 = c(
    "30e5122ade18200daba7fb1b4fe7126c830684785beb90d827648fd611d03ce7",
    ""
  ),
  job_par_max_evaluations = c("10000", ""),
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F15-LT70-NMAX25",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job17227-finalpar-mgc-recpen-20260728",
  trigger_next = FALSE
)
