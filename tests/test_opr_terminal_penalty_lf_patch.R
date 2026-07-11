#!/usr/bin/env Rscript

## Base-R integration checks for the generated Step 11/12 sensitivity inputs.
## Set MFCL_SMOKE_PROGRAM to a 2.2.7.9 executable to add representative
## -makepar compatibility checks; the structural checks always run.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
if (length(file_arg) != 1L) stop("Run this test with Rscript.", call. = FALSE)
root <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."), winslash = "/", mustWork = TRUE)

source(file.path(root, "R", "step12_opr_terminal_penalty_lf_config.R"))
source(file.path(root, "R", "apply_opr_terminal_penalty_lf_patch.R"))

assert_true <- function(value, message) {
  if (length(value) != 1L || is.na(value) || !isTRUE(value)) stop(message, call. = FALSE)
}

assert_identical <- function(actual, expected, message) {
  if (!identical(actual, expected)) {
    stop(
      message, "\nExpected: ", paste(capture.output(str(expected)), collapse = " "),
      "\nActual:   ", paste(capture.output(str(actual)), collapse = " "),
      call. = FALSE
    )
  }
}

## The compact fit must retain the patched restart case rather than copying
## the unmodified thin-step parent or every large MFCL output.
runner_expressions <- parse(file.path(root, "R", "run_stepwise.R"))
copy_expression <- Filter(function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("<-")) &&
    identical(expr[[2L]], as.name("copy_raw_mfcl_inputs"))
}, as.list(runner_expressions))
assert_true(length(copy_expression) == 1L, "Could not isolate copy_raw_mfcl_inputs from the runner")
copy_environment <- new.env(parent = baseenv())
eval(copy_expression[[1L]], envir = copy_environment)
restart_test <- tempfile("opr-restart-copy-")
dir.create(restart_test)
on.exit(unlink(restart_test, recursive = TRUE, force = TRUE), add = TRUE)
restart_source <- file.path(restart_test, "source")
restart_work <- file.path(restart_test, "work")
restart_output <- file.path(restart_test, "output")
dir.create(restart_source)
dir.create(restart_work)
restart_names <- c("bet.frq", "bet.ini", "bet.tag", "doitall.sh")
for (name in restart_names) {
  writeLines(paste("parent", name), file.path(restart_source, name))
  writeLines(paste("patched", name), file.path(restart_work, name))
}
writeLines("fitted output", file.path(restart_work, "12.par"))
writeLines("large report", file.path(restart_work, "plot.rep"))
assert_true(
  copy_environment$copy_raw_mfcl_inputs(
    restart_work,
    restart_output,
    source_manifest_dir = restart_source
  ),
  "Patched restart-input copy failed"
)
assert_identical(sort(list.files(restart_output)), sort(restart_names), "Restart output included missing or fitted-output files")
assert_true(
  all(vapply(restart_names, function(name) {
    identical(readLines(file.path(restart_output, name)), paste("patched", name))
  }, logical(1L))),
  "Restart output copied the unmodified parent instead of patched inputs"
)

