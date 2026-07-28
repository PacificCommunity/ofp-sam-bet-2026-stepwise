fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job17805-finalpar-estimate-m.R")
task_path <- file.path(root, "kflow-job17805-finalpar-estimate-m.yaml")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
continuation_path <- file.path(source_dir, "continue-job17805-estimate-m.sh")
patch_path <- file.path(root, "steps", "F14-Y5-REC01", "patch.R")
runner_path <- file.path(root, "R", "run_stepwise.R")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")
source_input_names <- c(
  "doitall.sh", "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
  "bet.reg_scaling", "bet.reg_scaling.full"
)
required_files <- c(
  config_path, task_path, continuation_path, patch_path, runner_path,
  registrar_path, file.path(root, "R", c(
    "apply_f15_lf_qc.R", "apply_dom_lf_qc.R",
    "apply_movement_prior_penalty.R", "apply_opr_sensitivity.R"
  )),
  file.path(source_dir, source_input_names)
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing Job 17805 estimated-M sensitivity file(s): ",
       paste(missing_files, collapse = ", "))
}
if (file.access(continuation_path, mode = 1L) != 0L) {
  fail("The Job 17805 M-continuation script must be executable.")
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
if (!is.data.frame(models) || nrow(models) != 1L ||
    !identical(models$step_id, "F14-Y5-REC01") ||
    !identical(models$STEP_SELECT, "F14-Y5-REC01")) {
  fail("Expected one F14-Y5-REC01 row so Job 17805 payload matching is exact.")
}
expected <- list(
  run_mode = "job_par_script",
  run_script = "continue-job17805-estimate-m.sh",
  scientific_parent = "Job 17805",
  scientific_parent_mode = "par-input",
  independent_fit = FALSE,
  f14_youngest_zero = "5",
  f15_qc_mode = "lt70",
  dom_qc_mode = "gt90_midpoint",
  dm_nmax = "25",
  tau_mode = "estimated-common",
  tag_tau_grouping = "common",
  regional_recruitment_penalty = "0.1",
  movement_prior_penalty = "0.1",
  opr_mode = "off",
  estimate_m_final = "true",
  phase10_11_convergence = "-4",
  source_dir = "steps/S03-CommonTagTau-MIX015/model",
  kflow_cpus = 2L,
  kflow_memory = "8GB",
  kflow_disk = "8GB",
  mfcl_program_path = "/home/mfcl/mfclo64",
  input_par = "",
  frq = "bet.frq",
  output_par = "final.par",
  par_source_job = "17805",
  kflow_input_jobs = "17805",
  expected_source_par_sha256 =
    "f68bb0eb7441fed6f32151c196fced94a1c19205ec8fd7b8bd750a5355b31a04",
  job_par_max_evaluations = "10000"
)
for (field in names(expected)) {
  if (!identical(models[[field]][[1L]], expected[[field]])) {
    fail("Unexpected estimated-M model control: ", field)
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

test_dir <- tempfile("job17805-estimate-m-validation-")
dir.create(test_dir, recursive = TRUE)
on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)
copied <- file.copy(
  file.path(source_dir, source_input_names),
  file.path(test_dir, source_input_names),
  overwrite = TRUE
)
if (!all(copied)) fail("Could not stage Job 17805 validation inputs.")
patch_env <- new.env(parent = globalenv())
patch_env$model_dir <- normalizePath(test_dir, mustWork = TRUE)
patch_env$config <- list(
  F15_QC_MODE = "lt70",
  DOM_QC_MODE = "gt90_midpoint",
  MOVEMENT_PRIOR_PENALTY = "0.1",
  OPR_MODE = "off"
)
Sys.setenv(
  F15_QC_MODE = "lt70",
  DOM_QC_MODE = "gt90_midpoint",
  MOVEMENT_PRIOR_PENALTY = "0.1",
  OPR_MODE = "off"
)
sys.source(patch_path, envir = patch_env)
if (!identical(
  sha256(file.path(test_dir, "bet.frq")),
  "9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3"
)) {
  fail("The staged F15 <70 plus DOM >90 FRQ does not reproduce Job 17805.")
}
for (name in c("bet.ini", "bet.tag", "bet.age_length",
               "bet.reg_scaling", "bet.reg_scaling.full")) {
  if (!identical(sha256(file.path(test_dir, name)), expected_hashes[[name]])) {
    fail("Job 17805 patch unexpectedly changed ", name, ".")
  }
}
if (!identical(sha256(file.path(test_dir, "doitall.sh")),
               expected_hashes[["doitall.sh"]])) {
  fail("Job 17805 patch unexpectedly changed the rec/move/OPR doitall.")
}

continuation <- readLines(continuation_path, warn = FALSE)
required_continuation <- c(
  "input_par=previous-job.par",
  "start_par=m-start-minus3.par",
  "stage_a_par=m-open-1e3.par",
  "final_par=final.par",
  "final_convergence_exponent=${BET_PHASE10_11_CONVERGENCE:--4}",
  "stage_a_evaluations=${M_STAGE_A_MAX_EVALUATIONS:-3000}",
  "final_evaluations=${JOB_PAR_MAX_EVALUATIONS:-10000}",
  "expected_source_par_sha256=${EXPECTED_SOURCE_PAR_SHA256:-}",
  "expected_start_par_sha256=16dda7c09f94919cc87c8cc30b350a68eb5017542b502f2dbfa491a72cd65a9b",
  "estimate_m_final=${ESTIMATE_M_FINAL:-false}",
  '"  1 50 -3  # initial M-opening convergence target"',
  '"  1 121 1  # estimate one natural-mortality age_pars(5) coefficient"',
  '"  1 50 $final_convergence_exponent  # final MGC target"',
  '"  1 121 1  # retain estimation of one Lorenzen M intercept"',
  '"$program_path" "$frq" "$stage_a_par" "$final_par" -file "$stage_b_control"',
  'if [ "$source_par_sha256" != "$expected_source_par_sha256" ]; then',
  'source_parest121=$(read_par_flag "# The parest_flags" 121 "$input_par")',
  'sub(/^[[:space:]]*[^[:space:]]+/, " -3.00000000000000e+00", line)',
  'starting_m=$(read_age_pars5 "$start_par")',
  '"$program_path" "$frq" "$start_par" "$stage_a_par" -file "$stage_a_control"',
  'estimated_m_count=$(awk \'$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}\' indepvar.rpt)',
  'estimated_tau_count=$(awk \'$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}\' indepvar.rpt)',
  '[ "$source_npars" -ne 1989 ]',
  '[ "$output_npars" -ne 1990 ]'
)
missing_continuation <- required_continuation[
  !vapply(
    required_continuation,
    function(x) any(grepl(x, continuation, fixed = TRUE)),
    logical(1L)
  )
]
if (length(missing_continuation)) {
  fail("M-continuation controls are incomplete: ",
       paste(missing_continuation, collapse = " | "))
}
if (any(grepl("1 121 0", continuation, fixed = TRUE))) {
  fail("The M-continuation script may not refix natural mortality.")
}

runner <- readLines(runner_path, warn = FALSE)
for (control in c(
  "is_job_par_script_mode <- function(run_mode) {",
  '"job_par_script", "previous_job_par_script"',
  'if (is_job_par_script_mode(requested_run_mode)) {',
  'run_mode <- "script"',
  "find_previous_job_payload <- function(step_id, job_ref = \"\", root, work_dir) {",
  "restore_payload_par <- function(payload_file, dest) {",
  "Compact payload does not contain a par artifact"
)) {
  if (!any(grepl(control, runner, fixed = TRUE))) {
    fail("Stepwise runner is missing Job 17805 compact-PAR support: ", control)
  }
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("par_source_job", "PAR_SOURCE_JOB")',
  '("kflow_input_jobs", "KFLOW_INPUT_JOBS")',
  '("expected_source_par_sha256", "EXPECTED_SOURCE_PAR_SHA256")',
  '("job_par_max_evaluations", "JOB_PAR_MAX_EVALUATIONS")',
  '("estimate_m_final", "ESTIMATE_M_FINAL")',
  '"input_jobs": split_job_refs(row.get("kflow_input_jobs"))'
)) {
  if (!any(grepl(mapping, registrar, fixed = TRUE))) {
    fail("Kflow registrar is missing per-row wiring: ", mapping)
  }
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-job17805-finalpar-estimate-m-20260729",
  "branch: sensitivity/job17805-finalpar-estimate-m-20260729",
  "command: Rscript --vanilla scripts/validate_job17805_finalpar_estimate_m.R && bash run.sh",
  "  CONFIG_R: job-config-job17805-finalpar-estimate-m.R",
  "  STEP_SELECT: F14-Y5-REC01",
  "  RUN_MODE: job_par_script",
  "  ESTIMATE_M_FINAL: \"true\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  M_STAGE_A_MAX_EVALUATIONS: \"3000\"",
  "  PAR_SOURCE_JOB: \"17805\"",
  "  KFLOW_INPUT_JOBS: \"17805\"",
  "  EXPECTED_SOURCE_PAR_SHA256: \"f68bb0eb7441fed6f32151c196fced94a1c19205ec8fd7b8bd750a5355b31a04\"",
  "  JOB_PAR_MAX_EVALUATIONS: \"10000\"",
  "  model_count: 1",
  "  source_final_parameter_count: 1989",
  "  requested_starting_m_intercept: \"-3.0\"",
  "  verified_starting_par_sha256: 16dda7c09f94919cc87c8cc30b350a68eb5017542b502f2dbfa491a72cd65a9b",
  "  expected_final_parameter_count: 1990",
  "  common_tag_tau_estimated: true",
  "  natural_mortality_estimated: true"
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow task defaults/metadata are incomplete: ",
       paste(missing_task, collapse = " | "))
}
if (any(grepl("^input_jobs:", task))) {
  fail("Job 17805 may be attached only through the single campaign row.")
}

cat(
  "Validated one exact Job 17805 final-PAR continuation: attached PAR SHA ",
  "f68bb0eb...; set the age_pars(5) M-intercept start to -3, then open only ",
  "parest flag 121 at MGC 1e-3 and 1e-4; expected parameter count 1989 -> 1990; ",
  "all Job 17805 data, mixing, rec, movement, Nmax and tag-tau controls retained.\n",
  sep = ""
)
