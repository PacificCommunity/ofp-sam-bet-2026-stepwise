source(file.path(getwd(), "R", "apply_f15_lf_qc.R"), local = TRUE)
env_f15 <- Sys.getenv("F15_QC_MODE", "")
if (nzchar(env_f15) && !identical(env_f15, config$F15_QC_MODE)) {
  stop("F15_QC_MODE environment/config mismatch.", call. = FALSE)
}
apply_f15_lf_qc(model_dir, config$F15_QC_MODE)

source(file.path(getwd(), "R", "apply_dom_lf_qc.R"), local = TRUE)
env_dom <- Sys.getenv("DOM_QC_MODE", "")
if (nzchar(env_dom) && !identical(env_dom, config$DOM_QC_MODE)) {
  stop("DOM_QC_MODE environment/config mismatch.", call. = FALSE)
}
apply_dom_lf_qc(model_dir, config$DOM_QC_MODE)

source(file.path(getwd(), "R", "apply_full_period_reg_scaling.R"), local = TRUE)
env_reg <- Sys.getenv("REG_SCALING_MODE", "")
if (nzchar(env_reg) && !identical(env_reg, config$REGIONAL_SCALING_MODE)) {
  stop("REG_SCALING_MODE environment/config mismatch.", call. = FALSE)
}
apply_full_period_reg_scaling(model_dir, config$REGIONAL_SCALING_MODE)

source(file.path(getwd(), "R", "apply_movement_prior_penalty.R"), local = TRUE)
env_move <- Sys.getenv("MOVEMENT_PRIOR_PENALTY", "")
if (nzchar(env_move) && !identical(env_move, config$MOVEMENT_PRIOR_PENALTY)) {
  stop("MOVEMENT_PRIOR_PENALTY environment/config mismatch.", call. = FALSE)
}
apply_movement_prior_penalty(model_dir, config$MOVEMENT_PRIOR_PENALTY)

source(file.path(getwd(), "R", "apply_opr_sensitivity.R"), local = TRUE)
env_opr <- Sys.getenv("OPR_MODE", "")
if (nzchar(env_opr) && !identical(env_opr, config$OPR_MODE)) {
  stop("OPR_MODE environment/config mismatch.", call. = FALSE)
}
apply_opr_sensitivity(model_dir, config$OPR_MODE)

source(
  file.path(getwd(), "R", "apply_john_selectivity_sensitivity.R"),
  local = TRUE
)
env_sel <- Sys.getenv("SELECTIVITY_MODE", "")
if (nzchar(env_sel) && !identical(env_sel, config$SELECTIVITY_MODE)) {
  stop("SELECTIVITY_MODE environment/config mismatch.", call. = FALSE)
}
apply_john_selectivity_sensitivity(model_dir, config$SELECTIVITY_MODE)

source(file.path(getwd(), "R", "apply_stable_doitall_schedule.R"), local = TRUE)
apply_stable_doitall_schedule(model_dir, config$OPR_MODE)
