## Rebuild BET 2026 stepwise input folders.
##
## This script copies source `.frq`, `.ini`, `.tag`, and age-length files from
## `input-repos/`, applies the documented stepwise changes, writes manifests
## and READMEs, and removes generated `.par` run products from model folders.
## Helper functions live in `R/prepare_*.R`; this file keeps setup and step
## definitions together.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
input_repo_names <- c(
  "ofp-sam-2026-BET-YFT-frq-build",
  "ofp-sam-2026-BET-YFT-build-ini",
  "ofp-sam-2026-BET-YFT-tag-prep",
  "ofp-sam-2026-BET-YFT-age-length-build"
)
input_root_env <- Sys.getenv("BET_2026_INPUT_ROOT", "")
input_root_candidates <- if (nzchar(input_root_env)) {
  input_root_env
} else {
  c(
    file.path(dirname(root), "input-repos"),
    dirname(root),
    file.path(dirname(root), "bet_2026_input_repos")
  )
}
has_input_repos <- function(path) {
  all(dir.exists(file.path(path, input_repo_names)))
}
input_root_hit <- input_root_candidates[vapply(input_root_candidates, has_input_repos, logical(1))]
if (!length(input_root_hit)) {
  stop(
    "Could not find BET 2026 input repos. Set BET_2026_INPUT_ROOT to a folder containing: ",
    paste(input_repo_names, collapse = ", "),
    call. = FALSE
  )
}
input_root <- normalizePath(input_root_hit[[1L]], winslash = "/", mustWork = TRUE)

input_repo_root <- function(repo_name, env_name = "") {
  configured <- if (nzchar(env_name)) trimws(Sys.getenv(env_name, "")) else ""
  path <- if (nzchar(configured)) configured else file.path(input_root, repo_name)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}
frq_repo_root <- input_repo_root("ofp-sam-2026-BET-YFT-frq-build")
ini_repo_root <- input_repo_root(
  "ofp-sam-2026-BET-YFT-build-ini", "BET_2026_INI_REPO_ROOT"
)
tag_repo_root <- input_repo_root(
  "ofp-sam-2026-BET-YFT-tag-prep", "BET_2026_TAG_REPO_ROOT"
)
age_repo_root <- input_repo_root(
  "ofp-sam-2026-BET-YFT-age-length-build", "BET_2026_AGE_REPO_ROOT"
)

frq_root <- file.path(frq_repo_root, "BET")
ini_root <- file.path(ini_repo_root, "BET")
tag_root <- file.path(tag_repo_root, "BET")
age_root <- file.path(age_repo_root, "BET")
reg_scaling_source <- file.path(frq_root, "bet.2026.reg_scaling")
read_reg_scaling_period <- function(name, default) {
  raw <- trimws(Sys.getenv(name, as.character(default)))
  value <- suppressWarnings(as.integer(raw))
  if (is.na(value) || value < 1L) {
    stop(name, " must be a positive integer; got `", raw, "`", call. = FALSE)
  }
  value
}
reg_scaling_active_start_period <- read_reg_scaling_period(
  "BET_REG_SCALING_START_PERIOD", 53L
)
reg_scaling_active_end_period <- read_reg_scaling_period(
  "BET_REG_SCALING_END_PERIOD", 72L
)
if (reg_scaling_active_end_period < reg_scaling_active_start_period) {
  stop("BET_REG_SCALING_END_PERIOD must not precede the start period", call. = FALSE)
}
reg_scaling_period_label <- function(period, first_year = 1952L) {
  offset <- as.integer(period) - 1L
  paste0(first_year + offset %/% 4L, "Q", offset %% 4L + 1L)
}
reg_scaling_active_years <- paste0(
  reg_scaling_period_label(reg_scaling_active_start_period), "-",
  reg_scaling_period_label(reg_scaling_active_end_period)
)
five_region_total_population_scalar <- 17L
bias_corrected_length_weight_parameters <- c("3.073533e-05", "2.932410")
bias_corrected_length_weight_note <- paste(
  "bias-corrected BET 2026 L-W parameters",
  paste0("a=", bias_corrected_length_weight_parameters[[1L]], ","),
  paste0("b=", bias_corrected_length_weight_parameters[[2L]])
)

fixm_age_par_value <- "-2.54930339768360e+00"
fixm_age_par_source <- "the 01-Diag2023 mgc=-5 diagnostic final par"
fixm_age_par_note <- paste(
  "Lorenzen natural-mortality scaling fixed to the 2023 diagnostic-model estimate from",
  fixm_age_par_source
)
fixm_age_par_display <- paste(
  "Diagnostic natural-mortality estimate fixed from",
  fixm_age_par_source
)

diagnostic_root_env <- Sys.getenv("BET_2023_DIAGNOSTIC_ROOT", "")
diagnostic_root_candidates <- if (nzchar(diagnostic_root_env)) {
  diagnostic_root_env
} else {
  c(
    file.path(dirname(root), "ofp-sam-bet-2023-diagnostic"),
    file.path(dirname(root), "input-repos", "ofp-sam-bet-2023-diagnostic")
  )
}
diagnostic_mfcl_candidate <- function(path) {
  if (file.exists(file.path(path, "MFCL", "bet.frq"))) {
    return(file.path(path, "MFCL"))
  }
  if (file.exists(file.path(path, "bet.frq"))) {
    return(path)
  }
  ""
}
diagnostic_mfcl_hits <- vapply(diagnostic_root_candidates, diagnostic_mfcl_candidate, character(1))
diagnostic_mfcl_hits <- diagnostic_mfcl_hits[nzchar(diagnostic_mfcl_hits)]
if (!length(diagnostic_mfcl_hits)) {
  stop(
    "Could not find the BET 2023 diagnostic MFCL folder. Set BET_2023_DIAGNOSTIC_ROOT to the repo root or MFCL folder.",
    call. = FALSE
  )
}
diagnostic_mfcl_root <- normalizePath(diagnostic_mfcl_hits[[1L]], winslash = "/", mustWork = TRUE)
diagnostic_repo_root <- if (basename(diagnostic_mfcl_root) == "MFCL") {
  dirname(diagnostic_mfcl_root)
} else {
  diagnostic_mfcl_root
}

bet_2026_root_env <- Sys.getenv("BET_2026_REPO_ROOT", "")
bet_2026_root_candidates <- if (nzchar(bet_2026_root_env)) {
  bet_2026_root_env
} else {
  c(
    file.path(dirname(root), "ofp-sam-2026-BET"),
    file.path(dirname(root), "input-repos", "ofp-sam-2026-BET")
  )
}
bet_2026_root_candidate <- function(path) {
  input_dir <- file.path(path, "mfcl", "inputs", "2023_rep")
  if (file.exists(file.path(input_dir, "bet.ini"))) return(input_dir)
  ""
}
bet_2026_rep_hits <- vapply(bet_2026_root_candidates, bet_2026_root_candidate, character(1))
bet_2026_rep_hits <- bet_2026_rep_hits[nzchar(bet_2026_rep_hits)]
if (!length(bet_2026_rep_hits)) {
  stop(
    "Could not find ofp-sam-2026-BET/mfcl/inputs/2023_rep. Set BET_2026_REPO_ROOT to the repo root.",
    call. = FALSE
  )
}
rep2023_root <- normalizePath(bet_2026_rep_hits[[1L]], winslash = "/", mustWork = TRUE)
bet_2026_repo_root <- normalizePath(file.path(rep2023_root, "..", "..", ".."), winslash = "/", mustWork = TRUE)

