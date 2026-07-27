fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job16594-f15-qc-sensitivity.R")
task_path <- file.path(root, "kflow-job16594-f15-qc-sensitivity.yaml")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
apply_path <- file.path(root, "R", "apply_f15_lf_qc.R")
runner_path <- file.path(root, "R", "run_stepwise.R")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")

required_files <- c(
  config_path, task_path, apply_path, runner_path, registrar_path,
  file.path(source_dir, c(
    "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
    "bet.reg_scaling", "bet.reg_scaling.full", "doitall.sh",
    "fishery_map.R", "tag_rep_map.R"
  ))
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing F15 QC campaign files: ", paste(missing_files, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
expected_steps <- c(
  "F15-LT68-NMAX25", "F15-LT70-NMAX25",
  "F15-LT68-NMAX15", "F15-LT70-NMAX15"
)
expected_modes <- rep(c("lt68", "lt70"), 2L)
expected_nmax <- c(rep("25", 2L), rep("15", 2L))

if (!is.data.frame(models) || nrow(models) != 4L) {
  fail("Expected exactly four F15 QC sensitivity rows.")
}
if (!identical(models$step_id, expected_steps)) {
  fail("Unexpected F15 QC step order: ", paste(models$step_id, collapse = ", "))
}
if (!identical(as.character(models$f15_qc_mode), expected_modes)) {
  fail("Unexpected F15 QC mode order.")
}
if (!identical(as.character(models$dm_nmax), expected_nmax)) {
  fail("Nmax rows must be four Nmax=25 followed by four Nmax=15.")
}
if (!identical(models$tag_tau_grouping, rep("common", 4L)) ||
    !identical(models$tau_mode, rep("estimated-common", 4L))) {
  fail("Every F15 QC sensitivity must estimate one common tag tau.")
}
if (!identical(
  models$source_dir,
  rep("steps/S03-CommonTagTau-MIX015/model", 4L)
)) {
  fail("Every F15 QC row must stage the exact Job 16594 S03 source model.")
}
if (anyDuplicated(models$step_id) || anyDuplicated(models$job_key) ||
    anyDuplicated(models$model_label)) {
  fail("F15 QC step IDs, job keys and labels must be unique.")
}

expected_patch <- c(
  'source(file.path(getwd(), "R", "apply_f15_lf_qc.R"), local = TRUE)',
  'env_mode <- Sys.getenv("F15_QC_MODE", "")',
  'if (nzchar(env_mode) && !identical(env_mode, config$F15_QC_MODE)) {',
  '  stop("F15_QC_MODE environment/config mismatch.", call. = FALSE)',
  '}',
  'apply_f15_lf_qc(model_dir, config$F15_QC_MODE)'
)
for (step in expected_steps) {
  step_dir <- file.path(root, "steps", step)
  patch_path <- file.path(step_dir, "patch.R")
  if (!dir.exists(step_dir) || !file.exists(patch_path)) {
    fail("Missing F15 QC step or patch: ", step)
  }
  if (!identical(readLines(patch_path, warn = FALSE), expected_patch)) {
    fail("Unexpected patch.R content for ", step, ".")
  }
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
  "bet.reg_scaling.full" = "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed",
  "fishery_map.R" = "0e989f4692c4a2a54abf22f12a1c53c7bd29cb7f0f3bd7c4457cdd3d6e1a125c",
  "tag_rep_map.R" = "e1bddfe316a8b3e39333d0792f58db8f070d3f6f370770507e2f500f9d88786c"
)
actual_hashes <- vapply(
  file.path(source_dir, names(expected_source_hashes)),
  sha256,
  character(1L)
)
names(actual_hashes) <- names(expected_source_hashes)
bad_hashes <- names(expected_source_hashes)[actual_hashes != expected_source_hashes]
if (length(bad_hashes)) {
  fail(
    "Frozen Job 16594 source hash mismatch: ",
    paste(paste0(bad_hashes, "=", actual_hashes[bad_hashes]), collapse = ", ")
  )
}

doitall <- readLines(file.path(source_dir, "doitall.sh"), warn = FALSE)
required_doitall <- c(
  'dm_nmax=${DM_NMAX:-25}',
  '  10|15|25|40|50)',
  '    dm_nmax_flag=$dm_nmax',
  'tag_tau_grouping=${TAG_TAU_GROUPING:-common}',
  '    expected_tau_count=1',
  '    tag_tau_grouping_label=common-F1-F28',
  '  1 111 4    # negative-binomial tag-recapture likelihood',
  '  1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound',
  'actual_tau=$(awk \'$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}\' indepvar.rpt)'
)
missing_doitall <- setdiff(required_doitall, doitall)
if (length(missing_doitall)) {
  fail("Job 16594 Nmax/tau controls are incomplete: ", paste(missing_doitall, collapse = " | "))
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("dm_nmax", "DM_NMAX")',
  '("f15_qc_mode", "F15_QC_MODE")'
)) {
  if (!any(grepl(mapping, registrar, fixed = TRUE))) {
    fail("Kflow registrar is missing row mapping: ", mapping)
  }
}
runner <- readLines(runner_path, warn = FALSE)
for (artifact in c('"f15-lf-qc-audit.csv"', '"f15-lf-qc-summary.csv"')) {
  if (!any(grepl(artifact, runner, fixed = TRUE))) {
    fail("Stepwise runner will not preserve ", artifact, ".")
  }
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-job16594-f15-length-qc-dm15-25-20260727",
  "branch: sensitivity/job16594-f15-length-qc-dm15-25-20260727",
  "command: Rscript --vanilla scripts/validate_job16594_f15_qc_sensitivity.R && bash run.sh",
  "  CONFIG_R: job-config-job16594-f15-qc-sensitivity.R",
  "  F15_QC_MODE: lt68",
  "  DM_NMAX: \"25\"",
  "  TAG_TAU_GROUPING: common",
  "  TAG_TAU_LOWER_BOUND: default",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  ESTIMATE_M_FINAL: \"false\"",
  "  TAG_LIKELIHOOD_WEIGHT: \"0\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  base_job: \"16594\"",
  "  unfiltered_nmax15_reference_job: \"17222\"",
  "  f15_qc_modes: [lt68, lt70]",
  "  dm_nmax_values: [25, 15]",
  "  model_count: 4",
  "  removed_counts_renormalised: false",
  "  catch_effort_changed: false"
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow F15 QC task is incomplete: ", paste(missing_task, collapse = " | "))
}

