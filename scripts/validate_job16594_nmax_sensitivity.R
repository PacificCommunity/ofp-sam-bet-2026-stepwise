fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job16594-nmax-sensitivity.R")
task_path <- file.path(root, "kflow-job16594-nmax-sensitivity.yaml")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
doitall_path <- file.path(source_dir, "doitall.sh")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")

required_files <- c(config_path, task_path, doitall_path, registrar_path)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing Nmax campaign files: ", paste(missing_files, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
expected_nmax <- c("10", "15", "40", "50")
expected_steps <- paste0("JOB16594-NMAX", expected_nmax)

if (!is.data.frame(models) || nrow(models) != 4L) {
  fail("Expected exactly four Nmax sensitivity rows.")
}
if (!identical(models$step_id, expected_steps)) {
  fail("Unexpected Nmax step order: ", paste(models$step_id, collapse = ", "))
}
if (!identical(as.character(models$dm_nmax), expected_nmax)) {
  fail("Nmax rows must be exactly 10, 15, 40 and 50.")
}
if (!identical(models$tag_tau_grouping, rep("common", 4L)) ||
    !identical(models$tau_mode, rep("estimated-common", 4L))) {
  fail("Every Nmax sensitivity must estimate one common tau.")
}
if (!identical(
  models$source_dir,
  rep("steps/S03-CommonTagTau-MIX015/model", 4L)
)) {
  fail("Every row must stage the exact Job 16594 S03 source model.")
}
if (anyDuplicated(models$step_id) || anyDuplicated(models$job_key) ||
    anyDuplicated(models$model_label)) {
  fail("Nmax sensitivity step IDs, job keys and labels must be unique.")
}
for (step in expected_steps) {
  if (!dir.exists(file.path(root, "steps", step))) {
    fail("Missing step directory: ", step)
  }
}

ini_path <- file.path(source_dir, "bet.ini")
if (!file.exists(ini_path)) fail("Missing Job 16594 source bet.ini.")
sha <- system2("sha256sum", ini_path, stdout = TRUE)
sha <- strsplit(sha[[1L]], "[[:space:]]+")[[1L]][[1L]]
expected_ini_sha <- "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a"
if (!identical(sha, expected_ini_sha)) {
  fail("Job 16594 source bet.ini SHA mismatch: ", sha)
}

doitall <- readLines(doitall_path, warn = FALSE)
required_doitall <- c(
  'dm_nmax=${DM_NMAX:-25}',
  '  10|15|25|40|50)',
  '    dm_nmax_flag=$dm_nmax',
  '    dm_nmax_effective=$dm_nmax',
  'tag_tau_grouping=${TAG_TAU_GROUPING:-common}',
  '    expected_tau_count=1',
  '    tag_tau_grouping_label=common-F1-F28',
  '  1 111 4    # negative-binomial tag-recapture likelihood',
  '  1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound',
  'actual_tau=$(awk \'$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}\' indepvar.rpt)'
)
missing_doitall <- setdiff(required_doitall, doitall)
if (length(missing_doitall)) {
  fail(
    "Job 16594 runtime Nmax/tau controls are incomplete: ",
    paste(missing_doitall, collapse = " | ")
  )
}
if (sum(trimws(doitall) ==
        "1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound") != 1L) {
  fail("Runtime doitall must set parest flag 342 exactly once.")
}

registrar <- readLines(registrar_path, warn = FALSE)
if (!any(grepl(
  '("dm_nmax", "DM_NMAX")',
  registrar,
  fixed = TRUE
))) {
  fail("Kflow registrar does not map row-specific dm_nmax to DM_NMAX.")
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-job16594-dm-nmax10-15-40-50-20260727",
  "branch: sensitivity/job16594-dm-nmax10-15-40-50-20260727",
  "  CONFIG_R: job-config-job16594-nmax-sensitivity.R",
  "  TAG_TAU_GROUPING: common",
  "  TAG_TAU_LOWER_BOUND: default",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  ESTIMATE_M_FINAL: \"false\"",
  "  TAG_LIKELIHOOD_WEIGHT: \"0\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  base_job: \"16594\"",
  "  reference_dm_nmax: 25",
  "  sensitivity_dm_nmax: [10, 15, 40, 50]"
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail(
    "Kflow task does not retain the required Job 16594 controls: ",
    paste(missing_task, collapse = " | ")
  )
}

cat(
  "Validated Job 16594 Nmax sensitivity: four independent rows ",
  "(10, 15, 40, 50), exact base INI, common tau, and runtime flag-342 audit.\n",
  sep = ""
)
