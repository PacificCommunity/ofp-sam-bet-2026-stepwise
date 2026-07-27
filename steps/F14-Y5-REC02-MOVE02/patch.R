source(file.path(getwd(), "R", "apply_f15_lf_qc.R"), local = TRUE)
env_mode <- Sys.getenv("F15_QC_MODE", "")
if (nzchar(env_mode) && !identical(env_mode, config$F15_QC_MODE)) {
  stop("F15_QC_MODE environment/config mismatch.", call. = FALSE)
}
apply_f15_lf_qc(model_dir, config$F15_QC_MODE)
source(file.path(getwd(), "R", "apply_movement_prior_penalty.R"), local = TRUE)
env_movement <- Sys.getenv("MOVEMENT_PRIOR_PENALTY", "")
if (nzchar(env_movement) && !identical(env_movement, config$MOVEMENT_PRIOR_PENALTY)) {
  stop("MOVEMENT_PRIOR_PENALTY environment/config mismatch.", call. = FALSE)
}
apply_movement_prior_penalty(model_dir, config$MOVEMENT_PRIOR_PENALTY)
source(file.path(getwd(), "R", "apply_opr_sensitivity.R"), local = TRUE)
env_opr <- Sys.getenv("OPR_MODE", "")
if (nzchar(env_opr) && !identical(env_opr, config$OPR_MODE)) {
  stop("OPR_MODE environment/config mismatch.", call. = FALSE)
}
apply_opr_sensitivity(model_dir, config$OPR_MODE)
