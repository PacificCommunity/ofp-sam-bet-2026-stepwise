fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
base_config_path <- file.path(root, "job-config-job17805-joe-regionmean.R")
config_path <- file.path(root, "job-config-job17805-joe-regionmean-estm.R")
task_path <- file.path(root, "kflow-job17805-joe-regionmean-estm.yaml")
base_validator <- file.path(
  root, "scripts", "validate_job17805_joe_regionmean_mixing.R"
)
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")
doitall_path <- file.path(
  root, "steps", "S03-CommonTagTau-MIX015", "model", "doitall.sh"
)
source_dir <- dirname(doitall_path)
step_ids <- c(
  "F14-Y5-REC01-JOE-K015-ESTM",
  "F14-Y5-REC01-JOE-K020-ESTM"
)
patch_paths <- file.path(root, "steps", step_ids, "patch.R")
source_input_names <- c(
  "doitall.sh", "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
  "bet.reg_scaling", "bet.reg_scaling.full"
)
required_files <- c(
  base_config_path, config_path, task_path, base_validator,
  registrar_path, doitall_path, patch_paths,
  file.path(root, "R", "apply_lorenzen_m_start.R"),
  file.path(source_dir, source_input_names)
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing Joe estimated-M sensitivity file(s): ",
       paste(missing_files, collapse = ", "))
}

base_check <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", base_validator),
  stdout = TRUE,
  stderr = TRUE
)
base_status <- attr(base_check, "status")
if (is.null(base_status)) base_status <- 0L
if (base_status != 0L) {
  fail(
    "Underlying fixed-M Joe mixing validation failed:\n",
    paste(base_check, collapse = "\n")
  )
}

base_cfg <- new.env(parent = baseenv())
new_cfg <- new.env(parent = baseenv())
sys.source(base_config_path, envir = base_cfg)
sys.source(config_path, envir = new_cfg)
base_models <- get("stepwise_models", envir = base_cfg)
models <- get("stepwise_models", envir = new_cfg)

if (!is.data.frame(models) || nrow(models) != 2L ||
    !identical(models$step_id, step_ids) ||
    !identical(models$STEP_SELECT, step_ids) ||
    !identical(models$mixing_period_mode, c(
      "joe-regionmean-k015", "joe-regionmean-k020"
    ))) {
  fail("Expected exactly the ordered Joe K=0.15 and K=0.20 rows.")
}
changed_metadata_fields <- c(
  "step_id", "STEP_SELECT",
  "major_step", "substep", "change_axis", "control_notes",
  "model_label", "job_title", "job_key", "estimate_m_final",
  "m_start_intercept"
)
unchanged_fields <- setdiff(names(base_models), changed_metadata_fields)
for (field in unchanged_fields) {
  if (!identical(models[[field]], base_models[[field]])) {
    fail("Estimated-M config differs from fixed-M Joe controls: ", field)
  }
}
if (!identical(models$estimate_m_final, rep("true", 2)) ||
    !identical(models$m_start_intercept, rep("-3", 2)) ||
    !identical(models$run_mode, rep("doitall", 2)) ||
    !identical(models$run_script, rep("doitall.sh", 2)) ||
    !identical(models$independent_fit, rep(TRUE, 2)) ||
    !identical(models$phase10_11_convergence, rep("-4", 2))) {
  fail("Both rows must be independent doitall fits estimating M at MGC 1e-4.")
}
for (field in c(
  "input_par", "output_par", "par_source_job", "kflow_input_jobs",
  "expected_source_par_sha256", "job_par_max_evaluations"
)) {
  if (!identical(models[[field]], rep("", 2))) {
    fail(field, " must remain empty; no previous PAR may be attached.")
  }
}

