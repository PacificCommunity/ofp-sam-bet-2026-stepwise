fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-job18400-dmfix.R")
task_path <- file.path(root, "kflow-job18400-dmfix.yaml")
script_path <- file.path(
  root, "steps", "S03-CommonTagTau-MIX015", "model",
  "continue-job18400-dmfix.sh"
)
required <- c(
  config_path, task_path, script_path,
  file.path(root, "R", "run_stepwise.R"),
  file.path(root, "scripts", "register_kflow_task.py")
)
missing <- required[!file.exists(required)]
if (length(missing)) fail("Missing Job 18400 DMfix files: ", paste(missing, collapse = ", "))
if (file.access(script_path, 1L) != 0L) fail("DMfix continuation script is not executable.")

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
if (!is.data.frame(models) || nrow(models) != 1L) fail("Expected one DMfix model row.")

expected <- list(
  step_id = "F14-Y5-REC01",
  run_mode = "job_par_script",
  run_script = "continue-job18400-dmfix.sh",
  scientific_parent = "Job 18400",
  scientific_parent_mode = "par-input",
  independent_fit = FALSE,
  dm_nmax = "25",
  estimate_m_final = "false",
  phase10_11_convergence = "-4",
  par_source_job = "18400",
  kflow_input_jobs = "18400",
  expected_source_par_sha256 =
    "23f8f45e43369fb5df4b797846f975221dc155113518327498906c424e35b86b",
  job_par_max_evaluations = "10000"
)
for (field in names(expected)) {
  if (!identical(models[[field]][[1L]], expected[[field]])) {
    fail("Unexpected Job 18400 DMfix control: ", field)
  }
}

script <- readLines(script_path, warn = FALSE)
must_contain <- c(
  "input_par=previous-job.par",
  "final_par=final.par",
  '"  -999 69 0  # fix grouped fish_pars(22) at Job 18400 values"',
  '[ "$(read_par_flag "# The parest_flags" 141 "$input_par")" = 11 ]',
  '[ "$(read_par_flag "# The parest_flags" 342 "$input_par")" = 25 ]',
  '[ "$group_count" -eq 8 ]',
  '[ "$dm22_count" -eq 0 ] && [ "$dm23_count" -eq 8 ]',
  '[ "$output_npars" -eq 1981 ]',
  '"$program_path" "$frq" "$input_par" "$final_par" -file "$control_file"'
)
for (value in must_contain) {
  if (!any(grepl(value, script, fixed = TRUE))) {
    fail("DMfix continuation is missing: ", value)
  }
}
if (any(grepl("-999 89 0", script, fixed = TRUE)) ||
    any(grepl("1 121 1", script, fixed = TRUE))) {
  fail("DMfix may not fix fish_pars(23) or reopen M.")
}

task <- readLines(task_path, warn = FALSE)
must_task <- c(
  "name: bet-2026-job18400-dmfix-20260729",
  "branch: sensitivity/job18400-dmfix-profile-20260729",
  "  PAR_SOURCE_JOB: \"18400\"",
  "  KFLOW_INPUT_JOBS: \"18400\"",
  "  DM_NMAX: \"25\"",
  "  FIX_M_FINAL: \"true\"",
  "  source_dm_groups: 8",
  "  expected_final_parameter_count: 1981",
  "  profile_followup: \"75 to 125 inclusive at increments of 5\""
)
missing_task <- setdiff(must_task, task)
if (length(missing_task)) fail("DMfix task metadata are incomplete: ",
                               paste(missing_task, collapse = " | "))

cat(
  "Validated Job 18400 DMfix continuation: exact source PAR checksum; ",
  "fish flag 69 fixed for all 33 fisheries; eight grouped fish_pars(22) ",
  "removed from estimation; flag 89 remains active; DM-noRE and Nmax25 ",
  "retained; fixed M retained; expected active parameters 1989 -> 1981.\n",
  sep = ""
)