copy_model <- function(source_dir, target_dir) {
  dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
  files <- list.files(source_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  copied <- file.copy(files, target_dir, recursive = TRUE, copy.mode = TRUE, copy.date = TRUE)
  assert_true(length(copied) == length(files) && all(copied), paste("Could not stage", source_dir))
}

first_data_words <- function(path) {
  lines <- readLines(path, warn = FALSE)
  index <- which(nzchar(trimws(lines)) & !grepl("^#", trimws(lines)))[[1L]]
  patch_words(lines[[index]])
}

ini_matrix <- function(path, marker) {
  lines <- readLines(path, warn = FALSE)
  index <- patch_ini_section_rows(lines, marker)
  values <- lapply(lines[index], patch_words)
  assert_true(length(unique(lengths(values))) == 1L, paste("Uneven INI matrix at", marker))
  matrix(unlist(values, use.names = FALSE), nrow = length(values), byrow = TRUE)
}

load_tag_map <- function(path) {
  environment <- new.env(parent = baseenv())
  sys.source(path, envir = environment)
  environment
}

validate_provenance <- function(model_dir, step_id) {
  hashes <- read.csv(file.path(model_dir, "sensitivity-input-hashes.csv"), stringsAsFactors = FALSE)
  spec_row <- read.csv(file.path(model_dir, "sensitivity-spec.csv"), stringsAsFactors = FALSE, check.names = FALSE)
  assert_identical(as.character(spec_row$step_id), step_id, paste("Wrong specification row for", step_id))
  assert_true(!anyDuplicated(hashes$file), paste("Duplicate provenance file for", step_id))
  paths <- file.path(model_dir, hashes$file)
  assert_true(all(file.exists(paths)), paste("Missing provenance input for", step_id))
  assert_identical(as.character(hashes$md5), unname(tools::md5sum(paths)), paste("Stale provenance hash for", step_id))
  paste(hashes$md5[order(hashes$file)], collapse = ":")
}

validate_restart_copy <- function(model_dir, source_dir, target_dir, row) {
  assert_true(
    copy_environment$copy_raw_mfcl_inputs(
      model_dir,
      target_dir,
      source_manifest_dir = source_dir
    ),
    paste("Could not save patched restart inputs for", row$step_id)
  )
  source_names <- basename(list.files(source_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE))
  source_names <- source_names[!grepl("[.]par[0-9]*$", source_names)]
  assert_identical(sort(list.files(target_dir)), sort(source_names), paste("Restart-input file set mismatch for", row$step_id))
  expected <- file.path(model_dir, source_names)
  actual <- file.path(target_dir, source_names)
  assert_identical(unname(tools::md5sum(actual)), unname(tools::md5sum(expected)), paste("Restart inputs are not the patched model files for", row$step_id))
  if (row$tag_deletion != "none") {
    changed <- tools::md5sum(file.path(target_dir, c("bet.frq", "bet.ini", "bet.tag"))) !=
      tools::md5sum(file.path(source_dir, c("bet.frq", "bet.ini", "bet.tag")))
    assert_true(all(changed), paste("Deletion restart inputs did not preserve all FRQ/INI/TAG edits for", row$step_id))
  }
  if (row$rr_2021_scope != "shared") {
    assert_true(
      tools::md5sum(file.path(target_dir, "bet.ini")) != tools::md5sum(file.path(source_dir, "bet.ini")),
      paste("Reporting-rate restart INI reverted to parent for", row$step_id)
    )
  }
}

validate_tag_synchronisation <- function(model_dir, row, parent_release_map) {
  expected_groups <- switch(
    row$tag_deletion,
    none = 98L,
    group18 = 97L,
    group60 = 97L,
    both = 96L,
    stop("Unknown tag-deletion mode in test: ", row$tag_deletion, call. = FALSE)
  )

  tag_lines <- readLines(file.path(model_dir, "bet.tag"), warn = FALSE)
  tag_blocks <- grep("^#[[:space:]]*[0-9]+[[:space:]]*-[[:space:]]*RELEASE REGION", tag_lines)
  assert_true(length(tag_blocks) == expected_groups, paste("TAG block count mismatch for", row$step_id))
  assert_true(as.integer(first_data_words(file.path(model_dir, "bet.tag"))[[1L]]) == expected_groups, paste("TAG header mismatch for", row$step_id))
  recovery_marker <- grep("^#[[:space:]]*TAG RECOVERIES", tag_lines)
  recovery_data <- which(
    seq_along(tag_lines) > recovery_marker & seq_along(tag_lines) < tag_blocks[[1L]] &
      nzchar(trimws(tag_lines)) & !grepl("^#", trimws(tag_lines))
  )
  assert_true(length(recovery_data) == 1L, paste("TAG recovery vector missing for", row$step_id))
  assert_true(length(patch_words(tag_lines[[recovery_data]])) == expected_groups, paste("TAG recovery vector mismatch for", row$step_id))

  frq_words <- first_data_words(file.path(model_dir, "bet.frq"))
  assert_true(as.integer(frq_words[[4L]]) == expected_groups, paste("FRQ tag count mismatch for", row$step_id))

  ini <- file.path(model_dir, "bet.ini")
  tag_flags <- ini_matrix(ini, "# tag flags")
  assert_identical(dim(tag_flags), c(expected_groups, 10L), paste("INI tag flags mismatch for", row$step_id))
  tag_shed <- unlist(lapply(readLines(ini, warn = FALSE)[patch_ini_section_rows(readLines(ini, warn = FALSE), "# tag shed rate")], patch_words), use.names = FALSE)
  assert_true(length(tag_shed) == expected_groups, paste("INI tag shed count mismatch for", row$step_id))

  matrix_markers <- c(
    "# tag fish rep", "# tag fish rep group flags", "# tag_fish_rep active flags",
    "# tag_fish_rep target", "# tag_fish_rep penalty"
  )
  matrices <- lapply(matrix_markers, function(marker) ini_matrix(ini, marker))
  names(matrices) <- matrix_markers
  for (marker in matrix_markers) {
    assert_identical(dim(matrices[[marker]]), c(expected_groups + 1L, 33L), paste("INI reporting matrix mismatch at", marker, "for", row$step_id))
  }

  map <- load_tag_map(file.path(model_dir, "tag_rep_map.R"))
  assert_identical(dim(map$tag_rep_matrix), c(expected_groups + 1L, 33L), paste("tag_rep_matrix dimensions mismatch for", row$step_id))
  assert_identical(dim(map$tag_rep_active_matrix), c(expected_groups + 1L, 33L), paste("tag_rep_active_matrix dimensions mismatch for", row$step_id))
  assert_identical(unname(matrix(as.integer(map$tag_rep_matrix), nrow = expected_groups + 1L)), unname(matrix(as.integer(matrices[["# tag fish rep group flags"]]), nrow = expected_groups + 1L)), paste("tag_rep_matrix is stale for", row$step_id))
  assert_identical(unname(matrix(as.integer(map$tag_rep_active_matrix), nrow = expected_groups + 1L)), unname(matrix(as.integer(matrices[["# tag_fish_rep active flags"]]), nrow = expected_groups + 1L)), paste("tag_rep_active_matrix is stale for", row$step_id))
  assert_true(nrow(map$tag_release_map) == expected_groups, paste("tag_release_map count mismatch for", row$step_id))
  assert_true(nrow(map$tag_event_map) == expected_groups + 1L, paste("tag_event_map count mismatch for", row$step_id))
  assert_identical(as.integer(map$tag_release_map$release_group), seq_len(expected_groups), paste("tag_release_map numbering mismatch for", row$step_id))
  assert_identical(as.integer(map$tag_event_map$release_group), c(seq_len(expected_groups), NA_integer_), paste("tag_event_map numbering mismatch for", row$step_id))

  drop_groups <- switch(row$tag_deletion, none = integer(), group18 = 18L, group60 = 60L, both = c(18L, 60L))
  expected_release_map <- parent_release_map[setdiff(seq_len(nrow(parent_release_map)), drop_groups), setdiff(names(parent_release_map), "release_group"), drop = FALSE]
  actual_release_map <- map$tag_release_map[, setdiff(names(map$tag_release_map), "release_group"), drop = FALSE]
  rownames(expected_release_map) <- NULL
  rownames(actual_release_map) <- NULL
  assert_identical(actual_release_map, expected_release_map, paste("Wrong release identity removed for", row$step_id))

  groups <- matrices[["# tag fish rep group flags"]]
  expected_max_group <- if (row$rr_2021_scope == "shared") 29L else 30L
  assert_true(max(as.integer(groups)) == expected_max_group, paste("Reporting-rate group mismatch for", row$step_id))
  assert_true(nrow(map$tag_rep_map) == expected_max_group, paste("tag_rep_map group summary mismatch for", row$step_id))
  if (row$rr_2021_scope != "shared") {
    rr_rows <- switch(row$rr_2021_scope, campaign = c(18L, 60L), group60 = 60L)
    assert_true(all(groups[rr_rows, 25:28, drop = FALSE] == "30"), paste("2021 reporting-rate split missing for", row$step_id))
    if (row$rr_2021_scope == "group60") {
      assert_true(all(groups[18L, 25:28] == "17"), paste("Group-60-only split changed release 18 for", row$step_id))
    }
    expected_cells <- list(
      `# tag fish rep` = row$rr_2021_target,
      `# tag_fish_rep active flags` = 1,
      `# tag_fish_rep target` = 100 * row$rr_2021_target,
      `# tag_fish_rep penalty` = row$rr_2021_penalty
    )
    for (marker in names(expected_cells)) {
      actual <- as.numeric(matrices[[marker]][rr_rows, 25:28, drop = FALSE])
      assert_true(
        all(abs(actual - expected_cells[[marker]]) < 1e-8),
        paste("2021 reporting-rate control mismatch at", marker, "for", row$step_id)
      )
    }
  }

  if (row$tag_rr_mixing_mode == "2021") assert_true(all(tag_flags[c(18L, 60L), 2L] == "1"), paste("2021 mixing flags missing for", row$step_id))
  if (row$tag_rr_mixing_mode == "group60") assert_true(tag_flags[60L, 2L] == "1", paste("Group-60 mixing flag missing for", row$step_id))
  if (row$tag_rr_mixing_mode == "all") assert_true(all(tag_flags[, 2L] == "1"), paste("All-release mixing flags missing for", row$step_id))
  if (!is.na(row$tag_2021_mixing_period)) assert_true(as.integer(tag_flags[60L, 1L]) == row$tag_2021_mixing_period, paste("Group-60 mixing period mismatch for", row$step_id))
  if (row$tag_loss_mode == "all") assert_true(all(abs(as.numeric(tag_shed) - row$tag_loss_rate) < 1e-12), paste("Tag-loss vector mismatch for", row$step_id))
}

validate_doitall <- function(model_dir, row) {
  lines <- readLines(file.path(model_dir, "doitall.sh"), warn = FALSE)
  text <- paste(lines, collapse = "\n")
  assert_true(grepl(sprintf("  1 177 %d  # tag likelihood scalar", row$tag_weight_flag), text, fixed = TRUE), paste("Tag weight flag missing for", row$step_id))
  assert_true(grepl(sprintf("  1 249 %d  # recaptures-conditioned", as.integer(row$tag_likelihood == "recaptures_conditioned")), text, fixed = TRUE), paste("Conditional-tag flag mismatch for", row$step_id))
  expected_likelihood <- switch(row$tag_likelihood, negative_binomial = 4L, recaptures_conditioned = 4L, binned_gamma = 5L, robust_binned_gamma = 6L)
  assert_true(grepl(sprintf("  1 111 %d  # tag observation likelihood", expected_likelihood), text, fixed = TRUE), paste("Tag likelihood flag mismatch for", row$step_id))
  if (isTRUE(row$estimate_tag_dispersion)) {
    expected_parameterisation <- if (row$tag_likelihood %in% c("negative_binomial", "recaptures_conditioned")) 1L else 0L
    assert_true(
      grepl(sprintf("  1 305 %d", expected_parameterisation), text, fixed = TRUE),
      paste("Tag-dispersion parameterisation mismatch for", row$step_id)
    )
    assert_true(
      grepl("  -999 43 1 -999 44 1", text, fixed = TRUE),
      paste("Pooled tag-dispersion flags missing for", row$step_id)
    )
  }
  if (row$length_comp_divisor > 0L) {
    assert_true(
      grepl(
        sprintf("  -999 49 %d  # divide every LF effective sample size", row$length_comp_divisor),
        text,
        fixed = TRUE
      ),
      paste("Uniform LF divisor missing for", row$step_id)
    )
  }
  generated_parts <- strsplit(
    text,
    "# Generated sensitivity overrides (last setting wins in PHASE 1)",
    fixed = TRUE
  )[[1L]]
  assert_true(length(generated_parts) == 2L, paste("Generated override block missing for", row$step_id))
  generated_overrides <- generated_parts[[2L]]
  assert_true(
    !grepl("-999 50", generated_overrides, fixed = TRUE),
    paste("Generated LF sensitivity also changed weight-composition divisors for", row$step_id)
  )
  if (row$fish_profile == "group_consistent") {
    assert_true(
      grepl("-27 16 0  -27 3 37", generated_overrides, fixed = TRUE) &&
        grepl("-18 16 2  -18 3 6", generated_overrides, fixed = TRUE),
      paste("Shared-selectivity partner controls missing for", row$step_id)
    )
  }
  if (row$fish_profile == "review_exact") {
    assert_true(
      grepl("-20 16 0  -20 3 37", generated_overrides, fixed = TRUE) &&
        grepl("-17 16 2  -17 3 6", generated_overrides, fixed = TRUE) &&
        !grepl("-27 16 0  -27 3 37", generated_overrides, fixed = TRUE) &&
        !grepl("-18 16 2  -18 3 6", generated_overrides, fixed = TRUE),
      paste("Exact-five-fishery grouping diagnostic mismatch for", row$step_id)
    )
  }
  if (row$parameterization == "opr") {
    assert_true(sum(trimws(lines) == "PHASE12") == 1L, paste("PHASE12 count mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 155 %d  # annual OPR coefficient count", row$opr_year_coefficients), text, fixed = TRUE), paste("Annual OPR count mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 221 %d  # legacy annual OPR override", row$opr_legacy_year_override), text, fixed = TRUE), paste("Legacy annual OPR override mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 217 %d  # seasonal OPR coefficient count", row$opr_season_coefficients), text, fixed = TRUE), paste("Seasonal OPR count mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 216 %d  # regional OPR coefficient count", row$opr_region_coefficients), text, fixed = TRUE), paste("Regional OPR count mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 218 %d  # season-by-region OPR coefficient count", row$opr_interaction_coefficients), text, fixed = TRUE), paste("Interaction OPR count mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 397 %d  # terminal-recruitment penalty", row$terminal_penalty_flag), text, fixed = TRUE), paste("Terminal penalty mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 202 %d  # terminal window", row$terminal_years), text, fixed = TRUE), paste("Terminal window mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 210 %d  # regional endpoint", row$component_terminal_years), text, fixed = TRUE), paste("Component terminal window mismatch for", row$step_id))
    assert_true(grepl(sprintf("  1 153 %d  # OPR trend penalty", row$trend_flag), text, fixed = TRUE), paste("Trend flag mismatch for", row$step_id))
  } else {
    assert_true(!any(trimws(lines) == "PHASE12"), paste("Unexpected PHASE12 for", row$step_id))
    assert_true(grepl(sprintf("  1 400 %d  # fixed terminal", row$standard_terminal_quarters), text, fixed = TRUE), paste("Standard terminal window mismatch for", row$step_id))
  }
}