doitall <- readLines(doitall_path, warn = FALSE)
required_m_controls <- c(
  "estimate_m_final=${ESTIMATE_M_FINAL:-false}",
  "    mortality_phase11_flag=0",
  "    mortality_phase11_flag=1",
  "  1 121 0    # keep the INI Lorenzen natural-mortality value fixed",
  "  1 121 $mortality_phase11_flag  # estimate M only in the final two phases when requested",
  "  1 121 $mortality_phase11_flag  # retain the requested final-phase M treatment",
  "estimated_m_count=$(awk '$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}' indepvar.rpt)",
  'if [ "$estimated_m_count" -ne 1 ]; then',
  '"$estimate_m_final" "$estimated_m_count" "$phase10_m" "$final_m"'
)
missing_m_controls <- required_m_controls[
  !vapply(
    required_m_controls,
    function(x) any(grepl(x, doitall, fixed = TRUE)),
    logical(1L)
  )
]
if (length(missing_m_controls)) {
  fail("Direct-doitall M controls are incomplete: ",
       paste(missing_m_controls, collapse = " | "))
}
if (sum(trimws(doitall) ==
        "1 121 $mortality_phase11_flag  # estimate M only in the final two phases when requested") != 1L ||
    sum(trimws(doitall) ==
        "1 121 $mortality_phase11_flag  # retain the requested final-phase M treatment") != 1L) {
  fail("M must open exactly once in Phase 11 and remain open in Phase 12.")
}

expected_patch_sources <- c(
  "F14-Y5-REC01-JOE-K015", "F14-Y5-REC01-JOE-K020"
)
for (i in seq_along(patch_paths)) {
  patch <- readLines(patch_paths[[i]], warn = FALSE)
  required_patch <- c(
    paste0(
      'source(file.path(getwd(), "steps", "',
      expected_patch_sources[[i]], '", "patch.R"), local = TRUE)'
    ),
    'source(file.path(getwd(), "R", "apply_lorenzen_m_start.R"), local = TRUE)',
    'env_m_start <- Sys.getenv("M_START_INTERCEPT", "")',
    'apply_lorenzen_m_start(model_dir, config$M_START_INTERCEPT)'
  )
  if (!all(required_patch %in% patch)) {
    fail("Estimated-M step patch is incomplete: ", patch_paths[[i]])
  }
}

