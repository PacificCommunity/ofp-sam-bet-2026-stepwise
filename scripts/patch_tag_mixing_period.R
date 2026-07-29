#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 4L) {
  stop(
    "Usage: patch_tag_mixing_period.R BASELINE_INI TARGET_INI OUTPUT_INI AUDIT_CSV",
    call. = FALSE
  )
}

baseline_path <- args[[1L]]
target_path <- args[[2L]]
output_path <- args[[3L]]
audit_path <- args[[4L]]

read_tag_flags <- function(path) {
  lines <- readLines(path, warn = FALSE)
  marker <- which(trimws(lines) == "# tag flags")
  if (length(marker) != 1L) {
    stop(path, " must contain exactly one '# tag flags' marker.", call. = FALSE)
  }
  next_marker <- which(seq_along(lines) > marker & grepl("^#", trimws(lines)))
  if (!length(next_marker)) {
    stop(path, " has no section following '# tag flags'.", call. = FALSE)
  }
  row_index <- seq.int(marker + 1L, next_marker[[1L]] - 1L)
  row_index <- row_index[nzchar(trimws(lines[row_index]))]
  values <- lapply(
    lines[row_index],
    function(line) suppressWarnings(as.numeric(strsplit(trimws(line), "[[:space:]]+")[[1L]]))
  )
  if (length(values) != 98L || any(lengths(values) != 10L) ||
      any(!vapply(values, function(x) all(is.finite(x)), logical(1L)))) {
    stop(path, " must contain a numeric 98 x 10 tag-flags matrix.", call. = FALSE)
  }
  list(lines = lines, row_index = row_index, values = do.call(rbind, values))
}

baseline <- read_tag_flags(baseline_path)
target <- read_tag_flags(target_path)
patched <- baseline$values
patched[, 1L] <- target$values[, 1L]

output_lines <- baseline$lines
output_lines[baseline$row_index] <- apply(
  patched,
  1L,
  function(row) paste(format(row, scientific = FALSE, trim = TRUE), collapse = " ")
)
writeLines(output_lines, output_path, useBytes = TRUE)

audit <- data.frame(
  release_group = seq_len(nrow(patched)),
  baseline_mixing_period = as.integer(baseline$values[, 1L]),
  target_mixing_period = as.integer(target$values[, 1L]),
  changed = baseline$values[, 1L] != target$values[, 1L],
  stringsAsFactors = FALSE
)
write.csv(audit, audit_path, row.names = FALSE)

check <- read_tag_flags(output_path)
if (!identical(check$values[, 1L], target$values[, 1L])) {
  stop("Patched first tag-flag column does not match the target.", call. = FALSE)
}
if (!identical(check$values[, 2:10, drop = FALSE],
               baseline$values[, 2:10, drop = FALSE])) {
  stop("Patch changed tag-flag columns 2-10.", call. = FALSE)
}

outside <- setdiff(seq_along(baseline$lines), baseline$row_index)
if (!identical(output_lines[outside], baseline$lines[outside])) {
  stop("Patch changed content outside the tag-flags matrix.", call. = FALSE)
}

message(
  "Patched ", sum(audit$changed), " of 98 release groups in ",
  normalizePath(output_path, winslash = "/", mustWork = TRUE), "."
)
