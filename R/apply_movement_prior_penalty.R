## Apply the movement-prior penalty sensitivity in the staged doitall script.
##
## MFCL age flag 27 is negative when the movement coefficient penalty is
## computed against the prior. The magnitude selects the coefficient:
## -1 = 0.1 and -2 = 0.2.

movement_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

apply_movement_prior_penalty <- function(
  model_dir,
  penalty,
  script_name = "doitall.sh"
) {
  penalty <- trimws(as.character(penalty[[1L]]))
  flag_by_penalty <- c("0.1" = "-1", "0.2" = "-2")
  if (!penalty %in% names(flag_by_penalty)) {
    stop("MOVEMENT_PRIOR_PENALTY must be 0.1 or 0.2; got ", penalty, ".", call. = FALSE)
  }

  path <- file.path(model_dir, script_name)
  if (!file.exists(path)) stop("Missing staged doitall script: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE)
  source_line <- "2 27 -1  # penalty wt 0.1 computed against prior"
  source_matches <- which(trimws(lines) == source_line)
  any_flag27 <- grep("^\\s*2\\s+27\\s+", lines)
  if (!identical(source_matches, any_flag27) || length(source_matches) != 1L) {
    stop(
      "Expected exactly one baseline movement-prior control `", source_line,
      "` and no other age flag 27 entries.",
      call. = FALSE
    )
  }

  source_sha <- movement_sha256(path)
  target_flag <- unname(flag_by_penalty[[penalty]])
  target_line <- paste0(
    "2 27 ", target_flag, "  # penalty wt ", penalty, " computed against prior"
  )
  if (!identical(penalty, "0.1")) {
    indent <- sub("^(\\s*).*", "\\1", lines[[source_matches]])
    lines[[source_matches]] <- paste0(indent, target_line)
    writeLines(lines, path, useBytes = TRUE)
  }

  staged <- readLines(path, warn = FALSE)
  if (sum(trimws(staged) == target_line) != 1L ||
      sum(grepl("^\\s*2\\s+27\\s+", staged)) != 1L) {
    stop("Staged movement-prior control does not match the requested penalty.", call. = FALSE)
  }
  output_sha <- movement_sha256(path)
  if (identical(penalty, "0.2") && identical(output_sha, source_sha)) {
    stop("Movement-prior 0.2 did not change the staged doitall script.", call. = FALSE)
  }

  audit <- data.frame(
    movement_prior_penalty = penalty,
    age_flag_27 = target_flag,
    source_sha256 = source_sha,
    output_sha256 = output_sha,
    source_line = source_line,
    staged_line = target_line,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    audit,
    file.path(model_dir, "movement-prior-audit.csv"),
    row.names = FALSE
  )
  message(
    "[movement-prior] penalty=", penalty,
    "; age flag 27=", target_flag,
    "; doitall SHA=", output_sha
  )
  invisible(audit)
}