## The overwrite cleanup may remove only recognised immediate generated dirs.
cleanup_root <- tempfile("opr-cleanup-")
dir.create(cleanup_root)
on.exit(unlink(cleanup_root, recursive = TRUE, force = TRUE), add = TRUE)
make_dir <- function(name, marker = NULL, patch = NULL) {
  path <- file.path(cleanup_root, name)
  dir.create(path)
  if (!is.null(marker)) writeLines(marker, file.path(path, opr_terminal_penalty_lf_generator_marker()))
  if (!is.null(patch)) writeLines(patch, file.path(path, "patch.R"))
  path
}
marked <- make_dir("12p999-Stale", "opr-terminal-penalty-lf-generator-v1")
legacy <- make_dir("11p998-Legacy", patch = c(
  "## Generated thin patch: the parent model is staged before this file runs.",
  "source(file.path(root, \"R\", \"apply_opr_terminal_penalty_lf_patch.R\"), local = TRUE)",
  "apply_opr_terminal_penalty_lf_patch(model_dir, step_id, root = root)"
))
manual <- make_dir("12p997-Manual", patch = "# manually maintained")
wrong_marker <- make_dir("12p996-WrongMarker", "unrecognised-generator")
outside_namespace <- make_dir("13p999-Other", "opr-terminal-penalty-lf-generator-v1")
removed <- sort(opr_terminal_penalty_lf_cleanup_generated_steps(cleanup_root))
assert_identical(removed, sort(c(basename(marked), basename(legacy))), "Cleanup removed the wrong folders")
assert_true(all(dir.exists(c(manual, wrong_marker, outside_namespace))), "Cleanup touched an unrecognised folder")

