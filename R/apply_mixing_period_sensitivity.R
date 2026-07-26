## Apply one frozen tag-mixing sensitivity to a staged copy of Job 16594.
##
## This file is sourced by steps/MIX-*/patch.R. The runner supplies:
##   model_dir: staged model directory
##   config:    selected row from job-config-mixing-period-sensitivity.R

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) {
    if (is.null(x) || !length(x) || is.na(x[[1L]]) || !nzchar(as.character(x[[1L]]))) y else x
  }
}

if (!exists("model_dir", inherits = FALSE) || !dir.exists(model_dir)) {
  stop("mixing-period patch requires a staged model_dir.", call. = FALSE)
}
if (!exists("config", inherits = FALSE) || !is.list(config)) {
  stop("mixing-period patch requires the selected model config.", call. = FALSE)
}

sha256_file <- function(path) {
  command <- Sys.which("sha256sum")
  if (!nzchar(command)) stop("sha256sum is required.", call. = FALSE)
  output <- system2(command, path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Could not calculate SHA256 for ", path, ": ", paste(output, collapse = " "), call. = FALSE)
  }
  value <- strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
  if (!grepl("^[0-9a-f]{64}$", value)) {
    stop("Invalid SHA256 output for ", path, ".", call. = FALSE)
  }
  value
}

parse_tag_flags <- function(lines) {
  marker <- which(tolower(trimws(lines)) == "# tag flags")
  if (length(marker) != 1L) stop("bet.ini must contain exactly one # tag flags section.", call. = FALSE)
  following_markers <- which(seq_along(lines) > marker & grepl("^#", trimws(lines)))
  if (!length(following_markers)) stop("Could not find the end of # tag flags.", call. = FALSE)
  candidates <- seq.int(marker + 1L, following_markers[[1L]] - 1L)
  row_lines <- candidates[nzchar(trimws(lines[candidates]))]
  rows <- lapply(row_lines, function(index) {
    suppressWarnings(as.numeric(strsplit(trimws(lines[[index]]), "[[:space:]]+")[[1L]]))
  })
  if (!length(rows) || length(unique(lengths(rows))) != 1L ||
      any(!vapply(rows, function(row) all(is.finite(row)), logical(1)))) {
    stop("The # tag flags matrix is not rectangular numeric data.", call. = FALSE)
  }
  list(marker = marker, row_lines = row_lines, values = do.call(rbind, rows))
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
ini_path <- file.path(model_dir, "bet.ini")
grid_path <- file.path(root, "config", "sc22-ip10-mixing-period-grid.csv")
expected_baseline_sha256 <- "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a"
source_commit <- "5b2fb6053e34a58ef61275a68d8a67ec988833c1"
source_repo <- "PacificCommunity/ofp-sam-2026-BET-YFT-build-ini"

if (!file.exists(ini_path)) stop("Missing staged bet.ini: ", ini_path, call. = FALSE)
if (!file.exists(grid_path)) stop("Missing frozen mixing-period grid: ", grid_path, call. = FALSE)

baseline_sha256 <- sha256_file(ini_path)
if (!identical(baseline_sha256, expected_baseline_sha256)) {
  stop(
    "Refusing to patch a model that is not the exact Job 16594 bet.ini. Expected ",
    expected_baseline_sha256, ", found ", baseline_sha256, ".",
    call. = FALSE
  )
}

mixing_key <- toupper(trimws(as.character(config$MIXING_KEY %||% "")))
tag_flag2 <- suppressWarnings(as.integer(config$TAG_FLAGS_IT2 %||% NA_character_))
if (!mixing_key %in% c("K005", "K010", "K015", "K020", "K025",
                       "K030", "K035", "K040", "K045", "ALL2")) {
  stop("Unknown MIXING_KEY: ", mixing_key, call. = FALSE)
}
if (!tag_flag2 %in% c(0L, 1L)) {
  stop("TAG_FLAGS_IT2 must be exactly 0 or 1.", call. = FALSE)
}

grid <- read.csv(grid_path, check.names = FALSE, stringsAsFactors = FALSE)
if (!identical(grid$release_group, seq_len(nrow(grid)))) {
  stop("Frozen mixing-period grid release groups must be consecutive.", call. = FALSE)
}

lines <- readLines(ini_path, warn = FALSE)
parsed <- parse_tag_flags(lines)
baseline_flags <- parsed$values
if (nrow(baseline_flags) != nrow(grid) || ncol(baseline_flags) != 10L) {
  stop(
    "Expected ", nrow(grid), " release groups and 10 tag-flag columns; found ",
    nrow(baseline_flags), "x", ncol(baseline_flags), ".",
    call. = FALSE
  )
}

mixing_values <- if (identical(mixing_key, "ALL2")) {
  rep(2L, nrow(grid))
} else {
  as.integer(grid[[mixing_key]])
}
if (length(mixing_values) != nrow(baseline_flags) ||
    any(!mixing_values %in% 0:4)) {
  stop("Invalid release-group mixing-period vector for ", mixing_key, ".", call. = FALSE)
}

final_flags <- baseline_flags
final_flags[, 1L] <- mixing_values
final_flags[, 2L] <- tag_flag2
if (!identical(final_flags[, 3:10, drop = FALSE], baseline_flags[, 3:10, drop = FALSE])) {
  stop("Internal error: tag-flag columns 3-10 changed.", call. = FALSE)
}

for (index in seq_along(parsed$row_lines)) {
  lines[[parsed$row_lines[[index]]]] <- paste(
    format(final_flags[index, ], scientific = FALSE, trim = TRUE),
    collapse = " "
  )
}
writeLines(lines, ini_path, useBytes = TRUE)

check <- parse_tag_flags(readLines(ini_path, warn = FALSE))$values
if (!identical(unname(check), unname(final_flags))) {
  stop("Written tag flags do not match the requested sensitivity.", call. = FALSE)
}

patched_sha256 <- sha256_file(ini_path)
audit <- data.frame(
  release_group = grid$release_group,
  mixing_key = mixing_key,
  tag_flag2 = tag_flag2,
  baseline_mixing_period = as.integer(baseline_flags[, 1L]),
  final_mixing_period = as.integer(final_flags[, 1L]),
  changed_from_job_16594 = as.integer(final_flags[, 1L]) != as.integer(baseline_flags[, 1L]),
  baseline_ini_sha256 = baseline_sha256,
  patched_ini_sha256 = patched_sha256,
  mixing_source_repo = source_repo,
  mixing_source_commit = source_commit,
  stringsAsFactors = FALSE
)
write.csv(audit, file.path(model_dir, "mixing-period-audit.csv"), row.names = FALSE)

message(
  "Applied ", mixing_key, " with tag_flags(:,2)=", tag_flag2,
  " to ", nrow(final_flags), " release groups; ",
  sum(audit$changed_from_job_16594), " mixing-period entries differ from Job 16594."
)