source(apply_path, local = TRUE)
test_root <- tempfile("job16594-f15-qc-validation-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)
expected_mode_results <- data.frame(
  mode = c("lt68", "lt70"),
  output_sha256 = c(
    "7cc230a126b67d96b305cb9af8e61eb346554cc6974d75e76ec5c8645f2e5990",
    "3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60"
  ),
  affected = c(61L, 66L),
  rows_after = c(135L, 135L),
  removed = c(867, 1057),
  stringsAsFactors = FALSE
)
source_frq <- file.path(source_dir, "bet.frq")
for (i in seq_len(nrow(expected_mode_results))) {
  expectation <- expected_mode_results[i, , drop = FALSE]
  mode_dir <- file.path(test_root, expectation$mode)
  dir.create(mode_dir)
  if (!file.copy(source_frq, file.path(mode_dir, "bet.frq"))) {
    fail("Could not stage validation FRQ for ", expectation$mode, ".")
  }
  result <- apply_f15_lf_qc(mode_dir, expectation$mode)
  summary <- result$summary
  checks <- c(
    identical(summary$output_sha256[[1L]], expectation$output_sha256),
    identical(as.integer(summary$f15_lf_rows_affected[[1L]]), expectation$affected),
    identical(as.integer(summary$f15_lf_rows_after[[1L]]), expectation$rows_after),
    isTRUE(all.equal(summary$removed_count[[1L]], expectation$removed)),
    identical(summary$renormalised[[1L]], FALSE),
    identical(summary$catch_or_effort_changed[[1L]], FALSE)
  )
  if (!all(checks)) fail("Unexpected deterministic F15 QC result for ", expectation$mode, ".")
}

if (!identical(sha256(source_frq), expected_source_hashes[["bet.frq"]])) {
  fail("Validation modified the frozen Job 16594 source FRQ.")
}

cat(
  "Validated Job 16594 F15 LF QC campaign: four independent rows; ",
  "exact frozen inputs; deterministic F15-only edits; Nmax 25/15; ",
  "common estimated tau; no renormalisation; catch and effort unchanged.\n",
  sep = ""
)