input_repo_roots <- c(
  "ofp-sam-2026-BET-YFT-frq-build" = frq_repo_root,
  "ofp-sam-2026-BET-YFT-build-ini" = ini_repo_root,
  "ofp-sam-2026-BET-YFT-tag-prep" = tag_repo_root,
  "ofp-sam-2026-BET-YFT-age-length-build" = age_repo_root,
  "ofp-sam-bet-2023-diagnostic" = diagnostic_repo_root,
  "ofp-sam-2026-BET" = bet_2026_repo_root
)

git_value <- function(repo, args) {
  if (!file.exists(file.path(repo, ".git"))) return("")
  value <- tryCatch(
    system2("git", c("-C", repo, args), stdout = TRUE, stderr = NULL),
    error = function(e) character()
  )
  if (!length(value)) "" else value[[1L]]
}

git_commit <- function(repo) {
  git_value(repo, c("rev-parse", "--short", "HEAD"))
}

git_subject <- function(repo) {
  git_value(repo, c("log", "-1", "--pretty=%s"))
}

source_commit_for_path <- function(path) {
  if (!nzchar(path)) return("")
  norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  for (repo in input_repo_roots) {
    repo_prefix <- paste0(normalizePath(repo, winslash = "/", mustWork = FALSE), "/")
    if (startsWith(norm, repo_prefix)) {
      return(git_commit(repo))
    }
  }
  input_prefix <- paste0(normalizePath(input_root, winslash = "/", mustWork = TRUE), "/")
  root_prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  if (startsWith(norm, input_prefix)) {
    parts <- strsplit(substring(norm, nchar(input_prefix) + 1L), "/", fixed = TRUE)[[1L]]
    repo <- file.path(input_root, parts[[1L]])
    return(git_commit(repo))
  }
  if (startsWith(norm, root_prefix) || grepl("^steps/", path)) {
    return(git_commit(root))
  }
  ""
}

input_repo_revision_table <- function() {
  data.frame(
    repo = names(input_repo_roots),
    commit = vapply(input_repo_roots, git_commit, character(1)),
    subject = vapply(input_repo_roots, git_subject, character(1)),
    stringsAsFactors = FALSE
  )
}

region_map_helper <- file.path(root, "R", "write_bet_region_map_assets.R")
if (file.exists(region_map_helper)) {
  source(region_map_helper, local = TRUE)
}

source_prepare_module <- function(file) {
  sys.source(file.path(root, "R", file), envir = parent.frame())
}

for (module in c(
  "prepare_common.R",
  "prepare_mfcl_inputs.R",
  "prepare_readme_manifest.R",
  "prepare_doitall.R",
  "apply_size_data_qc.R",
  "prepare_step_builder.R",
  "prepare_final_diagnostic_steps.R"
)) {
  source_prepare_module(module)
}

write_shared_region_map_assets()

## Step definitions ----------------------------------------------------------

first_existing <- function(paths, label) {
  hit <- paths[file.exists(paths)]
  if (!length(hit)) {
    stop(
      "Could not find ", label, ". Tried: ",
      paste(paths, collapse = ", "),
      call. = FALSE
    )
  }
  hit[[1L]]
}

diagnostic_file <- function(file) {
  file.path(diagnostic_mfcl_root, file)
}

diagnostic_model_files <- c(
  "bet.frq",
  "bet.ini",
  "bet.tag",
  "bet.age_length",
  "mfcl.cfg",
  "labels.tmp"
)

prepare_step_model_dir <- function(step_id) {
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  remove_model_par_files(model_dir)
  list(step_dir = step_dir, model_dir = model_dir)
}

copy_diagnostic_model_files <- function(model_dir) {
  for (file in diagnostic_model_files) {
    copy_if_exists(diagnostic_file(file), file.path(model_dir, file))
  }
  unlink(file.path(model_dir, "fdesc.txt"), force = TRUE)
}

copy_aux_if_exists <- function(from_dir, to_dir, file) {
  from <- file.path(from_dir, file)
  to <- file.path(to_dir, file)
  if (!file.exists(from)) return(invisible(FALSE))
  if (normalizePath(from, winslash = "/", mustWork = FALSE) ==
      normalizePath(to, winslash = "/", mustWork = FALSE)) {
    return(invisible(FALSE))
  }
  copy_one(from, to)
  invisible(TRUE)
}

write_original_diagnostic_step <- function() {
  paths <- prepare_step_model_dir("01-Diag2023")
  copy_diagnostic_model_files(paths$model_dir)
  copy_one(rep2023_file("fishery_map.R"), file.path(paths$model_dir, "fishery_map.R"))
  write_2023_historical_doitall(
    diagnostic_file("doitall.sh"),
    file.path(paths$model_dir, "doitall.sh")
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = diagnostic_file("bet.frq"), note = "original 2023 diagnostic frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = diagnostic_file("bet.ini"), note = "original 2023 diagnostic ini, intentionally not promoted or edited"),
    list(role = "tag", file = "bet.tag", source = diagnostic_file("bet.tag"), note = "original 2023 diagnostic tag input"),
    list(role = "age_length", file = "bet.age_length", source = diagnostic_file("bet.age_length"), note = "original 2023 diagnostic CAAL input"),
    list(role = "fishery_map", file = "fishery_map.R", source = rep2023_file("fishery_map.R"), note = "display metadata copied from the 2023 assessment replication inputs; fishery definitions match the diagnostic model"),
    list(role = "doitall", file = "doitall.sh", source = diagnostic_file("doitall.sh"), note = "historical 2023 diagnostic control script with PHASE 10/11 convergence switch; run_stepwise resolves bare mfclo64 to the historical 2.2.2.0 executable for this step")
  ))
  write_readme(
    paths$step_dir,
    "01 Diag2023",
    "Original BET 2023 diagnostic model rerun with the historical MFCL executable.",
    c(
      "Copies the 2023 diagnostic `MFCL` model files without changing the model inputs.",
      "`bet.ini` remains in its original 2023 diagnostic format for the historical `mfclo64` reader.",
      "`doitall.sh` keeps the historical diagnostic control sequence while allowing `BET_PHASE10_11_CONVERGENCE` to set PHASE 10/11 convergence from Kflow.",
      "The runner resolves `mfclo64` to the historical 2023 diagnostic MFCL executable for this step.",
      "This step is the direct reproducibility anchor before moving to the current executable."
    ),
    c(
      "bet.frq" = "original 2023 diagnostic frequency/catch/size input",
      "bet.ini" = "original 2023 diagnostic ini, not promoted to MFCL 1007",
      "bet.tag" = "original 2023 diagnostic tag input",
      "bet.age_length" = "original 2023 diagnostic CAAL input",
      "fishery_map.R" = "2023 fishery names copied from the assessment replication input set for viewer labels",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The model files come from `ofp-sam-bet-2023-diagnostic/MFCL`.",
      "`fishery_map.R` is copied from the 2023 assessment replication input set because the diagnostic and replication fisheries match; this only supplies viewer/display labels.",
      "The step-specific executable path is set in `job-config.R`; only this step uses the historical MFCL binary.",
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; the default for all stepwise model fits is `-4`.",
      "No FixM, new-executable compatibility edits, new fishery structure, or 2026 input files are applied here."
    ),
    c(
      "Compare this rerun against the archived 2023 diagnostic output before interpreting later deltas.",
      "Apart from the PHASE 10/11 convergence switch, failures will reflect the original diagnostic control sequence."
    ),
    "Ready for Kflow with the tuna-flow image that includes the historical 2023 diagnostic MFCL executable.",
    input_changes = input_change_table(
      c(".frq", ".ini", ".tag", ".age_length", "fishery_map.R"),
      c("No generated edit.", "No generated edit.", "No generated edit.", "No generated edit.", "Copied from the 2023 assessment replication inputs for display labels."),
      c("Original 2023 diagnostic source file.", "Original 2023 diagnostic format.", "Original 2023 diagnostic source file.", "Original 2023 diagnostic source file.", "Fishery names and grouping only; not an MFCL input.")
    ),
    source_revisions = input_repo_revision_table()
  )
}

