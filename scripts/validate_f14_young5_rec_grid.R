fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-f14-young5-rec-grid.R")
task_path <- file.path(root, "kflow-f14-young5-rec-grid.yaml")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
doitall_path <- file.path(source_dir, "doitall.sh")
apply_path <- file.path(root, "R", "apply_f15_lf_qc.R")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")
step_ids <- c("F14-Y5-REC01", "F14-Y5-REC02")
patch_paths <- file.path(root, "steps", step_ids, "patch.R")

required_files <- c(
  config_path, task_path, doitall_path, apply_path, registrar_path, patch_paths,
  file.path(source_dir, c(
    "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
    "bet.reg_scaling", "bet.reg_scaling.full"
  ))
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing F14 sensitivity file(s): ", paste(missing_files, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)

if (!is.data.frame(models) || nrow(models) != 2L) {
  fail("Expected exactly two independent F14 sensitivity rows.")
}
if (!identical(models$step_id, step_ids) ||
    !identical(models$STEP_SELECT, step_ids)) {
  fail("Unexpected model row order or STEP_SELECT values.")
}
if (!identical(models$run_mode, c("doitall", "doitall")) ||
    !identical(models$run_script, c("doitall.sh", "doitall.sh")) ||
    !identical(models$independent_fit, c(TRUE, TRUE))) {
  fail("Both rows must be independent doitall fits.")
}
if (!identical(models$scientific_parent_mode, c("metadata-only", "metadata-only"))) {
  fail("Scientific parents must be provenance metadata only.")
}
if (!identical(models$regional_recruitment_penalty, c("0.1", "0.2"))) {
  fail("Expected regional recruitment penalties 0.1 and 0.2.")
}
if (!identical(models$phase10_11_convergence, c("-4", "-4")) ||
    !identical(models$dm_nmax, c("25", "25")) ||
    !identical(models$f14_youngest_zero, c("5", "5"))) {
  fail("Expected F14=5, Nmax=25 and MGC=1e-4 in both rows.")
}
if (!identical(models$f15_qc_mode, c("lt70", "lt70")) ||
    !identical(models$tag_tau_grouping, c("common", "common")) ||
    !identical(models$tau_mode, c("estimated-common", "estimated-common"))) {
  fail("F15 QC or tag-tau controls differ between rows.")
}
for (field in c(
  "input_par", "output_par", "par_source_job", "kflow_input_jobs",
  "expected_source_par_sha256", "job_par_max_evaluations"
)) {
  if (!identical(models[[field]], c("", ""))) {
    fail(field, " must be empty: doitall may not attach or continue a previous PAR.")
  }
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
for (patch_path in patch_paths) {
  if (!identical(readLines(patch_path, warn = FALSE), expected_patch)) {
    fail("Unexpected F15 QC patch content: ", patch_path)
  }
}

sha256 <- function(path) {
  out <- system2("sha256sum", path, stdout = TRUE)
  strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
}
expected_hashes <- c(
  "doitall.sh" = "9a5922133fd749ff162972590897f47796e0423c18dc71d0e332828f37e92ccf",
  "bet.ini" = "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a",
  "bet.frq" = "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c",
  "bet.tag" = "b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f",
  "bet.age_length" = "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c",
  "bet.reg_scaling" = "6330fb6a36d63424c18f81cbc620c1d9607c2a5c43d0308d19941f12938ec9a1",
  "bet.reg_scaling.full" = "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed"
)
hash_paths <- file.path(source_dir, names(expected_hashes))
actual_hashes <- vapply(hash_paths, sha256, character(1L))
names(actual_hashes) <- names(expected_hashes)
bad_hashes <- names(expected_hashes)[actual_hashes != expected_hashes]
if (length(bad_hashes)) {
  fail("Frozen source hash mismatch: ", paste(bad_hashes, collapse = ", "))
}

doitall <- readLines(doitall_path, warn = FALSE)
exact_count <- function(text) sum(trimws(doitall) == text)
required_controls <- c(
  "-14 24 12  # F14 selectivity-stability group" = 2L,
  "-15 24 13  # F15 selectivity-stability group" = 2L,
  "-14 75 5  # F14 HL.ID.2 youngest age classes fixed at zero selectivity" = 1L,
  "-15 75 5  # F15 youngest age classes fixed at zero selectivity" = 1L,
  "2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient" = 1L,
  "1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound" = 1L,
  "1 50 $phase10_11_convergence" = 2L
)
bad_controls <- names(required_controls)[
  vapply(names(required_controls), exact_count, integer(1L)) != required_controls
]
if (length(bad_controls)) {
  fail("Missing or duplicated doitall control(s): ", paste(bad_controls, collapse = " | "))
}
if (!any(grepl("0.1)", doitall, fixed = TRUE)) ||
    !any(grepl("regional_recruitment_penalty_flag=0", doitall, fixed = TRUE)) ||
    !any(grepl("0.2)", doitall, fixed = TRUE)) ||
    !any(grepl("regional_recruitment_penalty_flag=2", doitall, fixed = TRUE))) {
  fail("Doitall does not map rec penalties 0.1 and 0.2 to age flag 110 correctly.")
}
if (!any(grepl("$program_path bet.frq bet.ini 00.par -makepar", doitall, fixed = TRUE))) {
  fail("Doitall no longer starts from bet.ini using -makepar.")
}

source(apply_path, local = TRUE)
test_dir <- tempfile("f14-young5-validation-")
dir.create(test_dir, recursive = TRUE)
on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)
if (!file.copy(file.path(source_dir, "bet.frq"), file.path(test_dir, "bet.frq"))) {
  fail("Could not stage the validation FRQ.")
}
qc <- apply_f15_lf_qc(test_dir, "lt70")
if (!identical(qc$summary$output_sha256[[1L]],
               "3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60") ||
    !identical(as.integer(qc$summary$f15_lf_rows_affected[[1L]]), 66L) ||
    !isTRUE(all.equal(qc$summary$removed_count[[1L]], 1057)) ||
    !identical(qc$summary$renormalised[[1L]], FALSE) ||
    !identical(qc$summary$catch_or_effort_changed[[1L]], FALSE)) {
  fail("The deterministic F15 <70 cm patch does not reproduce Job 17227/17513.")
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
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
  "name: bet-2026-f14-young5-rec-grid-20260728",
  "branch: sensitivity/job17513-f14-young5-rec-grid-20260728",
  "command: Rscript --vanilla scripts/validate_f14_young5_rec_grid.R && bash run.sh",
  "  CONFIG_R: job-config-f14-young5-rec-grid.R",
  "  STEP_SELECT: F14-Y5-REC01",
  "  RUN_MODE: doitall",
  "  F15_QC_MODE: lt70",
  "  DM_NMAX: \"25\"",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  model_count: 2",
  "  common_tag_tau_estimated: true",
  "  natural_mortality_fixed: true",
  "  execution: \"independent doitall from bet.ini for both rows\""
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow task defaults/metadata are incomplete: ", paste(missing_task, collapse = " | "))
}
if (any(grepl("^input_jobs:", task))) {
  fail("The task must not attach a previous job; both rows are doitall.")
}

cat(
  "Validated two independent F14 youngest-five-age doitall sensitivities: ",
  "rec penalties 0.1 and 0.2; MGC 1e-4; Nmax=25; F15 <70 cm; ",
  "common estimated tag tau; fixed M; no previous PAR inputs.\n",
  sep = ""
)
