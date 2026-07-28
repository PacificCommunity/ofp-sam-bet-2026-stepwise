apply_lorenzen_m_start <- function(model_dir, requested_start = "-3") {
  requested_start <- trimws(as.character(requested_start))
  if (!identical(requested_start, "-3")) {
    stop("This sensitivity requires M_START_INTERCEPT=-3.", call. = FALSE)
  }
  ini_path <- file.path(model_dir, "bet.ini")
  if (!file.exists(ini_path)) stop("Missing staged bet.ini.", call. = FALSE)

  lines <- readLines(ini_path, warn = FALSE)
  marker <- which(trimws(lines) %in% c(
    "# age_pars", "# age-class related parameters (age_pars)"
  ))
  if (length(marker) != 1L) {
    stop("Expected exactly one age_pars block in bet.ini.", call. = FALSE)
  }
  data_idx <- integer()
  for (i in seq.int(marker + 1L, length(lines))) {
    if (grepl("^[[:space:]]*#", lines[[i]])) {
      if (length(data_idx)) break
      next
    }
    if (nzchar(trimws(lines[[i]]))) data_idx <- c(data_idx, i)
    if (length(data_idx) == 5L) break
  }
  if (length(data_idx) != 5L) {
    stop("Could not locate age_pars row 5 in bet.ini.", call. = FALSE)
  }

  fields <- strsplit(trimws(lines[[data_idx[[5L]]]]), "[[:space:]]+")[[1L]]
  if (length(fields) != 40L ||
      !isTRUE(all.equal(as.numeric(fields[[1L]]), -2.54930339768360,
                       tolerance = 1e-12)) ||
      !isTRUE(all.equal(as.numeric(fields[[2L]]), -1, tolerance = 1e-12))) {
    stop("Unexpected Job 17805 Lorenzen M intercept or length slope.", call. = FALSE)
  }

  source_intercept <- fields[[1L]]
  source_slope <- fields[[2L]]
  lines[[data_idx[[5L]]]] <- sub(
    "^[[:space:]]*[^[:space:]]+",
    "-3.00000000000000e+00",
    lines[[data_idx[[5L]]]]
  )
  writeLines(lines, ini_path, useBytes = TRUE)

  audit <- data.frame(
    parameter = "age_pars(5)[1]",
    source_intercept = source_intercept,
    requested_start_intercept = "-3.00000000000000e+00",
    fixed_lorenzen_length_slope = source_slope,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    audit,
    file.path(model_dir, "lorenzen-m-start-audit.csv"),
    row.names = FALSE
  )
  message(
    "[lorenzen-m-start] age_pars(5)[1]: ", source_intercept,
    " -> -3.00000000000000e+00; age_pars(5)[2] remains ", source_slope
  )
  invisible(audit)
}