spec <- opr_terminal_penalty_lf_model_spec()
assert_true(nrow(spec) == 73L, "Expected 73 generated sensitivities")
assert_true(length(opr_terminal_penalty_lf_run_step_ids()) == 74L, "Expected 74 total fit models")
assert_true(opr_terminal_penalty_lf_hessian_nsplit() == 1L, "Expected unpartitioned Hessian jobs above 50 models")
expected_families <- c(
  `annual-count-penalty` = 15L,
  `endpoint-free-control` = 3L,
  `length-composition-weight` = 6L,
  `length-selectivity` = 9L,
  `longer-terminal-window` = 9L,
  `standard-recruitment-control` = 5L,
  `supplied-opr221-check` = 2L,
  `supplied-benchmark` = 1L,
  `tagging-diagnostic` = 21L,
  `trend-penalty` = 2L
)
actual_families <- table(spec$family)
actual_families <- setNames(as.integer(actual_families[names(expected_families)]), names(expected_families))
assert_identical(actual_families, expected_families, "Sensitivity family counts changed")

generated_dirs <- file.path(root, "steps", spec$step_id)
assert_true(all(vapply(generated_dirs, opr_terminal_penalty_lf_generated_step_dir, logical(1L))), "A generated step is missing its trusted generator marker")
grid <- read.csv(file.path(root, "docs", "opr-terminal-penalty-lf-sensitivity-grid.csv"), stringsAsFactors = FALSE, check.names = FALSE)
assert_identical(as.character(grid$step_id), as.character(spec$step_id), "Generated grid and model specification differ")

