#!/usr/bin/env Rscript

## Fail-closed, read-only validation for the BET 2026 public stepwise inputs.
## This script never invokes MFCL. Executable files are checked inside the
## tuna-flow runtime; local validation checks their configured container paths.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- Sys.getenv("CONFIG_R", "job-config.R")
lock_path <- Sys.getenv(
  "PUBLIC_RUN_PROVENANCE",
  file.path(root, "config", "public-run-provenance.csv")
)

failures <- character()
add_failure <- function(scope, message) {
  failures <<- c(failures, paste0("[", scope, "] ", message))
  invisible(FALSE)
}

trim_character <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  trimws(x)
}

truthy <- function(x) {
  tolower(trim_character(x)) %in% c("true", "t", "1", "yes", "y")
}

first_column <- function(data, candidates) {
  hit <- candidates[candidates %in% names(data)]
  if (length(hit)) hit[[1L]] else ""
}

row_value <- function(row, candidates, default = "") {
  column <- first_column(row, candidates)
  if (!nzchar(column)) return(default)
  value <- trim_character(row[[column]])
  if (length(value) && nzchar(value[[1L]])) value[[1L]] else default
}

sha256_file <- local({
  cache <- new.env(parent = emptyenv())
  function(path) {
    if (!file.exists(path)) return("")
    key <- normalizePath(path, winslash = "/", mustWork = TRUE)
    if (exists(key, envir = cache, inherits = FALSE)) return(get(key, envir = cache))
    executable <- Sys.which("sha256sum")
    if (!nzchar(executable)) {
      add_failure("tooling", "`sha256sum` is required for deterministic validation.")
      return("")
    }
    output <- system2(executable, shQuote(path), stdout = TRUE, stderr = TRUE)
    status <- attr(output, "status")
    value <- if (length(output)) strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]] else ""
    if ((!is.null(status) && status != 0L) || !grepl("^[0-9a-f]{64}$", value)) {
      add_failure(path, paste0("could not calculate SHA256: ", paste(output, collapse = " ")))
      return("")
    }
    assign(key, value, envir = cache)
    value
  }
})

read_text <- function(path) {
  if (!file.exists(path)) return(character())
  readLines(path, warn = FALSE)
}

numeric_section <- function(lines, label) {
  markers <- which(tolower(trimws(lines)) == paste0("# ", tolower(label)))
  if (length(markers) != 1L) return(NULL)
  start <- markers[[1L]] + 1L
  next_markers <- which(seq_along(lines) > markers[[1L]] & grepl("^#", trimws(lines)))
  end <- if (length(next_markers)) next_markers[[1L]] - 1L else length(lines)
  if (end < start) return(NULL)
  block <- trimws(lines[start:end])
  block <- block[nzchar(block) & !grepl("^#", block)]
  rows <- lapply(block, function(line) suppressWarnings(as.numeric(strsplit(line, "[[:space:]]+")[[1L]])))
  rows <- rows[vapply(rows, function(x) length(x) && all(is.finite(x)), logical(1))]
  if (!length(rows) || length(unique(lengths(rows))) != 1L) return(NULL)
  do.call(rbind, rows)
}

section_text <- function(lines, label) {
  markers <- which(tolower(trimws(lines)) == paste0("# ", tolower(label)))
  if (length(markers) != 1L) return("")
  next_markers <- which(seq_along(lines) > markers[[1L]] & grepl("^#", trimws(lines)))
  end <- if (length(next_markers)) next_markers[[1L]] - 1L else length(lines)
  paste(trimws(lines[(markers[[1L]] + 1L):end]), collapse = "\n")
}

