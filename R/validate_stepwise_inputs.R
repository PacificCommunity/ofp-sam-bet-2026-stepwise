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
if ("enabled" %in% names(models)) models <- models[truthy(models$enabled), , drop = FALSE]

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
missing_ids <- setdiff(models$step_id, actual_ids)
extra_ids <- setdiff(actual_ids, models$step_id)
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
fitted_lock <- job_record("fitted_source", 13328L)
hessian_lock <- job_record("hessian_merge", 13432L)
if (!is.null(fitted_lock) && !is.null(hessian_lock) &&
    identical(tolower(trim_character(fitted_lock$status)), "locked") &&
    identical(tolower(trim_character(hessian_lock$status)), "locked") &&
    identical(trim_character(fitted_lock$repository_commit), trim_character(hessian_lock$repository_commit)) &&
    identical(trim_character(fitted_lock$repository_path), trim_character(hessian_lock$repository_path)) &&
    identical(trim_character(fitted_lock$source_sha256), trim_character(hessian_lock$source_sha256))) {
  add_failure("provenance", "Job13328 fitted source and Job13432 Hessian merge resolve to the same artifact; the roles must remain distinct.")
}

lock_by_role_name <- function(role, name = NULL) {
  if (!nrow(lock) || !"role" %in% names(lock)) return(NULL)
  hit <- lock$role == role
  if (!is.null(name) && "name" %in% names(lock)) hit <- hit & toupper(lock$name) == toupper(name)
  if (sum(hit) == 1L) lock[hit, , drop = FALSE] else NULL
}

age_column <- first_column(models, c("age_length_variant", "age_variant", "caal_variant"))
if (!nzchar(age_column)) add_failure("job-config", "age variants require an `age_length_variant` (or alias) column.")

semantic_columns <- c("tag_flag2", "dm_grouping", "dm_nmax", "regional_scaling_weight", "reporting_rate_prior")
for (column in semantic_columns) {
  if (!column %in% names(models)) add_failure("job-config", paste0("missing semantic validation column `", column, "`."))
}

required_files <- c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "doitall.sh", "mfcl.cfg")
g8_expected <- c(1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 3, 7, 6, 6, 7, 3, 3, 4, 5, 7, 7, 7, 7, 4, 4, 5, 5, 8, 8, 8, 8, 8)
rr_signatures <- list()
model_cache <- list()

