#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
baseline_path <- file.path(
  root, "steps", "S03-CommonTagTau-MIX015", "model", "bet.ini"
)
grid_path <- file.path(root, "config", "sc22-ip10-mixing-period-grid.csv")
config_path <- file.path(root, "job-config-mixing-period-sensitivity.R")
patch_path <- file.path(root, "R", "apply_mixing_period_sensitivity.R")
task_path <- file.path(root, "kflow-mixing-period-sensitivity.yaml")
doitall_path <- file.path(
  root, "steps", "S03-CommonTagTau-MIX015", "model", "doitall.sh"
)
tau_template_path <- file.path(root, "templates", "common-tag-tau-tail.sh")
expected_baseline_sha256 <- "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a"
expected_doitall_sha256 <- "f81e2d7ec11297c7279f89e0be67fc07b5baa4fcbe4ce42371990a33a4eede53"
expected_tau_template_sha256 <- "d9b9955fafc2643e905c8ab8c03fb28bc45f86d9d5ccd7a9a752c942e07f6ab2"

fail <- function(...) stop(..., call. = FALSE)

sha256_file <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) fail("sha256sum failed for ", path)
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

section_bounds <- function(lines, label) {
  marker <- which(tolower(trimws(lines)) == paste0("# ", tolower(label)))
  if (length(marker) != 1L) fail("Expected one # ", label, " section.")
  following <- which(seq_along(lines) > marker & grepl("^#", trimws(lines)))
  end <- if (length(following)) following[[1L]] - 1L else length(lines)
  c(start = marker + 1L, end = end)
}

numeric_section <- function(lines, label) {
  bounds <- section_bounds(lines, label)
  block <- trimws(lines[seq.int(bounds[["start"]], bounds[["end"]])])
  block <- block[nzchar(block)]
  rows <- lapply(block, function(line) {
    suppressWarnings(as.numeric(strsplit(line, "[[:space:]]+")[[1L]]))
  })
  if (!length(rows) || length(unique(lengths(rows))) != 1L ||
      any(!vapply(rows, function(row) all(is.finite(row)), logical(1)))) {
    fail("Invalid numeric # ", label, " section.")
  }
  do.call(rbind, rows)
}

tag_flag_rows <- function(lines) {
  bounds <- section_bounds(lines, "tag flags")
  rows <- seq.int(bounds[["start"]], bounds[["end"]])
  rows[nzchar(trimws(lines[rows]))]
}

parse_tag_flags <- function(lines) {
  rows <- tag_flag_rows(lines)
  values <- lapply(rows, function(index) {
    suppressWarnings(as.numeric(strsplit(trimws(lines[[index]]), "[[:space:]]+")[[1L]]))
  })
  if (!length(values) || length(unique(lengths(values))) != 1L) {
    fail("Invalid tag-flags matrix.")
  }
  do.call(rbind, values)
}

required <- c(
  baseline_path, grid_path, config_path, patch_path, task_path,
  doitall_path, tau_template_path
)
missing <- required[!file.exists(required)]
if (length(missing)) fail("Missing sensitivity files: ", paste(missing, collapse = ", "))
if (!identical(sha256_file(baseline_path), expected_baseline_sha256)) {
  fail("Baseline bet.ini is not the exact Job 16594 input.")
}
if (!identical(sha256_file(doitall_path), expected_doitall_sha256)) {
  fail("S03 doitall.sh is not the tau-off implementation verified by Job 16699.")
}
if (!identical(sha256_file(tau_template_path), expected_tau_template_sha256)) {
  fail("Common-tau template differs from the tau-off implementation verified by Job 16699.")
}

baseline_lines <- readLines(baseline_path, warn = FALSE)
baseline_flags <- parse_tag_flags(baseline_lines)
baseline_rows <- tag_flag_rows(baseline_lines)
if (!identical(dim(baseline_flags), c(98L, 10L))) {
  fail("Job 16594 tag flags must be 98x10.")
}

natural_mortality <- as.numeric(numeric_section(
  baseline_lines, "natural mortality (per year)"
))
if (!isTRUE(all.equal(natural_mortality, 0.112362446639794, tolerance = 0))) {
  fail("Job 16594 natural-mortality scalar drifted.")
}
age_pars <- numeric_section(baseline_lines, "age_pars")
if (!isTRUE(all.equal(age_pars[5L, 1L], -2.54930339768360, tolerance = 0))) {
  fail("Job 16594 fixed-M age parameter drifted.")
}
length_weight <- as.numeric(numeric_section(baseline_lines, "Length-weight parameters"))
if (!isTRUE(all.equal(
  length_weight,
  c(3.073533e-05, 2.932410),
  tolerance = 0
))) {
  fail("Job 16594 length-weight parameters drifted.")
}