parse_control_flags <- function(lines) {
  rows <- list()
  n <- 0L
  phase <- 0L
  for (line_number in seq_along(lines)) {
    raw <- trimws(lines[[line_number]])
    phase_start <- regmatches(raw, regexec("<<PHASE([0-9]+)$", raw))[[1L]]
    if (length(phase_start) == 2L) {
      phase <- as.integer(phase_start[[2L]])
      next
    }
    if (grepl("^PHASE[0-9]+$", raw)) {
      phase <- 0L
      next
    }
    clean <- trimws(sub("#.*$", "", raw))
    if (!nzchar(clean)) next
    words <- strsplit(clean, "[[:space:]]+")[[1L]]
    values <- suppressWarnings(as.numeric(words))
    if (length(values) < 3L || any(!is.finite(values))) next
    starts <- seq.int(1L, length(values) - 2L, by = 3L)
    for (start in starts) {
      n <- n + 1L
      rows[[n]] <- data.frame(
        scope = as.integer(values[[start]]),
        flag = as.integer(values[[start + 1L]]),
        value = values[[start + 2L]],
        line = line_number,
        phase = phase,
        stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) {
    return(data.frame(
      scope = integer(), flag = integer(), value = numeric(),
      line = integer(), phase = integer()
    ))
  }
  do.call(rbind, rows)
}

flag_values <- function(flags, scope, flag) {
  flags$value[flags$scope == as.integer(scope) & flags$flag == as.integer(flag)]
}

effective_flag <- function(flags, scope, flag) {
  specific <- flag_values(flags, scope, flag)
  if (length(specific)) return(tail(specific, 1L))
  global <- flag_values(flags, -999L, flag)
  if (length(global)) tail(global, 1L) else NA_real_
}

effective_flag_at_phase <- function(flags, scope, flag, phase) {
  eligible <- flags$phase == 0L | flags$phase <= as.integer(phase)
  effective_flag(flags[eligible, , drop = FALSE], scope, flag)
}

check_flag <- function(flags, scope, flag, expected, model_id, description = "") {
  value <- effective_flag(flags, scope, flag)
  if (!is.finite(value) || !isTRUE(all.equal(value, as.numeric(expected)))) {
    suffix <- if (nzchar(description)) paste0(" (", description, ")") else ""
    add_failure(
      model_id,
      paste0("fish/control scope ", scope, " flag ", flag, " must be ", expected,
             suffix, "; found ", if (is.finite(value)) value else "missing", ".")
    )
  }
}

initial_z_control_value <- function(lines) {
  clean <- trimws(sub("#.*$", "", lines))
  words <- strsplit(clean[nzchar(clean)], "[[:space:]]+")
  prefix <- c("2", "94", "1", "2", "128")
  matches <- words[vapply(
    words,
    function(x) length(x) == 6L && identical(x[seq_along(prefix)], prefix),
    logical(1)
  )]
  if (length(matches) != 1L) return(NA_real_)
  suppressWarnings(as.numeric(matches[[1L]][[6L]]))
}

scientific_flag_table <- function(flags) {
  reporting_only <- flags$scope == 1L & flags$flag == 246L
  out <- flags[!reporting_only, c("scope", "flag", "value", "phase"), drop = FALSE]
  rownames(out) <- NULL
  out
}

placeholder_pattern <- "(?i)(TODO|TBD|FIXME|CHANGEME|REPLACE[_ -]?ME|UNKNOWN|<[^>]+>)"
check_placeholders <- function(values, scope) {
  values <- trim_character(values)
  hit <- unique(values[grepl(placeholder_pattern, values, perl = TRUE)])
  if (length(hit)) {
    add_failure(scope, paste0("unresolved placeholder text: ", paste(head(hit, 5L), collapse = " | ")))
  }
}

if (!file.exists(config_path)) {
  add_failure("job-config", paste0("missing ", config_path, "."))
}

config_env <- new.env(parent = baseenv())
if (file.exists(config_path)) {
  tryCatch(
    sys.source(config_path, envir = config_env),
    error = function(e) add_failure("job-config", paste0("could not source ", config_path, ": ", conditionMessage(e)))
  )
}

models <- if (exists("stepwise_models", envir = config_env, inherits = FALSE)) {
  get("stepwise_models", envir = config_env)
} else {
  add_failure("job-config", "must define a `stepwise_models` data frame.")
  data.frame(step_id = character(), stringsAsFactors = FALSE)
}
if (!is.data.frame(models)) {
  add_failure("job-config", "`stepwise_models` is not a data frame.")
  models <- data.frame(step_id = character(), stringsAsFactors = FALSE)
}
configured_models <- models
# Validation covers the complete configured scientific chain, including rows
# that are not currently enabled for execution.

if (!"step_id" %in% names(models)) {
  add_failure("job-config", "`stepwise_models` must include `step_id`.")
  models$step_id <- character(nrow(models))
}
models$step_id <- trim_character(models$step_id)
if (any(!nzchar(models$step_id))) add_failure("job-config", "enabled rows contain blank `step_id` values.")
if (anyDuplicated(models$step_id)) add_failure("job-config", "enabled `step_id` values are not unique.")
if (!nrow(models)) add_failure("folder-set", "job-config does not enable any independent model folders.")

configured_text <- unlist(models, use.names = FALSE)
check_placeholders(configured_text, "job-config")
forbidden_pattern <- "OrthogonalPoly|LengthBasedSel|G7OSHL|NMAX(10|15)([^0-9]|$)"
identity_columns <- intersect(
  c("step_id", "model_label", "job_title", "job_key", "major_step", "substep", "change_axis"),
  names(models)
)
configured_identity <- unlist(models[identity_columns], use.names = FALSE)
forbidden <- grepl(forbidden_pattern, configured_identity, ignore.case = TRUE, perl = TRUE)
if (any(forbidden)) {
  add_failure(
    "job-config",
    "configured rows contain forbidden intermediate G7OSHL, Nmax10, Nmax15, OrthogonalPoly, or LengthBasedSel models."
  )
}

model_dir_for_row <- function(row) {
  configured <- row_value(row, c("model_dir", "folder", "model_path"))
  if (nzchar(configured)) {
    return(if (grepl("^/", configured)) configured else file.path(root, configured))
  }
  step_id <- row_value(row, "step_id")
  step_path <- file.path(root, "steps", step_id, "model")
  sensitivity_path <- file.path(root, "sensitivity", step_id, "model")
  if (dir.exists(step_path) || !dir.exists(sensitivity_path)) step_path else sensitivity_path
}

configured_dirs <- if (nrow(models)) {
  vapply(seq_len(nrow(models)), function(i) model_dir_for_row(models[i, , drop = FALSE]), character(1))
} else character()

actual_ids <- character()
for (container in c("steps", "sensitivity")) {
  container_path <- file.path(root, container)
  if (!dir.exists(container_path)) next
  children <- list.dirs(container_path, full.names = FALSE, recursive = FALSE)
  actual_ids <- c(actual_ids, children[dir.exists(file.path(container_path, children, "model"))])
}
actual_ids <- sort(unique(actual_ids))
configured_ids <- if ("step_id" %in% names(configured_models)) {
  trim_character(configured_models$step_id)
} else {
  character()
}
missing_ids <- setdiff(configured_ids, actual_ids)
extra_ids <- setdiff(actual_ids, configured_ids)
if (length(missing_ids)) add_failure("folder-set", paste0("configured model folders are missing: ", paste(missing_ids, collapse = ", "), "."))
if (length(extra_ids)) add_failure("folder-set", paste0("unconfigured model folders must be removed or configured: ", paste(extra_ids, collapse = ", "), "."))
if (any(grepl(forbidden_pattern, actual_ids, ignore.case = TRUE, perl = TRUE))) {
  add_failure(
    "folder-set",
    "generated folders include forbidden intermediate G7OSHL, Nmax10, Nmax15, OrthogonalPoly, or LengthBasedSel models."
  )
}

## Parent graph: accept a config column or a named/data-frame graph object.
parent_column <- first_column(models, c(
  "scientific_parent_id", "parent_step", "parent_step_id", "parent_id", "parent_model"
))
parents <- rep("", nrow(models))
if (nzchar(parent_column)) {
  parents <- trim_character(models[[parent_column]])
} else if (exists("stepwise_parent_graph", envir = config_env, inherits = FALSE)) {
  graph <- get("stepwise_parent_graph", envir = config_env)
  if (is.data.frame(graph)) {
    child_column <- first_column(graph, c("step_id", "child", "model"))
    graph_parent_column <- first_column(graph, c("parent_step", "parent", "parent_id"))
    if (nzchar(child_column) && nzchar(graph_parent_column)) {
      map <- setNames(trim_character(graph[[graph_parent_column]]), trim_character(graph[[child_column]]))
      parents <- unname(map[models$step_id])
      parents[is.na(parents)] <- ""
    } else {
      add_failure("parent-graph", "`stepwise_parent_graph` data frame needs child and parent columns.")
    }
  } else if (is.atomic(graph) && !is.null(names(graph))) {
    parents <- trim_character(graph[models$step_id])
    parents[is.na(parents)] <- ""
  } else {
    add_failure("parent-graph", "`stepwise_parent_graph` must be a named vector or data frame.")
  }
} else {
  add_failure("parent-graph", "job-config must define a parent column or `stepwise_parent_graph`.")
}

root_parent <- function(x) {
  !nzchar(x) || toupper(x) %in% c("NA", "NONE", "ROOT", "SOURCE") ||
    grepl("^external-", x, ignore.case = TRUE)
}
for (i in seq_along(parents)) {
  parent_tokens <- trimws(strsplit(parents[[i]], "[,;]")[[1L]])
  parent_tokens <- parent_tokens[nzchar(parent_tokens)]
  for (parent in parent_tokens) {
    if (root_parent(parent)) next
    if (identical(parent, models$step_id[[i]])) {
      add_failure(models$step_id[[i]], "parent graph contains a self-parent edge.")
    } else if (!parent %in% models$step_id) {
      add_failure(models$step_id[[i]], paste0("parent `", parent, "` is not an enabled configured model."))
    }
  }
}

state <- setNames(integer(nrow(models)), models$step_id)
visit_parent <- function(id, trail = character()) {
  if (!id %in% names(state)) return(invisible(NULL))
  if (state[[id]] == 2L) return(invisible(NULL))
  if (state[[id]] == 1L) {
    add_failure("parent-graph", paste0("cycle detected: ", paste(c(trail, id), collapse = " -> "), "."))
    return(invisible(NULL))
  }
  state[[id]] <<- 1L
  index <- match(id, models$step_id)
  tokens <- trimws(strsplit(parents[[index]], "[,;]")[[1L]])
  tokens <- tokens[nzchar(tokens) & !vapply(tokens, root_parent, logical(1))]
  for (parent in tokens) visit_parent(parent, c(trail, id))
  state[[id]] <<- 2L
  invisible(NULL)
}
for (id in models$step_id) visit_parent(id)

expected_weighting_parents <- c(
  "20a-DOMDiv200" = "19-EffortCreep",
  "20b-Francis" = "19-EffortCreep",
  "20c-DMG8Nmax25" = "19-EffortCreep",
  "21a-R1F2F3F29Shared-MIX015" = "20c-DMG8Nmax25",
  "S01-SelectivityStability-MIX015" =
    "21a-R1F2F3F29Shared-MIX015",
  "S02-F33Asymptotic-MIX015" =
    "S01-SelectivityStability-MIX015",
  "S03-CommonTagTau-MIX015" =
    "S02-F33Asymptotic-MIX015",
  "S04-CommonTagTauSpline-MIX015" =
    "S01-SelectivityStability-MIX015",
  "S05-CommonTagTauOPR-MIX015" =
    "S03-CommonTagTau-MIX015",
  "S06-CommonTagTauSplineOPR-MIX015" =
    "S04-CommonTagTauSpline-MIX015",
  "21b-R1F2F3F29Shared-MIX005" =
    "21a-R1F2F3F29Shared-MIX015",
  "22a-R1F2F3F29Shared-MIX015-TAGW500" =
    "21a-R1F2F3F29Shared-MIX015",
  "22b-R1F2F3F29Shared-MIX015-TAGW250" =
    "21a-R1F2F3F29Shared-MIX015",
  "22c-R1F2F3F29Shared-MIX005-TAGW500" =
    "21b-R1F2F3F29Shared-MIX005",
  "22d-R1F2F3F29Shared-MIX005-TAGW250" =
    "21b-R1F2F3F29Shared-MIX005"
)
for (child in names(expected_weighting_parents)) {
  index <- match(child, models$step_id)
  if (is.na(index)) {
    add_failure("parent-graph", paste0("required weighting branch `", child, "` is missing."))
    next
  }
  actual_parent <- parents[[index]]
  expected_parent <- expected_weighting_parents[[child]]
  if (!identical(actual_parent, expected_parent)) {
    add_failure(
      child,
      paste0(
        "scientific parent must be `", expected_parent,
        "`; found `", actual_parent, "`."
      )
    )
  }
}

## Provenance lock validation.
lock <- if (file.exists(lock_path)) {
  tryCatch(
    utils::read.csv(lock_path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = character()),
    error = function(e) {
      add_failure("provenance", paste0("could not read ", lock_path, ": ", conditionMessage(e)))
      data.frame(stringsAsFactors = FALSE)
    }
  )
} else {
  add_failure("provenance", paste0("missing machine-readable lock ", lock_path, "."))
  data.frame(stringsAsFactors = FALSE)
}

lock_columns <- c(
  "role", "name", "job_id", "repository_url", "repository_commit", "repository_path",
  "source_sha256", "prepared_sha256", "public_access", "status", "expected_values", "source_models"
)
missing_lock_columns <- setdiff(lock_columns, names(lock))
if (length(missing_lock_columns)) {
  add_failure("provenance", paste0("lock is missing columns: ", paste(missing_lock_columns, collapse = ", "), "."))
}
if (nrow(lock)) check_placeholders(unlist(lock, use.names = FALSE), "provenance")

is_sha <- function(x) grepl("^[0-9a-f]{64}$", trim_character(x))
is_commit <- function(x) grepl("^[0-9a-f]{40}$", trim_character(x))
is_public_repo <- function(x) grepl("^https://github[.]com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+([.]git)?$", trim_character(x))
required_lock_roles <- c(
  "cpue_mle_sigma", "francis_weights", "ini_source", "tag_source",
  "frq_source", "regional_scaling", "age_variant"
)
if (nrow(lock) && "role" %in% names(lock)) {
  missing_roles <- setdiff(required_lock_roles, unique(lock$role))
  if (length(missing_roles)) add_failure("provenance", paste0("lock is missing roles: ", paste(missing_roles, collapse = ", "), "."))
  for (i in seq_len(nrow(lock))) {
    record <- lock[i, , drop = FALSE]
    scope <- paste0("provenance:", record$role[[1L]], ":", record$name[[1L]])
    locked <- identical(tolower(trim_character(record$status[[1L]])), "locked")
    if (!locked) {
      if (record$role[[1L]] %in% required_lock_roles) {
        add_failure(scope, paste0("status is `", record$status[[1L]], "`; supply exact public repository, full commit, path, and SHA256."))
      }
      next
    }
    if (!truthy(record$public_access[[1L]])) add_failure(scope, "locked record is not explicitly public; it cannot support a public run.")
    if (!is_public_repo(record$repository_url[[1L]])) add_failure(scope, "repository_url must be an exact public GitHub repository URL, not a local/private/blob URL.")
    if (!is_commit(record$repository_commit[[1L]])) add_failure(scope, "repository_commit must be a full 40-character commit.")
    path <- trim_character(record$repository_path[[1L]])
    if (!nzchar(path) || grepl("^/|(^|/)[.][.](/|$)", path)) add_failure(scope, "repository_path must be a non-empty repo-relative path.")
    if (!is_sha(record$source_sha256[[1L]])) add_failure(scope, "source_sha256 must be an exact lowercase SHA256.")
    if (!is_sha(record$prepared_sha256[[1L]])) add_failure(scope, "prepared_sha256 must be an exact lowercase SHA256.")
  }
}

job_record <- function(role, job_id) {
  if (!nrow(lock) || !all(c("role", "job_id") %in% names(lock))) return(NULL)
  hit <- lock$role == role & trim_character(lock$job_id) == as.character(job_id)
  if (sum(hit) == 1L) lock[hit, , drop = FALSE] else NULL
}
fitted_lock <- job_record("fitted_source", 14363L)
if (is.null(fitted_lock)) {
  add_failure(
    "provenance",
    "the selected all-relaxed/DM fitted reference must identify Job14363."
  )
}

lock_by_role_name <- function(role, name = NULL) {
  if (!nrow(lock) || !"role" %in% names(lock)) return(NULL)
  hit <- lock$role == role
  if (!is.null(name) && "name" %in% names(lock)) hit <- hit & toupper(lock$name) == toupper(name)
  if (sum(hit) == 1L) lock[hit, , drop = FALSE] else NULL
}

age_column <- first_column(models, c("age_length_variant", "age_variant", "caal_variant"))
if (!nzchar(age_column)) add_failure("job-config", "age variants require an `age_length_variant` (or alias) column.")

semantic_columns <- c(
  "tag_flag2", "dm_grouping", "dm_nmax", "regional_scaling_weight",
  "reporting_rate_prior", "fixed_natural_mortality",
  "length_weight_updated", "tail_compression_percent", "fixed_cpue_sigma",
  "selectivity_update",
  "all_selectivity_forms_relaxed"
)
for (column in semantic_columns) {
  if (!column %in% names(models)) add_failure("job-config", paste0("missing semantic validation column `", column, "`."))
}

required_files <- c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "doitall.sh", "mfcl.cfg")
g8_expected <- c(1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 3, 7, 6, 6, 7, 3, 3, 4, 5, 7, 7, 7, 7, 4, 4, 5, 5, 8, 8, 8, 8, 8)
rr_signatures <- list()
model_cache <- list()

normalise_exact_control <- function(line) {
  body <- sub("[[:space:]]+#.*$", "", line)
  paste(strsplit(trimws(body), "[[:space:]]+")[[1L]], collapse = " ")
}

exact_control_count <- function(lines, control) {
  expected <- normalise_exact_control(control)
  sum(vapply(
    lines,
    function(line) {
      words <- strsplit(trimws(sub("[[:space:]]+#.*$", "", line)), "[[:space:]]+")[[1L]]
      if (length(words) < 3L || length(words) %% 3L != 0L) return(0L)
      starts <- seq.int(1L, length(words) - 2L, by = 3L)
      sum(vapply(
        starts,
        function(start) identical(
          paste(words[start:(start + 2L)], collapse = " "),
          expected
        ),
        logical(1)
      ))
    },
    integer(1)
  ))
}

require_exact_controls <- function(lines, controls, model_id, description) {
  counts <- vapply(
    controls,
    function(control) exact_control_count(lines, control),
    integer(1)
  )
  if (any(counts != 1L)) {
    details <- paste0("`", controls[counts != 1L], "`=", counts[counts != 1L])
    add_failure(
      model_id,
      paste0(description, " requires exactly one of each control; found ", paste(details, collapse = ", "), ".")
    )
  }
}

forbid_exact_controls <- function(lines, controls, model_id, description) {
  counts <- vapply(
    controls,
    function(control) exact_control_count(lines, control),
    integer(1)
  )
  if (any(counts != 0L)) {
    details <- paste0("`", controls[counts != 0L], "`=", counts[counts != 0L])
    add_failure(
      model_id,
      paste0(description, " forbids these controls; found ", paste(details, collapse = ", "), ".")
    )
  }
}

legacy_selectivity_controls <- c(
  "-5 16 1", "-14 75 5", "-20 16 2",
  "-20 3 30", "-28 16 2", "-28 3 30"
)
dom_divisor_controls <- c("-21 49 200", "-22 49 200", "-23 49 200")
francis_dom_controls <- c("-21 49 114", "-22 49 398", "-23 49 705")
job13328_dm_controls <- c(
  "1 141 11", "1 311 1", "1 320 5", "1 342 25",
  "-999 69 1", "-999 89 0", "-999 89 1"
)
dm_branch_only_controls <- setdiff(job13328_dm_controls, "1 311 1")

tag_release_programs <- function(lines, path) {
  headers <- grep("#[[:space:]]+[0-9]+ - RELEASE REGION", lines)
  if (!length(headers)) {
    add_failure(path, "bet.tag has no readable release-group headers.")
    return(character())
  }
  titles <- trimws(sub("^#[[:space:]]*", "", lines[headers]))
  groups <- suppressWarnings(as.integer(sub("^([0-9]+).*", "\\1", titles)))
  programs <- toupper(trimws(sub(".*Tag_program[[:space:]]+", "", titles)))
  if (anyNA(groups) || !identical(groups, seq_along(groups)) ||
      any(!programs %in% c("RTTP", "PTTP", "JPTP"))) {
    add_failure(path, "bet.tag release groups/programmes are not a contiguous RTTP/PTTP/JPTP map.")
    return(character())
  }
  programs
}

rr_source_path <- file.path(root, "config", "rrpttp26-reporting-rates.csv")
rr_fields <- c("group", "active", "initial", "target", "penalty")
rr_programs <- c("RTTP", "PTTP", "JPTP")
rr_expected_columns <- c(
  "fishery",
  unlist(lapply(rr_programs, function(program) paste0(program, "_", rr_fields)), use.names = FALSE)
)
rr_spec <- if (file.exists(rr_source_path)) {
  tryCatch(
    utils::read.csv(rr_source_path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) {
      add_failure("reporting-rates", paste0("could not read ", rr_source_path, ": ", conditionMessage(e)))
      data.frame()
    }
  )
} else {
  add_failure("reporting-rates", paste0("missing audited mapping ", rr_source_path, "."))
  data.frame()
}
if (nrow(rr_spec) != 33L || !identical(names(rr_spec), rr_expected_columns) ||
    !identical(as.integer(rr_spec$fishery), 1:33)) {
  add_failure("reporting-rates", "audited reporting-rate mapping must contain the exact 33-fishery RTTP/PTTP/JPTP schema.")
}
if (nrow(rr_spec) == 33L) {
  for (program in rr_programs) {
    west <- as.integer(rr_spec[[paste0(program, "_group")]][c(25L, 27L)])
    east <- as.integer(rr_spec[[paste0(program, "_group")]][c(26L, 28L)])
    if (length(unique(west)) != 1L || length(unique(east)) != 1L ||
        identical(west[[1L]], east[[1L]])) {
      add_failure(
        "reporting-rates",
        paste0(program, " West F25/F27 and East F26/F28 must use separate, internally consistent penalty groups.")
      )
    }
  }
}

rr_parser_env <- new.env(parent = baseenv())
rr_parser_env$read_words <- function(line) {
  strsplit(trimws(line), "[[:space:]]+")[[1L]]
}
tryCatch(
  sys.source(file.path(root, "R", "prepare_mfcl_inputs.R"), envir = rr_parser_env),
  error = function(e) {
    add_failure("reporting-rates", paste0("could not load tag parser: ", conditionMessage(e)))
  }
)

expected_rr_matrices <- function(program_rows, release_programs, tag_path, model_id) {
  if (!nrow(rr_spec) || !length(program_rows) ||
      !exists("tag_recapture_table", envir = rr_parser_env, inherits = FALSE)) {
    return(NULL)
  }
  program_spec <- setNames(lapply(rr_programs, function(program) {
    setNames(
      lapply(rr_fields, function(field) {
        as.numeric(rr_spec[[paste0(program, "_", field)]])
      }),
      rr_fields
    )
  }), rr_programs)

  recaps <- tryCatch(
    rr_parser_env$tag_recapture_table(tag_path),
    error = function(e) {
      add_failure(model_id, paste0("could not parse positive tag recaptures: ", conditionMessage(e)))
      data.frame()
    }
  )
  if (nrow(recaps)) {
    recaps <- recaps[
      recaps$recap_number > 0L &
        recaps$release_group <= length(release_programs),
      ,
      drop = FALSE
    ]
  }
  if (nrow(recaps)) {
    required <- unique(data.frame(
      program = release_programs[recaps$release_group],
      fishery = as.integer(recaps$recap_fishery),
      stringsAsFactors = FALSE
    ))
    for (i in seq_len(nrow(required))) {
      program <- required$program[[i]]
      fishery <- required$fishery[[i]]
      if (program_spec[[program]]$active[[fishery]] == 0) {
        if (program_spec$PTTP$active[[fishery]] == 0 ||
            any(c(
              program_spec$PTTP$initial[[fishery]],
              program_spec$PTTP$target[[fishery]],
              program_spec$PTTP$penalty[[fishery]]
            ) <= 0)) {
          add_failure(
            model_id,
            paste0(
              "positive ", program, " recaptures in F", fishery,
              " have no active audited PTTP reporting-rate prior."
            )
          )
          next
        }
        for (field in c("active", "initial", "target", "penalty")) {
          program_spec[[program]][[field]][[fishery]] <-
            program_spec$PTTP[[field]][[fishery]]
        }
      }
    }
  }

  setNames(lapply(rr_fields, function(field) {
    do.call(
      rbind,
      lapply(program_rows, function(program) program_spec[[program]][[field]])
    )
  }), rr_fields)
}

format_rr_map_values <- function(x) {
  x <- unique(as.vector(x))
  x <- x[!is.na(x)]
  if (!length(x)) return("")
  paste(format(x, digits = 10L, scientific = FALSE, trim = TRUE), collapse = ",")
}

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  model_id <- row$step_id[[1L]]
  major_number <- suppressWarnings(as.integer(sub("[^0-9].*$", "", model_id)))
  path_stage <- suppressWarnings(as.integer(row_value(row, "path_stage")))
  model_dir <- configured_dirs[[i]]
  step_dir <- dirname(model_dir)
  label <- paste(trim_character(unlist(row, use.names = FALSE)), collapse = " ")
  token <- toupper(paste(model_id, row_value(row, "model_label"), collapse = " "))

  if (!dir.exists(model_dir)) next
  missing_files <- required_files[!file.exists(file.path(model_dir, required_files))]
  if (length(missing_files)) add_failure(model_id, paste0("missing required MFCL files: ", paste(missing_files, collapse = ", "), "."))
  manifest_path <- file.path(step_dir, "input_manifest.csv")
  if (!file.exists(manifest_path)) add_failure(model_id, "missing input_manifest.csv beside model/.")
  if (file.exists(file.path(model_dir, "doitall.sh")) && file.access(file.path(model_dir, "doitall.sh"), 1L) != 0L) {
    add_failure(model_id, "doitall.sh is not executable.")
  }

  configured_program <- row_value(row, c("mfcl_program_path", "program_path"), Sys.getenv("PROGRAM_PATH", ""))
  if (!nzchar(configured_program)) configured_program <- Sys.getenv("PROGRAM_PATH", "")
  if (!nzchar(configured_program)) {
    add_failure(model_id, "MFCL executable is not configured; pass PROGRAM_PATH or set mfcl_program_path in job-config.")
  } else if (!grepl("^/home/mfcl/", configured_program)) {
    add_failure(model_id, paste0("MFCL executable must use an absolute tuna-flow path; found ", configured_program, "."))
  } else if (truthy(Sys.getenv("STEPWISE_VALIDATE_EXECUTABLES", "false")) &&
             (!file.exists(configured_program) || file.access(configured_program, 1L) != 0L)) {
    add_failure(model_id, paste0("configured MFCL executable is missing or not executable: ", configured_program, "."))
  }

  doitall_path <- file.path(model_dir, "doitall.sh")
  ini_path <- file.path(model_dir, "bet.ini")
  tag_path <- file.path(model_dir, "bet.tag")
  age_path <- file.path(model_dir, "bet.age_length")
  doitall <- read_text(doitall_path)
  ini <- read_text(ini_path)
  flags <- parse_control_flags(doitall)
  check_placeholders(c(doitall, if (file.exists(manifest_path)) read_text(manifest_path) else character()), model_id)

  tail_percent <- suppressWarnings(as.numeric(
    row_value(row, "tail_compression_percent")
  ))
  if (is.finite(tail_percent)) {
    check_flag(
      flags, 1L, 313L, tail_percent, model_id,
      "length-frequency tail aggregation percentage"
    )
    check_flag(flags, 1L, 311L, 1L, model_id, "length-frequency tail arrays enabled")
    check_flag(flags, 1L, 301L, 1L, model_id, "weight-frequency tail arrays retained")
    check_flag(flags, 1L, 303L, 0L, model_id, "weight-frequency tail aggregation remains off")
  }

  selectivity_expected <- truthy(row_value(row, "selectivity_update"))
  all_forms_relaxed <- truthy(
    row_value(row, "all_selectivity_forms_relaxed")
  )
  if (!identical(selectivity_expected, all_forms_relaxed)) {
    add_failure(
      model_id,
      paste0(
        "the revised fishery-specific selectivity specification and all-relaxed form choice ",
        "must start together at Step 16 and remain paired thereafter."
      )
    )
  }
  all_relaxed_fisheries <- c(
    12L, 13L, 15L, 16L, 17L, 18L, 19L,
    21L, 22L, 23L, 24L, 25L, 26L, 27L
  )
  if (!selectivity_expected) {
    premature_relaxation <- all_relaxed_fisheries[vapply(
      all_relaxed_fisheries,
      function(fishery) identical(effective_flag(flags, -fishery, 16L), 0),
      logical(1)
    )]
    if (length(premature_relaxation)) {
      add_failure(
        model_id,
        paste0(
          "all-relaxed flag 16=0 must not appear before Step 16; found F",
          paste(premature_relaxation, collapse = ", F"), "."
        )
      )
    }
  }
  if (selectivity_expected) {
    forbid_exact_controls(
      doitall, legacy_selectivity_controls, model_id,
      "selected revised fishery-specific selectivity cleanup"
    )
  }
  if (identical(model_id, "16-SelectivityUpdate")) {
    forbid_exact_controls(
      doitall,
      c(dom_divisor_controls, francis_dom_controls, dm_branch_only_controls),
      model_id,
      "Step 16 pre-weighting state"
    )
  }
  if (identical(model_id, "20a-DOMDiv200")) {
    require_exact_controls(doitall, dom_divisor_controls, model_id, "20a DOM weighting")
    forbid_exact_controls(
      doitall, c(francis_dom_controls, dm_branch_only_controls), model_id,
      "20a DOM-only weighting"
    )
  }
  if (identical(model_id, "20b-Francis")) {
    require_exact_controls(doitall, francis_dom_controls, model_id, "20b Francis weighting")
    forbid_exact_controls(
      doitall, c(dom_divisor_controls, dm_branch_only_controls), model_id,
      "20b Francis replacement weighting"
    )
  }
  common_tau_models <- c(
    "S03-CommonTagTau-MIX015",
    "S04-CommonTagTauSpline-MIX015",
    "S05-CommonTagTauOPR-MIX015",
    "S06-CommonTagTauSplineOPR-MIX015"
  )
  final_dm_models <- c(
    "20c-DMG8Nmax25",
    "21a-R1F2F3F29Shared-MIX015",
    "21b-R1F2F3F29Shared-MIX005",
    "22a-R1F2F3F29Shared-MIX015-TAGW500",
    "22b-R1F2F3F29Shared-MIX015-TAGW250",
    "22c-R1F2F3F29Shared-MIX005-TAGW500",
    "22d-R1F2F3F29Shared-MIX005-TAGW250",
    "S01-SelectivityStability-MIX015",
    "S02-F33Asymptotic-MIX015",
    "S03-CommonTagTau-MIX015",
    "S04-CommonTagTauSpline-MIX015",
    "S05-CommonTagTauOPR-MIX015",
    "S06-CommonTagTauSplineOPR-MIX015"
  )
  if (model_id %in% final_dm_models) {
    required_dm_controls <- if (model_id %in% common_tau_models) {
      setdiff(job13328_dm_controls, "1 342 25")
    } else {
      job13328_dm_controls
    }
    require_exact_controls(
      doitall, required_dm_controls, model_id,
      "Job 13328 S011 DM/G8/Nmax25 state"
    )
    forbid_exact_controls(
      doitall, c(dom_divisor_controls, francis_dom_controls), model_id,
      "direct Step 19 DM branch"
    )
    if (sum(trimws(doitall) == "phase10_11_convergence=${BET_PHASE10_11_CONVERGENCE:--4}") != 1L) {
      add_failure(model_id, "final MGC default must be exactly 1e-4 (`BET_PHASE10_11_CONVERGENCE=-4`).")
    }
    if (exact_control_count(doitall, "1 50 $phase10_11_convergence") != 2L) {
      add_failure(model_id, "PHASE 10 and PHASE 11 must both use the final run-time MGC target.")
    }
  }
  if (model_id %in% common_tau_models) {
    required_runtime_controls <- c(
      "regional_recruitment_penalty=${REGIONAL_RECRUITMENT_PENALTY:-0.1}",
      "regional_recruitment_penalty_flag=0",
      "regional_recruitment_penalty_flag=2",
      "2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient",
      "dm_nmax=${DM_NMAX:-25}",
      "tag_tau_lower_bound=${TAG_TAU_LOWER_BOUND:-default}",
      "tag_tau_grouping=${TAG_TAU_GROUPING:-common}",
      "estimate_m_final=${ESTIMATE_M_FINAL:-false}"
    )
    missing_runtime_controls <- required_runtime_controls[
      !vapply(
        required_runtime_controls,
        function(control) any(trimws(doitall) == control),
        logical(1)
      )
    ]
    if (length(missing_runtime_controls)) {
      add_failure(
        model_id,
        paste0(
          "common-tau runtime controls are incomplete: ",
          paste(missing_runtime_controls, collapse = "; "),
          "."
        )
      )
    }
    if (sum(grepl(
      "^[[:space:]]*2[[:space:]]+110[[:space:]]+\\$regional_recruitment_penalty_flag",
      doitall
    )) != 1L) {
      add_failure(
        model_id,
        "age flag 110 must be set exactly once in Phase 1 from the 0.1/0.2 runtime switch."
      )
    }
    if (!any(grepl(
      'age_flag_110=.*print \\$110',
      doitall
    ))) {
      add_failure(
        model_id,
        "final-par audit must read and verify age flag 110."
      )
    }
  }
  opr_models <- c(
    "S05-CommonTagTauOPR-MIX015",
    "S06-CommonTagTauSplineOPR-MIX015"
  )
  if (model_id %in% opr_models) {
    require_exact_controls(
      doitall,
      c(
        "1 398 0", "1 400 0",
        "2 177 0", "2 32 0",
        "1 155 72", "1 217 1", "1 216 50", "1 218 50",
        "1 202 2", "1 210 0", "1 212 0", "1 214 0",
        "2 30 1", "2 70 0", "2 71 0", "2 178 0"
      ),
      model_id,
      "BET 2026 72-01-50-50 OPR transfer"
    )
    if (exact_control_count(doitall, "1 155 72") != 1L ||
        exact_control_count(doitall, "1 216 50") != 1L ||
        exact_control_count(doitall, "1 217 1") != 1L ||
        exact_control_count(doitall, "1 218 50") != 1L) {
      add_failure(
        model_id,
        "OPR year, region, season and region-season controls must each be introduced exactly once."
      )
    }
  }

  if (length(ini)) {
    first_value <- suppressWarnings(as.integer(trimws(ini[which(nzchar(trimws(ini)) & !grepl("^#", trimws(ini)))[[1L]]])))
    expected_version <- if (model_id %in% c("01-Diag2023", "02-NewExe1003")) 1003L else 1007L
    if (!is.finite(first_value) || first_value != expected_version) {
      add_failure(model_id, paste0("bet.ini must be MFCL ", expected_version, "; found ", if (is.finite(first_value)) first_value else "unreadable", "."))
    }
    if (truthy(row_value(row, "fixed_natural_mortality"))) {
      age_pars <- numeric_section(ini, "age_pars")
      expected_m <- -2.54930339768360
      m_rows <- if (!is.null(age_pars) && ncol(age_pars) >= 2L) {
        which(age_pars[, 2L] == -1 & age_pars[, 1L] > -3 & age_pars[, 1L] < -2)
      } else integer()
      if (length(m_rows) != 1L ||
          !isTRUE(all.equal(age_pars[m_rows, 1L], expected_m, tolerance = 1e-12))) {
        found <- if (length(m_rows)) paste(age_pars[m_rows, 1L], collapse = ", ") else "missing"
        add_failure(
          model_id,
          paste0(
            "fixed natural mortality must remain ", format(expected_m, digits = 16L),
            " from Step 04 onward; found ", found, "."
          )
        )
      }
    }
    if (truthy(row_value(row, "length_weight_updated"))) {
      length_weight <- numeric_section(ini, "Length-weight parameters")
      expected_length_weight <- c(3.073533e-05, 2.932410)
      actual_length_weight <- if (!is.null(length_weight) &&
                                  length(length_weight) == 2L) {
        as.numeric(length_weight)
      } else {
        numeric()
      }
      if (!isTRUE(all.equal(
        actual_length_weight,
        expected_length_weight,
        tolerance = 1e-12,
        check.attributes = FALSE
      ))) {
        add_failure(
          model_id,
          paste0(
            "updated length-weight parameters must remain `",
            paste(expected_length_weight, collapse = " "),
            "` from Step 05 onward; found `",
            paste(actual_length_weight, collapse = " "), "`."
          )
        )
      }
    }
  }

  tag_lock <- lock_by_role_name("tag_source", "LOW_RECAPS_REMOVED")
  if (is.finite(path_stage) && path_stage >= 10L &&
      !is.null(tag_lock) && file.exists(tag_path)) {
    expected <- trim_character(tag_lock$prepared_sha256[[1L]])
    actual <- sha256_file(tag_path)
    if (nzchar(expected) && !identical(expected, actual)) add_failure(model_id, paste0("bet.tag rollback/drift: expected SHA256 ", expected, ", got ", actual, "."))
  }

  age_variant <- if (nzchar(age_column)) toupper(row_value(row, age_column)) else ""
  age_lock <- if (nzchar(age_variant)) lock_by_role_name("age_variant", age_variant) else NULL
  if (nzchar(age_variant) && is.null(age_lock)) {
    add_failure(model_id, paste0("age variant `", age_variant, "` has no unique provenance lock."))
  } else if (!is.null(age_lock) && file.exists(age_path)) {
    expected <- trim_character(age_lock$prepared_sha256[[1L]])
    actual <- sha256_file(age_path)
    if (!identical(expected, actual)) add_failure(model_id, paste0("age variant ", age_variant, " SHA256 mismatch: expected ", expected, ", got ", actual, "."))
  }

  tag_flags <- numeric_section(ini, "tag flags")
  expected_tag_flag2 <- suppressWarnings(as.integer(row_value(row, "tag_flag2")))
  if (is.finite(expected_tag_flag2)) {
    if (is.null(tag_flags) || ncol(tag_flags) < 2L) {
      add_failure(model_id, "bet.ini has no readable tag flags matrix.")
    } else if (any(tag_flags[, 2L] != expected_tag_flag2)) {
      add_failure(model_id, paste0("TAGF2", if (expected_tag_flag2 == 1L) "ON" else "OFF", " is not isolated: every tag_flags(:,2) value must be ", expected_tag_flag2, "."))
    }
  }
  mixing_expected <- is.finite(path_stage) && path_stage >= 17L
  if (mixing_expected) {
    if (!length(tag_flags) || length(unique(tag_flags[, 1L])) < 2L) add_failure(model_id, "MIX015 requires release-specific mixing periods in bet.ini.")
    override <- flags$scope == -9999L & flags$flag == 1L
    if (any(override)) add_failure(model_id, "MIX015 rollback: doitall.sh overrides release-specific INI mixing periods with -9999 flag 1.")
  }
  if (is.finite(path_stage) && path_stage >= 10L && path_stage < 17L &&
      length(tag_flags) && length(unique(tag_flags[, 1L])) != 1L) {
    add_failure(model_id, "release-group-specific mixing periods must not appear before Step 17.")
  }

  rr_labels <- c("tag fish rep", "tag fish rep group flags", "tag_fish_rep active flags", "tag_fish_rep target", "tag_fish_rep penalty")
  rr <- lapply(rr_labels, function(label) numeric_section(ini, label))
  names(rr) <- rr_labels
  if (any(vapply(rr, is.null, logical(1)))) {
    add_failure(model_id, "bet.ini is missing one or more reporting-rate matrices (mean/group/active/target/penalty).")
  } else {
    dimensions <- vapply(rr, function(x) paste(dim(x), collapse = "x"), character(1))
    if (length(unique(dimensions)) != 1L) add_failure(model_id, paste0("reporting-rate matrix dimensions differ: ", paste(names(dimensions), dimensions, collapse = "; "), "."))
    active <- rr[["tag_fish_rep active flags"]]
    target <- rr[["tag_fish_rep target"]]
    penalty <- rr[["tag_fish_rep penalty"]]
    means <- rr[["tag fish rep"]]
    if (any(!active %in% c(0, 1))) add_failure(model_id, "reporting-rate active matrix must contain only 0/1.")
    active_cells <- active == 1
    if (any(means[active_cells] <= 0) || any(target[active_cells] <= 0) || any(penalty[active_cells] <= 0)) {
      add_failure(model_id, "active reporting-rate cells require positive mean, target, and penalty values.")
    }
    groups <- rr[["tag fish rep group flags"]]
    positive_group_cells <- active_cells & groups > 0 & target > 0 & penalty > 0
    for (group_id in sort(unique(as.integer(groups[positive_group_cells])))) {
      cells <- positive_group_cells & groups == group_id
      signatures <- unique(paste(
        format(target[cells], digits = 15L, scientific = FALSE, trim = TRUE),
        format(penalty[cells], digits = 15L, scientific = FALSE, trim = TRUE),
        sep = ", "
      ))
      if (length(signatures) > 1L) {
        add_failure(
          model_id,
          paste0(
            "active reporting-rate group ", group_id,
            " has multiple positive target/penalty signatures: (",
            paste(signatures, collapse = "), ("), ")."
          )
        )
      }
    }
    rr_prior <- row_value(row, "reporting_rate_prior")
    signature <- paste(vapply(rr, function(x) paste(format(x, scientific = FALSE, trim = TRUE), collapse = ","), character(1)), collapse = "|")
    if (nzchar(rr_prior)) {
      if (is.null(rr_signatures[[rr_prior]])) rr_signatures[[rr_prior]] <- signature
      else if (!identical(rr_signatures[[rr_prior]], signature)) add_failure(model_id, paste0("RR matrices drift within reporting_rate_prior `", rr_prior, "`."))
    }
    if (grepl("manual[_ /-]*8[_ /-]*10|RR8-10|RR8/10", paste(rr_prior, token), ignore.case = TRUE)) {
      unusual <- unique(penalty[active_cells & penalty != 1])
      if (length(unusual) && any(!unusual %in% c(8, 10))) add_failure(model_id, "manual RR8/10 prior contains active non-default penalties other than 8 or 10.")
    }
    if (grepl("PTTP", paste(rr_prior, token), ignore.case = TRUE)) {
      required_targets <- c(49.62, 51.21, 52.82)
      if (!all(required_targets %in% as.numeric(target))) add_failure(model_id, "PTTP RR matrices are missing exact targets 49.62, 51.21, and 52.82.")
    }

    current_tag_sensitivity_ids <- c(
      "S02-F33Asymptotic-MIX015",
      "S03-CommonTagTau-MIX015",
      "S04-CommonTagTauSpline-MIX015",
      "S05-CommonTagTauOPR-MIX015",
      "S06-CommonTagTauSplineOPR-MIX015"
    )
    if (model_id %in% current_tag_sensitivity_ids) {
      expected_ini_sha256 <-
        "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a"
      if (!identical(sha256_file(ini_path), expected_ini_sha256)) {
        add_failure(
          model_id,
          paste0(
            "final sensitivity INI drift: expected frozen SC22-IP10 K=0.15 ",
            "and RR specification SHA256 ", expected_ini_sha256, "."
          )
        )
      }
      expected_active_groups <- c(
        1L, 6L, 7L, 10L, 13L, 14L, 17L, 18L, 19L, 20L, 23L, 29L
      )
      actual_active_groups <- sort(unique(as.integer(groups[active_cells])))
      if (!identical(actual_active_groups, expected_active_groups)) {
        add_failure(
          model_id,
          paste0(
            "active RR groups must remain the 12 audited groups ",
            paste(expected_active_groups, collapse = ", "), "; found ",
            paste(actual_active_groups, collapse = ", "), "."
          )
        )
      }
      expected_rr_values <- list(
        mean = c(0.4962, 0.5, 0.5121, 0.5282),
        target = c(49.62, 50, 51.21, 52.82),
        penalty = c(1, 231.2, 354.5, 739.2)
      )
      actual_rr_values <- list(
        mean = sort(unique(as.numeric(means[active_cells]))),
        target = sort(unique(as.numeric(target[active_cells]))),
        penalty = sort(unique(as.numeric(penalty[active_cells])))
      )
      for (field in names(expected_rr_values)) {
        if (!isTRUE(all.equal(
          actual_rr_values[[field]],
          sort(expected_rr_values[[field]]),
          tolerance = 1e-12,
          check.attributes = FALSE
        ))) {
          add_failure(
            model_id,
            paste0(
              "active RR ", field, " values differ from the audited SC22-IP10 ",
              "specification."
            )
          )
        }
      }
    }

    if (is.finite(major_number) && major_number >= 6L) {
      release_programs <- tag_release_programs(read_text(tag_path), tag_path)
      program_rows <- c(release_programs, "PTTP")
      expected_matrices <- expected_rr_matrices(
        program_rows, release_programs, tag_path, model_id
      )
      rr_by_field <- list(
        initial = rr[["tag fish rep"]],
        group = rr[["tag fish rep group flags"]],
        active = rr[["tag_fish_rep active flags"]],
        target = rr[["tag_fish_rep target"]],
        penalty = rr[["tag_fish_rep penalty"]]
      )
      if (length(release_programs) && length(expected_matrices)) {
        for (field in names(rr_by_field)) {
          expected_matrix <- expected_matrices[[field]]
          actual_matrix <- rr_by_field[[field]]
          if (!identical(dim(actual_matrix), dim(expected_matrix)) ||
              !isTRUE(all.equal(
                unname(actual_matrix), unname(expected_matrix),
                tolerance = 1e-12, check.attributes = FALSE
              ))) {
            add_failure(
              model_id,
              paste0(
                "reporting-rate ", field,
                " matrix does not match the audited fishery/program mapping implied by bet.tag."
              )
            )
          }
        }
      }

      if (any(flags$scope == -9999L & flags$flag == 1L)) {
        add_failure(
          model_id,
          "doitall.sh must not override the release-specific tag/reporting map held in bet.ini."
        )
      }

      tag_map_path <- file.path(model_dir, "tag_rep_map.R")
      if (!file.exists(tag_map_path)) {
        add_failure(model_id, "missing generated tag_rep_map.R reporting-rate audit.")
      } else {
        tag_map_env <- new.env(parent = baseenv())
        loaded <- tryCatch(
          {
            sys.source(tag_map_path, envir = tag_map_env)
            TRUE
          },
          error = function(e) {
            add_failure(model_id, paste0("could not load tag_rep_map.R: ", conditionMessage(e)))
            FALSE
          }
        )
        if (loaded) {
          required_map_objects <- c(
            "tag_rep_matrix", "tag_rep_active_matrix",
            "tag_rep_map", "tag_release_map"
          )
          missing_map_objects <- required_map_objects[
            !vapply(required_map_objects, exists, logical(1), envir = tag_map_env, inherits = FALSE)
          ]
          if (length(missing_map_objects)) {
            add_failure(
              model_id,
              paste0("tag_rep_map.R is missing: ", paste(missing_map_objects, collapse = ", "), ".")
            )
          } else {
            if (!isTRUE(all.equal(
              unname(tag_map_env$tag_rep_matrix),
              unname(rr[["tag fish rep group flags"]]),
              tolerance = 1e-12, check.attributes = FALSE
            )) || !isTRUE(all.equal(
              unname(tag_map_env$tag_rep_active_matrix),
              unname(rr[["tag_fish_rep active flags"]]),
              tolerance = 1e-12, check.attributes = FALSE
            ))) {
              add_failure(model_id, "tag_rep_map.R numeric matrices differ from bet.ini.")
            }
            map_programs <- toupper(trimws(as.character(tag_map_env$tag_release_map$tag_program)))
            if (!identical(map_programs, release_programs)) {
              add_failure(model_id, "tag_rep_map.R release programmes differ from bet.tag.")
            }
            group_matrix <- rr[["tag fish rep group flags"]]
            group_table <- tag_map_env$tag_rep_map
            expected_groups <- sort(unique(as.integer(group_matrix)))
            if (anyDuplicated(group_table$tag_rep_group) ||
                !identical(as.integer(group_table$tag_rep_group), expected_groups)) {
              add_failure(model_id, "tag_rep_map.R must contain exactly one row per reporting-rate group.")
            } else {
              for (group_id in expected_groups) {
                table_row <- match(group_id, group_table$tag_rep_group)
                cells <- group_matrix == group_id
                expected_target <- format_rr_map_values(rr[["tag_fish_rep target"]][cells])
                expected_penalty <- format_rr_map_values(rr[["tag_fish_rep penalty"]][cells])
                if (!identical(as.character(group_table$target_values[[table_row]]), expected_target) ||
                    !identical(as.character(group_table$penalty_values[[table_row]]), expected_penalty)) {
                  add_failure(
                    model_id,
                    paste0("tag_rep_map.R target/penalty summary differs from bet.ini for group ", group_id, ".")
                  )
                }
              }
            }
          }
        }
      }
    }
  }

  regional_expected <- grepl("REGW[0-9]+", token) || nzchar(row_value(row, "regional_scaling_weight"))
  if (regional_expected) {
    active_path <- file.path(model_dir, "bet.reg_scaling")
    full_path <- file.path(model_dir, "bet.reg_scaling.full")
    if (!file.exists(active_path) || !file.exists(full_path)) {
      add_failure(model_id, "regional model requires bet.reg_scaling and bet.reg_scaling.full.")
    } else {
      active_lock <- lock_by_role_name("regional_scaling", "ACTIVE20X5")
      full_lock <- lock_by_role_name("regional_scaling", "FULL292X5")
      current_mfcl_header <- model_id %in% c(
        "S02-F33Asymptotic-MIX015",
        "S03-CommonTagTau-MIX015",
        "S04-CommonTagTauSpline-MIX015",
        "S05-CommonTagTauOPR-MIX015",
        "S06-CommonTagTauSplineOPR-MIX015"
      )
      if (current_mfcl_header) {
        active_lines <- readLines(active_path, warn = FALSE)
        full_lines <- readLines(full_path, warn = FALSE)
        if (length(active_lines) != 21L ||
            !identical(trimws(active_lines[[1L]]), "1965 2 1969 11") ||
            !identical(active_lines[-1L], full_lines[53:72])) {
          add_failure(
            model_id,
            paste0(
              "current MFCL regional-scaling input must contain header ",
              "`1965 2 1969 11` followed by the locked active periods 53-72."
            )
          )
        }
      } else if (!is.null(active_lock) &&
                 !identical(
                   sha256_file(active_path),
                   trim_character(active_lock$prepared_sha256[[1L]])
                 )) {
        add_failure(model_id, "active regional-scaling SHA256 differs from the locked 20x5 matrix.")
      }
      if (!is.null(full_lock) && !identical(sha256_file(full_path), trim_character(full_lock$prepared_sha256[[1L]]))) add_failure(model_id, "full regional-scaling SHA256 differs from the locked 292x5 matrix.")
    }
    regw <- suppressWarnings(as.numeric(row_value(row, "regional_scaling_weight", sub(".*REGW([0-9]+).*", "\\1", token))))
    if (is.finite(regw)) {
      check_flag(flags, 1L, 77L, regw, model_id, "regional-scaling weight")
      check_flag(flags, 1L, 78L, 1L, model_id, "mean regional-scaling target")
      check_flag(flags, 1L, 79L, 240L, model_id, "regional-scaling start offset")
      check_flag(flags, 1L, 80L, 220L, model_id, "regional-scaling end offset")
      check_flag(flags, 1L, 81L, 1L, model_id, "multivariate-normal regional-scaling penalty")
    }
    for (pair in list(c(78, 1), c(79, 240), c(80, 220), c(81, 1))) check_flag(flags, 1L, pair[[1L]], pair[[2L]], model_id, "regional-scaling window/control")
    phase1_cpue <- vapply(
      29:33, function(fishery) effective_flag_at_phase(flags, -fishery, 99L, 1L),
      numeric(1)
    )
    phase5_cpue <- vapply(
      29:33, function(fishery) effective_flag_at_phase(flags, -fishery, 99L, 5L),
      numeric(1)
    )
    phase1_sigma_groups <- vapply(
      29:33, function(fishery) effective_flag_at_phase(flags, -fishery, 94L, 1L),
      numeric(1)
    )
    phase5_sigma_groups <- vapply(
      29:33, function(fishery) effective_flag_at_phase(flags, -fishery, 94L, 5L),
      numeric(1)
    )
    if (!identical(as.numeric(phase1_cpue), rep(29, 5L))) {
      add_failure(model_id, paste0("phase-1 regional CPUE groups must all be 29; found ", paste(phase1_cpue, collapse = " "), "."))
    }
    if (!identical(as.numeric(phase5_cpue), as.numeric(29:33))) {
      add_failure(model_id, paste0("phase-5 regional CPUE groups must be 29:33; found ", paste(phase5_cpue, collapse = " "), "."))
    }
    if (!identical(as.numeric(phase1_sigma_groups), rep(1, 5L)) ||
        !identical(as.numeric(phase5_sigma_groups), rep(0, 5L))) {
      add_failure(
        model_id,
        paste0(
          "regional CPUE flag 94 must use fishery-specific flag-92 scales in the shared staged-run-1 group and revert after separate flag-99 groups are introduced in staged run 5; found ",
          paste(phase1_sigma_groups, collapse = " "), " -> ",
          paste(phase5_sigma_groups, collapse = " "), "."
        )
      )
    }
  }

  dom_expected <- identical(model_id, "20a-DOMDiv200") ||
    grepl("DW10|DOM200", token) ||
    identical(row_value(row, "lf_size_divisor"), "200") ||
    identical(row_value(row, "dom_lf_divisor"), "200")
  dom_200 <- flags$scope <= -1L & flags$scope >= -998L & flags$flag == 49L & flags$value == 200
  dom_200_fisheries <- sort(unique(abs(flags$scope[dom_200])))
  if (length(dom_200_fisheries) && !identical(dom_200_fisheries, 21:23)) {
    missing_dom <- setdiff(21:23, dom_200_fisheries)
    extra_dom <- setdiff(dom_200_fisheries, 21:23)
    details <- c(
      if (length(missing_dom)) paste0("missing F", paste(missing_dom, collapse = ", F")) else character(),
      if (length(extra_dom)) paste0("unexpected F", paste(extra_dom, collapse = ", F")) else character()
    )
    add_failure(
      model_id,
      paste0("LF divisor 200 must apply to exactly DOM F21-F23; ", paste(details, collapse = "; "), ".")
    )
  }
  if (dom_expected) {
    for (fishery in 21:23) check_flag(flags, -fishery, 49L, 200, model_id, "DOM F21-F23 only")
  }

  sigma_expected <- truthy(row_value(row, "fixed_cpue_sigma"))
  if (sigma_expected) {
    sigma_lock <- lock_by_role_name("cpue_mle_sigma", "JOB13328_R1_R5")
    sigma_values <- if (!is.null(sigma_lock)) suppressWarnings(as.numeric(strsplit(sigma_lock$expected_values[[1L]], ";", fixed = TRUE)[[1L]])) else numeric()
    if (length(sigma_values) != 5L || any(!is.finite(sigma_values))) {
      add_failure(model_id, "CPUE observation-error lock must provide five R1-R5 expected_values.")
    } else {
      for (j in seq_len(5L)) check_flag(flags, -(28L + j), 92L, sigma_values[[j]], model_id, paste0("CPUE observation-error scale R", j))
    }
    if (is.null(sigma_lock) || !identical(trim_character(sigma_lock$job_id[[1L]]), "13328")) add_failure(model_id, "CPUE observation-error provenance must identify Job 13328.")
  }

  grouping <- toupper(row_value(row, "dm_grouping"))
  if (grouping == "G8PSSET" || grepl("G8PSSET", token)) {
    actual <- vapply(1:33, function(fishery) effective_flag(flags, -fishery, 68L), numeric(1))
    if (any(!is.finite(actual)) || !identical(as.numeric(actual), as.numeric(g8_expected))) {
      add_failure(model_id, paste0("G8PSSET mapping must be exactly `", paste(g8_expected, collapse = " "), "`; found `", paste(actual, collapse = " "), "`."))
    }
  }

  expected_tag_weight <- c(
    "22a-R1F2F3F29Shared-MIX015-TAGW500" = 500,
    "22b-R1F2F3F29Shared-MIX015-TAGW250" = 250,
    "22c-R1F2F3F29Shared-MIX005-TAGW500" = 500,
    "22d-R1F2F3F29Shared-MIX005-TAGW250" = 250
  )
  if (model_id %in% names(expected_tag_weight)) {
    for (phase in c(1L, 5L, 11L)) {
      actual_weight <- effective_flag_at_phase(flags, 1L, 177L, phase)
      if (!identical(
        as.numeric(actual_weight),
        as.numeric(expected_tag_weight[[model_id]])
      )) {
        add_failure(
          model_id,
          paste0(
            "parest flag 177 must remain ",
            expected_tag_weight[[model_id]],
            " through Phase ", phase, "; found ", actual_weight, "."
          )
        )
      }
    }
    check_flag(
      flags, 2L, 177L, 1L, model_id,
      "age flag 177 old total-population scaling remains unchanged"
    )
  }

  n7_expected <- selectivity_expected
  if (n7_expected) {
    selectivity_stability <- model_id %in% c(
      "S01-SelectivityStability-MIX015",
      "S02-F33Asymptotic-MIX015",
      "S03-CommonTagTau-MIX015",
      "S04-CommonTagTauSpline-MIX015",
      "S05-CommonTagTauOPR-MIX015",
      "S06-CommonTagTauSplineOPR-MIX015"
    )
    f33_asymptotic <- model_id %in% c(
      "S02-F33Asymptotic-MIX015",
      "S03-CommonTagTau-MIX015",
      "S05-CommonTagTauOPR-MIX015"
    )
    r1_shared_selectivity <- model_id %in% c(
      "21a-R1F2F3F29Shared-MIX015",
      "21b-R1F2F3F29Shared-MIX005",
      "22a-R1F2F3F29Shared-MIX015-TAGW500",
      "22b-R1F2F3F29Shared-MIX015-TAGW250",
      "22c-R1F2F3F29Shared-MIX005-TAGW500",
      "22d-R1F2F3F29Shared-MIX005-TAGW250"
    )
    phase1_groups <- vapply(
      1:33, function(fishery) effective_flag_at_phase(flags, -fishery, 24L, 1L),
      numeric(1)
    )
    phase5_groups <- vapply(
      1:33, function(fishery) effective_flag_at_phase(flags, -fishery, 24L, 5L),
      numeric(1)
    )
    expected_r1_shared <- c(1, 2, 2, 3:27, 2, 3, 6, 7, 28)
    expected_stability <- c(
      1, 2, 2, 3, 4, 5, 6, 7, 6, 8, 9, 10, 11, 12, 13, 14,
      15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
      27, 28, 29, 30, 31
    )
    expected_phase1 <- if (selectivity_stability) {
      expected_stability
    } else if (r1_shared_selectivity) {
      expected_r1_shared
    } else {
      c(1:28, rep(29, 5L))
    }
    expected_phase5 <- if (selectivity_stability) {
      expected_stability
    } else if (r1_shared_selectivity) {
      expected_r1_shared
    } else {
      1:33
    }
    if (!identical(as.numeric(phase1_groups), as.numeric(expected_phase1))) {
      add_failure(
        model_id,
        paste0(
          "phase-1 selectivity grouping must be `", paste(expected_phase1, collapse = " "),
          "`; found `", paste(phase1_groups, collapse = " "), "`."
        )
      )
    }
    if (!identical(as.numeric(phase5_groups), as.numeric(expected_phase5))) {
      add_failure(
        model_id,
        paste0(
          "phase-5 effective selectivity grouping must be `",
          paste(expected_phase5, collapse = " "),
          "`; found `",
          paste(phase5_groups, collapse = " "), "`."
        )
      )
    }
    check_flag(
      flags, -999L, 26L, 2L, model_id,
      "age-based selectivity evaluated against scaled mean length-at-age"
    )
    check_flag(flags, -999L, 57L, 3L, model_id, "common cubic spline")
    expected_active_form_fisheries <- all_relaxed_fisheries
    if (all_forms_relaxed) {
      expected_active_form_fisheries <- integer()
    }
    actual_active_form_fisheries <- which(vapply(
      1:33,
      function(fishery) identical(effective_flag(flags, -fishery, 16L), 2),
      logical(1)
    ))
    if (!identical(actual_active_form_fisheries, expected_active_form_fisheries)) {
      add_failure(
        model_id,
        paste0(
          "active fishery flag-16 set must be `",
          paste(expected_active_form_fisheries, collapse = " "),
          "`; found `", paste(actual_active_form_fisheries, collapse = " "), "`."
        )
      )
    }
    for (fishery in 25:26) {
      expected_selectivity_group <- if (selectivity_stability) {
        c(`25` = 23L, `26` = 24L)[[as.character(fishery)]]
      } else if (r1_shared_selectivity) {
        fishery - 1L
      } else {
        fishery
      }
      check_flag(
        flags, -fishery, 3L, 25L, model_id,
        paste0("F", fishery, " last age class with non-zero dome selectivity")
      )
      check_flag(
        flags, -fishery, 24L, expected_selectivity_group, model_id,
        paste0("F", fishery, " independent selectivity group")
      )
      expected_form_flag <- if (all_forms_relaxed) 0L else 2L
      expected_nodes <- 7L
      for (pair in list(
        c(61, expected_nodes), c(16, expected_form_flag), c(75, 0)
      )) {
        check_flag(flags, -fishery, pair[[1L]], pair[[2L]], model_id, paste0("F", fishery, " N7 selectivity"))
      }
    }
    if (all_forms_relaxed) {
      for (fishery in all_relaxed_fisheries) {
        check_flag(
          flags, -fishery, 16L, 0L, model_id,
          paste0("F", fishery, " selected all-relaxed selectivity form")
        )
      }
    }
    if (selectivity_stability) {
      four_node_fisheries <- c(1L, 2L, 3L, 5L, 29L)
      if (!f33_asymptotic) four_node_fisheries <- c(four_node_fisheries, 33L)
      for (fishery in four_node_fisheries) {
        check_flag(
          flags, -fishery, 61L, 4L, model_id,
          paste0("F", fishery, " selectivity-stability four-node curve")
        )
      }
      for (fishery in c(25L, 26L)) {
        check_flag(
          flags, -fishery, 61L, 7L, model_id,
          paste0("F", fishery, " retained seven-node curve")
        )
      }
      for (fishery in 29:33) {
        check_flag(
          flags, -fishery, 99L, fishery, model_id,
          paste0("F", fishery, " index catchability remains independent")
        )
      }
      if (f33_asymptotic) {
        check_flag(
          flags, -33L, 57L, 1L, model_id,
          "F33 independent asymptotic logistic selectivity"
        )
        if (any(flags$scope == -33L & flags$flag == 61L)) {
          add_failure(
            model_id,
            "F33 logistic sensitivity must not retain a fish-specific spline-node override."
          )
        }
      } else {
        check_flag(
          flags, -33L, 57L, 3L, model_id,
          "F33 independent cubic-spline reference selectivity"
        )
      }
    }
    if (r1_shared_selectivity) {
      for (fishery in c(1L, 2L, 3L, 5L, 29L, 33L)) {
        check_flag(
          flags, -fishery, 61L, 4L, model_id,
          paste0("F", fishery, " Job 15984 four-node selectivity")
        )
      }
      check_flag(
        flags, -29L, 99L, 29L, model_id,
        "F29 index catchability remains independent"
      )
    }
    if (r1_shared_selectivity || selectivity_stability) {
      for (phase in c(1L, 10L, 11L)) {
        if (!identical(effective_flag_at_phase(flags, 1L, 121L, phase), 0)) {
          add_failure(
            model_id,
            paste0("Lorenzen M must remain fixed in Phase ", phase, ".")
          )
        }
      }
    }
  }

  nmax_label <- regmatches(token, regexpr("NMAX[0-9]+", token))
  nmax_from_label <- if (length(nmax_label) && nzchar(nmax_label)) suppressWarnings(as.numeric(sub("NMAX", "", nmax_label))) else NA_real_
  nmax_config <- suppressWarnings(as.numeric(row_value(row, "dm_nmax")))
  nmax_values <- unique(flag_values(flags, 1L, 342L))
  if (is.finite(nmax_config) && is.finite(nmax_from_label) && nmax_config != nmax_from_label) add_failure(model_id, paste0("Nmax label says ", nmax_from_label, " but job-config says ", nmax_config, "."))
  expected_nmax <- if (is.finite(nmax_config)) nmax_config else nmax_from_label
  runtime_nmax <- model_id %in% common_tau_models
  if (runtime_nmax &&
      sum(trimws(doitall) == "1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound") != 1L) {
    add_failure(model_id, "runtime Nmax model must set parest flag 342 exactly once from DM_NMAX.")
  }
  if (!runtime_nmax && is.finite(expected_nmax) &&
      (length(nmax_values) == 0L || any(nmax_values != expected_nmax))) {
    add_failure(model_id, paste0("Nmax label/config requires parest flag 342=", expected_nmax, "; found ", paste(nmax_values, collapse = ", "), "."))
  }

  manifest <- if (file.exists(manifest_path)) {
    tryCatch(utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = character()), error = function(e) data.frame())
  } else data.frame()
  manifest_columns <- c("role", "file", "source_repository", "source_commit", "source_path", "source_sha256", "sha256", "source_access", "provenance_status")
  missing_manifest_columns <- setdiff(manifest_columns, names(manifest))
  if (length(missing_manifest_columns)) {
    add_failure(model_id, paste0("input_manifest.csv lacks deterministic provenance columns: ", paste(missing_manifest_columns, collapse = ", "), ". Re-run make prepare."))
  } else {
    input_rows <- manifest$file %in% required_files | manifest$file %in% c("bet.reg_scaling", "bet.reg_scaling.full")
    for (j in which(input_rows)) {
      record <- manifest[j, , drop = FALSE]
      target <- file.path(model_dir, record$file[[1L]])
      if (!file.exists(target)) next
      actual <- sha256_file(target)
      if (!identical(trim_character(record$sha256[[1L]]), actual)) add_failure(model_id, paste0(record$file[[1L]], " SHA256 does not match input_manifest.csv."))
      public_source <- identical(trim_character(record$source_access[[1L]]), "public") &&
        identical(trim_character(record$provenance_status[[1L]]), "locked")
      if (public_source &&
          (!is_public_repo(record$source_repository[[1L]]) ||
           !is_commit(record$source_commit[[1L]]) ||
           !is_sha(record$source_sha256[[1L]]))) {
        add_failure(model_id, paste0(record$file[[1L]], " public source needs exact repository/full commit/path/SHA256."))
      }
    }
    if (sigma_expected && sum(manifest$role == "cpue_mle_sigma") != 1L) {
      add_failure(model_id, "input_manifest.csv must contain exactly one `cpue_mle_sigma` provenance row after its introduction.")
    }
  }

  model_cache[[model_id]] <- list(
    row = row,
    token = token,
    model_dir = model_dir,
    ini = ini,
    doitall = doitall,
    flags = flags,
    tag_flags = tag_flags,
    hashes = setNames(vapply(required_files, function(file) sha256_file(file.path(model_dir, file)), character(1)), required_files)
  )
}

