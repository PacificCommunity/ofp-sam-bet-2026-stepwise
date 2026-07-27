## Apply the repository's verified BET 2026 OPR transfer to staged doitall.
##
## The active sensitivity is 72-01-50-50 with parest flag 202=2. This wrapper
## deliberately delegates the Phase-3 transformation to apply_opr() in
## prepare_doitall.R, the same implementation used to build S05/S06.

opr_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

apply_opr_sensitivity <- function(model_dir, mode, script_name = "doitall.sh") {
  mode <- trimws(as.character(mode[[1L]]))
  allowed <- c("off", "72-01-50-50-end2")
  if (!mode %in% allowed) {
    stop("OPR_MODE must be one of: ", paste(allowed, collapse = ", "), ".", call. = FALSE)
  }

  path <- file.path(model_dir, script_name)
  if (!file.exists(path)) stop("Missing staged doitall script: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE)
  source_sha <- opr_sha256(path)
  baseline <- c(
    "2 70 1   # activate time series of reg recruitment parameters",
    "2 71 1   # estimate temporal changes in recruitment distribution",
    "2 178 1  # constrain regional recruitments",
    "1 1 200"
  )
  phase3_start <- grep("<<PHASE3$", lines)
  phase3_end <- grep("^PHASE3$", lines)
  if (length(phase3_start) != 1L || length(phase3_end) != 1L ||
      phase3_start >= phase3_end ||
      !identical(trimws(lines[(phase3_start + 1L):(phase3_end - 1L)]), baseline)) {
    stop("Staged doitall does not contain the exact S03 Phase-3 baseline.", call. = FALSE)
  }

  if (identical(mode, "72-01-50-50-end2")) {
    source(file.path(getwd(), "R", "prepare_common.R"), local = TRUE)
    source(file.path(getwd(), "R", "prepare_doitall.R"), local = TRUE)
    lines <- apply_opr(
      lines,
      year_effect = 72L,
      season_effect = 1L,
      region_effect = 50L,
      region_season_effect = 50L,
      terminal_year_constraint = 2L
    )
    writeLines(lines, path, useBytes = TRUE)
    Sys.chmod(path, mode = "0755")
  }

  staged <- readLines(path, warn = FALSE)
  phase3_start <- grep("<<PHASE3$", staged)
  phase3_end <- grep("^PHASE3$", staged)
  phase3 <- trimws(staged[(phase3_start + 1L):(phase3_end - 1L)])
  opr_block <- trimws(c(
    "# BET 2026 OPR settings: 72-01-50-50 with a two-real-year end window.",
    "1 149 0   # turn off recruitment-deviation penalty for OPR",
    "1 398 0   # turn off arithmetic-mean terminal fixed-recruitment option for OPR",
    "1 400 0   # clear fixed terminal recruitment-deviate block for OPR",
    "2 177 0   # turn off old total-pop scaling for OPR",
    "2 32 0    # turn off overall population scaling parameter for OPR",
    "2 113 0   # keep scaling init pop off during OPR transfer",
    "1 155 72  # orthogonal polynomial recruitment - year effect",
    "1 217 1   # orthogonal polynomial recruitment - season effect",
    "1 216 50  # orthogonal polynomial recruitment - region effect",
    "1 218 50  # orthogonal polynomial recruitment - region-season interaction effect",
    "1 202 2   # OPR end window: last 2 real years use lower-degree/constant-end basis",
    "1 210 0   # OPR region end window: 0 inherits parest_flag(202)",
    "1 212 0   # OPR season end window: 0 inherits parest_flag(202)",
    "1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)",
    "2 30 1    # keep age_flag(30) on so current MFCL activates OPR coefficients",
    "2 70 0    # turn off mean+deviate regional recruitment time series",
    "2 71 0    # turn off regional recruitment distribution deviations",
    "2 178 0   # turn off regional recruitment sum-product constraint",
    "-100000 1 0  # turn off time-invariant recruitment distribution, region 1",
    "-100000 2 0  # turn off time-invariant recruitment distribution, region 2",
    "-100000 3 0  # turn off time-invariant recruitment distribution, region 3",
    "-100000 4 0  # turn off time-invariant recruitment distribution, region 4",
    "-100000 5 0  # turn off time-invariant recruitment distribution, region 5",
    "1 1 500  # function evaluations for the BET 2026 OPR transfer"
  ))
  expected <- if (identical(mode, "off")) baseline else opr_block
  if (!identical(phase3, expected)) {
    stop("Final staged Phase-3 block does not exactly match OPR_MODE=", mode, ".", call. = FALSE)
  }

  output_sha <- opr_sha256(path)
  if (identical(mode, "off") && !identical(source_sha, output_sha)) {
    stop("OPR_MODE=off unexpectedly modified staged doitall.", call. = FALSE)
  }
  if (!identical(mode, "off") && identical(source_sha, output_sha)) {
    stop("OPR mode did not modify staged doitall.", call. = FALSE)
  }
  audit <- data.frame(
    opr_mode = mode,
    year_effect = if (identical(mode, "off")) NA_integer_ else 72L,
    season_effect = if (identical(mode, "off")) NA_integer_ else 1L,
    region_effect = if (identical(mode, "off")) NA_integer_ else 50L,
    region_season_effect = if (identical(mode, "off")) NA_integer_ else 50L,
    terminal_year_constraint = if (identical(mode, "off")) NA_integer_ else 2L,
    source_sha256 = source_sha,
    output_sha256 = output_sha,
    stringsAsFactors = FALSE
  )
  utils::write.csv(audit, file.path(model_dir, "opr-audit.csv"), row.names = FALSE)
  message("[opr] mode=", mode, "; doitall SHA=", output_sha)
  invisible(audit)
}
