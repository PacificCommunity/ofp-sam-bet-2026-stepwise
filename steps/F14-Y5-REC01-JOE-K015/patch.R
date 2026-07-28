source(file.path(getwd(), "steps", "F14-Y5-REC01", "patch.R"), local = TRUE)
source(file.path(getwd(), "R", "apply_job17805_joe_mixing.R"), local = TRUE)
env_mixing <- Sys.getenv("MIXING_PERIOD_MODE", "")
if (nzchar(env_mixing) && !identical(env_mixing, config$MIXING_PERIOD_MODE)) {
  stop("MIXING_PERIOD_MODE environment/config mismatch.", call. = FALSE)
}
apply_job17805_joe_mixing(model_dir, config$MIXING_PERIOD_MODE)