## Step 02 is executable-only: its source inputs and scientific controls must
## match Step 01. Steps 03-05 inherit the Step 01 CPUE and initial-Z controls.
early_control_ids <- c(
  "01-Diag2023", "02-NewExe1003", "03-Ini1007",
  "04-FixM", "05-LengthWeight"
)
available_early_ids <- early_control_ids[early_control_ids %in% names(model_cache)]
if ("01-Diag2023" %in% available_early_ids) {
  anchor <- model_cache[["01-Diag2023"]]
  expected_cpue_flag92 <- c(88, 53, 130, 109, 76, 93, 121, 77, 23)
  anchor_cpue_flag92 <- vapply(
    33:41,
    function(fishery) effective_flag_at_phase(anchor$flags, -fishery, 92L, 1L),
    numeric(1)
  )
  if (!identical(as.numeric(anchor_cpue_flag92), as.numeric(expected_cpue_flag92))) {
    add_failure(
      "01-Diag2023",
      paste0(
        "audited F33-F41 CPUE flag-92 anchor must be `",
        paste(expected_cpue_flag92, collapse = " "),
        "`; found `", paste(anchor_cpue_flag92, collapse = " "), "`."
      )
    )
  }
  for (model_id in available_early_ids) {
    cached <- model_cache[[model_id]]
    cpue_flag92 <- vapply(
      33:41,
      function(fishery) effective_flag_at_phase(cached$flags, -fishery, 92L, 1L),
      numeric(1)
    )
    if (!identical(as.numeric(cpue_flag92), as.numeric(anchor_cpue_flag92))) {
      add_failure(
        model_id,
        paste0(
          "F33-F41 CPUE flag-92 controls must inherit Step 01 unchanged; found `",
          paste(cpue_flag92, collapse = " "), "`."
        )
      )
    }
    initial_z <- initial_z_control_value(cached$doitall)
    if (!is.finite(initial_z) || initial_z != 10) {
      add_failure(
        model_id,
        paste0(
          "global `2 94 1 2 128` control must inherit Step 01 value 10; found ",
          if (is.finite(initial_z)) initial_z else "missing/ambiguous", "."
        )
      )
    }
  }
  if ("02-NewExe1003" %in% available_early_ids) {
    executable_step <- model_cache[["02-NewExe1003"]]
    for (file in c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "mfcl.cfg")) {
      if (!identical(anchor$hashes[[file]], executable_step$hashes[[file]])) {
        add_failure(
          "02-NewExe1003",
          paste0("executable-only isolation changed ", file, " relative to Step 01.")
        )
      }
    }
    if (!identical(
      scientific_flag_table(anchor$flags),
      scientific_flag_table(executable_step$flags)
    )) {
      add_failure(
        "02-NewExe1003",
        "scientific controls differ from Step 01 outside allowed reporting-only flag 1/246."
      )
    }
  }
}

