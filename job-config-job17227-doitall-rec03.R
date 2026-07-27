## Independent Job 17227-input sensitivity with a 0.3 regional
## recruitment-distribution penalty. No previous Kflow job or final PAR is
## attached: the model runs doitall from the frozen S03 source inputs.

stepwise_models <- data.frame(
  step_id = "F15-LT70-NMAX25-REC03",
  STEP_SELECT = "F15-LT70-NMAX25-REC03",
  enabled = TRUE,
  major_step = "Job17227AdditionalSensitivity",
  substep = "Doitall-Rec03-MGC1e4",
  scientific_parent = "Job 17227",
  scientific_parent_mode = "metadata-only",
  independent_fit = TRUE,
  change_axis = paste(
    "Independent doitall from frozen Job 17227 inputs;",
    "regional recruitment-distribution penalty 0.1 to 0.3;",
    "retain F15 <70 cm, Nmax=25, and MGC 1e-4."
  ),
  control_notes = paste(
    "Do not attach or reuse Job 17227 PAR. Run doitall from bet.ini and the",
    "frozen S03 source files. Apply deterministic F15 <70 cm QC, Nmax=25,",
    "parest flag 50=-4, and age flag 110=3. Retain fixed M, common estimated",
    "tag tau, SC22-IP10 K=0.15 mixing, and all other controls."
  ),
  model_label = "Job17227 inputs doitall | rec penalty 0.3 | MGC 1e-4",
  job_title = "Job17227-input doitall sensitivity | rec 0.3 | MGC 1e-4",
  job_key = "job17227-input-doitall-rec03-mgc1e4",
  plot_order = 1L,
  f15_qc_mode = "lt70",
  dm_nmax = "25",
  tau_mode = "estimated-common",
  tag_tau_grouping = "common",
  regional_recruitment_penalty = "0.3",
  phase10_11_convergence = "-4",
  run_mode = "doitall",
  run_script = "doitall.sh",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  region_count = 5L,
  kflow_cpus = 2L,
  kflow_memory = "8GB",
  kflow_disk = "8GB",
  mfcl_program_path = "/home/mfcl/mfclo64",
  input_par = "",
  frq = "bet.frq",
  output_par = "",
  par_source_job = "",
  kflow_input_jobs = "",
  expected_source_par_sha256 = "",
  job_par_max_evaluations = "",
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F15-LT70-NMAX25-REC03",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job17227-input-doitall-rec03-mgc1e4-20260728",
  trigger_next = FALSE
)
