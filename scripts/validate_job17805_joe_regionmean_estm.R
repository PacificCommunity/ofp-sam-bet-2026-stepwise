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
required_files <- c(
  base_config_path, config_path, task_path, base_validator,
  registrar_path, doitall_path
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
    !identical(models$step_id, c(
      "F14-Y5-REC01-JOE-K015", "F14-Y5-REC01-JOE-K020"
    )) ||
    !identical(models$mixing_period_mode, c(
      "joe-regionmean-k015", "joe-regionmean-k020"
    ))) {
  fail("Expected exactly the ordered Joe K=0.15 and K=0.20 rows.")
}
changed_metadata_fields <- c(
  "major_step", "substep", "change_axis", "control_notes",
  "model_label", "job_title", "job_key", "estimate_m_final"
)
unchanged_fields <- setdiff(names(base_models), changed_metadata_fields)
for (field in unchanged_fields) {
  if (!identical(models[[field]], base_models[[field]])) {
    fail("Estimated-M config differs from fixed-M Joe controls: ", field)
  }
}
if (!identical(models$estimate_m_final, rep("true", 2)) ||
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

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("mixing_period_mode", "MIXING_PERIOD_MODE")',
  '("estimate_m_final", "ESTIMATE_M_FINAL")',
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
  "  STEP_SELECT: F14-Y5-REC01-JOE-K015",
  "  MIXING_PERIOD_MODE: joe-regionmean-k015",
  "  RUN_MODE: doitall",
  "  ESTIMATE_M_FINAL: \"true\"",
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
  "counterparts; M fixed through Phase 10 and one age_pars(5) Lorenzen ",
  "intercept estimated in Phases 11-12; all other Job 17805 controls retained.\n",
  sep = ""
)