compare_model_hashes_except <- function(parent_id, child_id, except = character()) {
  parent <- model_cache[[parent_id]]
  child <- model_cache[[child_id]]
  if (is.null(parent) || is.null(child)) return(invisible(NULL))
  files <- setdiff(intersect(names(parent$hashes), names(child$hashes)), except)
  changed <- files[parent$hashes[files] != child$hashes[files]]
  if (length(changed)) {
    add_failure(
      child_id,
      paste0(
        "unexpected file drift from scientific parent ", parent_id, ": ",
        paste(changed, collapse = ", "), "."
      )
    )
  }
  invisible(NULL)
}

sorted_scientific_flags <- function(flags) {
  flags <- scientific_flag_table(flags)
  flags <- flags[order(flags$phase, flags$scope, flags$flag, flags$value), , drop = FALSE]
  rownames(flags) <- NULL
  flags
}

compare_flags_after_filter <- function(parent_id, child_id, remove) {
  parent <- model_cache[[parent_id]]
  child <- model_cache[[child_id]]
  if (is.null(parent) || is.null(child)) return(invisible(NULL))
  parent_flags <- parent$flags[!remove(parent$flags), , drop = FALSE]
  child_flags <- child$flags[!remove(child$flags), , drop = FALSE]
  if (!identical(
    sorted_scientific_flags(parent_flags),
    sorted_scientific_flags(child_flags)
  )) {
    add_failure(
      child_id,
      paste0(
        "scientific controls differ from parent ", parent_id,
        " outside the declared isolated change."
      )
    )
  }
  invisible(NULL)
}

