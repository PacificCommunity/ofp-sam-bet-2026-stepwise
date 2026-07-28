## Independent F14 youngest-age sensitivities with DOM >90 cm LF QC.
##
## All eight rows start from bet.ini and the same frozen S03 inputs via doitall.
## They form a 2 x 2 x 2 grid of regional recruitment-distribution penalties
## (0.1 versus 0.2), movement-prior penalties (0.1 versus 0.2), and recruitment
## structure (the S03 mean-plus-deviation structure versus BET 2026
## 72-01-50-50 OPR with the last-two-real-year end window). Every row also
## retains F15 <70 cm QC and excludes DOM F21-F23 intervals with midpoint
## >90 cm while leaving selectivity unchanged.

stepwise_models <- data.frame(
  step_id = c(
    "F14-Y5-REC01",
    "F14-Y5-REC02",
    "F14-Y5-REC01-MOVE02",
    "F14-Y5-REC02-MOVE02",
    "F14-Y5-REC01-OPR",
    "F14-Y5-REC02-OPR",
    "F14-Y5-REC01-MOVE02-OPR",
    "F14-Y5-REC02-MOVE02-OPR"
  ),
  STEP_SELECT = c(
    "F14-Y5-REC01",
    "F14-Y5-REC02",
    "F14-Y5-REC01-MOVE02",
    "F14-Y5-REC02-MOVE02",
    "F14-Y5-REC01-OPR",
    "F14-Y5-REC02-OPR",
    "F14-Y5-REC01-MOVE02-OPR",
    "F14-Y5-REC02-MOVE02-OPR"
  ),
  enabled = rep(TRUE, 8),
  major_step = rep("F14YoungAgeDOMQCSensitivity", 8),
  substep = c(
    "Doitall-Rec01",
    "Doitall-Rec02",
    "Doitall-Rec01-Move02",
    "Doitall-Rec02-Move02",
    "Doitall-Rec01-OPR",
    "Doitall-Rec02-OPR",
    "Doitall-Rec01-Move02-OPR",
    "Doitall-Rec02-Move02-OPR"
  ),
  scientific_parent = c(
    "Job 17227",
    "Job 17513",
    "F14-Y5-REC01",
    "F14-Y5-REC02",
    "F14-Y5-REC01",
    "F14-Y5-REC02",
    "F14-Y5-REC01-MOVE02",
    "F14-Y5-REC02-MOVE02"
  ),
  scientific_parent_mode = rep("metadata-only", 8),
  independent_fit = rep(TRUE, 8),
  change_axis = c(
    paste(
      "Independent doitall from the frozen S03 inputs. Add fish flag 75=5",
      "for F14 HL.ID.2; retain the default regional recruitment-distribution",
      "penalty 0.1 and movement-prior penalty 0.1 (age flag 27=-1)."
    ),
    paste(
      "Independent doitall from the frozen S03 inputs. Add fish flag 75=5",
      "for F14 HL.ID.2; set the regional recruitment-distribution penalty",
      "to 0.2 (age flag 110=2); retain movement-prior penalty 0.1",
      "(age flag 27=-1)."
    ),
    paste(
      "Independent doitall from the frozen S03 inputs. Add fish flag 75=5",
      "for F14 HL.ID.2; retain regional recruitment-distribution penalty 0.1;",
      "set movement-prior penalty to 0.2 (age flag 27=-2)."
    ),
    paste(
      "Independent doitall from the frozen S03 inputs. Add fish flag 75=5",
      "for F14 HL.ID.2; set regional recruitment-distribution penalty to 0.2",
      "(age flag 110=2) and movement-prior penalty to 0.2 (age flag 27=-2)."
    ),
    paste(
      "As row 1, with the Phase-3 regional recruitment structure replaced by",
      "BET 2026 OPR 72-01-50-50 and parest flag 202=2."
    ),
    paste(
      "As row 2, with the Phase-3 regional recruitment structure replaced by",
      "BET 2026 OPR 72-01-50-50 and parest flag 202=2."
    ),
    paste(
      "As row 3, with the Phase-3 regional recruitment structure replaced by",
      "BET 2026 OPR 72-01-50-50 and parest flag 202=2."
    ),
    paste(
      "As row 4, with the Phase-3 regional recruitment structure replaced by",
      "BET 2026 OPR 72-01-50-50 and parest flag 202=2."
    )
  ),
  control_notes = rep(
    paste(
      "Do not attach a previous PAR. Start with -makepar from bet.ini.",
      "Retain F15 <70 cm QC; exclude DOM F21-F23 LF intervals with midpoint",
      ">90 cm without changing selectivity; retain F15 fish flag 75=5,",
      "Nmax=25, fixed M, common estimated tag tau, SC22-IP10 K=0.15 mixing,",
      "and MGC 1e-4."
    ),
    8
  ),
  model_label = c(
    "01. DOM >90 excluded | F14 youngest 5 fixed | doitall | rec penalty 0.1",
    "02. DOM >90 excluded | F14 youngest 5 fixed | doitall | rec penalty 0.2",
    "03. DOM >90 excluded | F14 youngest 5 fixed | doitall | rec 0.1 | movement prior 0.2",
    "04. DOM >90 excluded | F14 youngest 5 fixed | doitall | rec 0.2 | movement prior 0.2",
    "05. DOM >90 excluded | F14 youngest 5 fixed | OPR 72-01-50-50 end2 | rec 0.1 | move 0.1",
    "06. DOM >90 excluded | F14 youngest 5 fixed | OPR 72-01-50-50 end2 | rec 0.2 | move 0.1",
    "07. DOM >90 excluded | F14 youngest 5 fixed | OPR 72-01-50-50 end2 | rec 0.1 | move 0.2",
    "08. DOM >90 excluded | F14 youngest 5 fixed | OPR 72-01-50-50 end2 | rec 0.2 | move 0.2"
  ),
  job_title = c(
    "01. DOM >90 excluded | F14 Y5 | standard | rec 0.1 | move 0.1",
    "02. DOM >90 excluded | F14 Y5 | standard | rec 0.2 | move 0.1",
    "03. DOM >90 excluded | F14 Y5 | standard | rec 0.1 | move 0.2",
    "04. DOM >90 excluded | F14 Y5 | standard | rec 0.2 | move 0.2",
    "05. DOM >90 excluded | F14 Y5 | OPR end2 | rec 0.1 | move 0.1",
    "06. DOM >90 excluded | F14 Y5 | OPR end2 | rec 0.2 | move 0.1",
    "07. DOM >90 excluded | F14 Y5 | OPR end2 | rec 0.1 | move 0.2",
    "08. DOM >90 excluded | F14 Y5 | OPR end2 | rec 0.2 | move 0.2"
  ),
  job_key = c(
    "f14-young5-domgt90-doitall-rec01",
    "f14-young5-domgt90-doitall-rec02",
    "f14-young5-domgt90-doitall-rec01-move02",
    "f14-young5-domgt90-doitall-rec02-move02",
    "f14-young5-domgt90-doitall-rec01-opr-end2",
    "f14-young5-domgt90-doitall-rec02-opr-end2",
    "f14-young5-domgt90-doitall-rec01-move02-opr-end2",
    "f14-young5-domgt90-doitall-rec02-move02-opr-end2"
  ),
  plot_order = 1:8,
  f14_youngest_zero = rep("5", 8),
  f15_qc_mode = rep("lt70", 8),
  dom_qc_mode = rep("gt90_midpoint", 8),
  dm_nmax = rep("25", 8),
  tau_mode = rep("estimated-common", 8),
  tag_tau_grouping = rep("common", 8),
  regional_recruitment_penalty = rep(c("0.1", "0.2"), 4),
  movement_prior_penalty = rep(c("0.1", "0.1", "0.2", "0.2"), 2),
  opr_mode = c(rep("off", 4), rep("72-01-50-50-end2", 4)),
  phase10_11_convergence = rep("-4", 8),
  run_mode = rep("doitall", 8),
  run_script = rep("doitall.sh", 8),
  source_dir = rep("steps/S03-CommonTagTau-MIX015/model", 8),
  region_count = rep(5L, 8),
  kflow_cpus = rep(2L, 8),
  kflow_memory = rep("8GB", 8),
  kflow_disk = rep("8GB", 8),
  mfcl_program_path = rep("/home/mfcl/mfclo64", 8),
  input_par = rep("", 8),
  frq = rep("bet.frq", 8),
  output_par = rep("", 8),
  par_source_job = rep("", 8),
  kflow_input_jobs = rep("", 8),
  expected_source_par_sha256 = rep("", 8),
  job_par_max_evaluations = rep("", 8),
  stringsAsFactors = FALSE
)

stepwise_run <- list(
  default_step_select = "F14-Y5-REC01",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-f14-young5-domgt90-rec-opr-grid-20260728",
  trigger_next = FALSE
)