parent_map <- load_tag_map(file.path(root, "steps", "12-OrthogonalPoly", "model", "tag_rep_map.R"))$tag_release_map
parent_inputs <- unlist(lapply(
  unique(spec$parent_step),
  function(parent) file.path(root, "steps", parent, "model", c("bet.frq", "bet.ini", "bet.tag", "doitall.sh", "tag_rep_map.R"))
), use.names = FALSE)
parent_hashes_before <- tools::md5sum(parent_inputs)

mfcl_program <- Sys.getenv("MFCL_SMOKE_PROGRAM", unset = "")
makepar_ids <- character()
if (nzchar(mfcl_program)) {
  mfcl_program <- normalizePath(mfcl_program, winslash = "/", mustWork = TRUE)
  expected_sha <- Sys.getenv("MFCL_EXPECTED_SHA256", unset = "02e12dbdf2a564983e9fb50baf095ff472ba3831f71ecc0e3082f49478dac723")
  sha_output <- system2("sha256sum", mfcl_program, stdout = TRUE)
  actual_sha <- strsplit(sha_output[[1L]], "[[:space:]]+")[[1L]][[1L]]
  assert_identical(actual_sha, expected_sha, "MFCL smoke executable is not the recorded 2.2.7.9 binary")
  select_first <- function(condition) spec$step_id[which(condition)[[1L]]]
  makepar_ids <- unique(c(
    vapply(c(71L, 72L, 73L), function(value) select_first(spec$parameterization == "opr" & spec$opr_year_coefficients == value & !spec$benchmark_protocol), character(1L)),
    vapply(c(0L, 1L, 2L, 3L), function(value) select_first(spec$parameterization == "opr" & spec$terminal_years == value & !spec$benchmark_protocol), character(1L)),
    select_first(spec$benchmark_protocol),
    vapply(
      c(0L, 71L),
      function(value) select_first(spec$family == "supplied-opr221-check" & spec$opr_legacy_year_override == value),
      character(1L)
    ),
    select_first(spec$tag_deletion == "group60"),
    select_first(spec$tag_deletion == "both"),
    vapply(c("campaign", "group60"), function(value) select_first(spec$rr_2021_scope == value), character(1L)),
    select_first(spec$rr_2021_scope == "campaign" & spec$tag_rr_mixing_mode == "all"),
    vapply(c(40L, 80L), function(value) select_first(spec$length_comp_divisor == value), character(1L)),
    vapply(c("group60", "all"), function(value) select_first(spec$tag_rr_mixing_mode == value), character(1L)),
    vapply(c("recaptures_conditioned", "robust_binned_gamma"), function(value) select_first(spec$tag_likelihood == value), character(1L)),
    select_first(spec$estimate_tag_dispersion & spec$tag_likelihood == "negative_binomial"),
    select_first(
      spec$parameterization == "standard" & spec$standard_terminal_quarters == 0L &
        spec$tag_deletion == "none" & spec$tag_weight_flag == 0L
    ),
    select_first(spec$parameterization == "standard" & spec$tag_deletion == "group60")
  ))
}

