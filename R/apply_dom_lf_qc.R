## Apply the historical >90 cm data-QC rule to domestic-fishery length data.
##
## Job 16594 stores lengths in 2-cm intervals with lower bounds
## 10, 12, ..., 198 cm. The source assessment rule was applied to raw
## observations, but exact raw lengths cannot be reconstructed from bet.frq.
## This sensitivity therefore removes intervals whose midpoint is >90 cm
## (lower bound >=90 cm). Catch, effort, weight-frequency data, other
## fisheries, and all selectivity controls are left unchanged.

dom_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

dom_frq_layout <- function(lines) {
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
    n_lf = as.integer(values[[2L]]),
    lf_first = as.numeric(values[[3L]]),
    lf_width = as.numeric(values[[4L]])
  )
}

dom_split_record <- function(line) {
  strsplit(trimws(line), "[[:space:]]+")[[1L]]
}

dom_is_record <- function(tokens, fisheries) {
  if (length(tokens) < 7L) return(FALSE)
  prefix <- suppressWarnings(as.numeric(tokens[seq_len(4L)]))
  all(is.finite(prefix)) &&
    prefix[[1L]] >= 1900 &&
    prefix[[1L]] <= 2100 &&
    as.integer(prefix[[4L]]) %in% fisheries
}

dom_period_label <- function(year, month) {
  quarter <- match(as.integer(month), c(2L, 5L, 8L, 11L))
  if (is.na(quarter)) {
    stop("Unexpected seasonal month in DOM record: ", month, call. = FALSE)
  }
  sprintf("%dQ%d", as.integer(year), quarter)
}

