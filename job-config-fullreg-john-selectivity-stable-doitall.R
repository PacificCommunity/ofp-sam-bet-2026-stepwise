## Two independent full-period regional-scaling fits for the John Hampton
## selectivity sensitivity. Recruitment and movement penalties are fixed at
## 0.1; only the standard versus OPR recruitment structure is compared.

stepwise_models <- data.frame(
  step_id = c("FULLREG-JOHN-SEL-STD", "FULLREG-JOHN-SEL-OPR"),
  STEP_SELECT = c("FULLREG-JOHN-SEL-STD", "FULLREG-JOHN-SEL-OPR"),
  enabled = c(TRUE, TRUE),
  major_step = rep("FullRegJohnSelectivityStableDoitall", 2),
  substep = c("StandardRecruitment", "OPR72015050End2"),
  scientific_parent = c(
    "full-reg standard rec0.1 move0.1",
    "full-reg OPR end2 rec0.1 move0.1"
  ),
  scientific_parent_mode = rep("metadata-only", 2),
  independent_fit = rep(TRUE, 2),
  change_axis = c(
    paste(
      "Independent doitall from bet.ini. Retain standard mean-plus-deviation",
      "recruitment; change the shared F2/F3 curve to non-decreasing and",
      "change F33 from logistic to an unconstrained four-node cubic spline."
    ),
    paste(
      "Independent doitall from bet.ini. Use OPR 72-01-50-50 end2;",
      "change the shared F2/F3 curve to non-decreasing and change F33",
      "from logistic to an unconstrained four-node cubic spline."
    )
  ),
  control_notes = rep(
    paste(
      "Retain F15 <70 cm LF QC, DOM F21-F23 midpoint >90 cm LF exclusion,",
      "F14/F15 youngest five ages fixed at zero selectivity, full-period",
      "regional scaling over model periods 3-292, Nmax25, fixed M, common",
      "estimated tau, rec penalty 0.1 and movement prior 0.1. Use the",
      "source/manual-audited staged optimizer schedule with separate",
      "recruitment, REGW, index-CPUE, movement and growth blocks,",
      "same-dimension gradient-rescaled stabilization runs, and a final",
      "native-scale MGC 1e-4 confirmation."
    ),
    2
  ),
  model_label = c(
    paste(
      "01. Full REG | John selectivity | F2/F3 non-decreasing |",
      "F33 spline4 | stable doitall | standard recruitment"
    ),
    paste(
      "02. Full REG | John selectivity | F2/F3 non-decreasing |",
      "F33 spline4 | stable doitall | OPR 72-01-50-50 end2"
    )
  ),
  job_title = c(
    "01. Full REG | F2/F3 nondec | F33 spline4 | stable doitall | standard",
    "02. Full REG | F2/F3 nondec | F33 spline4 | stable doitall | OPR end2"
  ),
  job_key = c(
    "fullreg-john-sel-stable-doitall-standard",
    "fullreg-john-sel-stable-doitall-opr-end2"
  ),
  plot_order = 1:2,
  f14_youngest_zero = rep("5", 2),
  f15_qc_mode = rep("lt70", 2),
  dom_qc_mode = rep("gt90_midpoint", 2),
  regional_scaling_mode = rep("full_period", 2),
  selectivity_mode = rep("f2f3-nondecreasing-f33-spline4", 2),
  dm_nmax = rep("25", 2),
  tau_mode = rep("estimated-common", 2),
  tag_tau_grouping = rep("common", 2),
  regional_recruitment_penalty = rep("0.1", 2),
  movement_prior_penalty = rep("0.1", 2),
  opr_mode = c("off", "72-01-50-50-end2"),
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
  default_step_select = "FULLREG-JOHN-SEL-STD",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-fullreg-john-selectivity-stable-doitall-20260728",
  trigger_next = FALSE
)
