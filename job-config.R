# OPR phase-placement sensitivity derived from the PDH-rebuild Step 11.
#
# Every row executes its own model-local doitall from bet.ini. The six OPR
# rows differ only in the phase at which the complete standard-to-OPR switch
# is applied and whether the reviewed terminal-recruitment penalty is used.

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-opr-phase-placement",
  trigger_next = FALSE
)

stepwise_models <- data.frame(
  step_id = c(
    "11-Standard-Fix6",
    "12a-OPR-Phase3-P0",
    "12b-OPR-Phase3-P100",
    "12c-OPR-Phase8-P0",
    "12d-OPR-Phase8-P100",
    "12e-OPR-Phase10-P0",
    "12f-OPR-Phase10-P100"
  ),
  enabled = rep(TRUE, 7),
  major_step = c("11-StandardReference", rep("12-OPRPhasePlacement", 6)),
  substep = c("11r", "12a", "12b", "12c", "12d", "12e", "12f"),
  change_axis = c(
    "PDH-rebuild standard Step-11 Fix6 reference",
    "OPR conversion at Phase 3 without terminal penalty",
    "OPR conversion at Phase 3 with terminal penalty",
    "OPR conversion at Phase 8 without terminal penalty",
    "OPR conversion at Phase 8 with terminal penalty",
    "OPR conversion at Phase 10 without terminal penalty",
    "OPR conversion at Phase 10 with terminal penalty"
  ),
  model_label = c(
    "Standard Fix6",
    "OPR Phase 3 P0",
    "OPR Phase 3 P100",
    "OPR Phase 8 P0",
    "OPR Phase 8 P100",
    "OPR Phase 10 P0",
    "OPR Phase 10 P100"
  ),
  job_title = c(
    "11 Standard reference (Fix6)",
    "12a OPR switch Phase 3 P0",
    "12b OPR switch Phase 3 P100",
    "12c OPR switch Phase 8 P0",
    "12d OPR switch Phase 8 P100",
    "12e OPR switch Phase 10 P0",
    "12f OPR switch Phase 10 P100"
  ),
  job_key = c(
    "11-standard-fix6",
    "12a-opr-phase3-p0",
    "12b-opr-phase3-p100",
    "12c-opr-phase8-p0",
    "12d-opr-phase8-p100",
    "12e-opr-phase10-p0",
    "12f-opr-phase10-p100"
  ),
  run_mode = rep("doitall", 7),
  run_script = rep("doitall.sh", 7),
  region_count = rep(5L, 7),
  kflow_memory = rep("8GB", 7),
  mfcl_program_path = rep("", 7),
  input_par = rep("", 7),
  par_source_step_id = rep("", 7),
  frq = rep("bet.frq", 7),
  output_par = rep("", 7),
  expected_final_par = c("11.par", rep("final.par", 6)),
  stringsAsFactors = FALSE
)