rr_sections <- c(
  "tag fish rep",
  "tag fish rep group flags",
  "tag_fish_rep active flags",
  "tag_fish_rep target",
  "tag_fish_rep penalty"
)
baseline_rr <- lapply(rr_sections, function(label) numeric_section(baseline_lines, label))
names(baseline_rr) <- rr_sections

grid <- read.csv(grid_path, check.names = FALSE, stringsAsFactors = FALSE)
expected_columns <- c(
  "release_group", "K005", "K010", "K015", "K020",
  "K025", "K030", "K035", "K040", "K045"
)
if (!identical(names(grid), expected_columns)) fail("Mixing grid columns are incorrect.")
if (!identical(grid$release_group, 1:98)) fail("Mixing grid release groups are incorrect.")
if (any(!as.matrix(grid[-1L]) %in% 0:4)) fail("Mixing grid values must be integers 0-4.")
if (!identical(as.integer(grid$K015), as.integer(baseline_flags[, 1L]))) {
  fail("K=0.15 does not reproduce Job 16594 tag_flags(:,1).")
}

config_env <- new.env(parent = baseenv())
sys.source(config_path, envir = config_env)
models <- get("stepwise_models", envir = config_env)
if (!is.data.frame(models) || nrow(models) != 40L) fail("Expected exactly 40 model rows.")
if (anyDuplicated(models$step_id) || anyDuplicated(models$job_key)) {
  fail("Sensitivity step IDs and job keys must be unique.")
}
if (!identical(as.integer(models$plot_order), 1:40) ||
    !identical(
      substr(models$model_label, 1L, 3L),
      sprintf("%02d.", 1:40)
    ) ||
    !identical(
      substr(models$job_key, 1L, 6L),
      sprintf("mix-%02d", 1:40)
    )) {
  fail("Model labels and job keys must retain the fixed 01-40 plotting order.")
}
if (!identical(sort(unique(models$mixing_key)), sort(c(expected_columns[-1L], "ALL2")))) {
  fail("Sensitivity grid must contain nine SC22 K vectors plus ALL2.")
}
if (!identical(models$tag_tau_grouping[1:20], rep("common", 20L)) ||
    !identical(models$tag_tau_grouping[21:40], rep("off", 20L))) {
  fail("Rows 1-20 must estimate common tau and rows 21-40 must not estimate tau.")
}
if (any(grepl("-TAUOFF$", models$step_id[1:20])) ||
    any(!grepl("-TAUOFF$", models$step_id[21:40]))) {
  fail("Only tau-off rows 21-40 may use the -TAUOFF step suffix.")
}
design_counts <- table(
  models$mixing_key,
  models$tag_flags_it2,
  models$tag_tau_grouping
)
if (!identical(dim(design_counts), c(10L, 2L, 2L)) || any(design_counts != 1L)) {
  fail(
    "Every mixing vector must have one tag-flag-2=0 and one tag-flag-2=1 row ",
    "under each tau treatment."
  )
}

