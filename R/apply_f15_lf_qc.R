## Apply a narrowly scoped F15 (HL.PH.2) length-frequency QC sensitivity.
##
## The function edits only F15 length-frequency fields in the exact Job 16594
## bet.frq. Catch, effort, every other fishery, and all other model inputs are
## left unchanged. Removed fish are not renormalised back to the original
## sample total.

f15_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

f15_frq_layout <- function(lines) {
  marker <- grep("^# Datasets / LFIntervals", lines)
  if (length(marker) != 1L) {
    stop("Could not uniquely locate the LF interval header in bet.frq.", call. = FALSE)
  }
  candidate <- seq.int(marker + 1L, length(lines))
  candidate <- candidate[nzchar(trimws(lines[candidate])) & !grepl("^\\s*#", lines[candidate])]
  if (!length(candidate)) stop("Missing LF interval values in bet.frq.", call. = FALSE)
  values <- scan(text = lines[candidate[[1L]]], quiet = TRUE)
  if (length(values) < 4L) stop("Malformed LF interval values in bet.frq.", call. = FALSE)
  list(
    datasets = as.integer(values[[1L]]),
    n_lf = as.integer(values[[2L]]),
    lf_first = as.numeric(values[[3L]]),
    lf_width = as.numeric(values[[4L]])
  )
}

f15_split_record <- function(line) {
  strsplit(trimws(line), "[[:space:]]+")[[1L]]
}

f15_is_record <- function(tokens, fishery = 15L) {
  if (length(tokens) < 7L) return(FALSE)
  prefix <- suppressWarnings(as.numeric(tokens[seq_len(4L)]))
  all(is.finite(prefix)) &&
    prefix[[1L]] >= 1900 &&
    prefix[[1L]] <= 2100 &&
    as.integer(prefix[[4L]]) == as.integer(fishery)
}

f15_period_label <- function(year, month) {
  quarter <- match(as.integer(month), c(2L, 5L, 8L, 11L))
  if (is.na(quarter)) {
    stop("Unexpected seasonal month in F15 record: ", month, call. = FALSE)
  }
  sprintf("%dQ%d", as.integer(year), quarter)
}

