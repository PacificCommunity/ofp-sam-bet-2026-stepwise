source(file.path(getwd(), "steps", "F14-Y5-REC01-JOE-K020", "patch.R"), local = TRUE)
source(file.path(getwd(), "R", "apply_lorenzen_m_start.R"), local = TRUE)
env_m_start <- Sys.getenv("M_START_INTERCEPT", "")
if (nzchar(env_m_start) && !identical(env_m_start, config$M_START_INTERCEPT)) {
  stop("M_START_INTERCEPT environment/config mismatch.", call. = FALSE)
}
apply_lorenzen_m_start(model_dir, config$M_START_INTERCEPT)
