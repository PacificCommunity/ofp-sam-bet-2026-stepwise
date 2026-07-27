fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job17227-finalpar-mgc-recpen.R")
task_path <- file.path(root, "kflow-job17227-finalpar-mgc-recpen.yaml")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
continuation_path <- file.path(source_dir, "continue-job17227-final-par.sh")
patch_path <- file.path(root, "steps", "F15-LT70-NMAX25-REC02", "patch.R")
apply_path <- file.path(root, "R", "apply_f15_lf_qc.R")
runner_path <- file.path(root, "R", "run_stepwise.R")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")

required_files <- c(
  config_path, task_path, continuation_path, patch_path, apply_path,
  runner_path, registrar_path,
  file.path(source_dir, c(
    "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
    "bet.reg_scaling", "bet.reg_scaling.full", "doitall.sh"
  ))
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing Job 17227 follow-up file(s): ", paste(missing_files, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)

if (!is.data.frame(models) || nrow(models) != 2L) {
  fail("Expected exactly two Job 17227 follow-up rows.")
}
expected_steps <- c("F15-LT70-NMAX25", "F15-LT70-NMAX25-REC02")
if (!identical(models$step_id, expected_steps)) fail("Unexpected model row order.")
if (!identical(models$run_mode, c("job_par_script", "doitall"))) {
  fail("The first row must continue a job PAR and the second must run doitall.")
}
if (!identical(models$run_script, c("continue-job17227-final-par.sh", "doitall.sh"))) {
  fail("Unexpected run scripts.")
}
if (!identical(models$phase10_11_convergence, c("-5", "-4"))) {
  fail("Expected MGC exponents -5 and -4.")
}
if (!identical(models$regional_recruitment_penalty, c("0.1", "0.2"))) {
  fail("Expected recruitment penalties 0.1 and 0.2.")
}
if (!identical(models$par_source_job, c("17227", "")) ||
    !identical(models$kflow_input_jobs, c("17227", ""))) {
  fail("Only the 1e-5 continuation may attach Job 17227.")
}
if (!identical(models$independent_fit, c(FALSE, TRUE)) ||
    !identical(models$scientific_parent_mode, c("par-input", "metadata-only"))) {
  fail("Continuation/independent-fit provenance is incorrect.")
}
expected_par_sha <- "30e5122ade18200daba7fb1b4fe7126c830684785beb90d827648fd611d03ce7"
if (!identical(models$expected_source_par_sha256, c(expected_par_sha, ""))) {
  fail("Only the continuation must require the verified Job 17227 final PAR hash.")
}
if (!identical(models$job_par_max_evaluations, c("10000", ""))) {
  fail("The final-PAR continuation must allow 10000 evaluations.")
}
if (!identical(models$f15_qc_mode, c("lt70", "lt70")) ||
    !identical(models$dm_nmax, c("25", "25")) ||
    !identical(models$tag_tau_grouping, c("common", "common")) ||
    !identical(models$tau_mode, c("estimated-common", "estimated-common"))) {
  fail("F15, Nmax or tag-tau controls differ from Job 17227.")
}
if (anyDuplicated(models$step_id) || anyDuplicated(models$job_key) ||
    anyDuplicated(models$model_label)) {
  fail("Step IDs, job keys and labels must be unique.")
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
  fail("Unexpected REC02 F15 patch content.")
}

sha256 <- function(path) {
  out <- system2("sha256sum", path, stdout = TRUE)
  strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
}
expected_source_hashes <- c(
  "bet.ini" = "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a",
  "bet.frq" = "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c",
  "bet.tag" = "b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f",
  "bet.age_length" = "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c",
  "bet.reg_scaling" = "6330fb6a36d63424c18f81cbc620c1d9607c2a5c43d0308d19941f12938ec9a1",
  "bet.reg_scaling.full" = "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed"
)
actual_hashes <- vapply(
  file.path(source_dir, names(expected_source_hashes)),
  sha256,
  character(1L)
)
names(actual_hashes) <- names(expected_source_hashes)
bad_hashes <- names(expected_source_hashes)[actual_hashes != expected_source_hashes]
if (length(bad_hashes)) {
  fail("Frozen source hash mismatch: ", paste(bad_hashes, collapse = ", "))
}

source(apply_path, local = TRUE)
test_dir <- tempfile("job17227-recpen-validation-")
dir.create(test_dir, recursive = TRUE)
on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)
if (!file.copy(file.path(source_dir, "bet.frq"), file.path(test_dir, "bet.frq"))) {
  fail("Could not stage the validation FRQ.")
}
qc <- apply_f15_lf_qc(test_dir, "lt70")
expected_patched_frq_sha <- "3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60"
if (!identical(qc$summary$output_sha256[[1L]], expected_patched_frq_sha) ||
    !identical(as.integer(qc$summary$f15_lf_rows_affected[[1L]]), 66L) ||
    !isTRUE(all.equal(qc$summary$removed_count[[1L]], 1057)) ||
    !identical(qc$summary$renormalised[[1L]], FALSE) ||
    !identical(qc$summary$catch_or_effort_changed[[1L]], FALSE)) {
  fail("The deterministic F15 <70 cm patch does not reproduce Job 17227.")
}