rep2023_file <- function(file) {
  file.path(rep2023_root, file)
}

copy_model_core_files <- function(from_dir, to_dir) {
  for (file in c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "mfcl.cfg", "fishery_map.R")) {
    copy_if_exists(file.path(from_dir, file), file.path(to_dir, file))
  }
}

write_02_newexe_ini1007_step <- function() {
  paths <- prepare_step_model_dir("02-NewExeIni1007")
  step01_model_dir <- file.path(root, "steps", "01-Diag2023", "model")
  copy_model_core_files(step01_model_dir, paths$model_dir)
  ini_notes <- ensure_ini_1007_compatibility(
    file.path(paths$model_dir, "bet.ini"),
    file.path(paths$model_dir, "bet.tag"),
    total_population_scalar = 25L,
    retain_reporting_rates_during_mixing = TRUE
  )
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    file.path(step01_model_dir, "doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = FALSE,
    mix_from_ini = TRUE
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = diagnostic_file("bet.frq"), note = "exact Step 01 diagnostic frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = diagnostic_file("bet.ini"), note = paste(ini_notes, collapse = "; ")),
    list(role = "tag", file = "bet.tag", source = diagnostic_file("bet.tag"), note = "exact Step 01 diagnostic tag input; tag reporting map regenerated from ini/tag"),
    list(role = "age_length", file = "bet.age_length", source = diagnostic_file("bet.age_length"), note = "exact Step 01 diagnostic CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = diagnostic_file("doitall.sh"), note = "2.2.7.9 compatibility: F33-F41 flag-92 values converted to CV units and age_flags(128) changed from 10 to 100")
  ))
  write_readme(
    paths$step_dir,
    "02 New executable and INI 1007",
    "Step 01 input data promoted to INI 1007 and run with the 2.2.7.9-based executable.",
    c(
      "Uses the generated Step 01 model files, sourced from `ofp-sam-bet-2023-diagnostic/MFCL`, as the exact comparison baseline.",
      "Promotes `bet.ini` from format 1003 to 1007 in the same compatibility step.",
      "Converts F33-F41 CPUE flag-92 values from legacy penalty units to `24, 31, 20, 21, 26, 23, 20, 25, 47`.",
      "Changes global `2 94 1 2 128 10` to `2 94 1 2 128 100`; the 2.2.7.9-based code divides by 100, preserving initial Z = 1.0*M.",
      "Reads tag mixing periods from the INI 1007 tag-flags block."
    ),
    c(
      "bet.frq" = "exact Step 01 diagnostic `.frq`; 9 regions, 41 fisheries, terminal year 2021",
      "bet.ini" = "Step 01 diagnostic values promoted to MFCL 1007",
      "bet.tag" = "exact Step 01 diagnostic `.tag`",
      "bet.age_length" = "exact Step 01 diagnostic `.age_length`",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable configured by the runtime is used.",
      "This step deliberately combines the executable and required INI-format update.",
      "The reporting-only `1 246 1` control requests `indepvar.rpt` and does not alter the fit.",
      "The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs."
    ),
    c(
      "Compare directly with 01-Diag2023 for the combined executable/format transition.",
      "The CPUE and age_flags(128) conversions preserve the legacy scientific interpretation."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    input_changes = input_change_table(
      c(".ini", ".frq", ".tag", ".age_length"),
      c("Promoted to MFCL 1007 with explicit tag flags.", "No generated edit.", "No generated edit.", "No generated edit."),
      c("Step 01 diagnostic numeric values.", "Step 01 diagnostic source file.", "Step 01 diagnostic source file.", "Step 01 diagnostic source file.")
    ),
    source_revisions = input_repo_revision_table()
  )
}

write_diagnostic_substep <- function(step_id, title, summary, source_step,
                                     promote_1007 = FALSE,
                                     total_population_scalar = NA_integer_,
                                     length_weight_parameters = character(),
                                     fixm = FALSE) {
  paths <- prepare_step_model_dir(step_id)
  source_model_dir <- file.path(root, "steps", source_step, "model")
  copy_model_core_files(source_model_dir, paths$model_dir)
  ini_notes <- character()
  if (isTRUE(promote_1007)) {
    ini_notes <- c(ini_notes, ensure_ini_1007_compatibility(
      file.path(paths$model_dir, "bet.ini"),
      file.path(paths$model_dir, "bet.tag"),
      total_population_scalar = 25L,
      retain_reporting_rates_during_mixing = TRUE
    ))
  }
  if (!is.na(total_population_scalar)) {
    ini_notes <- c(ini_notes, set_total_population_scalar(
      file.path(paths$model_dir, "bet.ini"),
      total_population_scalar
    ))
  }
  if (length(length_weight_parameters)) {
    ini_notes <- c(ini_notes, set_length_weight_parameters(
      file.path(paths$model_dir, "bet.ini"),
      length_weight_parameters
    ))
  }
  if (isTRUE(fixm)) {
    apply_fixm_m(file.path(paths$model_dir, "bet.ini"))
    ini_notes <- c(
      ini_notes,
      paste(
        "Lorenzen natural-mortality scaling fixed to the 2023 diagnostic-model estimate from",
        fixm_age_par_source
      )
    )
  }
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    file.path(source_model_dir, "doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = fixm,
    mix_from_ini = TRUE
  )
  ini_note_text <- paste(ini_notes[nzchar(ini_notes)], collapse = "; ")
  if (!nzchar(ini_note_text)) ini_note_text <- paste0("inherits `", source_step, "` ini unchanged")
  diagnostic_input_changes <- if (isTRUE(promote_1007)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c("Promotes MFCL 1003 to 1007 by adding tag flags, tag shed rates, `LN(R0)=25`, and Richards growth default `0`.", "No generated edit."),
      c("Diagnostic data values and tag grouping.", paste0("Inherited from `", source_step, "`."))
    )
  } else if (!is.na(total_population_scalar)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c(paste0("Changes only `LN(R0)` to `", as.integer(total_population_scalar), "`."), "No generated edit."),
      c(paste0("All other `", source_step, "` ini controls."), paste0("Inherited from `", source_step, "`."))
    )
  } else if (length(length_weight_parameters)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c(
        paste0(
          "Changes only `# Length-weight parameters` to `",
          paste(length_weight_parameters, collapse = " "),
          "`."
        ),
        "No generated edit."
      ),
      c(paste0("All other `", source_step, "` ini controls."), paste0("Inherited from `", source_step, "`."))
    )
  } else if (isTRUE(fixm)) {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c("Uses the 2023 diagnostic-model estimate for Lorenzen natural-mortality scaling and retains the length exponent `-1`; both are fixed in later fits.", "No generated edit."),
      c(paste0("All other `", source_step, "` ini controls."), paste0("Inherited from `", source_step, "`."))
    )
  } else {
    input_change_table(
      c(".ini", ".frq/.tag/.age_length"),
      c("No generated edit.", "No generated edit."),
      c(paste0("Inherited from `", source_step, "`."), paste0("Inherited from `", source_step, "`."))
    )
  }
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = file.path("steps", source_step, "model", "bet.frq"), note = paste0("inherited from ", source_step)),
    list(role = "ini", file = "bet.ini", source = file.path("steps", source_step, "model", "bet.ini"), note = ini_note_text),
    list(role = "tag", file = "bet.tag", source = file.path("steps", source_step, "model", "bet.tag"), note = paste0("inherited from ", source_step, "; tag reporting map regenerated from ini/tag")),
    list(role = "age_length", file = "bet.age_length", source = file.path("steps", source_step, "model", "bet.age_length"), note = paste0("inherited from ", source_step)),
    list(role = "doitall", file = "doitall.sh", source = file.path("steps", source_step, "model", "doitall.sh"), note = "current-executable controls regenerated; 1007 tag flags drive mixing periods; PHASE 10/11 convergence switch retained")
  ))
  change_lines <- c(
    paste0("Inherits the diagnostic-side 2023 assessment replication model from `", source_step, "`."),
    if (isTRUE(promote_1007)) "`bet.ini` is promoted from MFCL 1003 to 1007 while retaining the diagnostic values.",
    if (!is.na(total_population_scalar)) paste0("Sets the total population scaling factor LN(R0) to ", as.integer(total_population_scalar), "."),
    if (length(length_weight_parameters)) paste0("Sets the BET bias-corrected 2026 length-weight parameters to `", paste(length_weight_parameters, collapse = " "), "`."),
    if (isTRUE(fixm)) paste("Applies the FixM M-scale row from", fixm_age_par_source, "with value", fixm_age_par_value),
    if (!isTRUE(promote_1007) && is.na(total_population_scalar) && !length(length_weight_parameters) && !isTRUE(fixm)) "No additional input change is applied."
  )
  write_readme(
    paths$step_dir,
    title,
    summary,
    change_lines[nzchar(change_lines)],
    c(
      "bet.frq" = paste0("`steps/", source_step, "/model/bet.frq`"),
      "bet.ini" = paste0("`steps/", source_step, "/model/bet.ini`; ", ini_note_text),
      "bet.tag" = paste0("`steps/", source_step, "/model/bet.tag`"),
      "bet.age_length" = paste0("`steps/", source_step, "/model/bet.age_length`"),
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable configured by the runtime is used.",
      "MFCL 1007 `# tag flags` supply tag mixing periods; the inherited `-9999 1 2` doitall override is removed.",
      "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; the default for all stepwise model fits is `-4`.",
      "The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs."
    ),
    c(
      paste0("Compare directly with ", source_step, " to isolate this substep's change."),
      if (isTRUE(fixm)) "No fishery, tag, CAAL, or CPUE update is intended in this step." else "Later steps inherit this substep unless explicitly documented otherwise."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    input_changes = diagnostic_input_changes,
    source_revisions = input_repo_revision_table()
  )
}

