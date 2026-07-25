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
age_repo_root <- input_repo_root("ofp-sam-2026-BET-YFT-age-length-build")

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

write_02_newexe_step <- function() {
  paths <- prepare_step_model_dir("02-NewExe1003")
  step01_model_dir <- file.path(root, "steps", "01-Diag2023", "model")
  copy_model_core_files(step01_model_dir, paths$model_dir)
  write_generated_tag_rep_map(paths$model_dir)
  write_2023_newexe_doitall(
    file.path(step01_model_dir, "doitall.sh"),
    file.path(paths$model_dir, "doitall.sh"),
    fixm = FALSE,
    mix_from_ini = FALSE
  )
  write_manifest(paths$step_dir, list(
    list(role = "frq", file = "bet.frq", source = diagnostic_file("bet.frq"), note = "exact Step 01 diagnostic frequency/catch/size input"),
    list(role = "ini", file = "bet.ini", source = diagnostic_file("bet.ini"), note = "exact Step 01 MFCL 1003 ini; not promoted in this substep"),
    list(role = "tag", file = "bet.tag", source = diagnostic_file("bet.tag"), note = "exact Step 01 diagnostic tag input; tag reporting map regenerated from ini/tag"),
    list(role = "age_length", file = "bet.age_length", source = diagnostic_file("bet.age_length"), note = "exact Step 01 diagnostic CAAL input"),
    list(role = "doitall", file = "doitall.sh", source = diagnostic_file("doitall.sh"), note = "Step 01 scientific controls retained exactly; only the PROGRAM_PATH/set -eu safety wrapper, existing convergence switch, and reporting-only indepvar.rpt compatibility control are added")
  ))
  write_readme(
    paths$step_dir,
    "02 Updated executable",
    "Step 01 inputs and scientific controls run with the current MFCL executable while keeping the MFCL 1003 ini.",
    c(
      "Uses the generated Step 01 model files, sourced from `ofp-sam-bet-2023-diagnostic/MFCL`, as the exact comparison baseline.",
      "Keeps `bet.ini` as version 1003 and retains every Step 01 scientific control so this is an executable-only comparison.",
      "Preserves Step 01 F33-F41 CPUE flag-92 values `88, 53, 130, 109, 76, 93, 121, 77, 23` and global `2 94 1 2 128 10`.",
      "Retains the `-9999 1 2` doitall tag-mixing override because MFCL 1003 inputs do not contain an explicit `# tag flags` block.",
      "Only modernizes executable invocation/safety with `set -eu` and a PROGRAM_PATH guard; the existing PHASE 10/11 switch is retained and reporting-only `1 246 1` compatibility is added."
    ),
    c(
      "bet.frq" = "exact Step 01 diagnostic `.frq`; 9 regions, 41 fisheries, terminal year 2021",
      "bet.ini" = "exact Step 01 diagnostic `.ini`; MFCL 1003, no explicit tag flags",
      "bet.tag" = "exact Step 01 diagnostic `.tag`",
      "bet.age_length" = "exact Step 01 diagnostic `.age_length`",
      "input_manifest.csv" = "machine-readable source/input notes with source commits"
    ),
    c(
      "The current MFCL executable configured by the runtime is used.",
      "This substep changes the executable invocation, not scientific controls, before changing the ini layout.",
      "The reporting-only `1 246 1` control requests `indepvar.rpt` and does not alter the fit.",
      "The 2023 nine-region GeoJSON asset remains display-only; it does not change MFCL inputs."
    ),
    c(
      "Compare directly with 01-Diag2023 to isolate only the historical versus current executable.",
      "Do not interpret this as a 1007 ini test; that is isolated in 03-Ini1007."
    ),
    "Ready for Kflow smoke runs; full MFCL fit not run here.",
    input_changes = input_change_table(
      c(".ini", ".frq", ".tag", ".age_length"),
      c("No generated input edit; MFCL 1003 layout is retained.", "No generated edit.", "No generated edit.", "No generated edit."),
      c("Step 01 diagnostic ini values.", "Step 01 diagnostic source file.", "Step 01 diagnostic source file.", "Step 01 diagnostic source file.")
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
write_02_newexe_step()
write_diagnostic_substep(
  "03-Ini1007",
  "03 Updated INI format",
  "Step 02 current-executable baseline promoted from MFCL 1003 to MFCL 1007 ini layout.",
  source_step = "02-NewExe1003",
  promote_1007 = TRUE
)
write_diagnostic_substep(
  "04-FixM",
  "04 Diagnostic natural-mortality estimate fixed",
  paste0(
    "Step 03 1007 INI baseline with Lorenzen natural-mortality scaling fixed ",
    "to the 2023 diagnostic-model estimate."
  ),
  source_step = "03-Ini1007",
  fixm = TRUE
)
write_diagnostic_substep(
  "05-LengthWeight",
  "05 Length-weight update",
  "Step 04 fixed natural-mortality baseline with BET 2026 bias-corrected length-weight parameters.",
  source_step = "04-FixM",
  length_weight_parameters = bias_corrected_length_weight_parameters,
  fixm = TRUE
)

old_age <- file.path(age_root, "bet.2023.new-structure.age_length")
new_age <- file.path(age_root, "bet.2026.age_length")
new_ini <- file.path(ini_root, "bet.2026.ini")
new_tag <- file.path(tag_root, "bet.2026.low.recaps.removed.tag")
mix015_ini <- file.path(
  ini_root, "ini.mix-period", "bet.2026.mix-0.15.ini"
)
mix005_ini <- file.path(
  ini_root, "ini.mix-period", "bet.2026.mix-0.05.ini"
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

## 06-NewStructure is the first 5-region template. Cache the inherited template
## before overwriting the folder so the script is rerunnable after old folders
## have been removed.
newstructure_dir <- file.path(root, "steps", "06-NewStructure")
newstructure_model_dir <- file.path(newstructure_dir, "model")
template_candidates <- c(
  newstructure_model_dir,
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
  "06 NewStructure",
  "First 5-region / 33-fishery BET input step, ending in 2021 with global CPUE.",
  c(
    "Uses the new 5-region and new-fishery frequency source from the frq-build repo.",
    "Represents 28 extraction fisheries plus 5 index fisheries.",
    "Keeps data through 2021 and uses the global CPUE setup for this structural transition.",
    "Uses old CAAL re-assigned to the new fisheries.",
    paste0("Uses the restructured tag setup with ", frq_counts_04$n_tag_groups, " release groups."),
    "Applies the SC22 BET purse-seine reporting-rate penalties with separate West and East groups.",
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
    "This step is the 5-region control template for steps 07-19.",
    "Generated `.frq` files include region locations for every fishery, including index fisheries.",
    "MFCL 1007 `# tag flags` supply tag mixing periods directly; the inherited `-9999 1 2` doitall override is removed.",
    "`doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.",
    "PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; the default for all stepwise model fits is `-4`."
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



## Self-contained public 23-row / 20-stage sequence --------------------------

stepwise_5_region_template_step_id <- "06-NewStructure"

age_variant_root <- file.path(
  input_root, "ofp-sam-bet-2026-exploration", "reference-inputs", "age-length-variants"
)
regional_age_075 <- file.path(age_variant_root, "bet.2026.regional.0.75.age_length")
sub_basin_age_075 <- file.path(age_variant_root, "bet.2026.sub.basin.0.75.age_length")
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

francis_ta18_path <- file.path(root, "config", "francis-ta18-divisors.csv")
francis_ta18_source_commit <- "a9d63b3111fb036b23fbe2803fcddf818420d09d"
francis_ta18_source_path <- paste0(
  "sensitivity/S009-TC1-NOCUT-FRANCIS-CPUEMLE-SUB075-MIX015-TAGF2ON-",
  "REGW100-RRPTTP26/model/francis_weights.csv"
)
francis_ta18_source_note <- paste0(
  "Exact audited TA1.8 CSV archived at PacificCommunity/",
  "ofp-sam-bet-2026-exploration@", francis_ta18_source_commit, "/",
  francis_ta18_source_path, ". The divisors were calculated from standardized ",
  "mean-length residuals for 2,399 retained compositions in the robust-normal ",
  "S022 fit (Kflow Job 12306; regional-scaling weight 11; F21-F23 stage-1 ",
  "divisors 200)."
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
    stop("Francis TA1.8 audit does not contain the validated F1-F33 vector", call. = FALSE)
  }
  audit
}

francis_ta18_audit <- read_francis_ta18_audit(francis_ta18_path)
francis_lf_divisors <- as.integer(francis_ta18_audit$recommended_divisor)

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
    index_selectivity = FALSE,
    r1_f2_f3_f29_shared_selectivity = FALSE,
    selectivity_stability_map = FALSE,
    f33_asymptotic_selectivity = FALSE,
    tag_return_likelihood_weight = NA_integer_,
    selectivity_update_bundle = FALSE,
    all_selectivity_forms_relaxed = FALSE,
    time_varying_cv = FALSE,
    effort_creep = FALSE,
    dom_divisor200 = FALSE,
    fixed_cpue_sigma = FALSE,
    francis_divisors = numeric(),
    francis_source = "",
    francis_source_note = "",
    dm_grouping = "",
    dm_nmax = NA_integer_,
    status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  controls <- list2env(
    list(
      regional_cpue = regional_cpue,
      index_selectivity = index_selectivity,
      r1_f2_f3_f29_shared_selectivity =
        r1_f2_f3_f29_shared_selectivity,
      selectivity_stability_map = selectivity_stability_map,
      f33_asymptotic_selectivity = f33_asymptotic_selectivity,
      tag_return_likelihood_weight = tag_return_likelihood_weight,
      selectivity_update_bundle = selectivity_update_bundle,
      all_selectivity_forms_relaxed = all_selectivity_forms_relaxed,
      tail_compression_1pct = tail_compression_1pct,
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
    reporting_rate_group_prior_repairs = reporting_rate_group_prior_repairs,
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
      if (index_selectivity) "F29-F33 use separate selectivity coefficient-sharing groups from staged MFCL run 5.",
      if (selectivity_stability_map) paste0(
        "The selectivity-stability sensitivity shares F2/F3 and F7/F9; ",
        "F19, F25, F26 and F29-F33 remain independent. The Job 15989 node ",
        "settings are retained, including seven nodes for F25/F26."
      ),
      if (f33_asymptotic_selectivity) paste0(
        "F33 remains an independent Region 5 index selectivity and uses the ",
        "two-parameter asymptotic logistic form; its catchability group and ",
        "all extraction-index separations are unchanged."
      ),
      if (selectivity_update_bundle && !selectivity_stability_map) paste0(
        "The intended selectivity bundle unshares F15-F28 and applies fishery-specific ",
        "terminal/dome and youngest-age-tail controls; F25/F26 each use seven ",
        "nodes, terminal age 25, dome flag 2, and youngest-tail flag 0."
      ),
      if (selectivity_update_bundle && selectivity_stability_map) paste0(
        "Fishery-specific terminal, dome and youngest-age-tail controls from ",
        "the revised selectivity bundle are retained; only the documented ",
        "coefficient-sharing groups change, while Job 15989 spline-node ",
        "counts are retained."
      ),
      if (all_selectivity_forms_relaxed) paste0(
        "The selected Job 14363 revised fishery-specific specification sets flag 16 to 0 ",
        "for all 14 applicable fisheries, so the dome/old-age-tail form penalty is off."
      ),
      if (!is.na(tag_return_likelihood_weight)) paste0(
        "Parest flag 177 is ", tag_return_likelihood_weight,
        ", multiplying the tag-return likelihood by ",
        format(tag_return_likelihood_weight / 1000, nsmall = 2L),
        "; release-group reporting-rate priors are retained at their configured weights."
      ),
      if (time_varying_cv) "F29-F33 use normalized time-varying CPUE relative-variance multipliers from the frequency data.",
      if (dom_divisor200) "Only F21-F23 receive the DOM LF divisor 200.",
      if (length(francis_divisors)) paste0(
        "Francis divisors are applied directly to all LF flag-49 values, including ",
        "F21-F23 = ", paste(francis_divisors[21:23], collapse = "/"), "."
      ),
      if (fixed_cpue_sigma) paste0(
        "Fixed CPUE observation-error scales (flag 92 integer percentages): ",
        paste(cpue_sigma_calibration$flag92, collapse = ", "), "."
      ),
      if (nzchar(dm_grouping)) paste0(
        dm_grouping, " DM likelihood with effective-sample-size upper asymptote Nmax=", dm_nmax, "."
      )
    ),
    input_changes = input_change_table(
      c(".frq", ".ini", ".tag", ".age_length", "Step-specific change"),
      c(
        if (effort_creep) "Changes only positive F29-F33 effort using the agreed creep schedule." else "Uses the selected source without additional scientific transformation.",
        paste(
          c(
            if (nzchar(tag_reporting_source)) paste0(reporting_rate_variant, " reporting-rate matrices"),
            if (nzchar(tag_mixing_source)) {
              paste0(
                basename(tag_mixing_source),
                " copied only into tag_flags(:,1)"
              )
            },
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
      if (fixed_cpue_sigma) "cpue_mle_sigma_audit.csv records the archived source commit/path/SHA256, preliminary maximum-likelihood observation-error estimates, and executed flag-92 values."
    ),
    outstanding = character(),
    status = status
  )
}

write_sequence_step(
  "07-ConvertToLength", "07 Convert weight to length compositions", "06-NewStructure",
  "Convert the existing weight-frequency compositions to length-frequency to evaluate the conversion effect.",
  frq_source = frq_convert_length_2021,
  ini_source = regfish_ini_source,
  tag_source = regfish_tag_source,
  reporting_rate_variant = "rrpttp26"
)

write_sequence_step(
  "08-AddLengthData", "08 Weight-as-length plus observed-length compositions", "07-ConvertToLength",
  "Use observed length compositions where their catch coverage exceeds that of weight samples.",
  frq_source = frq_length_plus_length_2021,
  ini_source = regfish_ini_source,
  tag_source = regfish_tag_source,
  reporting_rate_variant = "rrpttp26"
)

# Tail aggregation is introduced only after weight compositions have been
# converted to length and observed length compositions have been incorporated.
write_sequence_step(
  "09-TailCompression1Pct", "09 One-percent LF tail compression", "08-AddLengthData",
  "Activate 1% length-frequency tail aggregation by changing only parest flag 313 from 0 to 1.",
  audit_notes = c(
    "Held constant: flag 311 remains 1, length-frequency flag 301 remains 1, and weight-frequency flag 303 remains 0.",
    "This setting is inherited by every subsequent model."
  ),
  frq_source = frq_length_plus_length_2021,
  ini_source = regfish_ini_source,
  tag_source = regfish_tag_source,
  reporting_rate_variant = "rrpttp26",
  tail_compression_1pct = TRUE
)

# The SC22 BET reporting-rate priors enter with the 33-fishery structure in
# step 06. Step 10 remaps the same fishery-level specification to the two
# additional 2026 tag-release rows.
write_sequence_step(
  "10-DataTo2024", "10 Data through 2024", "09-TailCompression1Pct",
  "Extend data through 2024 while carrying the SC22 BET reporting-rate penalties.",
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini,
  tail_compression_1pct = TRUE
)

# Regional CPUE and REGW100 are one scientific group; selectivity is unchanged.
write_sequence_step(
  "11-RegionalCPUE", "11 Regional CPUE likelihood and weighting", "10-DataTo2024",
  "Add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty.",
  audit_notes = paste0(
    "The authoritative regional CPUE replacement has two fewer F32 1952 ",
    "quarterly records than Step 10; the source FRQ is copied without transformation."
  ),
  frq_source = frq_regional_2024,
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini,
  regional_cpue = TRUE,
  regional_scaling = TRUE,
  regional_scaling_weight = 100L,
  tail_compression_1pct = TRUE
)

# Apply the time-varying relative-variance schedule immediately after regional
# CPUE is introduced, without changing the index-specific observation-error
# scales in the same step.
write_sequence_step(
  "12-TimeVaryingCV", "12 Time-varying CPUE uncertainty", "11-RegionalCPUE",
  "Apply normalized time-varying CPUE relative-variance multipliers to F29-F33 while retaining the Step 11 observation-error scales.",
  frq_source = frq_regional_2024,
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini,
  regional_cpue = TRUE,
  regional_scaling = TRUE,
  regional_scaling_weight = 100L,
  tail_compression_1pct = TRUE,
  time_varying_cv = TRUE,
  fixed_cpue_sigma = FALSE
)

write_sequence_step(
  "13-CPUEErrorCalibration", "13 CPUE observation-error calibration", "12-TimeVaryingCV",
  paste(
    "Across multiple exploratory settings, the maximum-likelihood CPUE",
    "observation-error estimates changed little and converged near common values.",
    "Apply the calibrated R1-R5 scales 0.35, 0.24, 0.21, 0.24, and 0.23",
    "for every later step."
  ),
  frq_source = frq_regional_2024,
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini,
  regional_cpue = TRUE,
  regional_scaling = TRUE,
  regional_scaling_weight = 100L,
  tail_compression_1pct = TRUE,
  time_varying_cv = TRUE,
  fixed_cpue_sigma = TRUE
)

write_sequence_step(
  "14-NewAgeData", "14 New conditional age-at-length data", "13-CPUEErrorCalibration",
  "Add the new conditional age-at-length data with a weighting factor of 0.75 from the 2023 BET assessment.",
  frq_source = frq_regional_2024,
  age_source = new_age,
  age_effective_sample_size = 0.75,
  reporting_rate_variant = "rrpttp26",
  tag_reporting_source = peatman_rr_ini,
  regional_cpue = TRUE,
  regional_scaling = TRUE,
  regional_scaling_weight = 100L,
  tail_compression_1pct = TRUE,
  time_varying_cv = TRUE,
  fixed_cpue_sigma = TRUE
)

for (age_spec in list(
  list(id = "15a-REG075", title = "15a Regional age weighting", source = regional_age_075, ess = NA_real_,
       change = "Apply the exact heterogeneous REG075 composition-weighting alternative."),
  list(id = "15b-SUB075", title = "15b Sub-basin age weighting selected", source = sub_basin_age_075, ess = NA_real_,
       change = "Apply the exact heterogeneous SUB075 composition weighting; this sibling is selected.")
)) {
  write_sequence_step(
    age_spec$id, age_spec$title, "14-NewAgeData", age_spec$change,
    frq_source = frq_regional_2024,
    age_source = age_spec$source,
    age_effective_sample_size = age_spec$ess,
    reporting_rate_variant = "rrpttp26",
    tag_reporting_source = peatman_rr_ini,
    regional_cpue = TRUE,
    regional_scaling = TRUE,
    regional_scaling_weight = 100L,
    tail_compression_1pct = TRUE,
    time_varying_cv = TRUE,
    fixed_cpue_sigma = TRUE
  )
}

write_selected_path_step <- function(
    step_id, title, parent, change,
    audit_notes = character(),
    tag_mixing = FALSE, tag_flag2 = 0L,
    tag_mixing_source_override = "",
    tail_compression_1pct = TRUE,
    time_varying_cv = FALSE, effort_creep = FALSE,
    fixed_cpue_sigma = FALSE,
    index_selectivity = FALSE, selectivity_update_bundle = FALSE,
    r1_f2_f3_f29_shared_selectivity = FALSE,
    selectivity_stability_map = FALSE,
    f33_asymptotic_selectivity = FALSE,
    tag_return_likelihood_weight = NA_integer_,
    all_selectivity_forms_relaxed = FALSE,
    dom = FALSE, francis = numeric(),
    dm_grouping = "", dm_nmax = NA_integer_,
    status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  write_sequence_step(
    step_id, title, parent, change,
    audit_notes = audit_notes,
    frq_source = frq_regional_2024,
    age_source = sub_basin_age_075,
    age_effective_sample_size = NA_real_,
    reporting_rate_variant = "rrpttp26",
    tag_reporting_source = peatman_rr_ini,
    tag_mixing_source = if (nzchar(tag_mixing_source_override)) {
      tag_mixing_source_override
    } else if (tag_mixing) {
      mix015_ini
    } else {
      ""
    },
    tag_flag_column2 = tag_flag2,
    regional_cpue = TRUE,
    regional_scaling = TRUE,
    regional_scaling_weight = 100L,
    tail_compression_1pct = tail_compression_1pct,
    index_selectivity = index_selectivity,
    r1_f2_f3_f29_shared_selectivity =
      r1_f2_f3_f29_shared_selectivity,
    selectivity_stability_map = selectivity_stability_map,
    f33_asymptotic_selectivity = f33_asymptotic_selectivity,
    tag_return_likelihood_weight = tag_return_likelihood_weight,
    selectivity_update_bundle = selectivity_update_bundle,
    all_selectivity_forms_relaxed = all_selectivity_forms_relaxed,
    time_varying_cv = time_varying_cv,
    effort_creep = effort_creep,
    dom_divisor200 = dom,
    fixed_cpue_sigma = fixed_cpue_sigma,
    francis_divisors = francis,
    francis_source = if (length(francis)) francis_ta18_path else "",
    francis_source_note = if (length(francis)) francis_ta18_source_note else "",
    dm_grouping = dm_grouping,
    dm_nmax = dm_nmax,
    status = status
  )
}

write_selected_path_step(
  "16-SelectivityUpdate", "16 Revised fishery-specific selectivity", "15b-SUB075",
  paste0(
    "Revise fishery-specific selectivity sharing, terminal ages, and F25/F26 shape settings for the 33-fishery structure, ",
    "remove six superseded legacy controls, and set flag 16 to 0 for all 14 ",
    "applicable fisheries so all weighting comparisons use the selected Job 14363 setting."
  ),
  audit_notes = c(
    "Scientific rationale: represent fishery-specific size availability without imposing unnecessary older-age shape constraints before comparing composition weighting.",
    "Held constant: data, fixed natural mortality, growth, CPUE settings, tag reporting-rate mapping, and every non-selectivity control.",
    "The Step 15b parent has 15 active flag-16 penalties. The revised structure changes the applicable fishery set: superseded F20/F28 controls are removed and F15 is introduced.",
    "For the resulting F12, F13, F15-F19, and F21-F27 set, flag 16 is 0 (form penalty off); fishery-specific terminal ages, spline-node counts, and youngest-age tails are retained.",
    "Status: selected Job 14363 selectivity setting, carried forward to all Step 20 weighting comparisons."
  ),
  time_varying_cv = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  status = "Prepared input snapshot; model fit not run here."
)
write_selected_path_step(
  "17-MIX015", "17 Release-group-specific tag-mixing periods", "16-SelectivityUpdate",
  paste0(
    "Apply the release-group-specific MIX015 periods in tag_flags(:,1), while ",
    "keeping tag_flags(:,2)=0 so the treatment of reporting rates during mixing is tested separately ",
    "in Step 18; do not change reporting-rate values or priors."
  ),
  audit_notes = c(
    "INI source: ofp-sam-2026-BET-YFT-build-ini branch SC22-IP10-based at commit 5b2fb60; the main branch is not used for this mixing-period step.",
    "The release-group periods implement Appendix A of WCPFC-SC22-2026-SA-IP10.",
    "The five reporting-rate matrices are identical to the Step 10-16 source; only tag_flags(:,1) changes at this step."
  ),
  tag_mixing = TRUE, tag_flag2 = 0L, time_varying_cv = TRUE,
  fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE
)
write_selected_path_step(
  "18-TagReportingExclusion", "18 Tag reporting rates omitted in pre-mixing window", "17-MIX015",
  paste0(
    "Keep the release-group-specific mixing periods and set tag_flags(:,2)=1 ",
    "so reporting rates are not applied to predicted recaptures within each ",
    "release group's pre-mixing window; post-mixing treatment and all reporting-rate ",
    "values, groups, targets, and priors remain unchanged."
  ),
  audit_notes = c(
    "Scientific rationale: avoid applying poorly determined or assumed reporting rates during the pre-mixing reconstruction, as recommended in the MULTIFAN-CL manual.",
    "Held constant: all Step 17 data, biology, revised fishery-specific selectivity with form penalties off, CPUE, tag-mixing periods, and numeric reporting-rate settings.",
    "Only tag-flag column 2 changes from 0 to 1; reporting rates continue to apply after the mixing period."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE
)
write_selected_path_step(
  "19-EffortCreep", "19 Effort-creep adjustment", "18-TagReportingExclusion",
  "Apply the BET 2026 effort-creep series only to positive F29-F33 effort.",
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE
)
write_selected_path_step(
  "20a-DOMDiv200", "20a Three domestic fisheries downweighted", "19-EffortCreep",
  "Apply divisor 200 to length compositions from the Indonesian, Philippine, and Vietnamese domestic fisheries (F21-F23).",
  audit_notes = c(
    "Scientific rationale: test whether reducing the influence of these three composition series improves balance with other data.",
    "Held constant: the Step 19 data, biology, revised fishery-specific selectivity with form penalties off, CPUE, tag, and all other composition settings.",
    "Status: independent alternative comparison; not carried forward."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dom = TRUE,
  status = "Prepared alternative-comparison snapshot; model fit not run here."
)

write_selected_path_step(
  "20b-Francis", "20b Francis reweighting", "19-EffortCreep",
  "Apply fishery-specific Francis length-composition divisors as an independent Step 19 comparison branch.",
  audit_notes = c(
    "Rationale: compare fishery-specific composition weighting using method TA1.8 of Francis (2011).",
    "The applied divisors were calculated from standardized mean-length residuals for 2,399 retained compositions in the robust-normal S022 fit (Kflow Job 12306; regional-scaling weight 11; F21-F23 stage-1 divisors 200) and transferred unchanged to this branch.",
    "Held constant: all Step 19 settings and the standard composition likelihood; the 20a divisor-200 treatment is not inherited.",
    "Status: alternative comparison; not carried forward."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L, time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dom = FALSE,
  francis = francis_lf_divisors,
  status = "Prepared alternative-comparison snapshot; model fit not run here."
)
write_selected_path_step(
  "20c-DMG8Nmax25", "20c DM weighting", "19-EffortCreep",
  paste0(
    "Branch directly from Step 19 and use a Dirichlet-multinomial length-",
    "composition likelihood with G8 grouping and Nmax 25, ",
    "without DOM divisor 200 or Francis weighting."
  ),
  audit_notes = c(
    "Scientific rationale: estimate composition information internally with Nmax=25 as the asymptotic effective-sample-size upper bound. The value lies just above the 22.22-23.81 range of 95th-percentile composition-level Francis effective sample sizes across 2,399 positive LF compositions in matched robust-normal fits.",
    "Held constant: all Step 19 data, biology, Job 14363 revised fishery-specific selectivity with form penalties off, CPUE, and tag settings; neither the 20a divisor nor 20b Francis weights are inherited. Flag 313 is reset to 0 because the DM likelihood does not read that percentage threshold and to avoid unrelated percentage-tail preprocessing; flag 320=5 controls DM support and the resulting numeric controls match Job 14363.",
    "Status: selected final model."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L, tail_compression_1pct = FALSE,
  time_varying_cv = TRUE,
  effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared selected-model snapshot; model fit not run here."
)

write_selected_path_step(
  "21a-R1F2F3F29Shared-MIX015",
  "21a R1 shared selectivity with SC22 K=0.15 mixing",
  "20c-DMG8Nmax25",
  paste0(
    "Retain the final DM model and apply the exact Job 15984 selectivity map: ",
    "F2, F3 and F29 share one four-node Region 1 curve; F30/F4, F31/F7 ",
    "and F32/F8 remain paired; F33 and all index catchability groups remain ",
    "independent."
  ),
  audit_notes = c(
    "Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12.",
    "Mixing-period source: ofp-sam-2026-BET-YFT-build-ini SC22-IP10-based commit 5b2fb6053e34a58ef61275a68d8a67ec988833c1, K=0.15.",
    "Held constant: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets, penalties, CPUE controls, data and all non-selectivity settings."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix015_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  r1_f2_f3_f29_shared_selectivity = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent final-DM sensitivity snapshot."
)

write_selected_path_step(
  "21b-R1F2F3F29Shared-MIX005",
  "21b R1 shared selectivity with SC22 K=0.05 mixing",
  "21a-R1F2F3F29Shared-MIX015",
  paste0(
    "Use the same final DM model and exact Job 15984 selectivity map as Step ",
    "21a, changing only tag_flags(:,1) from the SC22 K=0.15 periods to the ",
    "SC22 K=0.05 periods."
  ),
  audit_notes = c(
    "Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12.",
    "Mixing-period source: ofp-sam-2026-BET-YFT-build-ini SC22-IP10-based commit 5b2fb6053e34a58ef61275a68d8a67ec988833c1, K=0.05.",
    "Held constant relative to Step 21a: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets, penalties, CPUE controls, data and every doitall control."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix005_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  r1_f2_f3_f29_shared_selectivity = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent K=0.05 mixing-period sensitivity snapshot."
)

write_selected_path_step(
  "22a-R1F2F3F29Shared-MIX015-TAGW500",
  "22a SC22 K=0.15 with tag-return weight 0.50",
  "21a-R1F2F3F29Shared-MIX015",
  paste0(
    "Retain the K=0.15 grouped-selectivity final DM model and set parest ",
    "flag 177 to 500, multiplying the tag-return likelihood by 0.50."
  ),
  audit_notes = c(
    "Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12.",
    "Mixing-period source: SC22-IP10 K=0.15.",
    "Held constant: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets and priors, CPUE controls, data and all other settings."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix015_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  r1_f2_f3_f29_shared_selectivity = TRUE,
  tag_return_likelihood_weight = 500L,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent tag-return weight sensitivity snapshot."
)

write_selected_path_step(
  "22b-R1F2F3F29Shared-MIX015-TAGW250",
  "22b SC22 K=0.15 with tag-return weight 0.25",
  "21a-R1F2F3F29Shared-MIX015",
  paste0(
    "Retain the K=0.15 grouped-selectivity final DM model and set parest ",
    "flag 177 to 250, multiplying the tag-return likelihood by 0.25."
  ),
  audit_notes = c(
    "Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12.",
    "Mixing-period source: SC22-IP10 K=0.15.",
    "Held constant: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets and priors, CPUE controls, data and all other settings."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix015_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  r1_f2_f3_f29_shared_selectivity = TRUE,
  tag_return_likelihood_weight = 250L,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent tag-return weight sensitivity snapshot."
)

write_selected_path_step(
  "22c-R1F2F3F29Shared-MIX005-TAGW500",
  "22c SC22 K=0.05 with tag-return weight 0.50",
  "21b-R1F2F3F29Shared-MIX005",
  paste0(
    "Retain the K=0.05 grouped-selectivity final DM model and set parest ",
    "flag 177 to 500, multiplying the tag-return likelihood by 0.50."
  ),
  audit_notes = c(
    "Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12.",
    "Mixing-period source: SC22-IP10 K=0.05.",
    "Held constant: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets and priors, CPUE controls, data and all other settings."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix005_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  r1_f2_f3_f29_shared_selectivity = TRUE,
  tag_return_likelihood_weight = 500L,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent tag-return weight sensitivity snapshot."
)

write_selected_path_step(
  "22d-R1F2F3F29Shared-MIX005-TAGW250",
  "22d SC22 K=0.05 with tag-return weight 0.25",
  "21b-R1F2F3F29Shared-MIX005",
  paste0(
    "Retain the K=0.05 grouped-selectivity final DM model and set parest ",
    "flag 177 to 250, multiplying the tag-return likelihood by 0.25."
  ),
  audit_notes = c(
    "Selectivity source: Job 15984, repository commit d9fd5377abd5ba6aac5aee1b56ec54a9d9d4fc12.",
    "Mixing-period source: SC22-IP10 K=0.05.",
    "Held constant: fixed Lorenzen M, DM G8 Nmax25, reporting-rate groups, targets and priors, CPUE controls, data and all other settings."
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix005_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  r1_f2_f3_f29_shared_selectivity = TRUE,
  tag_return_likelihood_weight = 250L,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent tag-return weight sensitivity snapshot."
)

write_selected_path_step(
  "S01-SelectivityStability-MIX015",
  "S01 Selectivity-stability sensitivity with SC22 K=0.15 mixing",
  "21a-R1F2F3F29Shared-MIX015",
  paste0(
    "Retain the final DM model and SC22-IP10 K=0.15 tag settings, separate ",
    "all regional index selectivities from extraction fisheries, and share ",
    "only the extraction-fishery pairs F2/F3 and F7/F9."
  ),
  audit_notes = c(
    paste0(
      "Basis: extraction and index compositions have different weighting and ",
      "sampling processes in Peatman et al. (2026), WCPFC-SC22-2026-SA-IP06; ",
      "index selectivities are therefore kept independent."
    ),
    paste0(
      "The two extraction-fishery pairs combine compatible gear, spatial and ",
      "composition-processing strata with similar fitted selectivity curves. ",
      "This is a stability sensitivity, not a claim that the paper prescribes ",
      "selectivity sharing."
    ),
    paste0(
      "F19, F25 and F26 remain independent, and all Job 15989 spline-node ",
      "settings are retained. Fixed Lorenzen M, DM G8 Nmax25, reporting-rate ",
      "priors, CPUE controls, data and all other settings are unchanged."
    ),
    paste0(
      "Report-ready rationale and interpretation: ",
      "[SELECTIVITY_STABILITY_SENSITIVITY.md]",
      "(../../SELECTIVITY_STABILITY_SENSITIVITY.md)."
    )
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix015_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  selectivity_stability_map = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent selectivity-stability sensitivity snapshot."
)

write_selected_path_step(
  "S02-F33Asymptotic-MIX015",
  "S02 F33 asymptotic-selectivity sensitivity with SC22 K=0.15 mixing",
  "S01-SelectivityStability-MIX015",
  paste0(
    "Retain the extraction-only selectivity sharing and independent regional ",
    "indices from S01, and replace only the F33 Region 5 four-node spline ",
    "with an independent asymptotic logistic selectivity."
  ),
  audit_notes = c(
    paste0(
      "F33 has 24 retained quarterly size compositions from 1965-1996, while ",
      "its regional CPUE index spans 292 quarters from 1952-2024. Peatman et ",
      "al. (2026; WCPFC-SC22-2026-SA-IP06) also identify Region 5 index ",
      "compositions as sparse."
    ),
    paste0(
      "The unconstrained F33 spline fitted an effectively asymptotic curve; ",
      "the logistic form tests whether removing an unsupported descending ",
      "limb improves stability without materially degrading fit."
    ),
    paste0(
      "F29-F33 remain independent from extraction fisheries and from each ",
      "other. F33 catchability, fixed Lorenzen M, DM G8 Nmax25, SC22-IP10 ",
      "K=0.15 tag settings, reporting-rate priors, CPUE controls, data and ",
      "all other settings are unchanged."
    ),
    paste0(
      "Runtime: tuna-flow v2.6 uses the MFCL pre-mixing reporting-rate ",
      "exclusion correction; comparison with earlier-executable runs therefore ",
      "includes that executable change as well as the F33 form change."
    )
  ),
  tag_mixing = TRUE, tag_flag2 = 1L,
  tag_mixing_source_override = mix015_ini,
  tail_compression_1pct = FALSE,
  time_varying_cv = TRUE, effort_creep = TRUE, fixed_cpue_sigma = TRUE,
  index_selectivity = TRUE, selectivity_update_bundle = TRUE,
  selectivity_stability_map = TRUE,
  f33_asymptotic_selectivity = TRUE,
  all_selectivity_forms_relaxed = TRUE,
  dm_grouping = "G8PSSET", dm_nmax = 25L,
  status = "Prepared independent F33 asymptotic-selectivity sensitivity snapshot."
)

# Remove superseded numbering and selectivity-sensitivity folders after the
# replacement sequence has been generated. Every removed folder remains
# recoverable from Git history.
config_env <- new.env(parent = baseenv())
sys.source(file.path(root, "job-config.R"), envir = config_env)
configured_steps <- as.character(config_env$stepwise_models$step_id)
obsolete_step_ids <- c(
  "01a-NewExe1003", "01b-Ini1007",
  "02-FixM", "03-LengthWeight", "04-NewStructure",
  "05-ConvertToLength", "06-AddLengthData", "07-TailCompression1Pct",
  "08-DataTo2024", "09-RegionalCPUE",
  "10a-BASE075", "10b-REG075", "10c-SUB075",
  "11-MIX015", "12-TAGF2ON", "13-TimeVaryingCV",
  "14-EffortCreep", "15-CPUESigma", "16-SelectivityUpdateAllRelaxed",
  "17a-DOMDiv200", "17b-Francis", "17c-DMG8Nmax25",
  "12a-BASE075", "12b-REG075", "12c-SUB075",
  "13a-BASE075", "13b-REG075", "13c-SUB075",
  "13-MIX015", "13-SelectivityUpdate", "13-CPUESigma",
  "14-TAGF2ON", "14-TimeVaryingCV", "14-SelectivityUpdate",
  "14a-BASE075", "14b-REG075", "14c-SUB075",
  "15-MIX015", "15-EffortCreep",
  "16-TimeVaryingCV", "16-CPUESigma", "18-CPUESigma",
  "18a-DOMDiv200", "18b-Francis", "18c-DMG8Nmax25",
  "13-NewAgeData", "14a-REG075", "14b-SUB075",
  "15-SelectivityUpdate", "16-MIX015", "17-EffortCreep",
  "19a-DOMDiv200", "19b-Francis", "19c-DMG8Nmax25",
  "13-CPUEObservationError",
  "02a-NewExe1003", "02b-Ini1007", "02c-LengthWeight", "03-FixM",
  "07-DataTo2024", "08-RegionalCPUE",
  "09a-BASE075", "09b-REG075", "09c-SUB075",
  "10-MIX015", "11-TAGF2ON",
  "13-EffortCreep", "14-CPUESigma",
  "16-DOMDiv200", "16a-DOMDiv200", "16b-Francis", "16c-DMG8Nmax25",
  "17a-F15FormRelaxed", "17b-F22FormRelaxed",
  "17c-F15F22FormRelaxed", "17d-AllSelectivityFormRelaxed",
  "17a-Francis", "17b-DMG8Nmax25",
  "18a-F22FormRelaxed", "18b-F15FormRelaxed",
  "18c-F15F22FormRelaxed", "18d-AllSelectivityFormRelaxed",
  "18-EffortCreep", "19-TagReportingExclusion"
)
if (length(intersect(obsolete_step_ids, configured_steps))) {
  stop("Obsolete weighting step IDs remain configured", call. = FALSE)
}
obsolete_step_dirs <- file.path(root, "steps", obsolete_step_ids)
unlink(obsolete_step_dirs[dir.exists(obsolete_step_dirs)], recursive = TRUE, force = TRUE)