continuation <- readLines(continuation_path, warn = FALSE)
required_continuation <- c(
  "input_par=previous-job.par",
  "final_par=final.par",
  "convergence_exponent=${BET_PHASE10_11_CONVERGENCE:--5}",
  "regional_recruitment_penalty=${REGIONAL_RECRUITMENT_PENALTY:-0.1}",
  "expected_source_par_sha256=${EXPECTED_SOURCE_PAR_SHA256:-}",
  "  0.3)",
  "    regional_recruitment_penalty_flag=3",
  '    echo "REGIONAL_RECRUITMENT_PENALTY must be 0.1, 0.2, or 0.3." >&2',
  'awk -v header="$1" -v field_no="$2" ',
  "      print $field_no",
  '"  1 50 $convergence_exponent  # MGC threshold = 10^exponent"',
  '"  2 110 $regional_recruitment_penalty_flag  # default 0.1 when 0; positive values are divided by 10"',
  '"$program_path" "$frq" "$input_par" "$final_par" -file "$control_file"',
  'if [ "$source_par_sha256" != "$expected_source_par_sha256" ]; then',
  'if [ "$source_age_flag_110" != 0 ]; then',
  'if [ "$source_parest_flag_50" != -4 ]; then',
  "estimated_tau_count=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' indepvar.rpt)"
)
missing_continuation <- required_continuation[
  !vapply(required_continuation, function(x) any(grepl(x, continuation, fixed = TRUE)), logical(1L))
]
if (length(missing_continuation)) {
  fail("Continuation controls are incomplete: ", paste(missing_continuation, collapse = " | "))
}
if (any(grepl('awk -v header="$1" -v index=', continuation, fixed = TRUE))) {
  fail("Continuation awk uses reserved built-in name index as a variable.")
}

doitall <- readLines(file.path(source_dir, "doitall.sh"), warn = FALSE)
required_doitall <- c(
  "regional_recruitment_penalty=${REGIONAL_RECRUITMENT_PENALTY:-0.1}",
  "    regional_recruitment_penalty_flag=2",
  "    regional_recruitment_penalty_flag=3",
  '    echo "REGIONAL_RECRUITMENT_PENALTY must be 0.1, 0.2, or 0.3." >&2',
  "  2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient",
  "  1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound",
  "  1 50 $phase10_11_convergence"
)
missing_doitall <- setdiff(required_doitall, doitall)
if (length(missing_doitall)) {
  fail("Doitall rec-penalty/convergence controls are incomplete: ", paste(missing_doitall, collapse = " | "))
}

runner <- readLines(runner_path, warn = FALSE)
for (control in c(
  "is_job_par_script_mode <- function(run_mode) {",
  '"job_par_script", "previous_job_par_script"',
  'if (is_job_par_script_mode(requested_run_mode)) {',
  'run_mode <- "script"',
  '"job-par-control.txt"',
  '"job-par-continuation-audit.csv"'
)) {
  if (!any(grepl(control, runner, fixed = TRUE))) {
    fail("Stepwise runner is missing continuation support: ", control)
  }
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("par_source_job", "PAR_SOURCE_JOB")',
  '("kflow_input_jobs", "KFLOW_INPUT_JOBS")',
  '("expected_source_par_sha256", "EXPECTED_SOURCE_PAR_SHA256")',
  '("job_par_max_evaluations", "JOB_PAR_MAX_EVALUATIONS")',
  '("phase10_11_convergence", "BET_PHASE10_11_CONVERGENCE")',
  '("regional_recruitment_penalty", "REGIONAL_RECRUITMENT_PENALTY")',
  '"input_jobs": split_job_refs(row.get("kflow_input_jobs"))'
)) {
  if (!any(grepl(mapping, registrar, fixed = TRUE))) {
    fail("Kflow registrar is missing per-row wiring: ", mapping)
  }
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-job17227-finalpar-mgc-recpen-20260728",
  "branch: sensitivity/job17227-finalpar-mgc-recpen-20260728",
  "command: Rscript --vanilla scripts/validate_job17227_finalpar_mgc_recpen.R && bash run.sh",
  "  CONFIG_R: job-config-job17227-finalpar-mgc-recpen.R",
  "  RUN_MODE: job_par_script",
  "  F15_QC_MODE: lt70",
  "  DM_NMAX: \"25\"",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-5\"",
  "  PAR_SOURCE_JOB: \"17227\"",
  "  KFLOW_INPUT_JOBS: \"17227\"",
  paste0("  EXPECTED_SOURCE_PAR_SHA256: \"", expected_par_sha, "\""),
  "  JOB_PAR_MAX_EVALUATIONS: \"10000\"",
  "  model_count: 2",
  "  common_tag_tau_estimated: true",
  "  natural_mortality_fixed: true"
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow task defaults/metadata are incomplete: ", paste(missing_task, collapse = " | "))
}
if (any(grepl("^input_jobs:", task))) {
  fail("The task must not attach Job 17227 globally; only campaign row 1 may attach it.")
}

cat(
  "Validated two Job 17227 follow-ups: exact-PAR rec0.1 continuation to 1e-5; ",
  "independent rec0.2 doitall to 1e-4; row-specific Job 17227 attachment; ",
  "F15 <70 cm; Nmax=25; common estimated tau; fixed M. Both the final-PAR ",
  "continuation and independent doitall paths support the separate rec0.3 ",
  "sensitivity through an explicit age flag 110=3 runtime override.\n",
  sep = ""
)
