## Apply the agreed BET 2026 PH/ID and domestic mixed-gear size-data rules.
##
## The edits are deliberately restricted to length-frequency fields:
##   * F15 bins below 70 cm are set to zero without renormalisation.
##   * F21-F23 bins whose midpoint is above 90 cm are set to zero.
##   * An LF composition that becomes empty is encoded as absent (`-1`).

size_qc_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && as.integer(status) != 0L) {
    stop("sha256sum failed for ", path, call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

size_qc_layout <- function(lines) {
  marker <- grep("^# Datasets / LFIntervals", lines)
  if (length(marker) != 1L) {
    stop("Could not uniquely locate the LF interval header.", call. = FALSE)
  }
  candidate <- seq.int(marker + 1L, length(lines))
  candidate <- candidate[
    nzchar(trimws(lines[candidate])) & !grepl("^\\s*#", lines[candidate])
  ]
  values <- scan(text = lines[candidate[[1L]]], quiet = TRUE)
  layout <- list(
    n_lf = as.integer(values[[2L]]),
    first = as.numeric(values[[3L]]),
    width = as.numeric(values[[4L]])
  )
  if (layout$n_lf != 95L || layout$first != 10 || layout$width != 2) {
    stop("Unexpected length-frequency layout.", call. = FALSE)
  }
  layout
}

size_qc_tokens <- function(line) {
  strsplit(trimws(line), "[[:space:]]+")[[1L]]
}

size_qc_is_fishery_record <- function(tokens, fisheries) {
  if (length(tokens) < 7L) return(FALSE)
  prefix <- suppressWarnings(as.numeric(tokens[seq_len(4L)]))
  all(is.finite(prefix)) &&
    prefix[[1L]] >= 1900 && prefix[[1L]] <= 2100 &&
    as.integer(prefix[[4L]]) %in% fisheries
}

size_qc_period <- function(year, month) {
  quarter <- match(as.integer(month), c(2L, 5L, 8L, 11L))
  if (is.na(quarter)) stop("Unexpected seasonal month: ", month, call. = FALSE)
  sprintf("%dQ%d", as.integer(year), quarter)
}

apply_bet_size_data_qc <- function(
    model_dir, frq_name = "bet.frq", expected_source_sha256 = "") {
  path <- file.path(model_dir, frq_name)
  if (!file.exists(path)) stop("Missing size-QC FRQ: ", path, call. = FALSE)
  source_sha <- size_qc_sha256(path)
  if (nzchar(expected_source_sha256) &&
      !identical(source_sha, expected_source_sha256)) {
    stop(
      "Size-QC source SHA mismatch. Expected ", expected_source_sha256,
      ", observed ", source_sha, ".", call. = FALSE
    )
  }

  lines <- readLines(path, warn = FALSE)
  layout <- size_qc_layout(lines)
  lower_bounds <- layout$first + layout$width * (seq_len(layout$n_lf) - 1L)
  midpoints <- lower_bounds + layout$width / 2
  lf_start <- 8L
  lf_end <- 7L + layout$n_lf

  ## F15: zero bins below 70 cm.
  tokenised <- lapply(lines, size_qc_tokens)
  f15_rows <- which(vapply(
    tokenised, size_qc_is_fishery_record, logical(1L), fisheries = 15L
  ))
  f15_comps <- f15_rows[vapply(tokenised[f15_rows], function(x) {
    length(x) == lf_end + 1L && identical(x[[lf_end + 1L]], "-1")
  }, logical(1L))]
  if (length(f15_rows) != 220L || length(f15_comps) != 135L) {
    stop("Unexpected F15 row counts.", call. = FALSE)
  }

  f15_audit <- lapply(f15_comps, function(line_index) {
    tokens <- tokenised[[line_index]]
    lf <- as.numeric(tokens[lf_start:lf_end])
    removed <- sum(lf[lower_bounds < 70])
    before <- sum(lf)
    if (removed > 0) {
      lf[lower_bounds < 70] <- 0
      if (sum(lf) <= 0) stop("F15 QC emptied a composition.", call. = FALSE)
      tokens[lf_start:lf_end] <- format(lf, scientific = FALSE, trim = TRUE)
      lines[[line_index]] <<- paste(tokens, collapse = " ")
    }
    data.frame(
      line = line_index,
      period = size_qc_period(tokens[[1L]], tokens[[2L]]),
      total_before = before,
      total_after = before - removed,
      removed_count = removed,
      action = if (removed > 0) "zero_bins_lt70" else "unchanged",
      stringsAsFactors = FALSE
    )
  })
  f15_audit <- do.call(rbind, f15_audit)
  if (sum(f15_audit$total_before) != 41908 ||
      sum(f15_audit$removed_count) != 1057 ||
      sum(f15_audit$removed_count > 0) != 66L) {
    stop("F15 baseline or removal counts changed.", call. = FALSE)
  }

  intermediate_sha <- ""
  writeLines(lines, path, useBytes = TRUE)
  intermediate_sha <- size_qc_sha256(path)

  ## F21-F23: remove bins with midpoint >90 cm (lower bound >=90 cm).
  lines <- readLines(path, warn = FALSE)
  tokenised <- lapply(lines, size_qc_tokens)
  fisheries <- 21:23
  dom_rows <- which(vapply(
    tokenised, size_qc_is_fishery_record, logical(1L), fisheries = fisheries
  ))
  dom_comps <- dom_rows[vapply(tokenised[dom_rows], function(x) {
    length(x) == lf_end + 1L && identical(x[[lf_end + 1L]], "-1")
  }, logical(1L))]
  record_counts <- table(factor(
    vapply(tokenised[dom_rows], function(x) as.integer(x[[4L]]), integer(1L)),
    levels = fisheries
  ))
  comp_counts <- table(factor(
    vapply(tokenised[dom_comps], function(x) as.integer(x[[4L]]), integer(1L)),
    levels = fisheries
  ))
  if (!identical(as.integer(record_counts), c(220L, 220L, 100L)) ||
      !identical(as.integer(comp_counts), c(40L, 138L, 21L))) {
    stop("Unexpected domestic-fishery row counts.", call. = FALSE)
  }

  remove_bins <- midpoints > 90
  dom_audit <- lapply(dom_comps, function(line_index) {
    tokens <- tokenised[[line_index]]
    prefix <- tokens[seq_len(7L)]
    lf <- as.numeric(tokens[lf_start:lf_end])
    before <- sum(lf)
    removed <- sum(lf[remove_bins])
    after <- before - removed
    if (removed > 0) {
      lf[remove_bins] <- 0
      if (after == 0) {
        tokens <- c(prefix, "-1", "-1")
      } else {
        tokens[lf_start:lf_end] <- format(lf, scientific = FALSE, trim = TRUE)
      }
      if (!identical(tokens[seq_len(7L)], prefix)) {
        stop("Size QC changed catch or effort fields.", call. = FALSE)
      }
      lines[[line_index]] <<- paste(tokens, collapse = " ")
    }
    data.frame(
      line = line_index,
      period = size_qc_period(tokens[[1L]], tokens[[2L]]),
      fishery = as.integer(tokens[[4L]]),
      total_before = before,
      total_after = after,
      removed_count = removed,
      action = if (removed == 0) "unchanged" else if (after == 0) {
        "remove_empty_lf_composition"
      } else {
        "zero_bins_midpoint_gt90"
      },
      stringsAsFactors = FALSE
    )
  })
  dom_audit <- do.call(rbind, dom_audit)
  dom_totals <- tapply(dom_audit$total_before, dom_audit$fishery, sum)
  dom_removed <- tapply(dom_audit$removed_count, dom_audit$fishery, sum)
  dom_affected <- tapply(dom_audit$removed_count > 0, dom_audit$fishery, sum)
  if (!identical(as.numeric(dom_totals), c(2130, 108385, 50146)) ||
      !identical(as.numeric(dom_removed), c(56, 6146, 1702)) ||
      !identical(as.integer(dom_affected), c(3L, 123L, 16L))) {
    stop("Domestic-fishery baseline or removal counts changed.", call. = FALSE)
  }
  emptied <- dom_audit$total_after == 0
  if (sum(emptied) != 1L ||
      dom_audit$fishery[emptied] != 21L ||
      dom_audit$period[emptied] != "2010Q3") {
    stop("Expected only F21 2010Q3 to become empty.", call. = FALSE)
  }

  writeLines(lines, path, useBytes = TRUE)
  output_sha <- size_qc_sha256(path)

  f15_summary <- data.frame(
    rule = "F15 lower-bound bins <70 cm set to zero",
    source_sha256 = source_sha,
    output_sha256 = intermediate_sha,
    lf_rows = nrow(f15_audit),
    affected_rows = sum(f15_audit$removed_count > 0),
    count_before = sum(f15_audit$total_before),
    count_after = sum(f15_audit$total_after),
    removed_count = sum(f15_audit$removed_count),
    renormalised = FALSE,
    catch_or_effort_changed = FALSE,
    stringsAsFactors = FALSE
  )
  dom_summary <- do.call(rbind, lapply(fisheries, function(fishery) {
    rows <- dom_audit$fishery == fishery
    data.frame(
      rule = "interval midpoint >90 cm removed",
      fishery = fishery,
      source_sha256 = intermediate_sha,
      output_sha256 = output_sha,
      lf_rows_before = sum(rows),
      affected_rows = sum(rows & dom_audit$removed_count > 0),
      empty_rows_removed = sum(rows & dom_audit$total_after == 0),
      count_before = sum(dom_audit$total_before[rows]),
      count_after = sum(dom_audit$total_after[rows]),
      removed_count = sum(dom_audit$removed_count[rows]),
      renormalised = FALSE,
      catch_or_effort_changed = FALSE,
      stringsAsFactors = FALSE
    )
  }))
  utils::write.csv(
    f15_audit, file.path(model_dir, "f15-lf-qc-audit.csv"), row.names = FALSE
  )
  utils::write.csv(
    f15_summary, file.path(model_dir, "f15-lf-qc-summary.csv"), row.names = FALSE
  )
  utils::write.csv(
    dom_audit, file.path(model_dir, "dom-lf-qc-audit.csv"), row.names = FALSE
  )
  utils::write.csv(
    dom_summary, file.path(model_dir, "dom-lf-qc-summary.csv"), row.names = FALSE
  )
  message(
    "[size-data-qc] F15 removed=", sum(f15_audit$removed_count),
    "; F21-F23 removed=", sum(dom_audit$removed_count),
    "; output SHA=", output_sha
  )
  invisible(list(
    source_sha256 = source_sha,
    intermediate_sha256 = intermediate_sha,
    output_sha256 = output_sha,
    f15 = f15_summary,
    domestic = dom_summary
  ))
}