without_numeric_section <- function(lines, label) {
  marker <- which(tolower(trimws(lines)) == paste0("# ", tolower(label)))
  if (length(marker) != 1L) return(lines)
  next_marker <- which(seq_along(lines) > marker & grepl("^#", trimws(lines)))
  end <- if (length(next_marker)) next_marker[[1L]] - 1L else length(lines)
  c(
    lines[seq_len(marker)],
    paste0("<validated ", label, " section>"),
    if (end < length(lines)) lines[(end + 1L):length(lines)] else character()
  )
}

compare_ini_outside_section <- function(parent_id, child_id, label) {
  parent <- model_cache[[parent_id]]
  child <- model_cache[[child_id]]
  if (is.null(parent) || is.null(child)) return(invisible(NULL))
  if (!identical(
    without_numeric_section(parent$ini, label),
    without_numeric_section(child$ini, label)
  )) {
    add_failure(
      child_id,
      paste0(
        "bet.ini differs from parent ", parent_id,
        " outside the declared `", label, "` section."
      )
    )
  }
  invisible(NULL)
}

# Step 04 changes M only; Step 05 changes length-weight only while carrying M.
compare_model_hashes_except("03-Ini1007", "04-FixM", c("bet.ini", "doitall.sh"))
compare_ini_outside_section("03-Ini1007", "04-FixM", "age_pars")
compare_flags_after_filter(
  "03-Ini1007", "04-FixM",
  function(flags) flags$scope == 1L & flags$flag == 121L
)
compare_model_hashes_except("04-FixM", "05-LengthWeight", "bet.ini")
compare_ini_outside_section(
  "04-FixM", "05-LengthWeight", "Length-weight parameters"
)

