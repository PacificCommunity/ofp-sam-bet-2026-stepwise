## Independent F14 youngest-age selectivity sensitivities.
##
## Both rows start from bet.ini and the same frozen S03 inputs via doitall.
## The only difference between the rows is the regional recruitment-
## distribution penalty: default 0.1 versus 0.2 (age flag 110 = 2).

stepwise_models <- data.frame(
  step_id = c(
    "F14-Y5-REC01",
    "F14-Y5-REC02"
  ),
  STEP_SELECT = c(
    "F14-Y5-REC01",
    "F14-Y5-REC02"
  ),
  enabled = c(TRUE, TRUE),
  major_step = c(
    "F14YoungAgeSensitivity",
    "F14YoungAgeSensitivity"
  ),
  substep = c(
    "Doitall-Rec01",
    "Doitall-Rec02"
  ),
  scientific_parent = c(
    "Job 17227",
    "Job 17513"
  ),
  scientific_parent_mode = c(
    "metadata-only",
    "metadata-only"
  ),
  independent_fit = c(TRUE, TRUE),
  change_axis = c(
    paste(
      "Independent doitall from the frozen S03 inputs. Add fish flag 75=5",
      "for F14 HL.ID.2; retain the default regional recruitment-distribution",
      "penalty 0.1."
    ),
    paste(
      "Independent doitall from the frozen S03 inputs. Add fish flag 75=5",
      "for F14 HL.ID.2; set the regional recruitment-distribution penalty",
      "to 0.2 (age flag 110=2)."
    )
  ),
  control_notes = c(
    paste(
      "Do not attach a previous PAR. Start with -makepar from bet.ini.",
      "Retain F15 <70 cm QC, F15 fish flag 75=5, Nmax=25, fixed M,",
      "common estimated tag tau, SC22-IP10 K=0.15 mixing, and MGC 1e-4."
    ),
    paste(
      "Do not attach a previous PAR. Start with -makepar from bet.ini.",
      "Retain F15 <70 cm QC, F15 fish flag 75=5, Nmax=25, fixed M,",
      "common estimated tag tau, SC22-IP10 K=0.15 mixing, and MGC 1e-4."
    )
  ),
  model_label = c(
    "01. F14 youngest 5 fixed | doitall | rec penalty 0.1",
    "02. F14 youngest 5 fixed | doitall | rec penalty 0.2"
  ),
  job_title = c(
    "01. F14 youngest-5 sensitivity | doitall | rec 0.1",
    "02. F14 youngest-5 sensitivity | doitall | rec 0.2"
  ),
  job_key = c(
    "f14-young5-doitall-rec01",
    "f14-young5-doitall-rec02"
  ),
  plot_order = c(1L, 2L),
  f14_youngest_zero = c("5", "5"),
  f15_qc_mode = c("lt70", "lt70"),
  dm_nmax = c("25", "25"),
  tau_mode = c("estimated-common", "estimated-common"),
  tag_tau_grouping = c("common", "common"),
  regional_recruitment_penalty = c("0.1", "0.2"),
  phase10_11_convergence = c("-4", "-4"),
  run_mode = c("doitall", "doitall"),
  run_script = c("doitall.sh", "doitall.sh"),
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
  output_par = c("", ""),
  par_source_job = c("", ""),
  kflow_input_jobs = c("", ""),
  expected_source_par_sha256 = c("", ""),
  job_par_max_evaluations = c("", ""),
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F14-Y5-REC01",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-f14-young5-rec-grid-20260728",
  trigger_next = FALSE
)