write_original_diagnostic_step()
write_02_newexe_ini1007_step()
write_diagnostic_substep(
  "03-FixM",
  "03 Diagnostic natural-mortality estimate fixed",
  paste0(
    "Step 02 1007 INI baseline with Lorenzen natural-mortality scaling fixed ",
    "to the 2023 diagnostic-model estimate."
  ),
  source_step = "02-NewExeIni1007",
  fixm = TRUE
)
write_diagnostic_substep(
  "04-LengthWeight",
  "04 Length-weight update",
  "Step 03 fixed natural-mortality baseline with BET 2026 bias-corrected length-weight parameters.",
  source_step = "03-FixM",
  length_weight_parameters = bias_corrected_length_weight_parameters,
  fixm = TRUE
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(tag_root, "bet.2026.low.recaps.removed.tag")
mix020_ini <- file.path(
  ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini"
)
regfish_ini_source <- file.path(ini_root, "bet.2023.new.structure.ini")
regfish_tag_source <- file.path(tag_root, "bet.2023.new.structure-low.recaps.removed.tag")
rrpttp26_reporting_source <- file.path(root, "config", "rrpttp26-reporting-rates.csv")

frq_new_structure_global_2021 <- file.path(frq_root, "bet.2023.new-structure.global-cpue.frq")
frq_convert_length_2021 <- file.path(frq_root, "bet.2023.new-structure.global-cpue.wt-as-len.frq")
frq_length_plus_length_2021 <- file.path(frq_root, "bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq")
frq_global_2024 <- file.path(frq_root, "bet.2026.new-structure.global-cpue.wt-as-len-plus-len.frq")
frq_regional_2024 <- first_existing(
  c(
    file.path(frq_root, "bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq"),
    file.path(frq_root, "bet.2026.new-structure.regional-cpue.wt-as-len-plus-len.frq")
  ),
  "2026 regional CPUE frq"
)

## 05-NewStructure is the first 5-region template. Cache the inherited template
## before overwriting the folder so the script is rerunnable after old folders
## have been removed.
newstructure_dir <- file.path(root, "steps", "05-NewStructure")
newstructure_model_dir <- file.path(newstructure_dir, "model")
template_candidates <- c(
  newstructure_model_dir,
  file.path(root, "steps", "06-NewStructure", "model"),
  file.path(root, "steps", "04-NewStructure", "model")
)
template_model_dir <- first_existing(
  file.path(template_candidates, "doitall.sh"),
  "5-region doitall template"
)
template_model_dir <- dirname(template_model_dir)
template_cache <- tempfile("newstructure-template-")
dir.create(template_cache, recursive = TRUE, showWarnings = FALSE)
for (file in c("mfcl.cfg", "fishery_map.R", "doitall.sh")) {
  copy_one(file.path(template_model_dir, file), file.path(template_cache, file))
}

dir.create(newstructure_model_dir, recursive = TRUE, showWarnings = FALSE)
remove_model_par_files(newstructure_model_dir)
copy_one(frq_new_structure_global_2021, file.path(newstructure_model_dir, "bet.frq"))
copy_one(regfish_ini_source, file.path(newstructure_model_dir, "bet.ini"))
copy_one(regfish_tag_source, file.path(newstructure_model_dir, "bet.tag"))
copy_one(old_age, file.path(newstructure_model_dir, "bet.age_length"))
age_note_04 <- set_age_length_effective_sample_size(file.path(newstructure_model_dir, "bet.age_length"))
copy_one(file.path(template_cache, "mfcl.cfg"), file.path(newstructure_model_dir, "mfcl.cfg"))
copy_one(file.path(template_cache, "fishery_map.R"), file.path(newstructure_model_dir, "fishery_map.R"))
n_normalized_04 <- normalize_frq_absent_lf_records(file.path(newstructure_model_dir, "bet.frq"))
ensure_frq_fishery_region_locations(file.path(newstructure_model_dir, "bet.frq"))
apply_fixm_m(file.path(newstructure_model_dir, "bet.ini"))
total_population_note_04 <- set_total_population_scalar(
  file.path(newstructure_model_dir, "bet.ini"),
  five_region_total_population_scalar
)
length_weight_note_04 <- set_length_weight_parameters(
  file.path(newstructure_model_dir, "bet.ini"),
  bias_corrected_length_weight_parameters
)
frq_counts_04 <- frq_header_counts(
  readLines(file.path(newstructure_model_dir, "bet.frq"), warn = FALSE),
  file.path(newstructure_model_dir, "bet.frq")
)
ini_tag_note_04 <- ensure_ini_tag_flags(
  file.path(newstructure_model_dir, "bet.ini"),
  frq_counts_04$n_tag_groups
)
tag_reporting_source_note_04 <- apply_rrpttp26_reporting_rates(
  file.path(newstructure_model_dir, "bet.ini"),
  tag_path = file.path(newstructure_model_dir, "bet.tag"),
  source_csv = rrpttp26_reporting_source
)
tag_reporting_group_note_04 <- repair_tag_reporting_grouped_initial_values(
  file.path(newstructure_model_dir, "bet.ini")
)
validate_tag_reporting_grouped_initial_values(file.path(newstructure_model_dir, "bet.ini"))
write_generated_tag_rep_map(newstructure_model_dir)
write_doitall(
  file.path(template_cache, "doitall.sh"),
  file.path(newstructure_model_dir, "doitall.sh"),
  mix_from_ini = TRUE
)
write_manifest(newstructure_dir, list(
  list(
    role = "frq",
    file = "bet.frq",
    source = frq_new_structure_global_2021,
    note = paste0(
      "5-region 2021-terminal new-structure frq with global CPUE",
      if (n_normalized_04) paste0("; normalized ", n_normalized_04, " records with stray absent-LF bins") else ""
    )
  ),
  list(
    role = "ini",
    file = "bet.ini",
    source = regfish_ini_source,
    note = paste(
      c(fixm_age_par_note, total_population_note_04, length_weight_note_04, ini_tag_note_04, tag_reporting_source_note_04, tag_reporting_group_note_04)[
        nzchar(c(fixm_age_par_note, total_population_note_04, length_weight_note_04, ini_tag_note_04, tag_reporting_source_note_04, tag_reporting_group_note_04))
      ],
      collapse = "; "
    )
  ),
  list(
    role = "rrpttp26_reporting_audit",
    file = "bet.ini",
    source = rrpttp26_reporting_source,
    note = "SC22 BET purse-seine reporting-rate means and penalties mapped to the 2023-structure tag rows"
  ),
  list(
    role = "tag",
    file = "bet.tag",
    source = regfish_tag_source,
    note = "low-recapture-removed 2023 new-structure tag input; tag reporting map regenerated from ini/tag"
  ),
  list(
    role = "age_length",
    file = "bet.age_length",
    source = old_age,
    note = paste("old CAAL / age_length reassigned to the new fisheries", age_note_04, sep = "; ")
  ),
  list(
    role = "doitall",
    file = "doitall.sh",
    source = file.path("steps", basename(dirname(template_model_dir)), "model", "doitall.sh"),
    note = "5-region controls retained; tag mixing periods read from MFCL 1007 ini tag flags; made fail-fast for Kflow"
  )
))
write_readme(
  newstructure_dir,
  "05 NewStructure",
  paste(
    "First 5-region / 33-fishery BET input step, ending in 2021 with global CPUE",
    "and the current reporting-rate controls remapped to the revised fisheries."
  ),
  c(
    "Uses the new 5-region and new-fishery frequency source from the frq-build repo.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Keeps data through 2021 and uses the global CPUE setup for this structural transition.",
    "Uses old CAAL re-assigned to the new fisheries.",
    paste0("Uses the restructured tag setup with ", frq_counts_04$n_tag_groups, " release groups."),
    paste(
      "Begins the current reporting-rate specification by rebuilding all group,",
      "active, initial, target and penalty matrices for the 33-fishery structure,",
      "including separate West and East purse-seine groups."
    ),
    paste("Applies", fixm_age_par_display, "while retaining the 5-region `.ini` structure."),
    paste0("Sets total population scaling factor LN(R0) to ", five_region_total_population_scalar, "."),
    paste0("Uses ", bias_corrected_length_weight_note, ".")
  ),
  c(
    "bet.frq" = "`bet.2023.new-structure.global-cpue.frq`; 5-region, 33-fishery structure, terminal year 2021, global CPUE",
    "bet.ini" = paste(
      c(
        "`bet.2023.new.structure.ini`",
        fixm_age_par_note,
        total_population_note_04,
        length_weight_note_04,
        ini_tag_note_04,
        tag_reporting_source_note_04,
        tag_reporting_group_note_04
      )[nzchar(c(
        "`bet.2023.new.structure.ini`",
        fixm_age_par_note,
        total_population_note_04,
        length_weight_note_04,
        ini_tag_note_04,
        tag_reporting_source_note_04,
        tag_reporting_group_note_04
      ))],
      collapse = "; "
    ),
    "bet.tag" = "`bet.2023.new.structure-low.recaps.removed.tag`; low-recapture-removed tag input",
    "bet.age_length" = paste("`bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries", age_note_04, sep = "; "),
    "input_manifest.csv" = "machine-readable source/input notes with source commits"
  ),
  c(
    "This step is the 5-region control template for steps 06-19.",
    "Generated `.frq` files include region locations for every fishery, including index fisheries.",
    "MFCL 1007 `# tag flags` supply tag mixing periods directly; the inherited `-9999 1 2` doitall override is removed.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; the default for all stepwise model fits is `-4`.",
    paste(
      "The Step 04-to-Step 05 comparison includes the reporting-rate remapping",
      "required by the fishery-structure change; Step 17 later changes only pre-mixing application."
    )
  ),
  c(
    "After fitting, review the 5-region selectivity/tag grouping inherited from the workbook mapping.",
    "The `.frq` region-location line must contain all 33 fisheries: 28 extraction fisheries followed by index fishery regions 1-5."
  ),
  "Ready for Kflow smoke runs; full MFCL fit not run here.",
  input_changes = input_change_table(
    c(".frq", ".ini", ".tag", ".age_length"),
    c(
      "No generated edit beyond source validation.",
      paste(
        "Applies the fixed Lorenzen natural-mortality coefficients, normalizes the tag-flags marker, and uses",
        paste0(bias_corrected_length_weight_note, "."),
        "SC22 BET reporting-rate means and penalties are mapped by tag programme and fishery, with West and East purse-seine groups kept separate."
      ),
      "No generated edit.",
      "Changes effective sample size from `1` to `0.75`."
    ),
    c(
      "2023 new-structure global-CPUE source records.",
      "`LN(R0)=17`, bias-corrected L-W, tag grouping, and `tag_flags(it,2)=0`.",
      "2023 new-structure low-recapture-removed source file.",
      "CAAL records themselves."
    )
  ),
  source_revisions = input_repo_revision_table()
)



## Self-contained public 20-row / 19-stage sequence --------------------------

stepwise_5_region_template_step_id <- "05-NewStructure"

regional_age_075 <- file.path(age_root, "bet.2026.regional.0.75.age_length")
sub_basin_age_075 <- file.path(age_root, "bet.2026.sub.basin.0.75.age_length")
peatman_rr_ini <- new_ini

# Step 13 carries the CPUE observation-error controls actually submitted and
# executed for Job13328. It is an exact input transfer, not a recalculation.
cpue_mle_sigma_path <- file.path(root, "config", "job13328-cpue-sigma.csv")
cpue_mle_sigma_audit <- read.csv(
  cpue_mle_sigma_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
expected_cpue_sigma_columns <- c(
  "region", "fishery", "fish_flag_92", "cpue_mle_sigma", "source_job",
  "source_commit", "source_path", "source_sha256"
)
expected_cpue_sigma_flags <- c(35L, 24L, 21L, 24L, 23L)
expected_cpue_mle_sigma <- c(0.354, 0.237, 0.212, 0.239, 0.225)
expected_cpue_sigma_commit <- "c940601bb95797a5cc5b4a2dbc01cfd6daa86a70"
expected_cpue_sigma_path <- paste0(
  "sensitivity/S011-DM-G8PSSET-CEST-NOCUT-SUB075-MIX015-TAGF2ON-",
  "NMAX25-REGW100-RRPTTP26/model/doitall.sh"
)
expected_cpue_sigma_sha256 <-
  "a47ef47502d94229bc68ea963256e6243e2579fce4320a21a2eb55fc738ed471"
if (!identical(names(cpue_mle_sigma_audit), expected_cpue_sigma_columns) ||
    nrow(cpue_mle_sigma_audit) != 5L ||
    !identical(as.integer(cpue_mle_sigma_audit$region), 1:5) ||
    !identical(as.integer(cpue_mle_sigma_audit$fishery), 29:33) ||
    !identical(as.integer(cpue_mle_sigma_audit$fish_flag_92), expected_cpue_sigma_flags) ||
    !isTRUE(all.equal(
      as.numeric(cpue_mle_sigma_audit$cpue_mle_sigma),
      expected_cpue_mle_sigma,
      tolerance = 1e-12,
      check.attributes = FALSE
    )) ||
    any(cpue_mle_sigma_audit$source_job != "Job13328") ||
    any(cpue_mle_sigma_audit$source_commit != expected_cpue_sigma_commit) ||
    any(cpue_mle_sigma_audit$source_path != expected_cpue_sigma_path) ||
    any(cpue_mle_sigma_audit$source_sha256 != expected_cpue_sigma_sha256)) {
  stop("Job13328 CPUE observation-error audit is incomplete or altered", call. = FALSE)
}
cpue_sigma_calibration <- list(
  estimates = matrix(numeric(), nrow = 0L, ncol = 5L),
  source_ids = character(),
  cpue_mle_sigma = as.numeric(cpue_mle_sigma_audit$cpue_mle_sigma),
  flag92 = as.integer(cpue_mle_sigma_audit$fish_flag_92),
  sigma_row_type = "job13328_cpue_mle_sigma",
  basis = paste0(
    "Job13328 submitted S011 CPUE observation-error scales; PacificCommunity/",
    "ofp-sam-bet-2026-exploration@", expected_cpue_sigma_commit, "/",
    expected_cpue_sigma_path, "; SHA256 ", expected_cpue_sigma_sha256
  ),
  source_file = cpue_mle_sigma_path
)

write_sequence_step <- function(
    step_id, title, parent, change,
    audit_notes = character(),
    frq_source = frq_global_2024,
    ini_source = new_ini,
    tag_source = new_tag,
    age_source = old_age,
    age_effective_sample_size = 0.75,
    reporting_rate_variant = "none",
    tag_reporting_source = "",
    tag_mixing_source = "",
    tag_flag_column2 = 0L,
    reporting_rate_group_prior_repairs = list(),
    regional_cpue = FALSE,
    regional_scaling = FALSE,
    regional_scaling_weight = NA_integer_,
    tail_compression_1pct = FALSE,
    selectivity_update = FALSE,
    f10_weak_non_decreasing_penalty = FALSE,
    ph_id_young5_selectivity = FALSE,
    time_varying_cv = FALSE,
    effort_creep = FALSE,
    size_data_qc = FALSE,
    size_data_qc_source_sha256 = "",
    dom_divisor200 = FALSE,
    fixed_cpue_sigma = FALSE,
    dm_grouping = "",
    dm_nmax = NA_integer_,
    dm_fixed_concentration = NA_real_,
    status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  controls <- list2env(
    list(
      regional_cpue = regional_cpue,
      selectivity_update = selectivity_update,
      f10_weak_non_decreasing_penalty = f10_weak_non_decreasing_penalty,
      ph_id_young5_selectivity = ph_id_young5_selectivity,
      tail_compression_1pct = tail_compression_1pct,
      time_varying_cv = time_varying_cv,
      dom_divisor200 = dom_divisor200,
      dm_grouping = dm_grouping,
      dm_nmax = dm_nmax,
      dm_fixed_concentration = dm_fixed_concentration
    ),
    parent = emptyenv()
  )
  make_step(
    step_id = step_id,
    frq_source = frq_source,
    ini_source = ini_source,
    tag_source = tag_source,
    age_source = age_source,
    frq_transform = if (isTRUE(effort_creep)) "effort_creep" else NULL,
    size_data_qc = size_data_qc,
    size_data_qc_source_sha256 = size_data_qc_source_sha256,
    mix_from_ini = TRUE,
    retain_reporting_rates_during_mixing = TRUE,
    tag_reporting_source = tag_reporting_source,
    reporting_rate_variant = reporting_rate_variant,
    tag_mixing_source = tag_mixing_source,
    tag_flag_column2 = tag_flag_column2,
    reporting_rate_group_prior_repairs = reporting_rate_group_prior_repairs,
    age_effective_sample_size = age_effective_sample_size,
    reg_scaling_source = if (isTRUE(regional_scaling)) reg_scaling_source else "",
    regional_scaling_weight = regional_scaling_weight,
    doitall_edits = controls,
    cpue_sigma_calibration = if (isTRUE(fixed_cpue_sigma)) cpue_sigma_calibration else NULL,
    title = title,
    summary = change,
    bullets = c(
      change,
      audit_notes,
      paste0("Scientific parent: '", parent, "'."),
      "The model folder is rebuilt from source inputs plus the complete cumulative edit set."
    ),
    input_notes = c(
      "bet.frq" = basename(frq_source),
      "bet.ini" = basename(ini_source),
      "bet.tag" = basename(tag_source),
      "bet.age_length" = basename(age_source)
    ),
    control_notes = c(
      if (regional_cpue) "Regional CPUE indices use the configured stationary-catchability/likelihood groups.",
      if (!is.na(regional_scaling_weight)) paste0("Regional-scaling weight is ", regional_scaling_weight, "."),
      if (tail_compression_1pct && !nzchar(dm_grouping)) "Length-frequency parest flag 313 is 1, activating 1% tail aggregation; flags 311/301 remain 1 and weight-frequency flag 303 remains 0.",
      if (nzchar(dm_grouping)) "Length-frequency parest flag 313 is reset to 0 because the DM likelihood does not read the percentage threshold; this also avoids unrelated percentage-tail preprocessing, while parest flag 320 controls DM support.",
      if (selectivity_update) paste0(
        "The Job 18718 flexible selectivity update keeps F1-F28 independent, ",
        "separates F29-F33 in staged run 5, retains the flexible spline forms, ",
        "and keeps the documented F14/F15 youngest-five-age constraints."
      ),
      if (f10_weak_non_decreasing_penalty) paste0(
        "F10 LL.ALL.5 retains five estimated spline nodes and adds only fish flags ",
        "16=1 and 56=10000, matching the deterministic Job 19325 treatment."
      ),
      if (time_varying_cv) "F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data.",
      if (dom_divisor200) "Only F21-F23 receive the DOM LF divisor 200.",
      if (fixed_cpue_sigma) paste0(
        "Fixed CPUE observation-error scales (flag 92 integer percentages): ",
        paste(cpue_sigma_calibration$flag92, collapse = ", "), "."
      ),
      if (nzchar(dm_grouping)) paste0(
        dm_grouping, " DM likelihood with effective-sample-size upper asymptote Nmax=", dm_nmax,
        if (is.finite(dm_fixed_concentration)) {
          paste0("; grouped fish_pars(22) fixed at ", dm_fixed_concentration, " as in Job 18518.")
        } else "."
      )
    ),
    input_changes = input_change_table(
      c(".frq", ".ini", ".tag", ".age_length", "Step-specific change"),
      c(
        if (effort_creep) "Changes only positive F29-F33 effort using the agreed creep schedule." else "Uses the selected source without additional scientific transformation.",
        paste(
          c(
            if (nzchar(tag_reporting_source)) paste0(reporting_rate_variant, " reporting-rate matrices"),
            if (nzchar(tag_mixing_source)) "MIX020 copied only into tag_flags(:,1)",
            paste0("tag_flags(:,2)=", tag_flag_column2)
          ),
          collapse = "; "
        ),
        "Uses the selected TAG source without rollback or replacement.",
        if (is.na(age_effective_sample_size)) "Preserves the exact heterogeneous age-length variant." else paste0("Sets only the effective-sample-size row to ", age_effective_sample_size, "."),
        change
      ),
      c(
        "All non-effort FRQ values.",
        "All unlisted INI fields and cumulative RR/tag controls.",
        "All tag release and recapture records.",
        "Age-length records and variant-specific structure.",
        "All previously selected controls; no OPR or length-bin selectivity."
      )
    ),
    run_notes = c(
      "No preliminary parameter file or scientific-parent model folder is read at runtime.",
      if (selectivity_update) {
        paste0(
          "The fishery definitions and tag-recapture groups in `fishery_map.R` are unchanged; ",
          "only its selectivity-group metadata changes. See ",
          "[the Step 15 comparison](../../docs/selectivity-update.md)."
        )
      },
      if (fixed_cpue_sigma) "cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values."
    ),
    outstanding = character(),
    status = status
  )
}

write_sequence_step(
  "06-ConvertToLength", "06 Convert weight to length", "05-NewStructure",
  "Replace the reweighted weight compositions with their length-frequency conversion through 2021.",
  frq_source = frq_convert_length_2021, ini_source = regfish_ini_source,
  tag_source = regfish_tag_source, reporting_rate_variant = "rrpttp26"
)
write_sequence_step(
  "07-AddLengthData", "07 Add observed length data", "06-ConvertToLength",
  "Add observed length compositions where their catch coverage exceeds that of weight samples.",
  frq_source = frq_length_plus_length_2021, ini_source = regfish_ini_source,
  tag_source = regfish_tag_source, reporting_rate_variant = "rrpttp26"
)
write_sequence_step(
  "08-DataTo2024", "08 Data through 2024", "07-AddLengthData",
  "Extend data through 2024 except CAAL while retaining the same reporting-rate specification.",
  reporting_rate_variant = "rrpttp26", tag_reporting_source = peatman_rr_ini
)

global_2024_raw_sha <- "21bf76372bbd8b7ef570f1f5dbd4c6821f00efd20e7b7174fc58a09fda34d78d"
regional_2024_raw_sha <- "5e2520afef613c563b27ee794c402e192dfdb114edc52c130323fa80ae876152"
effort_creep_raw_sha <- "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c"

common_late_step <- function(
    step_id, title, parent, change,
    age_source = old_age, age_ess = 0.75,
    regional_cpue = FALSE, time_varying_cv = FALSE,
    fixed_cpue_sigma = FALSE, selectivity = FALSE,
    f10_weak_non_decreasing_penalty = FALSE,
    tag_mixing = FALSE, tag_flag2 = 0L, effort_creep = FALSE,
    dm = FALSE) {
  raw_sha <- if (effort_creep) {
    effort_creep_raw_sha
  } else if (regional_cpue) {
    regional_2024_raw_sha
  } else {
    global_2024_raw_sha
  }
  write_sequence_step(
    step_id, title, parent, change,
    frq_source = if (regional_cpue) frq_regional_2024 else frq_global_2024,
    age_source = age_source,
    age_effective_sample_size = age_ess,
    reporting_rate_variant = "rrpttp26",
    tag_reporting_source = peatman_rr_ini,
    tag_mixing_source = if (tag_mixing) mix020_ini else "",
    tag_flag_column2 = tag_flag2,
    regional_cpue = regional_cpue,
    regional_scaling = regional_cpue,
    regional_scaling_weight = if (regional_cpue) 100L else NA_integer_,
    ph_id_young5_selectivity = TRUE,
    selectivity_update = selectivity,
    f10_weak_non_decreasing_penalty = f10_weak_non_decreasing_penalty,
    time_varying_cv = time_varying_cv,
    effort_creep = effort_creep,
    size_data_qc = TRUE,
    size_data_qc_source_sha256 = raw_sha,
    fixed_cpue_sigma = fixed_cpue_sigma,
    dm_grouping = if (dm) "G8PSSET" else "",
    dm_nmax = if (dm) 25L else NA_integer_,
    dm_fixed_concentration = if (dm) 7 else NA_real_,
    audit_notes = c(
      "F15 bins below 70 cm are zeroed without renormalisation.",
      "F21-F23 intervals with midpoint above 90 cm are removed.",
      "F14 and F15 youngest five ages are fixed at zero selectivity.",
      "Tag tau remains not estimated under the original 2023 negative-binomial parameterisation."
    )
  )
}

common_late_step(
  "09-SizeDataQC", "09 PH/ID and domestic size-data rules", "08-DataTo2024",
  "Apply the agreed PH/ID and domestic mixed-gear size-data rules."
)
common_late_step(
  "10-RegionalCPUE", "10 Regional CPUE and scaling", "09-SizeDataQC",
  "Use five separate regional CPUE indices and the REGW100 regional-scaling prior.",
  regional_cpue = TRUE
)
common_late_step(
  "11-TimeVaryingCV", "11 Time-varying CPUE uncertainty", "10-RegionalCPUE",
  "Apply normalized time-varying relative-variance multipliers to F29-F33.",
  regional_cpue = TRUE, time_varying_cv = TRUE
)
common_late_step(
  "12-CPUEErrorCalibration", "12 MLE-based regional CPUE observation-error SDs", "11-TimeVaryingCV",
  "Fix R1-R5 observation-error SDs at their maximum-likelihood estimates: 0.35, 0.24, 0.21, 0.24 and 0.23.",
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE
)
common_late_step(
  "13-NewAgeData", "13 New CAAL data", "12-CPUEErrorCalibration",
  "Add the new CAAL data with weighting factor 0.75.",
  age_source = new_age, age_ess = 0.75,
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE
)
for (age_spec in list(
  list(
    id = "14a-REG075", title = "14a Regional CAAL reweighting",
    source = regional_age_075,
    change = "Apply the all-five-region CAAL reweighting alternative."
  ),
  list(
    id = "14b-SUB075", title = "14b Sub-basin CAAL reweighting",
    source = sub_basin_age_075,
    change = "Apply the selected CAAL reweighting with regions 3 and 4 combined."
  )
)) {
  common_late_step(
    age_spec$id, age_spec$title, "13-NewAgeData", age_spec$change,
    age_source = age_spec$source, age_ess = NA_real_,
    regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE
  )
}
common_late_step(
  "15-SelectivityUpdate", "15 Selectivity update", "14b-SUB075",
  paste(
    "Apply the Job 18718 flexible fishery-specific selectivity and the",
    "deterministic Job 19325 weak F10 non-decreasing penalty (flags 16=1",
    "and 56=10000) from the ordinary makepar start."
  ),
  age_source = sub_basin_age_075, age_ess = NA_real_,
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE,
  selectivity = TRUE, f10_weak_non_decreasing_penalty = TRUE
)
common_late_step(
  "16-MIX020", "16 KS D-statistic cutoff 0.20 tag-mixing periods", "15-SelectivityUpdate",
  paste(
    "Copy only release-group mixing periods from",
    "SC22-IP10-regionMean using a KS D-statistic cutoff of 0.20; retain reporting-rate matrices unchanged."
  ),
  age_source = sub_basin_age_075, age_ess = NA_real_,
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE,
  selectivity = TRUE, f10_weak_non_decreasing_penalty = TRUE,
  tag_mixing = TRUE
)
common_late_step(
  "17-TagReportingExclusion", "17 Pre-mixing reporting-rate exclusion", "16-MIX020",
  "Set tag_flags(:,2)=1 so reporting rates are excluded only in pre-mixing windows.",
  age_source = sub_basin_age_075, age_ess = NA_real_,
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE,
  selectivity = TRUE, f10_weak_non_decreasing_penalty = TRUE,
  tag_mixing = TRUE, tag_flag2 = 1L
)
common_late_step(
  "18-EffortCreep", "18 Effort-creep adjustment", "17-TagReportingExclusion",
  "Apply the BET 2026 effort-creep series only to positive F29-F33 effort.",
  age_source = sub_basin_age_075, age_ess = NA_real_,
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE,
  selectivity = TRUE, f10_weak_non_decreasing_penalty = TRUE,
  tag_mixing = TRUE, tag_flag2 = 1L,
  effort_creep = TRUE
)
common_late_step(
  "19-DMG8Nmax25", "19 DM weighting: G8 Nmax 25", "18-EffortCreep",
  paste(
    "Apply the Job 18718 final composition treatment: DM-noRE, G8, Nmax=25,",
    "fish_pars(22) fixed at 7 and fish_pars(23) estimated."
  ),
  age_source = sub_basin_age_075, age_ess = NA_real_,
  regional_cpue = TRUE, time_varying_cv = TRUE, fixed_cpue_sigma = TRUE,
  selectivity = TRUE, f10_weak_non_decreasing_penalty = TRUE,
  tag_mixing = TRUE, tag_flag2 = 1L,
  effort_creep = TRUE, dm = TRUE
)

diagnostic_repo_env <- trimws(Sys.getenv("BET_2026_DIAGNOSTIC_ROOT", ""))
diagnostic_repo_candidates <- if (nzchar(diagnostic_repo_env)) {
  diagnostic_repo_env
} else {
  c(
    file.path(dirname(root), "ofp-sam-bet-2026-diagnostic"),
    file.path(dirname(root), "input-repos", "ofp-sam-bet-2026-diagnostic")
  )
}
diagnostic_repo_hits <- diagnostic_repo_candidates[
  dir.exists(file.path(diagnostic_repo_candidates, ".git")) |
    file.exists(file.path(diagnostic_repo_candidates, ".git"))
]
if (!length(diagnostic_repo_hits)) {
  stop(
    "Could not find ofp-sam-bet-2026-diagnostic. Set BET_2026_DIAGNOSTIC_ROOT ",
    "to a clone containing commits 770edf1 and d57127a.",
    call. = FALSE
  )
}
write_final_diagnostic_steps(
  normalizePath(diagnostic_repo_hits[[1L]], winslash = "/", mustWork = TRUE)
)

# Remove every superseded step folder after the replacement sequence is
# generated. Every removed folder remains recoverable from Git history.
config_env <- new.env(parent = baseenv())
sys.source(file.path(root, "job-config.R"), envir = config_env)
configured_steps <- as.character(config_env$stepwise_models$step_id)
existing_step_ids <- basename(list.dirs(
  file.path(root, "steps"), recursive = FALSE, full.names = TRUE
))
obsolete_step_ids <- setdiff(existing_step_ids, configured_steps)
obsolete_step_dirs <- file.path(root, "steps", obsolete_step_ids)
unlink(obsolete_step_dirs[dir.exists(obsolete_step_dirs)], recursive = TRUE, force = TRUE)
