fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job17227-doitall-rec03.R")
patch_path <- file.path(root, "steps", "F15-LT70-NMAX25-REC03", "patch.R")
if (!file.exists(config_path) || !file.exists(patch_path)) {
  fail("The dedicated rec0.3 doitall config or F15 patch is missing.")
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
if (!is.data.frame(models) || nrow(models) != 1L) {
  fail("Expected exactly one independent rec0.3 doitall row.")
}

expected <- list(
  step_id = "F15-LT70-NMAX25-REC03",
  STEP_SELECT = "F15-LT70-NMAX25-REC03",
  scientific_parent_mode = "metadata-only",
  independent_fit = TRUE,
  f15_qc_mode = "lt70",
  dm_nmax = "25",
  tau_mode = "estimated-common",
  tag_tau_grouping = "common",
  regional_recruitment_penalty = "0.3",
  phase10_11_convergence = "-4",
  run_mode = "doitall",
  run_script = "doitall.sh",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  par_source_job = "",
  kflow_input_jobs = "",
  expected_source_par_sha256 = ""
)
for (field in names(expected)) {
  actual <- models[[field]][[1L]]
  if (!identical(actual, expected[[field]])) {
    fail("Unexpected rec0.3 doitall field ", field, ": ", actual)
  }
}

expected_patch <- c(
  'source(file.path(getwd(), "R", "apply_f15_lf_qc.R"), local = TRUE)',
  'env_mode <- Sys.getenv("F15_QC_MODE", "")',
  'if (nzchar(env_mode) && !identical(env_mode, config$F15_QC_MODE)) {',
  '  stop("F15_QC_MODE environment/config mismatch.", call. = FALSE)',
  '}',
  'apply_f15_lf_qc(model_dir, config$F15_QC_MODE)'
)
if (!identical(readLines(patch_path, warn = FALSE), expected_patch)) {
  fail("Unexpected dedicated REC03 F15 patch content.")
}

doitall <- readLines(
  file.path(root, "steps", "S03-CommonTagTau-MIX015", "model", "doitall.sh"),
  warn = FALSE
)
required <- c(
  "  0.3)",
  "    regional_recruitment_penalty_flag=3",
  "  2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient",
  "  1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound",
  "  1 50 $phase10_11_convergence"
)
missing <- setdiff(required, doitall)
if (length(missing)) {
  fail("Dedicated rec0.3 doitall controls are incomplete: ", paste(missing, collapse = " | "))
}

cat(
  "Validated dedicated independent rec0.3 doitall: no PAR input; F15 <70 cm; ",
  "Nmax=25; age flag 110=3; MGC=1e-4; common estimated tau; fixed M.\n",
  sep = ""
)
