## Apply the John Hampton selectivity sensitivity to the staged BET doitall.
##
## F2 and F3 retain their existing shared selectivity group. Because the
## MULTIFAN-CL manual requires grouped fisheries to have identical settings
## for fish flags 3, 16, 26, 57, 61, 62 and 75, the non-decreasing constraint
## requested for F2 is applied to both members of the shared curve.
##
## F33 (Index R5) is changed from a two-parameter logistic curve to the same
## unconstrained four-node cubic-spline treatment used by the earlier S04
## sensitivity. "Unconstrained" here means no logistic functional form and no
## non-decreasing/dome-shape penalty; the existing terminal-age and
## youngest-age controls are retained.

john_selectivity_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

john_exact_line_count <- function(lines, text) {
  sum(trimws(lines) == text)
}

apply_john_selectivity_sensitivity <- function(
  model_dir,
  mode = "f2f3-nondecreasing-f33-spline4",
  script_name = "doitall.sh"
) {
  if (!identical(mode, "f2f3-nondecreasing-f33-spline4")) {
    stop(
      "SELECTIVITY_MODE must be f2f3-nondecreasing-f33-spline4; got ",
      mode, ".", call. = FALSE
    )
  }

  path <- file.path(model_dir, script_name)
  if (!file.exists(path)) stop("Missing staged doitall script: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE)
  source_sha <- john_selectivity_sha256(path)

  required <- c(
    "-999 3 37  # all selectivities equal for age class 37 and older" = 1L,
    "-999 26 2  # evaluate age-based selectivity against scaled mean length-at-age" = 1L,
    "-999 57 3  # cubic-spline selectivity" = 1L,
    "-999 61 5  # five cubic-spline coefficients by default" = 1L,
    "-2 24 2  # F2 selectivity-stability group (shared Region 1 longline extraction curve (F2/F3))" = 2L,
    "-3 24 2  # F3 selectivity-stability group (shared Region 1 longline extraction curve (F2/F3))" = 2L,
    "-2 75 2  # F2 youngest age classes fixed at zero selectivity" = 1L,
    "-3 75 2  # F3 youngest age classes fixed at zero selectivity" = 1L,
    "-2 61 4  # F2 retained Job 15989 four-node selectivity" = 1L,
    "-3 61 4  # F3 retained Job 15989 four-node selectivity" = 1L,
    "-33 24 31  # F33 selectivity-stability group" = 2L,
    "-33 75 2  # Index R5 youngest age classes fixed at zero selectivity" = 1L,
    "-33 57 1  # F33 independent asymptotic logistic selectivity" = 1L
  )
  bad <- names(required)[
    vapply(
      names(required),
      function(x) john_exact_line_count(lines, x),
      integer(1L)
    ) != required
  ]
  if (length(bad)) {
    stop(
      "Unexpected baseline selectivity control(s): ",
      paste(bad, collapse = " | "), ".", call. = FALSE
    )
  }
  if (any(grepl("^\\s*-[23]\\s+16\\s+", lines)) ||
      any(grepl("^\\s*-[23]\\s+62\\s+", lines)) ||
      sum(grepl("^\\s*-33\\s+16\\s+", lines)) != 0L ||
      sum(grepl("^\\s*-33\\s+61\\s+", lines)) != 0L) {
    stop("Baseline doitall contains conflicting F2/F3/F33 selectivity controls.", call. = FALSE)
  }

  grouping_comment <- which(
    trimws(lines) ==
      "# Staged run 1 uses 29 contiguous groups: F1-F28 use groups 1-28; F29-F33 initially share group 29."
  )
  if (length(grouping_comment) != 1L) {
    stop("Could not uniquely locate the inherited selectivity-group comment.", call. = FALSE)
  }
  lines[[grouping_comment]] <- paste(
    "# Final selectivity groups are assigned in Phase 1:",
    "F2/F3 and F7/F9 share curves; F29-F33 are independent."
  )

  anchor <- which(
    trimws(lines) ==
      "# Non-decreasing selectivity for the old6-derived longline fishery."
  )
  if (length(anchor) != 1L) {
    stop("Could not uniquely locate the non-decreasing-selectivity anchor.", call. = FALSE)
  }
  shared_controls <- c(
    "# F2 and F3 share one curve, so all grouping-sensitive flags must match.",
    "  -2 16 1  # F2/F3 shared curve: non-decreasing (F2-motivated sensitivity)",
    "  -3 16 1  # F2/F3 shared curve: identical non-decreasing setting",
    "  -2 62 0  # F2/F3 shared curve: no staged spline-node increment",
    "  -3 62 0  # F2/F3 shared curve: identical spline-node increment setting"
  )
  lines <- append(lines, shared_controls, after = anchor)

  logistic <- which(
    trimws(lines) == "-33 57 1  # F33 independent asymptotic logistic selectivity"
  )
  if (length(logistic) != 1L) {
    stop("Could not uniquely locate the F33 logistic control.", call. = FALSE)
  }
  lines <- append(
    lines[-logistic],
    c(
      "  -33 16 0  # F33 spline: no non-decreasing or dome-shape constraint",
      "  -33 57 3  # F33 independent cubic-spline selectivity",
      "  -33 61 4  # F33 four-node cubic spline"
    ),
    after = logistic - 1L
  )

  writeLines(lines, path, useBytes = TRUE)
  Sys.chmod(path, mode = "0755")

  staged <- readLines(path, warn = FALSE)
  final_required <- c(
    "-2 16 1  # F2/F3 shared curve: non-decreasing (F2-motivated sensitivity)" = 1L,
    "-3 16 1  # F2/F3 shared curve: identical non-decreasing setting" = 1L,
    "-2 62 0  # F2/F3 shared curve: no staged spline-node increment" = 1L,
    "-3 62 0  # F2/F3 shared curve: identical spline-node increment setting" = 1L,
    "-33 16 0  # F33 spline: no non-decreasing or dome-shape constraint" = 1L,
    "-33 57 3  # F33 independent cubic-spline selectivity" = 1L,
    "-33 61 4  # F33 four-node cubic spline" = 1L
  )
  final_bad <- names(final_required)[
    vapply(
      names(final_required),
      function(x) john_exact_line_count(staged, x),
      integer(1L)
    ) != final_required
  ]
  if (length(final_bad) ||
      any(grepl("^\\s*-33\\s+57\\s+1(?:\\s|$)", staged))) {
    stop("Final John selectivity controls failed exact validation.", call. = FALSE)
  }

  output_sha <- john_selectivity_sha256(path)
  if (identical(source_sha, output_sha)) {
    stop("John selectivity sensitivity did not modify doitall.sh.", call. = FALSE)
  }
  audit <- data.frame(
    selectivity_mode = mode,
    f2_f3_shared_group = 2L,
    f2_f3_fish_flag_16 = 1L,
    f2_f3_fish_flag_61 = 4L,
    f2_f3_fish_flag_62 = 0L,
    f2_f3_fish_flag_75 = 2L,
    f33_fish_flag_16 = 0L,
    f33_fish_flag_57 = 3L,
    f33_fish_flag_61 = 4L,
    f33_fish_flag_75 = 2L,
    source_sha256 = source_sha,
    output_sha256 = output_sha,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    audit,
    file.path(model_dir, "john-selectivity-audit.csv"),
    row.names = FALSE
  )
  message(
    "[selectivity] F2/F3 group 2 non-decreasing; ",
    "F33 unconstrained four-node cubic spline; doitall SHA=", output_sha
  )
  invisible(audit)
}
