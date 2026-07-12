# Late-transfer OPR scale sensitivity.
#
# Every scenario is independently reproducible: its model-local `doitall.sh`
# rebuilds the common standard Step-11 sequence from the initial inputs, then
# applies its terminal-treatment or OPR setting from that newly fitted `11.par`.
# No scenario silently starts from a checked-in or another job's PAR.

stepwise_run <- list(
  default_step_select = "all",
  flow_group = "bet-2026-late-transfer-opr",
  trigger_next = FALSE
)

# One row is one independently runnable model. The first row is the standard
# Step-11 reference; the next two isolate terminal-treatment effects; the
# remaining rows are OPR sensitivities that make the native conversion only
# after rebuilding their own Step-11 reference path.
stepwise_models <- data.frame(
  step_id = c(
    "11-Reference-Fix6",
    "11a-Standard-Free",
    "11b-Standard-Fix8",
    "12a-OPR72-E2-P0",
    "12b-OPR72-E2-P100",
    "12c-OPR73-E1-P0",
    "12d-OPR73-E1-P100",
    "12e-OPR72-E2-SpatialFree-P100",
    "12f-OPR72-E2-Int72-P100",
    "12g-OPR73-E1-Saturated-P0"
  ),
  enabled = rep(TRUE, 10),
  major_step = c(
    "11-StandardReference",
    "11-TerminalControl",
    "11-TerminalControl",
    rep("12-LateTransferOPR", 7)
  ),
  substep = c("11r", "11a", "11b", "12a", "12b", "12c", "12d", "12e", "12f", "12g"),
  change_axis = c(
    "standard Step-11 Fix6 reference",
    "standard recruitment with terminal constraints removed",
    "standard recruitment with an eight-quarter terminal window",
    "late-transfer OPR 72-E2 without terminal penalty",
    "late-transfer OPR 72-E2 with terminal penalty",
    "late-transfer OPR 73-E1 without terminal penalty",
    "late-transfer OPR 73-E1 with terminal penalty",
    "late-transfer OPR 72-E2 with spatial endpoint ties released",
    "late-transfer OPR 72-E2 with expanded interaction rank",
    "late-transfer OPR saturated representation benchmark"
  ),
  model_label = c(
    "Standard Fix6",
    "Standard free terminal",
    "Standard Fix8",
    "OPR 72-E2 P0",
    "OPR 72-E2 P100",
    "OPR 73-E1 P0",
    "OPR 73-E1 P100",
    "OPR 72-E2 spatial free P100",
    "OPR 72-E2 interaction 72 P100",
    "OPR saturated benchmark"
  ),
  job_title = c(
    "11 Standard reference (Fix6)",
    "11a Standard terminal-free",
    "11b Standard terminal Fix8",
    "12a OPR 72-E2 P0",
    "12b OPR 72-E2 P100",
    "12c OPR 73-E1 P0",
    "12d OPR 73-E1 P100",
    "12e OPR 72-E2 spatial-free P100",
    "12f OPR 72-E2 interaction-72 P100",
    "12g OPR saturated representation"
  ),
  job_key = c(
    "11-standard-fix6",
    "11a-standard-free",
    "11b-standard-fix8",
    "12a-opr72-e2-p0",
    "12b-opr72-e2-p100",
    "12c-opr73-e1-p0",
    "12d-opr73-e1-p100",
    "12e-opr72-e2-spatialfree-p100",
    "12f-opr72-e2-int72-p100",
    "12g-opr73-e1-saturated-p0"
  ),
  run_mode = c("doitall", rep("doitall", 9)),
  run_script = rep("doitall.sh", 10),
  region_count = rep(5L, 10),
  kflow_memory = rep("8GB", 10),
  mfcl_program_path = rep("", 10),
  input_par = rep("", 10),
  par_source_step_id = rep("", 10),
  frq = rep("bet.frq", 10),
  output_par = rep("", 10),
  expected_final_par = c("11.par", rep("final.par", 9)),
  stringsAsFactors = FALSE
)
