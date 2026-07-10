#!/usr/bin/env Rscript
## Build the terminal-recruitment sensitivity folders from the current main
## step 11 (ordinary recruitment deviations) and step 12 (OPR) templates.
##
## Usage:
##   Rscript R/prepare_step12_terminal_sensitivity.R
##   Rscript R/prepare_step12_terminal_sensitivity.R --overwrite

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite" %in% args
unknown <- setdiff(args, "--overwrite")
if (length(unknown)) {
  stop("Unknown argument(s): ", paste(unknown, collapse = ", "), call. = FALSE)
}

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "prepare_doitall.R"))
source(file.path(root, "R", "step12_terminal_sensitivity_config.R"))

copy_tree <- function(from, to, overwrite = FALSE) {
  if (!dir.exists(from)) stop("Missing source folder: ", from, call. = FALSE)
  if (dir.exists(to)) {
    if (!isTRUE(overwrite)) {
      stop("Target already exists (use --overwrite to replace it): ", to, call. = FALSE)
    }
    unlink(to, recursive = TRUE, force = TRUE)
  }
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  paths <- list.files(from, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  files <- paths[!dir.exists(paths)]
  dirs <- paths[dir.exists(paths)]
  if (length(dirs)) {
    for (directory in dirs) {
      relative <- substring(directory, nchar(from) + 2L)
      dir.create(file.path(to, relative), recursive = TRUE, showWarnings = FALSE)
    }
  }
  if (length(files)) {
    relative <- substring(files, nchar(from) + 2L)
    destinations <- file.path(to, relative)
    for (destination_dir in unique(dirname(destinations))) {
      dir.create(destination_dir, recursive = TRUE, showWarnings = FALSE)
    }
    copied <- file.copy(files, destinations, overwrite = TRUE, copy.mode = TRUE, copy.date = TRUE)
    if (!all(copied)) stop("Could not copy every file from ", from, call. = FALSE)
  }
  invisible(to)
}

model_files <- function(model_dir) {
  files <- list.files(model_dir, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  files[!dir.exists(files)]
}

verify_inherited_inputs <- function(parent_model_dir, target_model_dir) {
  parent_files <- model_files(parent_model_dir)
  relative <- substring(parent_files, nchar(parent_model_dir) + 2L)
  keep <- relative != "doitall.sh"
  parent_files <- parent_files[keep]
  relative <- relative[keep]
  target_files <- file.path(target_model_dir, relative)
  if (!all(file.exists(target_files))) {
    missing <- relative[!file.exists(target_files)]
    stop("Sensitivity folder is missing inherited files: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  source_hash <- unname(tools::md5sum(parent_files))
  target_hash <- unname(tools::md5sum(target_files))
  if (!identical(source_hash, target_hash)) {
    changed <- relative[source_hash != target_hash]
    stop("Only doitall.sh may differ from the parent; changed input(s): ", paste(changed, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

shell_check <- function(path) {
  status <- system2("bash", c("-n", path), stdout = FALSE, stderr = FALSE)
  if (!identical(status, 0L)) stop("bash -n failed for ", path, call. = FALSE)
  invisible(TRUE)
}

phase3_flag_value <- function(lines, flag) {
  phase_start <- grep("<<PHASE3$", lines)
  phase_end <- grep("^PHASE3$", lines)
  if (length(phase_start) != 1L || length(phase_end) != 1L || phase_start >= phase_end) {
    stop("Expected one PHASE3 section", call. = FALSE)
  }
  pattern <- sprintf("^[[:space:]]*1[[:space:]]+%d[[:space:]]+(-?[0-9]+)([[:space:]]|$)", flag)
  hit <- grep(pattern, lines[seq.int(phase_start + 1L, phase_end - 1L)], value = TRUE, perl = TRUE)
  if (length(hit) != 1L) stop("Expected one PHASE3 parest flag ", flag, call. = FALSE)
  as.integer(sub(paste0(pattern, ".*$"), "\\1", hit, perl = TRUE))
}

initial_flag_value <- function(lines, flag) {
  pattern <- sprintf("^[[:space:]]*1[[:space:]]+%d[[:space:]]+(-?[0-9]+)([[:space:]]|$)", flag)
  hit <- grep(pattern, lines, value = TRUE, perl = TRUE)
  if (length(hit) != 1L) stop("Expected one initial parest flag ", flag, call. = FALSE)
  as.integer(sub(paste0(pattern, ".*$"), "\\1", hit, perl = TRUE))
}

standard_terminal_text <- function(periods, arithmetic_mean) {
  if (periods == 0L) {
    return("No fixed terminal recruitment deviations: all terminal quarters are estimated.")
  }
  target <- if (isTRUE(arithmetic_mean)) {
    "the arithmetic mean of earlier natural-scale recruitment"
  } else {
    "zero recruitment deviation (no arithmetic-mean replacement)"
  }
  sprintf("The last %d quarterly recruitment deviation(s) are fixed to %s.", periods, target)
}

opr_capacity_text <- function(year_end_window) {
  effective_window <- max(1L, as.integer(year_end_window))
  capacity <- 74L - effective_window
  sprintf(
    "With 73 real years and the default one-point initial endpoint, the annual coefficient ceiling for end window %d is %d%s.",
    as.integer(year_end_window), capacity,
    if (as.integer(year_end_window) == 0L) " (MFCL normalizes zero to a one-point, unpooled endpoint)" else ""
  )
}

opr_control_text <- function(spec) {
  sprintf(
    "`155=%d`, `217=%d`, `216=%d`, `218=%d`; `202/203=%d/%d`; `210/211=%d/%d`; `212/213=%d/%d`; `214/215=%d/%d`.",
    spec$year_effect, spec$season_effect, spec$region_effect, spec$region_season_effect,
    spec$year_end_window, spec$year_end_degree,
    spec$region_end_window, spec$region_end_degree,
    spec$season_end_window, spec$season_end_degree,
    spec$region_season_end_window, spec$region_season_end_degree
  )
}

write_sensitivity_manifest <- function(target_step_dir, parent_step, spec) {
  manifest_path <- file.path(target_step_dir, "input_manifest.csv")
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
  note <- if (identical(spec$parameterization, "standard")) {
    paste0(
      "terminal standard-recruitment control changed from ", parent_step,
      "; parest_flag(400)=", spec$standard_terminal_periods,
      ", parest_flag(398)=", if (isTRUE(spec$standard_arithmetic_mean) && spec$standard_terminal_periods > 0L) 1L else 0L
    )
  } else {
    paste0("OPR terminal controls changed from ", parent_step, "; ", opr_control_text(spec))
  }
  manifest <- rbind(
    manifest,
    data.frame(
      role = "sensitivity_control",
      file = "doitall.sh",
      source = file.path("steps", parent_step, "model", "doitall.sh"),
      source_commit = "",
      note = note,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
  utils::write.csv(manifest, manifest_path, row.names = FALSE, quote = TRUE)
}

write_sensitivity_readme <- function(target_step_dir, spec) {
  is_standard <- identical(spec$parameterization, "standard")
  parent <- spec$parent_step
  hessian_parts <- terminal_sensitivity_hessian_nsplit()
  terminal_definition <- if (is_standard) {
    standard_terminal_text(spec$standard_terminal_periods, spec$standard_arithmetic_mean)
  } else {
    paste(opr_control_text(spec), opr_capacity_text(spec$year_end_window))
  }
  source_controls <- if (is_standard) {
    c(
      "MFCL `ongoing-dev` `recinpop_standard.cpp` applies `parest_flag(400)` to ordinary recruitment-deviation time periods.",
      "With `parest_flag(398)=1`, MFCL replaces fixed terminal recruitments with the arithmetic mean of earlier natural-scale recruitment.",
      "The current model has four recruitment periods per year, so this sensitivity expresses `400` in quarters."
    )
  } else {
    c(
      "MFCL `ongoing-dev` `get_orth_poly_info.cpp` and `get_orth_weights.cpp` define 155/217/216/218 as coefficient counts; the polynomial degree is count minus one.",
      "`202/203` control the annual terminal window and its retained low-order terms; 210/211, 212/213, and 214/215 are the corresponding regional, seasonal, and season-by-region controls.",
      "`neworth.cpp` rejects a coefficient count above the endpoint-constrained capacity, so 73 annual coefficients are used only with a one-point annual endpoint."
    )
  }
  lines <- c(
    paste0("# ", spec$title),
    "",
    "This is a terminal-recruitment sensitivity derived from the current main-branch parent model.",
    "All MFCL inputs except `model/doitall.sh` are byte-identical to the parent; the copied provenance is retained in `input_manifest.csv`.",
    "",
    "## Question",
    "",
    spec$rationale,
    "",
    "## Model definition",
    "",
    "| Field | Value |",
    "| --- | --- |",
    paste0("| Parent model | `", parent, "` |"),
    paste0("| Recruitment parameterisation | `", if (is_standard) "standard mean + deviations" else "orthogonal-polynomial recruitment (OPR)", "` |"),
    paste0("| Terminal treatment | ", terminal_definition, " |"),
    "| Data / structure held fixed | 1952-2024, 5 regions, 33 fisheries, time-varying index CPUE CV, regional-scaling prior, age-based selectivity |",
    "",
    "## Controls written in `doitall.sh`",
    "",
    if (is_standard) {
      c(
        "```text",
        sprintf("1 400 %d", spec$standard_terminal_periods),
        sprintf("1 398 %d", if (isTRUE(spec$standard_arithmetic_mean) && spec$standard_terminal_periods > 0L) 1L else 0L),
        "```"
      )
    } else {
      c(
        "```text",
        sprintf("1 155 %d   1 217 %d   1 216 %d   1 218 %d", spec$year_effect, spec$season_effect, spec$region_effect, spec$region_season_effect),
        sprintf("1 202 %d   1 203 %d   1 210 %d   1 211 %d", spec$year_end_window, spec$year_end_degree, spec$region_end_window, spec$region_end_degree),
        sprintf("1 212 %d   1 213 %d   1 214 %d   1 215 %d", spec$season_end_window, spec$season_end_degree, spec$region_season_end_window, spec$region_season_end_degree),
        "```"
      )
    },
    "",
    "The surrounding comments in `model/doitall.sh` state the active MFCL source semantics and the reason for every changed control.",
    "",
    "## Source interpretation",
    "",
    paste0("- ", source_controls),
    "",
    "## Kflow and Hessian",
    "",
    paste0(
      "Run this folder as one independent Kflow model job. The terminal-sensitivity launcher submits a ",
      hessian_parts, "-part Hessian job with this fit as its input dependency, then submits the Hessian merge job. ",
      "The existing BET results task receives this merge bundle for one-session MFCL Shiny review, preserving its PDH/non-PDH result or explicit incomplete/failure reason. ",
      "`TRIGGER_NEXT=false` is intentional: this grid should not spawn one report chain per sensitivity model."
    ),
    "",
    "## Decision rule",
    "",
    "Compare convergence, objective components, terminal recruitment plausibility, population scale/depletion, and the Hessian result together. Do not select a model solely because it has the smallest objective value."
  )
  writeLines(lines, file.path(target_step_dir, "README.md"), useBytes = TRUE)
}

validate_sensitivity_doitall <- function(model_path, spec) {
  lines <- readLines(model_path, warn = FALSE)
  if (identical(spec$parameterization, "standard")) {
    expected_400 <- as.integer(spec$standard_terminal_periods)
    expected_398 <- if (isTRUE(spec$standard_arithmetic_mean) && expected_400 > 0L) 1L else 0L
    if (!identical(initial_flag_value(lines, 400L), expected_400) ||
        !identical(initial_flag_value(lines, 398L), expected_398)) {
      stop("Standard terminal controls do not match the specification for ", spec$step_id, call. = FALSE)
    }
  } else {
    expected <- c(
      "155" = spec$year_effect,
      "217" = spec$season_effect,
      "216" = spec$region_effect,
      "218" = spec$region_season_effect,
      "202" = spec$year_end_window,
      "203" = spec$year_end_degree,
      "210" = spec$region_end_window,
      "211" = spec$region_end_degree,
      "212" = spec$season_end_window,
      "213" = spec$season_end_degree,
      "214" = spec$region_season_end_window,
      "215" = spec$region_season_end_degree,
      "149" = 0L,
      "398" = 0L,
      "400" = 0L
    )
    got <- vapply(as.integer(names(expected)), function(flag) phase3_flag_value(lines, flag), integer(1))
    if (!identical(unname(got), as.integer(expected))) {
      stop("OPR controls do not match the specification for ", spec$step_id, call. = FALSE)
    }
  }
  shell_check(model_path)
  invisible(TRUE)
}

specs <- terminal_sensitivity_model_spec()
for (i in seq_len(nrow(specs))) {
  spec <- specs[i, , drop = FALSE]
  parent_step <- spec$parent_step[[1L]]
  target_step <- spec$step_id[[1L]]
  parent_dir <- file.path(root, "steps", parent_step)
  target_dir <- file.path(root, "steps", target_step)
  copy_tree(parent_dir, target_dir, overwrite = overwrite)
  parent_model <- file.path(parent_dir, "model")
  target_model <- file.path(target_dir, "model")
  target_doitall <- file.path(target_model, "doitall.sh")

  if (identical(spec$parameterization[[1L]], "standard")) {
    write_standard_terminal_sensitivity_doitall(
      file.path(parent_model, "doitall.sh"),
      target_doitall,
      terminal_periods = spec$standard_terminal_periods[[1L]],
      arithmetic_mean = spec$standard_arithmetic_mean[[1L]]
    )
  } else {
    write_opr_terminal_sensitivity_doitall(
      file.path(parent_model, "doitall.sh"),
      target_doitall,
      year_effect = spec$year_effect[[1L]],
      season_effect = spec$season_effect[[1L]],
      region_effect = spec$region_effect[[1L]],
      region_season_effect = spec$region_season_effect[[1L]],
      year_end_window = spec$year_end_window[[1L]],
      year_end_degree = spec$year_end_degree[[1L]],
      region_end_window = spec$region_end_window[[1L]],
      region_end_degree = spec$region_end_degree[[1L]],
      season_end_window = spec$season_end_window[[1L]],
      season_end_degree = spec$season_end_degree[[1L]],
      region_season_end_window = spec$region_season_end_window[[1L]],
      region_season_end_degree = spec$region_season_end_degree[[1L]],
      label = spec$title[[1L]]
    )
  }

  verify_inherited_inputs(parent_model, target_model)
  validate_sensitivity_doitall(target_doitall, spec)
  write_sensitivity_manifest(target_dir, parent_step, spec)
  write_sensitivity_readme(target_dir, spec)
  message("prepared ", target_step)
}

message("Prepared ", nrow(specs), " terminal-recruitment sensitivity model folders.")