# Step 09 changes only LF tail percentage 313 from 0 to 1.
compare_model_hashes_except(
  "08-AddLengthData", "09-TailCompression1Pct", "doitall.sh"
)
compare_flags_after_filter(
  "08-AddLengthData", "09-TailCompression1Pct",
  function(flags) flags$scope == 1L & flags$flag == 313L
)

# Step 12 changes only the time-varying CPUE relative-variance controls.
compare_model_hashes_except(
  "11-RegionalCPUE", "12-TimeVaryingCV", "doitall.sh"
)
compare_flags_after_filter(
  "11-RegionalCPUE", "12-TimeVaryingCV",
  function(flags) {
    (flags$scope %in% -(29:33) & flags$flag == 66L) |
      (flags$scope == 1L & flags$flag == 66L)
  }
)

# Step 13 changes only the five CPUE observation-error scales and adds their
# preliminary maximum-likelihood audit record.
compare_model_hashes_except(
  "12-TimeVaryingCV", "13-CPUEErrorCalibration",
  c("doitall.sh", "cpue_mle_sigma_audit.csv")
)
compare_flags_after_filter(
  "12-TimeVaryingCV", "13-CPUEErrorCalibration",
  function(flags) flags$scope %in% -(29:33) & flags$flag == 92L
)

