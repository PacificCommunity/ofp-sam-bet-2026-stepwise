source(file.path(getwd(), "R", "apply_f15_lf_qc.R"), local = TRUE)
env_mode <- Sys.getenv("F15_QC_MODE", "")
if (nzchar(env_mode) && !identical(env_mode, config$F15_QC_MODE)) {
  stop("F15_QC_MODE environment/config mismatch.", call. = FALSE)
}
apply_f15_lf_qc(model_dir, config$F15_QC_MODE)