summary_rows <- vector("list", nrow(models))
for (index in seq_len(nrow(models))) {
  row <- models[index, , drop = FALSE]
  step_dir <- file.path(root, "steps", row$step_id[[1L]])
  if (!file.exists(file.path(step_dir, "patch.R"))) {
    fail("Missing patch.R for ", row$step_id[[1L]])
  }
  if (!identical(row$source_dir[[1L]], "steps/S03-CommonTagTau-MIX015/model")) {
    fail(row$step_id[[1L]], " does not use the exact Job 16594 source model.")
  }

  temp_dir <- tempfile(paste0(row$step_id[[1L]], "-"))
  dir.create(temp_dir, recursive = TRUE)
  if (!file.copy(baseline_path, file.path(temp_dir, "bet.ini"))) {
    fail("Could not stage validation input for ", row$step_id[[1L]])
  }

  patch_env <- new.env(parent = globalenv())
  patch_env$model_dir <- temp_dir
  values <- as.list(row)
  names(values) <- toupper(gsub("[^A-Za-z0-9]+", "_", names(values)))
  patch_env$config <- lapply(values, function(value) as.character(value[[1L]]))
  sys.source(patch_path, envir = patch_env)

  candidate_path <- file.path(temp_dir, "bet.ini")
  candidate_lines <- readLines(candidate_path, warn = FALSE)
  candidate_flags <- parse_tag_flags(candidate_lines)

  if (!identical(
    baseline_lines[-baseline_rows],
    candidate_lines[-tag_flag_rows(candidate_lines)]
  )) {
    fail(row$step_id[[1L]], " changes bet.ini outside # tag flags.")
  }
  if (!identical(
    unname(candidate_flags[, 3:10, drop = FALSE]),
    unname(baseline_flags[, 3:10, drop = FALSE])
  )) {
    fail(row$step_id[[1L]], " changes tag-flag columns 3-10.")
  }

  expected_mixing <- if (identical(row$mixing_key[[1L]], "ALL2")) {
    rep(2L, 98L)
  } else {
    as.integer(grid[[row$mixing_key[[1L]]]])
  }
  expected_tag2 <- as.integer(row$tag_flags_it2[[1L]])
  if (!identical(as.integer(candidate_flags[, 1L]), expected_mixing)) {
    fail(row$step_id[[1L]], " has the wrong mixing-period vector.")
  }
  if (!identical(as.integer(candidate_flags[, 2L]), rep(expected_tag2, 98L))) {
    fail(row$step_id[[1L]], " has the wrong tag_flags(:,2) vector.")
  }

  if (!isTRUE(all.equal(
    as.numeric(numeric_section(candidate_lines, "natural mortality (per year)")),
    natural_mortality,
    tolerance = 0
  ))) fail(row$step_id[[1L]], " changes natural mortality.")
  if (!isTRUE(all.equal(
    as.numeric(numeric_section(candidate_lines, "Length-weight parameters")),
    length_weight,
    tolerance = 0
  ))) fail(row$step_id[[1L]], " changes length-weight.")
  for (label in rr_sections) {
    if (!isTRUE(all.equal(
      numeric_section(candidate_lines, label),
      baseline_rr[[label]],
      tolerance = 0
    ))) fail(row$step_id[[1L]], " changes RR section # ", label, ".")
  }

  summary_rows[[index]] <- data.frame(
    step_id = row$step_id[[1L]],
    mixing_key = row$mixing_key[[1L]],
    tag_flag2 = expected_tag2,
    tau_grouping = row$tag_tau_grouping[[1L]],
    changed_mixing_release_groups = sum(expected_mixing != baseline_flags[, 1L]),
    n_mix0 = sum(expected_mixing == 0L),
    n_mix1 = sum(expected_mixing == 1L),
    n_mix2 = sum(expected_mixing == 2L),
    n_mix3 = sum(expected_mixing == 3L),
    n_mix4 = sum(expected_mixing == 4L),
    stringsAsFactors = FALSE
  )
  unlink(temp_dir, recursive = TRUE, force = TRUE)
}

task_lines <- readLines(task_path, warn = FALSE)
required_task_lines <- c(
  "remote_host: suva",
  "docker_image: ghcr.io/pacificcommunity/tuna-flow@sha256:7b9dc95f535025a42109ac958c4faa3af96592cd19510ac0be15af4478eccf27",
  "  cpus: 2",
  "  memory: 8GB",
  "  disk: 8GB",
  "  CONFIG_R: job-config-mixing-period-sensitivity.R",
  "  ESTIMATE_M_FINAL: \"false\"",
  "  TAG_LIKELIHOOD_WEIGHT: \"0\"",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  DM_NMAX: \"25\""
)
missing_task_lines <- setdiff(required_task_lines, task_lines)
if (length(missing_task_lines)) {
  fail(
    "Sensitivity task differs from required Job 16594 execution settings: ",
    paste(missing_task_lines, collapse = " | ")
  )
}

summary <- do.call(rbind, summary_rows)
write.csv(summary, stdout(), row.names = FALSE)
message(
  "PASS: 40 variants. Rows 1-20 change only tag_flags(:,1:2); rows 21-40 ",
  "repeat the same grid with tau estimation disabled by the Job 16699 method. ",
  "M, length-weight, all five RR matrices, tag_flags(:,3:10), runtime ",
  "image/resources and all other source inputs are frozen."
)
