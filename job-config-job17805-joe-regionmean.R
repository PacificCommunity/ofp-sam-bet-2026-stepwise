## Two independent Job 17805 doitall sensitivities changing only the
## release-group tag-mixing periods.
stepwise_models <- data.frame(
  step_id = c(
    "F14-Y5-REC01-JOE-K015",
    "F14-Y5-REC01-JOE-K020"
  ),
  STEP_SELECT = c(
    "F14-Y5-REC01-JOE-K015",
    "F14-Y5-REC01-JOE-K020"
  ),
  enabled = rep(TRUE, 2),
  major_step = rep("Job17805JoeRegionMeanMixingSensitivity", 2),
  substep = c("JoeRegionMean-K015", "JoeRegionMean-K020"),
  scientific_parent = rep("Job 17805", 2),
  scientific_parent_mode = rep("metadata-only", 2),
  independent_fit = rep(TRUE, 2),
  change_axis = c(
    paste(
      "Independent doitall from the frozen Job 17805 source inputs.",
      "Replace only tag_flags(:,1) with the SC22-IP10 K=0.15 vector",
      "using Joe's all-region mean for Region 1."
    ),
    paste(
      "Independent doitall from the frozen Job 17805 source inputs.",
      "Replace only tag_flags(:,1) with the SC22-IP10 K=0.20 vector;",
      "Joe's Region-1 mean is 2 at this cutoff."
    )
  ),
  control_notes = rep(
    paste(
      "All non-mixing controls exactly match Job 17805: no previous PAR;",
      "F15 <70 cm and DOM midpoint >90 cm LF exclusions; F14/F15 youngest",
      "five ages fixed; standard recruitment; rec penalty 0.1; movement",
      "prior 0.1; Nmax=25; fixed M; common estimated tag tau; MGC 1e-4."
    ),
    2
  ),
  model_label = c(
    "Job 17805 controls | Joe all-region mean | K=0.15",
    "Job 17805 controls | Joe all-region mean | K=0.20"
  ),
  job_title = c(
    "01. Job 17805 | Joe region mean | mixing K=0.15",
    "02. Job 17805 | Joe region mean | mixing K=0.20"
  ),
  job_key = c(
    "job17805-joe-regionmean-k015",
    "job17805-joe-regionmean-k020"
  ),
  plot_order = 1:2,
  f14_youngest_zero = rep("5", 2),
  f15_qc_mode = rep("lt70", 2),
  dom_qc_mode = rep("gt90_midpoint", 2),
  dm_nmax = rep("25", 2),
  tau_mode = rep("estimated-common", 2),
  tag_tau_grouping = rep("common", 2),
  regional_recruitment_penalty = rep("0.1", 2),
  movement_prior_penalty = rep("0.1", 2),
  opr_mode = rep("off", 2),
  mixing_period_mode = c("joe-regionmean-k015", "joe-regionmean-k020"),
  phase10_11_convergence = rep("-4", 2),
  run_mode = rep("doitall", 2),
  run_script = rep("doitall.sh", 2),
  source_dir = rep("steps/S03-CommonTagTau-MIX015/model", 2),
  region_count = rep(5L, 2),
  kflow_cpus = rep(2L, 2),
  kflow_memory = rep("8GB", 2),
  kflow_disk = rep("8GB", 2),
  mfcl_program_path = rep("/home/mfcl/mfclo64", 2),
  input_par = rep("", 2),
  frq = rep("bet.frq", 2),
  output_par = rep("", 2),
  par_source_job = rep("", 2),
  kflow_input_jobs = rep("", 2),
  expected_source_par_sha256 = rep("", 2),
  job_par_max_evaluations = rep("", 2),
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F14-Y5-REC01-JOE-K015",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job17805-joe-regionmean-k015-k020-20260729",
  trigger_next = FALSE
)