apply_f15_lf_qc <- function(
  model_dir,
  mode,
  frq_name = "bet.frq",
  expected_source_sha256 = "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c"
) {
  allowed_modes <- c("lt68", "lt70")
  mode <- trimws(tolower(as.character(mode[[1L]])))
  if (!mode %in% allowed_modes) {
    stop(
      "F15_QC_MODE must be one of: ", paste(allowed_modes, collapse = ", "),
      "; got ", mode, ".",
      call. = FALSE
    )
  }

  frq_path <- file.path(model_dir, frq_name)
  if (!file.exists(frq_path)) stop("Missing F15 QC source FRQ: ", frq_path, call. = FALSE)
  source_sha <- f15_sha256(frq_path)
  if (!identical(source_sha, expected_source_sha256)) {
    stop(
      "F15 QC refuses to edit a non-Job16594 FRQ. Expected SHA256 ",
      expected_source_sha256, ", got ", source_sha, ".",
      call. = FALSE
    )
  }

  lines_before <- readLines(frq_path, warn = FALSE)
  lines_after <- lines_before
  layout <- f15_frq_layout(lines_before)
  if (!identical(layout$n_lf, 95L) ||
      !isTRUE(all.equal(layout$lf_first, 10)) ||
      !isTRUE(all.equal(layout$lf_width, 2))) {
    stop(
      "Unexpected Job16594 length-bin layout: n=", layout$n_lf,
      ", first=", layout$lf_first, ", width=", layout$lf_width, ".",
      call. = FALSE
    )
  }
  lengths <- layout$lf_first + layout$lf_width * (seq_len(layout$n_lf) - 1L)
  lf_start <- 8L
  lf_end <- 7L + layout$n_lf

  tokenised <- lapply(lines_before, f15_split_record)
  f15_rows <- which(vapply(tokenised, f15_is_record, logical(1L)))
  if (!identical(length(f15_rows), 220L)) {
    stop("Expected 220 F15 fishery records; found ", length(f15_rows), ".", call. = FALSE)
  }
  f15_comp_rows <- f15_rows[vapply(tokenised[f15_rows], function(tokens) {
    length(tokens) >= lf_end + 1L
  }, logical(1L))]
  if (!identical(length(f15_comp_rows), 135L)) {
    stop(
      "Expected 135 F15 length-composition records; found ",
      length(f15_comp_rows), ".",
      call. = FALSE
    )
  }

  records <- vector("list", length(f15_comp_rows))
  for (j in seq_along(f15_comp_rows)) {
    line_index <- f15_comp_rows[[j]]
    tokens <- tokenised[[line_index]]
    if (length(tokens) != lf_end + 1L || !identical(tokens[[lf_end + 1L]], "-1")) {
      stop(
        "F15 line ", line_index,
        " does not contain exactly 95 LF bins followed by an absent WF field.",
        call. = FALSE
      )
    }
    lf <- suppressWarnings(as.numeric(tokens[lf_start:lf_end]))
    if (length(lf) != layout$n_lf || any(!is.finite(lf)) || any(lf < 0)) {
      stop("Malformed F15 length composition on line ", line_index, ".", call. = FALSE)
    }
    total <- sum(lf)
    if (!is.finite(total) || total <= 0) {
      stop("Non-positive F15 sample total on line ", line_index, ".", call. = FALSE)
    }
    year <- as.integer(tokens[[1L]])
    month <- as.integer(tokens[[2L]])
    below68 <- sum(lf[lengths < 68])
    below70 <- sum(lf[lengths < 70])
    records[[j]] <- data.frame(
      line = line_index,
      year = year,
      month = month,
      period = f15_period_label(year, month),
      total_before = total,
      below68_before = below68,
      below70_before = below70,
      below70_fraction = below70 / total,
      stringsAsFactors = FALSE
    )
  }
  audit <- do.call(rbind, records)
  if (!isTRUE(all.equal(sum(audit$total_before), 41908)) ||
      !isTRUE(all.equal(sum(audit$below70_before), 1057))) {
    stop(
      "Job16594 F15 baseline counts changed: total=", sum(audit$total_before),
      ", below70=", sum(audit$below70_before), ".",
      call. = FALSE
    )
  }

  audit$action <- "unchanged"
  audit$total_after <- audit$total_before
  audit$removed_count <- 0
  affected <- rep(FALSE, nrow(audit))

  for (j in seq_len(nrow(audit))) {
    line_index <- audit$line[[j]]
    tokens <- tokenised[[line_index]]
    lf <- as.numeric(tokens[lf_start:lf_end])

    threshold <- if (identical(mode, "lt68")) 68 else 70
    remove_bins <- lengths < threshold
    removed <- sum(lf[remove_bins])
    if (removed > 0) {
      lf[remove_bins] <- 0
      if (sum(lf) <= 0) {
        stop(
          "Filtering <", threshold, " cm would empty F15 ", audit$period[[j]],
          "; refusing to create an invalid composition.",
          call. = FALSE
        )
      }
      tokens[lf_start:lf_end] <- format(lf, scientific = FALSE, trim = TRUE)
      lines_after[[line_index]] <- paste(tokens, collapse = " ")
      audit$action[[j]] <- paste0("zero_bins_lt", threshold)
      audit$total_after[[j]] <- sum(lf)
      audit$removed_count[[j]] <- removed
      affected[[j]] <- TRUE
    }
  }

  changed_lines <- which(lines_before != lines_after)
  if (!length(changed_lines)) stop("F15 QC mode ", mode, " made no changes.", call. = FALSE)
  if (length(setdiff(changed_lines, f15_comp_rows))) {
    stop("F15 QC modified a non-F15-composition line.", call. = FALSE)
  }
  if (!identical(sort(changed_lines), sort(audit$line[affected]))) {
    stop("F15 QC line-change audit does not match the actual file diff.", call. = FALSE)
  }

  writeLines(lines_after, frq_path, useBytes = TRUE)
  output_sha <- f15_sha256(frq_path)
  if (identical(output_sha, source_sha)) {
    stop("F15 QC output SHA unexpectedly equals the Job16594 source SHA.", call. = FALSE)
  }

  affected_periods <- paste(audit$period[affected], collapse = ";")
  summary <- data.frame(
    mode = mode,
    fishery = 15L,
    fishery_label = "15.HL.PH.2",
    source_sha256 = source_sha,
    output_sha256 = output_sha,
    f15_fishery_rows = length(f15_rows),
    f15_lf_rows_before = length(f15_comp_rows),
    f15_lf_rows_affected = sum(affected),
    f15_lf_rows_after = length(f15_comp_rows),
    f15_count_before = sum(audit$total_before),
    f15_count_after = sum(audit$total_after),
    removed_count = sum(audit$removed_count),
    below68_before = sum(audit$below68_before),
    below70_before = sum(audit$below70_before),
    affected_periods = affected_periods,
    renormalised = FALSE,
    catch_or_effort_changed = FALSE,
    stringsAsFactors = FALSE
  )

  utils::write.csv(
    audit,
    file.path(model_dir, "f15-lf-qc-audit.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    summary,
    file.path(model_dir, "f15-lf-qc-summary.csv"),
    row.names = FALSE
  )
  message(
    "[f15-lf-qc] mode=", mode,
    "; affected LF rows=", sum(affected),
    "; removed count=", sum(audit$removed_count),
    "; source SHA=", source_sha,
    "; output SHA=", output_sha
  )
  invisible(list(summary = summary, audit = audit))
}