work <- tempfile("opr-patch-all-")
dir.create(work)
on.exit(unlink(work, recursive = TRUE, force = TRUE), add = TRUE)
signatures <- character(nrow(spec))
names(signatures) <- spec$step_id
makepar_checked <- character()

for (i in seq_len(nrow(spec))) {
  row <- spec[i, , drop = FALSE]
  model_dir <- file.path(work, row$step_id)
  source_dir <- file.path(root, "steps", row$parent_step, "model")
  copy_model(source_dir, model_dir)
  apply_opr_terminal_penalty_lf_patch(model_dir, row$step_id, root = root)
  validate_doitall(model_dir, row)
  validate_tag_synchronisation(model_dir, row, parent_map)
  signatures[[row$step_id]] <- validate_provenance(model_dir, row$step_id)

  if (row$step_id %in% makepar_ids) {
    restart_dir <- file.path(work, "restart-inputs", row$step_id)
    validate_restart_copy(model_dir, source_dir, restart_dir, row)
    log <- file.path(model_dir, "makepar.log")
    old_wd <- setwd(model_dir)
    status <- tryCatch(
      system2(mfcl_program, c("bet.frq", "bet.ini", "00.par", "-makepar"), stdout = log, stderr = log),
      finally = setwd(old_wd)
    )
    assert_true(identical(status, 0L), paste("MFCL -makepar failed for", row$step_id, "(see", log, ")"))
    par <- file.path(model_dir, "00.par")
    assert_true(file.exists(par) && file.info(par)$size > 0, paste("MFCL did not create 00.par for", row$step_id))
    makepar_checked <- c(makepar_checked, row$step_id)
    unlink(restart_dir, recursive = TRUE, force = TRUE)
  }

  unlink(model_dir, recursive = TRUE, force = TRUE)
}

assert_true(!anyDuplicated(signatures), "Two sensitivity specifications produced identical hashed inputs")
assert_identical(unname(tools::md5sum(parent_inputs)), unname(parent_hashes_before), "A parent Step 11/12 input was modified")
if (nzchar(mfcl_program)) {
  assert_identical(sort(makepar_checked), sort(makepar_ids), "Not all representative MFCL -makepar checks ran")
  message("MFCL 2.2.7.9 -makepar passed for ", length(makepar_checked), " representative variants: ", paste(makepar_checked, collapse = ", "))
} else {
  message("MFCL -makepar checks skipped; set MFCL_SMOKE_PROGRAM to the 2.2.7.9 executable to enable them.")
}

message("Validated all ", nrow(spec), " generated sensitivity patches, synchronized tag structures/maps, hashes, and unique input signatures.")
