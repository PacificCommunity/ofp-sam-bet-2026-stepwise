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

frq_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build", "BET")
ini_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini", "BET")
tag_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep", "BET")
age_root <- file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build", "BET")
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
fixm_age_par_note <- paste("FixM M row applied from", fixm_age_par_source)
fixm_age_par_display <- paste("FixM M row from", fixm_age_par_source)

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
  "ofp-sam-2026-BET-YFT-frq-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-frq-build"),
  "ofp-sam-2026-BET-YFT-build-ini" = file.path(input_root, "ofp-sam-2026-BET-YFT-build-ini"),
  "ofp-sam-2026-BET-YFT-tag-prep" = file.path(input_root, "ofp-sam-2026-BET-YFT-tag-prep"),
  "ofp-sam-2026-BET-YFT-age-length-build" = file.path(input_root, "ofp-sam-2026-BET-YFT-age-length-build"),
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
  "prepare_step_builder.R"
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
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict archival comparisons can set `-5` without editing model folders.",
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

write_02a_newexe_step <- function() {
  paths <- prepare_step_model_dir("02a-NewExe1003")
  copy_model_core_files(rep2023_root, paths$model_dir)
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    rep2023_file("doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = FALSE,
    mix_from_ini = FALSE
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = rep2023_file("bet.frq"), note = "2023 assessment replication frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = rep2023_file("bet.ini"), note = "MFCL 1003 ini from the 2023 assessment replication input set; not promoted in this substep"),
    list(role = "tag", file = "bet.tag", source = rep2023_file("bet.tag"), note = "2023 replication tag input; tag reporting map regenerated from ini/tag"),
    list(role = "age_length", file = "bet.age_length", source = rep2023_file("bet.age_length"), note = "2023 replication CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = rep2023_file("doitall.sh"), note = "2023 assessment replication controls adapted for the current executable with PROGRAM_PATH wrapper, PHASE 10/11 convergence switch, and 1003 ini tag mixing override retained")
  ))
  write_readme(
    paths$step_dir,
    "02a NewExe1003",
    "2023 assessment replication inputs run with the current MFCL executable while keeping the MFCL 1003 ini.",
    c(
      "Uses the archived 2023 assessment replication input set as the source model (`ofp-sam-2026-BET/mfcl/inputs/2023_rep`).",
      "Keeps `bet.ini` as version 1003 so this substep isolates the current executable and the original 2023 control script.",
      "Retains the `-9999 1 2` doitall tag-mixing override because MFCL 1003 inputs do not contain an explicit `# tag flags` block.",
      "Adds the usual Kflow safety wrapper: `set -eu`, PROGRAM_PATH guard, and `BET_PHASE10_11_CONVERGENCE` for PHASE 10/11."
    ),
    c(
      "bet.frq" = "2023 assessment replication `.frq`; 9 regions, 41 fisheries, terminal year 2021",
      "bet.ini" = "2023 assessment replication `.ini`; MFCL 1003, no explicit tag flags",
      "bet.tag" = "2023 assessment replication `.tag`",
      "bet.age_length" = "2023 assessment replication `.age_length`",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable configured by the runtime is used.",
      "This substep is the executable/control-script bridge before changing the ini layout.",
      "The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs."
    ),
    c(
      "Compare directly with 01-Diag2023 to isolate historical-executable versus current-executable/control effects.",
      "Do not interpret this as a 1007 ini test; that is isolated in 02b-Ini1007."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    input_changes = input_change_table(
      c(".ini", ".frq", ".tag", ".age_length"),
      c("No generated input edit; MFCL 1003 layout is retained.", "No generated edit.", "No generated edit.", "No generated edit."),
      c("2023 replication ini values.", "2023 replication source file.", "2023 replication source file.", "2023 replication source file.")
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
    ini_notes <- c(ini_notes, paste("FixM M row applied from", fixm_age_par_source))
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
      c("Applies the fixed-M row from the 01 diagnostic `mgc=-5` final par.", "No generated edit."),
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
      "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.",
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
write_02a_newexe_step()
write_diagnostic_substep(
  "02b-Ini1007",
  "02b Ini1007",
  "02a current-executable baseline promoted from MFCL 1003 to MFCL 1007 ini layout.",
  source_step = "02a-NewExe1003",
  promote_1007 = TRUE
)
write_diagnostic_substep(
  "02c-LengthWeight",
  "02c LengthWeight",
  "02b 1007 ini baseline with BET bias-corrected 2026 length-weight parameters.",
  source_step = "02b-Ini1007",
  length_weight_parameters = bias_corrected_length_weight_parameters
)
write_diagnostic_substep(
  "03-FixM",
  "03 FixM",
  "02c length-weight baseline with the FixM M-scale row applied from the 01-Diag2023 mgc=-5 final run.",
  source_step = "02c-LengthWeight",
  fixm = TRUE
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(root, "inputs", "bet.2026.low.recaps.removed.tag")
mix_ini <- file.path(ini_root, "ini.mix-period", "bet.2026.mix-0.2.ini")
regfish_ini_source <- file.path(ini_root, "bet.2023.new.structure.ini")
regfish_tag_source <- file.path(tag_root, "bet.2023.new.structure-low.recaps.removed.tag")

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

## 04-NewStructure is the first 5-region template. Cache the inherited template
## before overwriting the folder so the script is rerunnable after old folders
## have been removed.
newstructure_dir <- file.path(root, "steps", "04-NewStructure")
newstructure_model_dir <- file.path(newstructure_dir, "model")
template_candidates <- c(
  newstructure_model_dir
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
      c(fixm_age_par_note, total_population_note_04, length_weight_note_04, ini_tag_note_04, tag_reporting_group_note_04)[
        nzchar(c(fixm_age_par_note, total_population_note_04, length_weight_note_04, ini_tag_note_04, tag_reporting_group_note_04))
      ],
      collapse = "; "
    )
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
  "04 NewStructure",
  "First 5-region / 33-fishery BET input step, ending in 2021 with global CPUE.",
  c(
    "Uses the new 5-region and new-fishery frequency source from the frq-build repo.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Keeps data through 2021 and uses the global CPUE setup for this structural transition.",
    "Uses old CAAL re-assigned to the new fisheries.",
    paste0("Uses the restructured tag setup with ", frq_counts_04$n_tag_groups, " release groups."),
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
        tag_reporting_group_note_04
      )[nzchar(c(
        "`bet.2023.new.structure.ini`",
        fixm_age_par_note,
        total_population_note_04,
        length_weight_note_04,
        ini_tag_note_04,
        tag_reporting_group_note_04
      ))],
      collapse = "; "
    ),
    "bet.tag" = "`bet.2023.new.structure-low.recaps.removed.tag`; low-recapture-removed tag input",
    "bet.age_length" = paste("`bet.2023.new-structure.age_length`; old CAAL / age_length re-assigned to new fisheries", age_note_04, sep = "; "),
    "input_manifest.csv" = "machine-readable source/input notes with source commits"
  ),
  c(
    "This step is the 5-region control template for steps 05-17.",
    "Generated `.frq` files include region locations for every fishery, including index fisheries.",
    "MFCL 1007 `# tag flags` supply tag mixing periods directly; the inherited `-9999 1 2` doitall override is removed.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders."
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
        "Applies the fixed-M row, normalizes the tag-flags marker, and uses",
        paste0(bias_corrected_length_weight_note, "."),
        "Grouped tag reporting-rate initial values are harmonized for native MFCL without changing group flags, targets, or penalties."
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



## Self-contained public 22-row / 17-group sequence --------------------------

stepwise_5_region_template_step_id <- "04-NewStructure"

age_variant_root <- file.path(
  dirname(root), "ofp-sam-bet-2026-exploration", "reference-inputs", "age-length-variants"
)
regional_age_075 <- file.path(age_variant_root, "bet.2026.regional.0.75.age_length")
sub_basin_age_075 <- file.path(age_variant_root, "bet.2026.sub.basin.0.75.age_length")
mix015_ini <- file.path(root, "inputs", "bet.2026.mix-0.15.ini")
peatman_rr_ini <- mix_ini
rrpttp26_reporting_source <- file.path(root, "config", "rrpttp26-reporting-rates.csv")

# Step 14 carries the CPUE MLE sigma controls actually submitted and executed
# for Job13328. It is an exact input transfer, not a newly recalculated median.
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
  stop("Job13328 CPUE MLE sigma audit is incomplete or altered", call. = FALSE)
}
cpue_sigma_calibration <- list(
  estimates = matrix(numeric(), nrow = 0L, ncol = 5L),
  source_ids = character(),
  cpue_mle_sigma = as.numeric(cpue_mle_sigma_audit$cpue_mle_sigma),
  flag92 = as.integer(cpue_mle_sigma_audit$fish_flag_92),
  sigma_row_type = "job13328_cpue_mle_sigma",
  basis = paste0(
    "Job13328 submitted S011 CPUE MLE sigma; PacificCommunity/",
    "ofp-sam-bet-2026-exploration@", expected_cpue_sigma_commit, "/",
    expected_cpue_sigma_path, "; SHA256 ", expected_cpue_sigma_sha256
  ),
  source_file = cpue_mle_sigma_path
)

francis_ta18_path <- file.path(root, "config", "francis-ta18-divisors.csv")
francis_ta18_source_commit <- "b22002ba461f3c752432ddec76baa1049edd6c8a"
francis_ta18_source_path <- paste0(
  "sensitivity/S001-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-",
  "REGW11-RRPTTP26/model/francis_weights.csv"
)
francis_ta18_source_note <- paste0(
  "Exact audited TA1.8 CSV from PacificCommunity/ofp-sam-bet-2026-exploration@",
  francis_ta18_source_commit, "/", francis_ta18_source_path
)
expected_francis_ta18_divisors <- c(
  115L, 147L, 42L, 110L, 63L, 23L, 77L, 43L, 85L, 117L, 48L,
  209L, 357L, 16L, 142L, 296L, 88L, 151L, 141L, 258L, 114L,
  398L, 705L, 39L, 27L, 37L, 18L, 50L, 115L, 57L, 51L, 56L, 38L
)

read_francis_ta18_audit <- function(path) {
  audit <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  expected_columns <- c(
    "fishery", "fishery_name", "n_used", "old_divisor", "raw_multiplier",
    "continuous_divisor", "recommended_divisor"
  )
  if (!identical(names(audit), expected_columns)) {
    stop("Unexpected Francis TA1.8 audit columns in ", path, call. = FALSE)
  }
  if (nrow(audit) != 33L ||
      !identical(as.integer(audit$fishery), seq_len(33L)) ||
      any(!is.finite(audit$recommended_divisor)) ||
      any(audit$recommended_divisor <= 0) ||
      !identical(
        as.integer(audit$recommended_divisor),
        expected_francis_ta18_divisors
      )) {
    stop("Francis TA1.8 audit does not contain the locked F1-F33 vector", call. = FALSE)
  }
  audit
}

francis_ta18_audit <- read_francis_ta18_audit(francis_ta18_path)
francis_lf_divisors <- as.integer(francis_ta18_audit$recommended_divisor)

write_sequence_step <- function(
    step_id, title, parent, change,
    frq_source = frq_global_2024,
    ini_source = new_ini,
    tag_source = new_tag,
    age_source = old_age,
    age_effective_sample_size = 0.75,
    reporting_rate_variant = "none",
    tag_reporting_source = "",
    tag_mixing_source = "",
    tag_flag_column2 = 0L,
    regional_cpue = FALSE,
    regional_scaling = FALSE,
    regional_scaling_weight = NA_integer_,
    index_selectivity = FALSE,
    f25_f26_spline7 = FALSE,
    time_varying_cv = FALSE,
    effort_creep = FALSE,
    dom_divisor200 = FALSE,
    fixed_cpue_sigma = FALSE,
    francis_divisors = numeric(),
    francis_source = "",
    francis_source_note = "",
    dm_grouping = "",
    dm_nmax = NA_integer_) {
  controls <- list2env(
    list(
      regional_cpue = regional_cpue,
      index_selectivity = index_selectivity,
      f25_f26_spline7 = f25_f26_spline7,
      time_varying_cv = time_varying_cv,
      dom_divisor200 = dom_divisor200,
      dm_grouping = dm_grouping,
      dm_nmax = dm_nmax
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
    mix_from_ini = TRUE,
    retain_reporting_rates_during_mixing = TRUE,
    tag_reporting_source = tag_reporting_source,
    reporting_rate_variant = reporting_rate_variant,
    tag_mixing_source = tag_mixing_source,
    tag_flag_column2 = tag_flag_column2,
    age_effective_sample_size = age_effective_sample_size,
    reg_scaling_source = if (isTRUE(regional_scaling)) reg_scaling_source else "",
    regional_scaling_weight = regional_scaling_weight,
    doitall_edits = controls,
    cpue_sigma_calibration = if (isTRUE(fixed_cpue_sigma)) cpue_sigma_calibration else NULL,
    francis_divisors = francis_divisors,
    francis_source = francis_source,
    francis_source_note = francis_source_note,
    title = title,
    summary = change,
    bullets = c(
      change,
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
      if (regional_cpue) "Regional CPUE likelihood controls are active.",
      if (!is.na(regional_scaling_weight)) paste0("Regional-scaling weight is ", regional_scaling_weight, "."),
      if (index_selectivity) "F29-F33 final selectivity groups are independent.",
      if (f25_f26_spline7) "F25 and F26 use independent groups 25/26 and seven-node cubic splines.",
      if (time_varying_cv) "F29-F33 time-varying CPUE CV controls are active.",
      if (dom_divisor200) "Only F21-F23 receive the DOM LF divisor 200.",
      if (fixed_cpue_sigma) paste0(
        "Fixed common CPUE MLE sigma flag-92 vector: ",
        paste(cpue_sigma_calibration$flag92, collapse = ", "), "."
      ),
      if (nzchar(dm_grouping)) paste0(dm_grouping, " DM likelihood with Nmax=", dm_nmax, ".")
    ),
    input_changes = input_change_table(
      c(".frq", ".ini", ".tag", ".age_length", "doitall.sh"),
      c(
        if (effort_creep) "Changes only positive F29-F33 effort using the agreed creep schedule." else "Uses the selected source without additional scientific transformation.",
        paste(
          c(
            if (nzchar(tag_reporting_source)) paste0(reporting_rate_variant, " reporting-rate matrices"),
            if (nzchar(tag_mixing_source)) "MIX015 copied only into tag_flags(:,1)",
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
      if (fixed_cpue_sigma) "cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, CPUE MLE sigma values, and executed flag-92 values."
    ),
    outstanding = character()
  )
}

write_sequence_step(
  "05-ConvertToLength", "05 ConvertToLength", "04-NewStructure",
  "Convert the existing weight compositions to length.",
  frq_source = frq_convert_length_2021,
  ini_source = regfish_ini_source,
  tag_source = regfish_tag_source
)

write_sequence_step(
  "06-AddLengthData", "06 AddLengthData", "05-ConvertToLength",
  "Add the additional length-composition data.",
  frq_source = frq_length_plus_length_2021,
  ini_source = regfish_ini_source,
  tag_source = regfish_tag_source
)

# RRPTTP26 is integrated in step 07 and inherited by every descendant.
write_sequence_step(
  "07-DataTo2024", "07 DataTo2024 with RRPTTP26", "06-AddLengthData",
  "Extend data through 2024 and integrate the latest RRPTTP26 penalties.",
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini
)

# Regional CPUE and REGW100 are one scientific group; selectivity is unchanged.
write_sequence_step(
  "08-RegionalCPUE", "08 Regional CPUE and REGW100", "07-DataTo2024",
  "Add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty.",
  frq_source = frq_regional_2024,
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini,
  regional_cpue = TRUE,
  regional_scaling = TRUE,
  regional_scaling_weight = 100L
)

for (age_spec in list(
  list(id = "09a-BASE075", title = "09a BASE075", source = new_age, ess = 0.75,
       change = "Apply the BASE075 composition-weighting alternative."),
  list(id = "09b-REG075", title = "09b REG075", source = regional_age_075, ess = NA_real_,
       change = "Apply the exact heterogeneous REG075 composition-weighting alternative."),
  list(id = "09c-SUB075", title = "09c SUB075 selected", source = sub_basin_age_075, ess = NA_real_,
       change = "Apply the exact heterogeneous SUB075 composition weighting; this sibling is selected.")
)) {
  write_sequence_step(
    age_spec$id, age_spec$title, "08-RegionalCPUE", age_spec$change,
    frq_source = frq_regional_2024,
    age_source = age_spec$source,
    age_effective_sample_size = age_spec$ess,
    reporting_rate_variant = "rrpttp26",
    tag_reporting_source = peatman_rr_ini,
    regional_cpue = TRUE,
    regional_scaling = TRUE,
    regional_scaling_weight = 100L
  )
}

write_selected_path_step <- function(
    step_id, title, parent, change,
    tag_mixing = FALSE, tag_flag2 = 0L,
    time_varying_cv = FALSE, effort_creep = FALSE,
    fixed_cpue_sigma = FALSE,
    index_selectivity = FALSE, f25_f26_spline7 = FALSE,
    dom = FALSE, francis = numeric(),
    dm_grouping = "", dm_nmax = NA_integer_) {
  write_sequence_step(
    step_id, title, parent, change,
    frq_source = frq_regional_2024,
    age_source = sub_basin_age_075,
    age_effective_sample_size = NA_real_,
    reporting_rate_variant = "rrpttp26",
    tag_reporting_source = peatman_rr_ini,
    tag_mixing_source = if (tag_mixing) mix015_ini else "",
    tag_flag_column2 = tag_flag2,
    regional_cpue = TRUE,
    regional_scaling = TRUE,
    regional_scaling_weight = 100L,
    index_selectivity = index_selectivity,
    f25_f26_spline7 = f25_f26_spline7,
    time_varying_cv = time_varying_cv,
    effort_creep = effort_creep,
    dom_divisor200 = dom,
    fixed_cpue_sigma = fixed_cpue_sigma,
    francis_divisors = francis,
    francis_source = if (length(francis)) francis_ta18_path else "",
    francis_source_note = if (length(francis)) francis_ta18_source_note else "",
    dm_grouping = dm_grouping,
    dm_nmax = dm_nmax
  )
}

write_selected_path_step(
  "10-MIX015", "10 MIX015", "09c-SUB075",
  "Copy only MIX015 tag mixing periods into column 1 while retaining tag_flags(:,2)=0.",
  tag_mixing = TRUE
)
write_selected_path_step(
  "11-TAGF2ON", "11 TAGF2ON column 2", "10-MIX015",
  "Change only tag_flags(:,2) from 0 to 1.",
  tag_mixing = TRUE, tag_flag2 = 1L
)
write_selected_path_step(
  "12-TimeVaryingCV", "12 TimeVaryingCV", "11-TAGF2ON",
  "Apply time-varying CPUE CVs to F29-F33.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE
)
write_selected_path_step(
  "13-EffortCreep", "13 EffortCreep", "12-TimeVaryingCV",
  "Apply the BET 2026 effort-creep series only to positive F29-F33 effort.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE
)
write_selected_path_step(
  "14-CPUESigma", "14 CPUE observation-error calibration", "13-EffortCreep",
  "Carry the common CPUE MLE sigma controls selected from the preliminary model fits.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE
)
write_selected_path_step(
  "15-SelectivityUpdate", "15 Consolidated selectivity update", "14-CPUESigma",
  "Apply independent seven-node F25/F26 splines and separate F29-F33 regional-index selectivities.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, f25_f26_spline7 = TRUE
)
write_selected_path_step(
  "16-DOMDiv200", "16 DOM F21-F23 divisor 200", "15-SelectivityUpdate",
  "Apply the assessment-specific DOM divisor 200 only to F21-F23.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, f25_f26_spline7 = TRUE,
  dom = TRUE
)

# The only final composition-likelihood siblings share 16-DOMDiv200 directly.
write_selected_path_step(
  "17a-Francis", "17a Francis comparison", "16-DOMDiv200",
  "Apply the locked Francis TA1.8 composition-data weighting comparison.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, f25_f26_spline7 = TRUE,
  dom = TRUE, francis = francis_lf_divisors
)
write_selected_path_step(
  "17b-DMG8Nmax25", "17b DM-G8PSSET-Nmax25 final", "16-DOMDiv200",
  "Apply DM-noRE, the exact G8 PSSET mapping, and Nmax=25 as one bundled final configuration.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, f25_f26_spline7 = TRUE,
  dom = TRUE, dm_grouping = "G8PSSET", dm_nmax = 25L
)

# Remove only folders that are no longer configured. The existing
# 04-NewStructure control files are intentionally retained as the rerunnable
# five-region template until their replacement has been generated.
config_env <- new.env(parent = baseenv())
sys.source(file.path(root, "job-config.R"), envir = config_env)
configured_steps <- as.character(config_env$stepwise_models$step_id)
step_dirs <- list.dirs(file.path(root, "steps"), recursive = FALSE, full.names = TRUE)
stale_dirs <- step_dirs[!basename(step_dirs) %in% configured_steps]
if (length(stale_dirs)) unlink(stale_dirs, recursive = TRUE, force = TRUE)
