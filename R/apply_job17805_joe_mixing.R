job17805_tag_flag_indices <- function(lines, path = "<ini>") {
  marker <- which(trimws(tolower(lines)) == "# tag flags")
  if (length(marker) != 1L) {
    stop("Expected exactly one # tag flags block in ", path, call. = FALSE)
  }
  following_comments <- which(
    seq_along(lines) > marker & grepl("^[[:space:]]*#", lines)
  )
  if (!length(following_comments)) {
    stop("Could not find the end of # tag flags in ", path, call. = FALSE)
  }
  idx <- seq.int(marker + 1L, following_comments[[1L]] - 1L)
  idx[nzchar(trimws(lines[idx]))]
}

apply_job17805_joe_mixing <- function(model_dir, mode) {
  mode <- trimws(as.character(mode))
  replacement_column <- switch(
    mode,
    "joe-regionmean-k015" = "joe_regionmean_k015",
    "joe-regionmean-k020" = "joe_regionmean_k020",
    stop("Unsupported MIXING_PERIOD_MODE: ", mode, call. = FALSE)
  )

  ini_path <- file.path(model_dir, "bet.ini")
  vector_path <- file.path(
    getwd(), "config", "job17805-joe-regionmean-mixing.csv"
  )
  if (!file.exists(ini_path) || !file.exists(vector_path)) {
    stop("Missing bet.ini or verified Joe mixing vector.", call. = FALSE)
  }

  vectors <- utils::read.csv(vector_path, stringsAsFactors = FALSE)
  if (nrow(vectors) != 98L ||
      !identical(as.integer(vectors$release_group), 1:98)) {
    stop("Verified Joe mixing vector must contain release groups 1:98.", call. = FALSE)
  }

  lines <- readLines(ini_path, warn = FALSE)
  idx <- job17805_tag_flag_indices(lines, ini_path)
  fields <- strsplit(trimws(lines[idx]), "[[:space:]]+")
  if (length(fields) != 98L || any(lengths(fields) != 10L)) {
    stop("bet.ini must contain 98 tag-flag rows with 10 columns.", call. = FALSE)
  }

  previous <- as.integer(vapply(fields, `[[`, character(1L), 1L))
  baseline <- as.integer(vectors$job17805_k015)
  replacement <- as.integer(vectors[[replacement_column]])
  if (!identical(previous, baseline)) {
    stop(
      "Staged bet.ini is not the frozen Job 17805 K=0.15 baseline.",
      call. = FALSE
    )
  }

  expected_changes <- if (identical(mode, "joe-regionmean-k015")) 37L else 32L
  changed <- which(previous != replacement)
  if (length(changed) != expected_changes) {
    stop("Unexpected number of tag mixing changes for ", mode, ".", call. = FALSE)
  }
  if (identical(mode, "joe-regionmean-k015")) {
    region1_groups <- c(16:18, 62:95)
    if (!identical(changed, region1_groups) ||
        any(previous[changed] != 2L) ||
        any(replacement[changed] != 4L)) {
      stop("Joe K=0.15 must change only the 37 Region-1 groups 2 -> 4.", call. = FALSE)
    }
  }

  for (i in seq_along(fields)) {
    fields[[i]][[1L]] <- as.character(replacement[[i]])
  }
  lines[idx] <- vapply(fields, paste, collapse = " ", character(1L))
  writeLines(lines, ini_path, useBytes = TRUE)

  audit <- data.frame(
    release_group = vectors$release_group,
    mode = mode,
    previous_mixing_period = previous,
    replacement_mixing_period = replacement,
    changed = previous != replacement,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    audit,
    file.path(model_dir, "tag-mixing-period-audit.csv"),
    row.names = FALSE
  )
  invisible(audit)
}