# Step 14 changes only the age-data input, using BASE075 as the common
# reference state. Step 15 siblings then change only that same input.
compare_model_hashes_except(
  "13-CPUEErrorCalibration", "14-NewAgeData", "bet.age_length"
)
compare_model_hashes_except(
  "14-NewAgeData", "15a-REG075", "bet.age_length"
)
compare_model_hashes_except(
  "14-NewAgeData", "15b-SUB075", "bet.age_length"
)

# Step 16 changes only the executable selectivity controls and their
# human-readable fishery grouping sidecar; every other carried input is exact.
compare_model_hashes_except(
  "15b-SUB075", "16-SelectivityUpdate",
  c("doitall.sh", "fishery_map.R")
)

# Step 17 changes only release-group mixing periods in tag-flag column 1.
compare_model_hashes_except(
  "16-SelectivityUpdate", "17-MIX015", "bet.ini"
)
compare_ini_outside_section(
  "16-SelectivityUpdate", "17-MIX015", "tag flags"
)

# Step 18 excludes reporting rates only within the pre-mixing windows while
# retaining the Step 17 mixing periods. Step 19 then applies effort creep only to the
# frequency file. Step 20 branches change only their declared weighting controls.
compare_model_hashes_except(
  "17-MIX015", "18-TagReportingExclusion", "bet.ini"
)
compare_model_hashes_except(
  "18-TagReportingExclusion", "19-EffortCreep", "bet.frq"
)
compare_ini_outside_section(
  "17-MIX015", "18-TagReportingExclusion", "tag flags"
)

compare_tag_flag_boundary <- function(
    parent_id, child_id, changed_column, description) {
  parent <- model_cache[[parent_id]]
  child <- model_cache[[child_id]]
  if (is.null(parent) || is.null(child)) return(invisible(NULL))
  parent_flags <- parent$tag_flags
  child_flags <- child$tag_flags
  if (is.null(parent_flags) || is.null(child_flags) ||
      !identical(dim(parent_flags), dim(child_flags))) {
    add_failure(child_id, paste0(description, " changed the tag-flag matrix shape."))
    return(invisible(NULL))
  }
  parent_flags[, changed_column] <- 0
  child_flags[, changed_column] <- 0
  if (!identical(parent_flags, child_flags)) {
    add_failure(
      child_id,
      paste0(description, " differs from ", parent_id,
             " outside tag_flags(:,", changed_column, ").")
    )
  }
  invisible(NULL)
}
compare_tag_flag_boundary(
  "16-SelectivityUpdate", "17-MIX015", 1L,
  "Step 17 release-group-specific mixing-period change"
)
compare_tag_flag_boundary(
  "17-MIX015", "18-TagReportingExclusion", 2L,
  "Step 18 pre-mixing reporting-rate treatment"
)