for (i in seq_len(nrow(models))) {
  row <- models[i, , drop = FALSE]
  model_id <- row$step_id[[1L]]
  major_number <- suppressWarnings(as.integer(sub("[^0-9].*$", "", model_id)))
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

  if (length(ini)) {
    first_value <- suppressWarnings(as.integer(trimws(ini[which(nzchar(trimws(ini)) & !grepl("^#", trimws(ini)))[[1L]]])))
    expected_version <- if (model_id %in% c("01-Diag2023", "02a-NewExe1003")) 1003L else 1007L
    if (!is.finite(first_value) || first_value != expected_version) {
      add_failure(model_id, paste0("bet.ini must be MFCL ", expected_version, "; found ", if (is.finite(first_value)) first_value else "unreadable", "."))
    }
    if (is.finite(major_number) && major_number >= 3L) {
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
            " from step 03 onward; found ", found, "."
          )
        )
      }
    }
  }

  tag_lock <- lock_by_role_name("tag_source", "LOW_RECAPS_REMOVED")
  if (is.finite(major_number) && major_number >= 7L && !is.null(tag_lock) && file.exists(tag_path)) {
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
  if (grepl("MIX015", token)) {
    if (!length(tag_flags) || length(unique(tag_flags[, 1L])) < 2L) add_failure(model_id, "MIX015 requires release-specific mixing periods in bet.ini.")
    override <- flags$scope == -9999L & flags$flag == 1L
    if (any(override)) add_failure(model_id, "MIX015 rollback: doitall.sh overrides release-specific INI mixing periods with -9999 flag 1.")
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
      if (!is.null(active_lock) && !identical(sha256_file(active_path), trim_character(active_lock$prepared_sha256[[1L]]))) add_failure(model_id, "active regional-scaling SHA256 differs from the locked 20x5 matrix.")
      if (!is.null(full_lock) && !identical(sha256_file(full_path), trim_character(full_lock$prepared_sha256[[1L]]))) add_failure(model_id, "full regional-scaling SHA256 differs from the locked 292x5 matrix.")
    }
    regw <- suppressWarnings(as.numeric(row_value(row, "regional_scaling_weight", sub(".*REGW([0-9]+).*", "\\1", token))))
    if (is.finite(regw)) check_flag(flags, 1L, 77L, regw, model_id, "regional-scaling weight")
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

  dom_expected <- grepl("DW10|DOM200", token) || identical(row_value(row, "lf_size_divisor"), "200") || identical(row_value(row, "dom_lf_divisor"), "200")
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

  sigma_expected <- is.finite(major_number) && major_number >= 14L
  if (sigma_expected) {
    sigma_lock <- lock_by_role_name("cpue_mle_sigma", "JOB13328_R1_R5")
    sigma_values <- if (!is.null(sigma_lock)) suppressWarnings(as.numeric(strsplit(sigma_lock$expected_values[[1L]], ";", fixed = TRUE)[[1L]])) else numeric()
    if (length(sigma_values) != 5L || any(!is.finite(sigma_values))) {
      add_failure(model_id, "CPUE MLE sigma lock must provide five R1-R5 expected_values.")
    } else {
      for (j in seq_len(5L)) check_flag(flags, -(28L + j), 92L, sigma_values[[j]], model_id, paste0("CPUE MLE sigma R", j))
    }
    if (is.null(sigma_lock) || !identical(trim_character(sigma_lock$job_id[[1L]]), "13328")) add_failure(model_id, "CPUE MLE sigma provenance must identify Job 13328.")
  }

  grouping <- toupper(row_value(row, "dm_grouping"))
  if (grouping == "G8PSSET" || grepl("G8PSSET", token)) {
    actual <- vapply(1:33, function(fishery) effective_flag(flags, -fishery, 68L), numeric(1))
    if (any(!is.finite(actual)) || !identical(as.numeric(actual), as.numeric(g8_expected))) {
      add_failure(model_id, paste0("G8PSSET mapping must be exactly `", paste(g8_expected, collapse = " "), "`; found `", paste(actual, collapse = " "), "`."))
    }
  }

  n7_expected <- is.finite(major_number) && major_number >= 15L
  if (n7_expected) {
    phase1_groups <- vapply(
      1:33, function(fishery) effective_flag_at_phase(flags, -fishery, 24L, 1L),
      numeric(1)
    )
    phase5_groups <- vapply(
      1:33, function(fishery) effective_flag_at_phase(flags, -fishery, 24L, 5L),
      numeric(1)
    )
    expected_phase1 <- c(1:28, rep(29, 5L))
    if (!identical(as.numeric(phase1_groups), as.numeric(expected_phase1))) {
      add_failure(
        model_id,
        paste0(
          "phase-1 selectivity grouping must be `", paste(expected_phase1, collapse = " "),
          "`; found `", paste(phase1_groups, collapse = " "), "`."
        )
      )
    }
    if (!identical(as.numeric(phase5_groups), as.numeric(1:33))) {
      add_failure(
        model_id,
        paste0(
          "phase-5 effective selectivity grouping must be contiguous 1:33; found `",
          paste(phase5_groups, collapse = " "), "`."
        )
      )
    }
    check_flag(
      flags, -999L, 26L, 2L, model_id,
      "age-based selectivity evaluated against scaled mean length-at-age"
    )
    check_flag(flags, -999L, 57L, 3L, model_id, "common cubic spline")
    for (fishery in 25:26) {
      check_flag(
        flags, -fishery, 3L, 25L, model_id,
        paste0("F", fishery, " last age class with non-zero dome selectivity")
      )
      check_flag(flags, -fishery, 24L, fishery, model_id, paste0("F", fishery, " independent selectivity group"))
      for (pair in list(c(61, 7), c(16, 2), c(75, 0))) {
        check_flag(flags, -fishery, pair[[1L]], pair[[2L]], model_id, paste0("F", fishery, " N7 selectivity"))
      }
    }
  }

  nmax_label <- regmatches(token, regexpr("NMAX[0-9]+", token))
  nmax_from_label <- if (length(nmax_label) && nzchar(nmax_label)) suppressWarnings(as.numeric(sub("NMAX", "", nmax_label))) else NA_real_
  nmax_config <- suppressWarnings(as.numeric(row_value(row, "dm_nmax")))
  nmax_values <- unique(flag_values(flags, 1L, 342L))
  if (is.finite(nmax_config) && is.finite(nmax_from_label) && nmax_config != nmax_from_label) add_failure(model_id, paste0("Nmax label says ", nmax_from_label, " but job-config says ", nmax_config, "."))
  expected_nmax <- if (is.finite(nmax_config)) nmax_config else nmax_from_label
  if (is.finite(expected_nmax) && (length(nmax_values) == 0L || any(nmax_values != expected_nmax))) {
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
    tag_flags = tag_flags,
    hashes = setNames(vapply(required_files, function(file) sha256_file(file.path(model_dir, file)), character(1)), required_files)
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
