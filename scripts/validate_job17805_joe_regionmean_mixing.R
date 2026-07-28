fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job17805-joe-regionmean.R")
task_path <- file.path(root, "kflow-job17805-joe-regionmean.yaml")
vector_path <- file.path(root, "config", "job17805-joe-regionmean-mixing.csv")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")
step_ids <- c("F14-Y5-REC01-JOE-K015", "F14-Y5-REC01-JOE-K020")
patch_paths <- file.path(root, "steps", step_ids, "patch.R")
source_input_names <- c(
  "doitall.sh", "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
  "bet.reg_scaling", "bet.reg_scaling.full"
)
required_files <- c(
  config_path, task_path, vector_path, registrar_path, patch_paths,
  file.path(root, "R", c(
    "apply_job17805_joe_mixing.R", "apply_f15_lf_qc.R",
    "apply_dom_lf_qc.R", "apply_movement_prior_penalty.R",
    "apply_opr_sensitivity.R", "prepare_common.R", "prepare_doitall.R"
  )),
  file.path(source_dir, source_input_names)
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing Job 17805 Joe mixing sensitivity file(s): ",
       paste(missing_files, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
expected_modes <- c("joe-regionmean-k015", "joe-regionmean-k020")
if (!is.data.frame(models) || nrow(models) != 2L ||
    !identical(models$step_id, step_ids) ||
    !identical(models$STEP_SELECT, step_ids) ||
    !identical(models$mixing_period_mode, expected_modes)) {
  fail("Expected exactly the ordered Joe K=0.15 and K=0.20 model rows.")
}

constant_controls <- list(
  run_mode = "doitall",
  run_script = "doitall.sh",
  independent_fit = TRUE,
  scientific_parent = "Job 17805",
  scientific_parent_mode = "metadata-only",
  f14_youngest_zero = "5",
  f15_qc_mode = "lt70",
  dom_qc_mode = "gt90_midpoint",
  dm_nmax = "25",
  tau_mode = "estimated-common",
  tag_tau_grouping = "common",
  regional_recruitment_penalty = "0.1",
  movement_prior_penalty = "0.1",
  opr_mode = "off",
  phase10_11_convergence = "-4",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  kflow_cpus = 2L,
  kflow_memory = "8GB",
  kflow_disk = "8GB",
  mfcl_program_path = "/home/mfcl/mfclo64"
)
for (field in names(constant_controls)) {
  expected <- rep(constant_controls[[field]], 2)
  if (!identical(models[[field]], expected)) {
    fail("Non-mixing Job 17805 control differs between rows: ", field)
  }
}
for (field in c(
  "input_par", "output_par", "par_source_job", "kflow_input_jobs",
  "expected_source_par_sha256", "job_par_max_evaluations"
)) {
  if (!identical(models[[field]], rep("", 2))) {
    fail(field, " must remain empty; both rows must start with -makepar.")
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
actual_hashes <- vapply(
  file.path(source_dir, names(expected_hashes)), sha256, character(1L)
)
names(actual_hashes) <- names(expected_hashes)
bad_hashes <- names(expected_hashes)[actual_hashes != expected_hashes]
if (length(bad_hashes)) {
  fail("Frozen Job 17805 source hash mismatch: ",
       paste(bad_hashes, collapse = ", "))
}

vectors <- utils::read.csv(vector_path, stringsAsFactors = FALSE)
if (nrow(vectors) != 98L ||
    !identical(as.integer(vectors$release_group), 1:98)) {
  fail("Mixing table must contain exactly release groups 1:98.")
}
region1_groups <- c(16:18, 62:95)
k015_changed <- which(vectors$job17805_k015 != vectors$joe_regionmean_k015)
k020_changed <- which(vectors$job17805_k015 != vectors$joe_regionmean_k020)
if (!identical(k015_changed, region1_groups) ||
    length(k015_changed) != 37L ||
    any(vectors$job17805_k015[k015_changed] != 2L) ||
    any(vectors$joe_regionmean_k015[k015_changed] != 4L)) {
  fail("Joe K=0.15 vector is not the verified 37-group Region-1 2 -> 4 change.")
}
if (length(k020_changed) != 32L) {
  fail("Joe K=0.20 vector must differ from Job 17805 in exactly 32 groups.")
}

tag_fields <- function(path) {
  lines <- readLines(path, warn = FALSE)
  marker <- which(trimws(tolower(lines)) == "# tag flags")
  if (length(marker) != 1L) fail("Expected one # tag flags block in ", path)
  next_comment <- which(
    seq_along(lines) > marker & grepl("^[[:space:]]*#", lines)
  )
  if (!length(next_comment)) fail("Missing end of # tag flags block in ", path)
  idx <- seq.int(marker + 1L, next_comment[[1L]] - 1L)
  idx <- idx[nzchar(trimws(lines[idx]))]
  fields <- strsplit(trimws(lines[idx]), "[[:space:]]+")
  if (length(fields) != 98L || any(lengths(fields) != 10L)) {
    fail("Tag flags must be a 98 x 10 block in ", path)
  }
  list(lines = lines, idx = idx, fields = fields)
}
source_ini <- tag_fields(file.path(source_dir, "bet.ini"))
source_matrix <- do.call(rbind, source_ini$fields)
storage.mode(source_matrix) <- "integer"
if (!identical(as.integer(source_matrix[, 1]), vectors$job17805_k015)) {
  fail("Frozen source bet.ini is not the actual Job 17805 K=0.15 vector.")
}

expected_patch <- c(
  'source(file.path(getwd(), "steps", "F14-Y5-REC01", "patch.R"), local = TRUE)',
  'source(file.path(getwd(), "R", "apply_job17805_joe_mixing.R"), local = TRUE)',
  'env_mixing <- Sys.getenv("MIXING_PERIOD_MODE", "")',
  'if (nzchar(env_mixing) && !identical(env_mixing, config$MIXING_PERIOD_MODE)) {',
  '  stop("MIXING_PERIOD_MODE environment/config mismatch.", call. = FALSE)',
  '}',
  'apply_job17805_joe_mixing(model_dir, config$MIXING_PERIOD_MODE)'
)
for (path in patch_paths) {
  if (!identical(readLines(path, warn = FALSE), expected_patch)) {
    fail("Unexpected model patch content: ", path)
  }
}

test_root <- tempfile("job17805-joe-mixing-validation-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)
output_matrices <- vector("list", 2)
for (i in seq_len(nrow(models))) {
  model_dir <- file.path(test_root, models$step_id[[i]])
  dir.create(model_dir, recursive = TRUE)
  copied <- file.copy(
    file.path(source_dir, source_input_names),
    file.path(model_dir, source_input_names),
    overwrite = TRUE
  )
  if (!all(copied)) fail("Could not stage validation inputs.")

  patch_env <- new.env(parent = globalenv())
  patch_env$model_dir <- normalizePath(model_dir, mustWork = TRUE)
  patch_env$config <- list(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    DOM_QC_MODE = models$dom_qc_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]],
    MIXING_PERIOD_MODE = models$mixing_period_mode[[i]]
  )
  Sys.setenv(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    DOM_QC_MODE = models$dom_qc_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]],
    MIXING_PERIOD_MODE = models$mixing_period_mode[[i]]
  )
  sys.source(patch_paths[[i]], envir = patch_env)

  output_ini <- tag_fields(file.path(model_dir, "bet.ini"))
  output_matrix <- do.call(rbind, output_ini$fields)
  storage.mode(output_matrix) <- "integer"
  replacement <- if (i == 1L) {
    vectors$joe_regionmean_k015
  } else {
    vectors$joe_regionmean_k020
  }
  if (!identical(as.integer(output_matrix[, 1]), as.integer(replacement)) ||
      !identical(output_matrix[, 2:10, drop = FALSE],
                 source_matrix[, 2:10, drop = FALSE])) {
    fail("Only tag_flags(:,1) may change for ", models$step_id[[i]], ".")
  }
  if (!identical(output_ini$lines[-output_ini$idx],
                 source_ini$lines[-source_ini$idx])) {
    fail("bet.ini changed outside # tag flags for ", models$step_id[[i]], ".")
  }
  output_matrices[[i]] <- output_matrix

  audit <- utils::read.csv(
    file.path(model_dir, "tag-mixing-period-audit.csv"),
    stringsAsFactors = FALSE
  )
  expected_change_count <- if (i == 1L) 37L else 32L
  if (nrow(audit) != 98L ||
      sum(audit$changed) != expected_change_count ||
      !identical(as.integer(audit$replacement_mixing_period),
                 as.integer(replacement))) {
    fail("Mixing audit failed for ", models$step_id[[i]], ".")
  }
  if (!identical(
    sha256(file.path(model_dir, "bet.frq")),
    "9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3"
  )) {
    fail("F15 <70 plus DOM >90 QC FRQ differs from Job 17805 controls.")
  }
  for (name in c("bet.tag", "bet.age_length", "bet.reg_scaling",
                 "bet.reg_scaling.full")) {
    if (!identical(sha256(file.path(model_dir, name)), expected_hashes[[name]])) {
      fail("Non-mixing input unexpectedly changed: ", name)
    }
  }
  doitall <- readLines(file.path(model_dir, "doitall.sh"), warn = FALSE)
  required_controls <- c(
    "-14 75 5  # F14 HL.ID.2 youngest age classes fixed at zero selectivity",
    "-15 75 5  # F15 youngest age classes fixed at zero selectivity",
    "2 27 -1  # penalty wt 0.1 computed against prior",
    "2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient",
    "1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound",
    "1 50 $phase10_11_convergence"
  )
  if (!all(required_controls %in% trimws(doitall)) ||
      sum(trimws(doitall) == "1 50 $phase10_11_convergence") != 2L ||
      !any(grepl("$program_path bet.frq bet.ini 00.par -makepar",
                 doitall, fixed = TRUE))) {
    fail("Job 17805 doitall controls changed for ", models$step_id[[i]], ".")
  }
}
if (!identical(
  output_matrices[[1L]][, 2:10, drop = FALSE],
  output_matrices[[2L]][, 2:10, drop = FALSE]
)) {
  fail("K=0.15 and K=0.20 rows differ outside tag_flags(:,1).")
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("mixing_period_mode", "MIXING_PERIOD_MODE")',
  '("regional_recruitment_penalty", "REGIONAL_RECRUITMENT_PENALTY")',
  '("movement_prior_penalty", "MOVEMENT_PRIOR_PENALTY")',
  '("dom_qc_mode", "DOM_QC_MODE")',
  '"input_jobs": split_job_refs(row.get("kflow_input_jobs"))'
)) {
  if (!any(grepl(mapping, registrar, fixed = TRUE))) {
    fail("Kflow registrar is missing per-row wiring: ", mapping)
  }
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-job17805-joe-regionmean-k015-k020-20260729",
  "branch: sensitivity/job17805-joe-regionmean-k015-k020-20260729",
  "command: Rscript --vanilla scripts/validate_job17805_joe_regionmean_mixing.R && bash run.sh",
  "  CONFIG_R: job-config-job17805-joe-regionmean.R",
  "  STEP_SELECT: F14-Y5-REC01-JOE-K015",
  "  MIXING_PERIOD_MODE: joe-regionmean-k015",
  "  RUN_MODE: doitall",
  "  F15_QC_MODE: lt70",
  "  DOM_QC_MODE: gt90_midpoint",
  "  DM_NMAX: \"25\"",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  MOVEMENT_PRIOR_PENALTY: \"0.1\"",
  "  OPR_MODE: \"off\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  model_count: 2",
  "  scientific_parent_job: \"17805\"",
  "  only_change: \"bet.ini tag_flags(:,1), selected per model row\"",
  "  common_tag_tau_estimated: true",
  "  natural_mortality_fixed: true"
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow task defaults/metadata are incomplete: ",
       paste(missing_task, collapse = " | "))
}
if (any(grepl("^input_jobs:", task))) {
  fail("The task must not attach a previous job; both rows are doitall.")
}

cat(
  "Validated two independent Job 17805-control doitall sensitivities: ",
  "Joe all-region mean K=0.15 changes only 37 Region-1 tag mixing periods ",
  "(2 -> 4); K=0.20 changes only the verified 32 tag mixing periods; ",
  "all other INI columns/sections and model controls remain identical.\n",
  sep = ""
)