compare_model_hashes_except(
  "19-EffortCreep", "20a-DOMDiv200", "doitall.sh"
)
compare_flags_after_filter(
  "19-EffortCreep", "20a-DOMDiv200",
  function(flags) flags$scope %in% -(21:23) & flags$flag == 49L
)
compare_model_hashes_except(
  "19-EffortCreep", "20b-Francis", "doitall.sh"
)
compare_flags_after_filter(
  "19-EffortCreep", "20b-Francis",
  function(flags) flags$scope <= -1L & flags$scope >= -33L & flags$flag == 49L
)
compare_model_hashes_except(
  "19-EffortCreep", "20c-DMG8Nmax25", "doitall.sh"
)
compare_flags_after_filter(
  "19-EffortCreep", "20c-DMG8Nmax25",
  function(flags) {
    (flags$scope == 1L & flags$flag %in% c(141L, 313L, 320L, 342L)) |
      (flags$scope <= -1L & flags$scope >= -33L & flags$flag == 68L) |
      (flags$scope == -999L & flags$flag %in% c(69L, 89L))
  }
)
compare_model_hashes_except(
  "20c-DMG8Nmax25",
  "21a-R1F2F3F29Shared-MIX015",
  "doitall.sh"
)
compare_flags_after_filter(
  "20c-DMG8Nmax25",
  "21a-R1F2F3F29Shared-MIX015",
  function(flags) {
    (flags$scope <= -1L & flags$scope >= -33L & flags$flag == 24L) |
      (flags$scope %in% -c(1L, 2L, 3L, 5L, 29L, 33L) &
         flags$flag == 61L)
  }
)
compare_model_hashes_except(
  "21a-R1F2F3F29Shared-MIX015",
  "S01-SelectivityStability-MIX015",
  "doitall.sh"
)
compare_flags_after_filter(
  "21a-R1F2F3F29Shared-MIX015",
  "S01-SelectivityStability-MIX015",
  function(flags) {
    flags$scope <= -1L & flags$scope >= -33L & flags$flag == 24L
  }
)
compare_model_hashes_except(
  "S01-SelectivityStability-MIX015",
  "S02-F33Asymptotic-MIX015",
  c("doitall.sh", "fishery_map.R")
)
compare_flags_after_filter(
  "S01-SelectivityStability-MIX015",
  "S02-F33Asymptotic-MIX015",
  function(flags) {
    flags$scope == -33L & flags$flag %in% c(57L, 61L)
  }
)
compare_model_hashes_except(
  "S02-F33Asymptotic-MIX015",
  "S03-CommonTagTau-MIX015",
  "doitall.sh"
)
compare_flags_after_filter(
  "S02-F33Asymptotic-MIX015",
  "S03-CommonTagTau-MIX015",
  function(flags) {
    (flags$scope == 1L & flags$flag %in% c(
      1L, 50L, 101L, 111L, 121L, 177L, 239L, 246L, 249L,
      305L, 306L, 342L, 358L
    )) |
      (flags$scope == 2L & flags$flag %in% c(
        100L, 110L, 121L, 122L
      )) |
      (flags$scope <= -1L & flags$scope >= -33L &
         flags$flag %in% c(43L, 44L))
  }
)
compare_model_hashes_except(
  "S01-SelectivityStability-MIX015",
  "S04-CommonTagTauSpline-MIX015",
  "doitall.sh"
)
compare_flags_after_filter(
  "S01-SelectivityStability-MIX015",
  "S04-CommonTagTauSpline-MIX015",
  function(flags) {
    (flags$scope == 1L & flags$flag %in% c(
      1L, 50L, 101L, 111L, 121L, 177L, 239L, 246L, 249L,
      305L, 306L, 342L, 358L
    )) |
      (flags$scope == 2L & flags$flag %in% c(
        100L, 110L, 121L, 122L
      )) |
      (flags$scope <= -1L & flags$scope >= -33L &
         flags$flag %in% c(43L, 44L))
  }
)
compare_model_hashes_except(
  "S03-CommonTagTau-MIX015",
  "S05-CommonTagTauOPR-MIX015",
  "doitall.sh"
)
compare_flags_after_filter(
  "S03-CommonTagTau-MIX015",
  "S05-CommonTagTauOPR-MIX015",
  function(flags) {
    (flags$scope == 1L & flags$flag %in% c(
      1L, 149L, 155L, 202L, 210L, 212L, 214L, 216L, 217L, 218L,
      398L, 400L
    )) |
      (flags$scope == 2L & flags$flag %in% c(
        30L, 32L, 70L, 71L, 113L, 177L, 178L
      )) |
      (flags$scope == -100000L & flags$flag %in% 1:5)
  }
)
compare_model_hashes_except(
  "S04-CommonTagTauSpline-MIX015",
  "S06-CommonTagTauSplineOPR-MIX015",
  "doitall.sh"
)
compare_flags_after_filter(
  "S04-CommonTagTauSpline-MIX015",
  "S06-CommonTagTauSplineOPR-MIX015",
  function(flags) {
    (flags$scope == 1L & flags$flag %in% c(
      1L, 149L, 155L, 202L, 210L, 212L, 214L, 216L, 217L, 218L,
      398L, 400L
    )) |
      (flags$scope == 2L & flags$flag %in% c(
        30L, 32L, 70L, 71L, 113L, 177L, 178L
      )) |
      (flags$scope == -100000L & flags$flag %in% 1:5)
  }
)

stability_id <- "S01-SelectivityStability-MIX015"
stability_map_path <- file.path(root, "config", "selectivity-stability-map.csv")
stability <- model_cache[[stability_id]]
if (is.null(stability)) {
  add_failure(stability_id, "generated model is unavailable for map validation.")
} else if (!file.exists(stability_map_path)) {
  add_failure(stability_id, "missing config/selectivity-stability-map.csv.")
} else {
  stability_map <- tryCatch(
    utils::read.csv(
      stability_map_path,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ),
    error = function(e) {
      add_failure(
        stability_id,
        paste0("could not read selectivity map: ", conditionMessage(e))
      )
      data.frame()
    }
  )
  required_map_columns <- c(
    "fishery", "fishery_name", "selectivity_group", "n_nodes", "role"
  )
  if (!all(required_map_columns %in% names(stability_map))) {
    add_failure(
      stability_id,
      paste0(
        "selectivity map must contain columns: ",
        paste(required_map_columns, collapse = ", "), "."
      )
    )
  } else if (!identical(as.integer(stability_map$fishery), 1:33)) {
    add_failure(stability_id, "selectivity map must contain fisheries 1:33 once and in order.")
  } else {
    configured_groups <- as.integer(stability_map$selectivity_group)
    configured_nodes <- as.integer(stability_map$n_nodes)
    phase1_groups <- vapply(
      1:33,
      function(fishery) effective_flag_at_phase(
        stability$flags, -fishery, 24L, 1L
      ),
      numeric(1)
    )
    phase5_groups <- vapply(
      1:33,
      function(fishery) effective_flag_at_phase(
        stability$flags, -fishery, 24L, 5L
      ),
      numeric(1)
    )
    effective_nodes <- vapply(
      1:33,
      function(fishery) effective_flag(
        stability$flags, -fishery, 61L
      ),
      numeric(1)
    )
    if (!identical(as.integer(phase1_groups), configured_groups) ||
        !identical(as.integer(phase5_groups), configured_groups)) {
      add_failure(
        stability_id,
        "phase-1/phase-5 flag-24 values differ from the documented map."
      )
    }
    if (!identical(as.integer(effective_nodes), configured_nodes)) {
      add_failure(
        stability_id,
        "effective flag-61 node counts differ from the documented map."
      )
    }
    if (!identical(sort(unique(configured_groups)), 1:31)) {
      add_failure(
        stability_id,
        "selectivity groups must be contiguous 1:31."
      )
    }
    shared_sets <- unname(split(1:33, configured_groups))
    shared_sets <- shared_sets[lengths(shared_sets) > 1L]
    shared_sets <- lapply(shared_sets, as.integer)
    expected_shared_sets <- list(c(2L, 3L), c(7L, 9L))
    if (!identical(shared_sets, expected_shared_sets)) {
      add_failure(
        stability_id,
        "only F2/F3 and F7/F9 may share selectivity."
      )
    }
    index_groups <- configured_groups[29:33]
    extraction_groups <- configured_groups[1:28]
    if (anyDuplicated(index_groups) ||
        any(index_groups %in% extraction_groups)) {
      add_failure(
        stability_id,
        "F29-F33 selectivity groups must be mutually independent and separate from extraction fisheries."
      )
    }
  }
}

compare_model_hashes_except(
  "21a-R1F2F3F29Shared-MIX015",
  "21b-R1F2F3F29Shared-MIX005",
  "bet.ini"
)
compare_tag_flag_boundary(
  "21a-R1F2F3F29Shared-MIX015",
  "21b-R1F2F3F29Shared-MIX005",
  1L,
  "SC22-IP10 K=0.15 versus K=0.05 mixing-period sensitivity"
)

tag_weight_parents <- c(
  "22a-R1F2F3F29Shared-MIX015-TAGW500" =
    "21a-R1F2F3F29Shared-MIX015",
  "22b-R1F2F3F29Shared-MIX015-TAGW250" =
    "21a-R1F2F3F29Shared-MIX015",
  "22c-R1F2F3F29Shared-MIX005-TAGW500" =
    "21b-R1F2F3F29Shared-MIX005",
  "22d-R1F2F3F29Shared-MIX005-TAGW250" =
    "21b-R1F2F3F29Shared-MIX005"
)
for (child in names(tag_weight_parents)) {
  parent <- tag_weight_parents[[child]]
  compare_model_hashes_except(parent, child, "doitall.sh")
  compare_flags_after_filter(
    parent,
    child,
    function(flags) flags$scope == 1L & flags$flag == 177L
  )
}

for (pair in list(
  c(
    "22a-R1F2F3F29Shared-MIX015-TAGW500",
    "22c-R1F2F3F29Shared-MIX005-TAGW500"
  ),
  c(
    "22b-R1F2F3F29Shared-MIX015-TAGW250",
    "22d-R1F2F3F29Shared-MIX005-TAGW250"
  )
)) {
  compare_model_hashes_except(pair[[1L]], pair[[2L]], "bet.ini")
  compare_tag_flag_boundary(
    pair[[1L]],
    pair[[2L]],
    1L,
    "matched tag-weight K=0.15 versus K=0.05 sensitivity"
  )
}

## Isolation checks for matched TAGF2 and mixing-period pairs, when configured.
normalise_pair_id <- function(id, dimension) {
  id <- sub("^S[0-9]+-", "", toupper(id))
  if (dimension == "tag") gsub("TAGF2(ON|OFF)", "TAGF2STATE", id)
  else gsub("MIX[0-9]+", "MIXSTATE", id)
}

compare_pair <- function(left, right, dimension) {
  left_cache <- model_cache[[left]]
  right_cache <- model_cache[[right]]
  if (is.null(left_cache) || is.null(right_cache)) return(invisible(NULL))
  if (!identical(left_cache$hashes[["bet.tag"]], right_cache$hashes[["bet.tag"]])) add_failure(paste(left, right, sep = " / "), paste0(dimension, " isolation changed bet.tag."))
  for (file in c("bet.frq", "bet.age_length", "mfcl.cfg", "doitall.sh")) {
    if (!identical(left_cache$hashes[[file]], right_cache$hashes[[file]])) add_failure(paste(left, right, sep = " / "), paste0(dimension, " isolation changed ", file, "."))
  }
  left_flags <- left_cache$tag_flags
  right_flags <- right_cache$tag_flags
  if (is.null(left_flags) || is.null(right_flags) || !identical(dim(left_flags), dim(right_flags))) return(invisible(NULL))
  column <- if (dimension == "TAGF2") 2L else 1L
  left_flags[, column] <- 0
  right_flags[, column] <- 0
  if (!identical(left_flags, right_flags)) add_failure(paste(left, right, sep = " / "), paste0(dimension, " pair differs outside tag_flags(:,", column, ")."))
}

for (dimension in c("tag", "mix")) {
  ids <- names(model_cache)
  if (!length(ids)) next
  keys <- vapply(ids, normalise_pair_id, character(1), dimension = dimension)
  for (key in unique(keys[duplicated(keys)])) {
    members <- ids[keys == key]
    if (length(members) == 2L) compare_pair(members[[1L]], members[[2L]], if (dimension == "tag") "TAGF2" else "MIX")
  }
}

if (length(failures)) {
  cat("STEPWISE INPUT VALIDATION FAILED\n")
  cat(paste0("Found ", length(failures), " actionable failure(s):\n"))
  cat(paste0(seq_along(failures), ". ", failures, "\n"), sep = "")
  cat("No MFCL fit was attempted.\n")
  quit(save = "no", status = 1L)
}

cat(
  "STEPWISE INPUT VALIDATION PASSED\n",
  "Configured folders: ", nrow(models), "\n",
  "Provenance lock: ", lock_path, "\n",
  "No MFCL fit was attempted.\n",
  sep = ""
)