sha256 <- function(path) {
  out <- system2("sha256sum", path, stdout = TRUE)
  strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
}
test_root <- tempfile("joe-regionmean-estm-validation-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)
staged_ini_hashes <- character(2)
for (i in seq_len(2L)) {
  model_dir <- file.path(test_root, step_ids[[i]])
  dir.create(model_dir, recursive = TRUE)
  copied <- file.copy(
    file.path(source_dir, source_input_names),
    file.path(model_dir, source_input_names),
    overwrite = TRUE
  )
  if (!all(copied)) fail("Could not stage estimated-M validation inputs.")

  patch_env <- new.env(parent = globalenv())
  patch_env$model_dir <- normalizePath(model_dir, mustWork = TRUE)
  patch_env$config <- list(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    DOM_QC_MODE = models$dom_qc_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]],
    MIXING_PERIOD_MODE = models$mixing_period_mode[[i]],
    M_START_INTERCEPT = models$m_start_intercept[[i]]
  )
  Sys.setenv(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    DOM_QC_MODE = models$dom_qc_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]],
    MIXING_PERIOD_MODE = models$mixing_period_mode[[i]],
    M_START_INTERCEPT = models$m_start_intercept[[i]]
  )
  sys.source(patch_paths[[i]], envir = patch_env)

  m_audit <- utils::read.csv(
    file.path(model_dir, "lorenzen-m-start-audit.csv"),
    stringsAsFactors = FALSE
  )
  if (nrow(m_audit) != 1L ||
      !isTRUE(all.equal(as.numeric(m_audit$source_intercept),
                       -2.54930339768360, tolerance = 1e-12)) ||
      !isTRUE(all.equal(as.numeric(m_audit$requested_start_intercept),
                       -3, tolerance = 1e-12)) ||
      !isTRUE(all.equal(as.numeric(m_audit$fixed_lorenzen_length_slope),
                       -1, tolerance = 1e-12))) {
    fail("Lorenzen M=-3 audit failed for ", step_ids[[i]], ".")
  }
  mix_audit <- utils::read.csv(
    file.path(model_dir, "tag-mixing-period-audit.csv"),
    stringsAsFactors = FALSE
  )
  expected_mix_changes <- if (i == 1L) 37L else 32L
  if (nrow(mix_audit) != 98L ||
      sum(mix_audit$changed) != expected_mix_changes) {
    fail("Joe mixing audit failed for ", step_ids[[i]], ".")
  }
  if (!identical(
    sha256(file.path(model_dir, "bet.frq")),
    "9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3"
  )) {
    fail("F15/DOM QC FRQ differs from Job 17805 for ", step_ids[[i]], ".")
  }
  ini <- readLines(file.path(model_dir, "bet.ini"), warn = FALSE)
  age_marker <- which(trimws(ini) == "# age_pars")
  if (length(age_marker) != 1L) fail("Missing age_pars block.")
  age_fields <- strsplit(
    trimws(ini[[age_marker + 5L]]), "[[:space:]]+"
  )[[1L]]
  if (length(age_fields) != 40L ||
      !isTRUE(all.equal(as.numeric(age_fields[[1L]]), -3,
                       tolerance = 1e-12)) ||
      !isTRUE(all.equal(as.numeric(age_fields[[2L]]), -1,
                       tolerance = 1e-12))) {
    fail("Staged INI does not contain M start -3 with fixed slope -1.")
  }
  staged_ini_hashes[[i]] <- sha256(file.path(model_dir, "bet.ini"))
}
expected_ini_hashes <- c(
  "0c50476c8287862e451c19bf51bb1fce3332f4146cbac6c88e6f1ef67b98f6ae",
  "f22599c8767204a8e789c1c68249abfad24740fb220df8c7e4fe196a9ac4bdc4"
)
if (!identical(staged_ini_hashes, expected_ini_hashes)) {
  fail("K=0.15 or K=0.20 staged M=-3 INI checksum mismatch.")
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("mixing_period_mode", "MIXING_PERIOD_MODE")',
  '("estimate_m_final", "ESTIMATE_M_FINAL")',
  '("m_start_intercept", "M_START_INTERCEPT")',
  '("regional_recruitment_penalty", "REGIONAL_RECRUITMENT_PENALTY")',
  '("movement_prior_penalty", "MOVEMENT_PRIOR_PENALTY")',
  '"input_jobs": split_job_refs(row.get("kflow_input_jobs"))'
)) {
  if (!any(grepl(mapping, registrar, fixed = TRUE))) {
    fail("Kflow registrar is missing per-row wiring: ", mapping)
  }
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-job17805-joe-regionmean-k015-k020-estm-20260729",
  "branch: sensitivity/job17805-joe-regionmean-k015-k020-estm-20260729",
  "command: Rscript --vanilla scripts/validate_job17805_joe_regionmean_estm.R && bash run.sh",
  "  CONFIG_R: job-config-job17805-joe-regionmean-estm.R",
  "  STEP_SELECT: F14-Y5-REC01-JOE-K015-ESTM",
  "  MIXING_PERIOD_MODE: joe-regionmean-k015",
  "  RUN_MODE: doitall",
  "  ESTIMATE_M_FINAL: \"true\"",
  "  M_START_INTERCEPT: \"-3\"",
  "  F15_QC_MODE: lt70",
  "  DOM_QC_MODE: gt90_midpoint",
  "  DM_NMAX: \"25\"",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  MOVEMENT_PRIOR_PENALTY: \"0.1\"",
  "  OPR_MODE: \"off\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  m_phase10_fixed: true",
  "  m_phases11_12_estimated: true",
  "  expected_estimated_m_count: 1",
  "  requested_starting_m_intercept: \"-3.0\"",
  "  staged_k015_ini_sha256: 0c50476c8287862e451c19bf51bb1fce3332f4146cbac6c88e6f1ef67b98f6ae",
  "  staged_k020_ini_sha256: f22599c8767204a8e789c1c68249abfad24740fb220df8c7e4fe196a9ac4bdc4",
  "  model_count: 2",
  "  common_tag_tau_estimated: true",
  "  natural_mortality_estimated: true"
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow task defaults/metadata are incomplete: ",
       paste(missing_task, collapse = " | "))
}
if (any(grepl("^input_jobs:", task))) {
  fail("Estimated-M Joe rows must run doitall without attached jobs.")
}

cat(
  "Validated two independent Joe region-mean doitall estimated-M fits: ",
  "K=0.15 and K=0.20 mixing vectors unchanged from their fixed-M ",
  "counterparts; INI M-intercept start set to -3; M fixed through Phase 10 ",
  "and one age_pars(5) Lorenzen ",
  "intercept estimated in Phases 11-12; all other Job 17805 controls retained.\n",
  sep = ""
)
