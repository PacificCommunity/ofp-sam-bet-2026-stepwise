regional_scaling_sha256 <- function(path) {
  sha256sum <- Sys.which("sha256sum")
  if (!nzchar(sha256sum)) {
    stop("sha256sum is required for regional-scaling validation.", call. = FALSE)
  }
  output <- system2(sha256sum, path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Could not calculate SHA256 for ", path, ".", call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

regional_scaling_matrix_lines <- function(lines, expected_rows, label) {
  if (length(lines) != expected_rows || any(!nzchar(trimws(lines)))) {
    stop(
      label, " must contain exactly ", expected_rows,
      " nonblank data rows.", call. = FALSE
    )
  }
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  if (!all(lengths(fields) == 5L)) {
    stop(label, " must contain five values per row.", call. = FALSE)
  }
  values <- suppressWarnings(as.numeric(unlist(fields, use.names = FALSE)))
  if (anyNA(values) || any(!is.finite(values))) {
    stop(label, " contains nonnumeric or non-finite values.", call. = FALSE)
  }
  invisible(TRUE)
}

apply_full_period_reg_scaling <- function(model_dir, mode = "full_period") {
  if (!identical(mode, "full_period")) {
    stop("REG_SCALING_MODE must be full_period.", call. = FALSE)
  }

  active_path <- file.path(model_dir, "bet.reg_scaling")
  full_path <- file.path(model_dir, "bet.reg_scaling.full")
  doitall_path <- file.path(model_dir, "doitall.sh")
  for (path in c(active_path, full_path, doitall_path)) {
    if (!file.exists(path)) {
      stop("Missing regional-scaling input: ", path, call. = FALSE)
    }
  }

  expected_source_hashes <- c(
    active = "6330fb6a36d63424c18f81cbc620c1d9607c2a5c43d0308d19941f12938ec9a1",
    full = "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed"
  )
  actual_source_hashes <- c(
    active = regional_scaling_sha256(active_path),
    full = regional_scaling_sha256(full_path)
  )
  if (!identical(actual_source_hashes, expected_source_hashes)) {
    stop(
      "Frozen regional-scaling source hash mismatch: expected ",
      paste(expected_source_hashes, collapse = ", "), "; got ",
      paste(actual_source_hashes, collapse = ", "), ".",
      call. = FALSE
    )
  }

  full_lines <- readLines(full_path, warn = FALSE)
  regional_scaling_matrix_lines(full_lines, 292L, "bet.reg_scaling.full")

  active_lines <- readLines(active_path, warn = FALSE)
  if (length(active_lines) != 21L ||
      !identical(trimws(active_lines[[1L]]), "1965 2 1969 11")) {
    stop(
      "Frozen active regional-scaling file must contain the 1965-1969 ",
      "calendar header plus 20 data rows.", call. = FALSE
    )
  }
  regional_scaling_matrix_lines(
    active_lines[-1L], 20L, "frozen 1965-1969 regional-scaling window"
  )
  if (!identical(trimws(active_lines[-1L]), trimws(full_lines[53:72]))) {
    stop(
      "Frozen 1965-1969 active regional-scaling rows do not match ",
      "full-source periods 53-72.", call. = FALSE
    )
  }

  # All five regional indices must cover the requested prior window. Index
  # fishery 32 starts in model period 3, so current MFCL rejects period 1 or 2
  # as a regional-scaling start. Preserve the complete 292-row source beside
  # the executable file and use the full mutually supported window, 3:292.
  output_lines <- c("1952 8 2024 11", full_lines[3:292])
  writeLines(output_lines, active_path, useBytes = TRUE)

  doitall <- readLines(doitall_path, warn = FALSE)
  start_line <- grep("^\\s*1\\s+79\\s+240\\s+", doitall)
  end_line <- grep("^\\s*1\\s+80\\s+220\\s+", doitall)
  if (length(start_line) != 1L || length(end_line) != 1L ||
      sum(grepl("^\\s*1\\s+79\\s+", doitall)) != 1L ||
      sum(grepl("^\\s*1\\s+80\\s+", doitall)) != 1L) {
    stop(
      "Expected exactly one frozen regional-scaling flag 79=240 and ",
      "one flag 80=220 in doitall.sh.", call. = FALSE
    )
  }
  doitall[[start_line]] <- paste(
    "  1 79 290  # full index-supported start: model period 3 (1952Q3)"
  )
  doitall[[end_line]] <- paste(
    "  1 80 0  # full-period end bound: default final model period 292 (2024Q4)"
  )
  writeLines(doitall, doitall_path, useBytes = TRUE)
  Sys.chmod(doitall_path, mode = "0755")

  output_hash <- regional_scaling_sha256(active_path)
  audit <- data.frame(
    mode = mode,
    source_full_sha256 = actual_source_hashes[["full"]],
    output_sha256 = output_hash,
    calendar_header = output_lines[[1L]],
    source_data_rows = 292L,
    active_data_rows = 290L,
    columns = 5L,
    start_period = 3L,
    end_period = 292L,
    start_label = "1952Q3",
    end_label = "2024Q4",
    parest_flag_79 = 290L,
    parest_flag_80 = 0L,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    audit,
    file.path(model_dir, "regional-scaling-full-period-summary.csv"),
    row.names = FALSE
  )
  invisible(audit)
}