apply_dom_lf_qc <- function(
  model_dir,
  mode,
  frq_name = "bet.frq",
  expected_source_sha256 = "3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60"
) {
  mode <- trimws(tolower(as.character(mode[[1L]])))
  if (!identical(mode, "gt90_midpoint")) {
    stop("DOM_QC_MODE must be gt90_midpoint; got ", mode, ".", call. = FALSE)
  }

  frq_path <- file.path(model_dir, frq_name)
  if (!file.exists(frq_path)) stop("Missing DOM QC source FRQ: ", frq_path, call. = FALSE)
  source_sha <- dom_sha256(frq_path)
  if (!identical(source_sha, expected_source_sha256)) {
    stop(
      "DOM QC requires the verified Job16594 FRQ after F15 <70 cm QC. Expected SHA256 ",
      expected_source_sha256, ", got ", source_sha, ".",
      call. = FALSE
    )
  }

  lines_before <- readLines(frq_path, warn = FALSE)
  lines_after <- lines_before
  layout <- dom_frq_layout(lines_before)
  if (!identical(layout$n_lf, 95L) ||
      !isTRUE(all.equal(layout$lf_first, 10)) ||
      !isTRUE(all.equal(layout$lf_width, 2))) {
    stop(
      "Unexpected Job16594 length-bin layout: n=", layout$n_lf,
      ", first=", layout$lf_first, ", width=", layout$lf_width, ".",
      call. = FALSE
    )
  }

  lower_bounds <- layout$lf_first + layout$lf_width * (seq_len(layout$n_lf) - 1L)
  midpoints <- lower_bounds + layout$lf_width / 2
  remove_bins <- midpoints > 90
  if (!identical(lower_bounds[remove_bins][[1L]], 90) ||
      !identical(midpoints[remove_bins][[1L]], 91)) {
    stop("The >90 cm midpoint rule did not resolve to lower bounds >=90 cm.", call. = FALSE)
  }

  fisheries <- 21:23
  fishery_labels <- c("21.DOM.ID.2", "22.DOM.PH.2", "23.DOM.VN.2")
  names(fishery_labels) <- as.character(fisheries)
  lf_start <- 8L
  lf_end <- 7L + layout$n_lf
  tokenised <- lapply(lines_before, dom_split_record)
  dom_rows <- which(vapply(tokenised, dom_is_record, logical(1L), fisheries = fisheries))
  dom_comp_rows <- dom_rows[vapply(tokenised[dom_rows], function(tokens) {
    length(tokens) == lf_end + 1L && identical(tokens[[lf_end + 1L]], "-1")
  }, logical(1L))]

  expected_record_rows <- c(`21` = 220L, `22` = 220L, `23` = 100L)
  expected_lf_rows <- c(`21` = 40L, `22` = 138L, `23` = 21L)
  actual_record_rows <- table(factor(
    vapply(tokenised[dom_rows], function(tokens) as.integer(tokens[[4L]]), integer(1L)),
    levels = fisheries
  ))
  actual_lf_rows <- table(factor(
    vapply(tokenised[dom_comp_rows], function(tokens) as.integer(tokens[[4L]]), integer(1L)),
    levels = fisheries
  ))
  names(actual_record_rows) <- names(expected_record_rows)
  names(actual_lf_rows) <- names(expected_lf_rows)
  if (!identical(as.integer(actual_record_rows), as.integer(expected_record_rows)) ||
      !identical(as.integer(actual_lf_rows), as.integer(expected_lf_rows))) {
    stop(
      "Unexpected DOM record counts. Fishery rows=", paste(actual_record_rows, collapse = ","),
      "; LF rows=", paste(actual_lf_rows, collapse = ","), ".",
      call. = FALSE
    )
  }

  records <- vector("list", length(dom_comp_rows))
  for (j in seq_along(dom_comp_rows)) {
    line_index <- dom_comp_rows[[j]]
    tokens <- tokenised[[line_index]]
    lf <- suppressWarnings(as.numeric(tokens[lf_start:lf_end]))
    if (length(lf) != layout$n_lf || any(!is.finite(lf)) || any(lf < 0)) {
      stop("Malformed DOM length composition on line ", line_index, ".", call. = FALSE)
    }
    total <- sum(lf)
    if (!is.finite(total) || total <= 0) {
      stop("Non-positive DOM sample total on line ", line_index, ".", call. = FALSE)
    }
    fishery <- as.integer(tokens[[4L]])
    year <- as.integer(tokens[[1L]])
    month <- as.integer(tokens[[2L]])
    removed <- sum(lf[remove_bins])
    retained <- total - removed
    records[[j]] <- data.frame(
      line = line_index,
      year = year,
      month = month,
      period = dom_period_label(year, month),
      fishery = fishery,
      fishery_label = unname(fishery_labels[[as.character(fishery)]]),
      total_before = total,
      count_midpoint_gt90_before = removed,
      total_after = retained,
      removed_count = removed,
      action = if (removed == 0) {
        "unchanged"
      } else if (retained == 0) {
        "remove_empty_lf_composition"
      } else {
        "zero_bins_midpoint_gt90"
      },
      stringsAsFactors = FALSE
    )
  }
  audit <- do.call(rbind, records)

  expected_totals <- c(`21` = 2130, `22` = 108385, `23` = 50146)
  expected_removed <- c(`21` = 56, `22` = 6146, `23` = 1702)
  expected_affected <- c(`21` = 3L, `22` = 123L, `23` = 16L)
  actual_totals <- tapply(audit$total_before, audit$fishery, sum)
  actual_removed <- tapply(audit$removed_count, audit$fishery, sum)
  actual_affected <- tapply(audit$removed_count > 0, audit$fishery, sum)
  if (!identical(as.numeric(actual_totals), as.numeric(expected_totals)) ||
      !identical(as.numeric(actual_removed), as.numeric(expected_removed)) ||
      !identical(as.integer(actual_affected), as.integer(expected_affected))) {
    stop(
      "Job16594 DOM baseline counts changed: totals=",
      paste(actual_totals, collapse = ","), "; removed=",
      paste(actual_removed, collapse = ","), "; affected=",
      paste(actual_affected, collapse = ","), ".",
      call. = FALSE
    )
  }

  affected <- audit$removed_count > 0
  emptied <- audit$total_after == 0
  if (sum(emptied) != 1L ||
      !identical(audit$fishery[emptied], 21L) ||
      !identical(audit$period[emptied], "2010Q3")) {
    stop("Expected only F21 2010Q3 to become empty under DOM >90 cm QC.", call. = FALSE)
  }

  for (j in which(affected)) {
    line_index <- audit$line[[j]]
    tokens <- tokenised[[line_index]]
    prefix_before <- tokens[seq_len(7L)]
    lf <- as.numeric(tokens[lf_start:lf_end])
    lf[remove_bins] <- 0
    if (sum(lf) == 0) {
      ## An absent LF and an absent WF are each represented by one -1 field.
      ## Retain the first seven catch/effort fields verbatim.
      tokens <- c(prefix_before, "-1", "-1")
    } else {
      tokens[lf_start:lf_end] <- format(lf, scientific = FALSE, trim = TRUE)
    }
    if (!identical(tokens[seq_len(7L)], prefix_before)) {
      stop("DOM QC altered catch/effort fields on line ", line_index, ".", call. = FALSE)
    }
    lines_after[[line_index]] <- paste(tokens, collapse = " ")
  }

  changed_lines <- which(lines_before != lines_after)
  if (!identical(sort(changed_lines), sort(audit$line[affected]))) {
    stop("DOM QC line-change audit does not match the actual file diff.", call. = FALSE)
  }
  if (length(setdiff(changed_lines, dom_comp_rows))) {
    stop("DOM QC modified a non-DOM-composition line.", call. = FALSE)
  }

  writeLines(lines_after, frq_path, useBytes = TRUE)
  output_sha <- dom_sha256(frq_path)
  if (identical(output_sha, source_sha)) {
    stop("DOM QC output SHA unexpectedly equals its source SHA.", call. = FALSE)
  }

  summaries <- lapply(fisheries, function(fishery) {
    rows <- audit$fishery == fishery
    affected_rows <- rows & affected
    emptied_rows <- rows & emptied
    data.frame(
      mode = mode,
      cutoff_cm = 90,
      bin_rule = "remove intervals with midpoint >90 cm (lower bound >=90 cm)",
      fishery = fishery,
      fishery_label = unname(fishery_labels[[as.character(fishery)]]),
      source_sha256 = source_sha,
      output_sha256 = output_sha,
      fishery_rows = as.integer(actual_record_rows[[as.character(fishery)]]),
      lf_rows_before = sum(rows),
      lf_rows_affected = sum(affected_rows),
      lf_rows_removed_as_empty = sum(emptied_rows),
      lf_rows_after = sum(rows) - sum(emptied_rows),
      count_before = sum(audit$total_before[rows]),
      count_after = sum(audit$total_after[rows]),
      removed_count = sum(audit$removed_count[rows]),
      affected_periods = paste(audit$period[affected_rows], collapse = ";"),
      removed_empty_periods = paste(audit$period[emptied_rows], collapse = ";"),
      renormalised = FALSE,
      catch_or_effort_changed = FALSE,
      selectivity_changed = FALSE,
      stringsAsFactors = FALSE
    )
  })
  summary <- do.call(rbind, summaries)

  utils::write.csv(
    audit,
    file.path(model_dir, "dom-lf-qc-audit.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    summary,
    file.path(model_dir, "dom-lf-qc-summary.csv"),
    row.names = FALSE
  )
  message(
    "[dom-lf-qc] mode=", mode,
    "; affected LF rows=", sum(affected),
    "; removed empty LF rows=", sum(emptied),
    "; removed count=", sum(audit$removed_count),
    "; source SHA=", source_sha,
    "; output SHA=", output_sha
  )
  invisible(list(summary = summary, audit = audit))
}
