## Regenerate the branch README sections for the length-based selectivity
## sensitivity grid.

source("R/length_selectivity_sensitivity_rows.R")

escape_md <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("\\|", "\\\\|", x)
  x <- gsub("\n", " ", x, fixed = TRUE)
  trimws(gsub("\\s+", " ", x))
}

markdown_table <- function(df, code_cols = character()) {
  stopifnot(is.data.frame(df))
  if (!nrow(df)) return("_No rows configured._")
  headers <- names(df)
  body <- apply(df, 1, function(row) {
    vals <- vapply(seq_along(headers), function(i) {
      val <- escape_md(row[[i]])
      if (headers[[i]] %in% code_cols) paste0("`", val, "`") else val
    }, character(1))
    paste(vals, collapse = " | ")
  })
  paste(c(
    paste0("| ", paste(headers, collapse = " | "), " |"),
    paste0("| ", paste(rep("---", length(headers)), collapse = " | "), " |"),
    paste0("| ", body, " |")
  ), collapse = "\n")
}

scenario_axis <- function(spec) {
  id <- tolower(spec$step_id)
  has_tail <- grepl("llidx|idxmono|idxsoft|idxvsoft|llmono|llcoremono|llrecentmono|llosmono", id)
  if (grepl("bound359", id) && has_tail) return("Spline bound + tail")
  if (grepl("bound359", id)) return("Spline bound")
  if (grepl("nodome|dome|relax", id) && has_tail) return("Dome/cutoff + tail")
  if (grepl("nodome|dome|relax", id)) return("Dome/cutoff")
  if (grepl("youngzero|surface75|idx75|ll75|hl75", id) && has_tail) return("Young-zero + tail")
  if (grepl("youngzero|surface75|idx75|ll75|hl75", id)) return("Young-zero")
  if (grepl("llidx|llcoreidx|llosidx", id)) return("Adult + index tail")
  if (grepl("idxmono|idxsoft|idxvsoft", id)) return("Index tail")
  if (grepl("llmono|llcoremono|llrecentmono|llosmono", id)) return("Longline tail")
  if (grepl("-n[0-9]+$", id)) return("Node count")
  "Other"
}

switch_count <- function(spec) {
  edits <- spec$edits
  if (!length(edits)) return("0")
  by_flag <- split(vapply(edits, function(x) x[["scope"]], integer(1)), vapply(edits, function(x) x[["flag"]], integer(1)))
  paste(vapply(names(by_flag), function(flag) {
    sprintf("flag %s: %d", flag, length(by_flag[[flag]]))
  }, character(1)), collapse = "; ")
}

replace_section <- function(lines, heading, body, next_heading_pattern = "^## ") {
  start <- which(lines == heading)
  if (length(start) != 1L) {
    stop("Expected exactly one section heading: ", heading, call. = FALSE)
  }
  start <- start[[1L]]
  after <- lines[(start + 1L):length(lines)]
  next_heading <- grep(next_heading_pattern, after)
  end <- if (length(next_heading)) start + next_heading[[1L]] - 1L else length(lines) + 1L
  c(
    lines[seq_len(start)],
    "",
    body,
    "",
    if (end <= length(lines)) lines[end:length(lines)] else character()
  )
}

specs <- length_selectivity_sensitivity_specs()
scenario_count <- length(specs)
substep_range <- paste0("`", specs[[1L]]$substep, "`-`", specs[[scenario_count]]$substep, "`")
detail <- data.frame(
  Model = vapply(specs, `[[`, character(1), "step_id"),
  Axis = vapply(specs, scenario_axis, character(1)),
  Change = vapply(specs, `[[`, character(1), "change"),
  Reason = vapply(specs, `[[`, character(1), "notes"),
  stringsAsFactors = FALSE
)

axis_summary <- as.data.frame(table(detail$Axis), stringsAsFactors = FALSE)
names(axis_summary) <- c("Axis", "Rows")
axis_summary <- axis_summary[order(axis_summary$Axis), , drop = FALSE]

root_body <- paste(c(
  sprintf("This branch replaces the earlier 24-row length-based selectivity trial with a %d-row axis grid focused on plausible MFCL controls and selected interactions among those controls. All rows reuse `steps/13-LengthBasedSel/model`, are disabled by default, and run only when explicitly selected with `STEP_SELECT`, so the normal `main` stepwise sequence is unchanged.", scenario_count),
  "",
  "The grid stays close to options supported by MFCL ongoing-dev: cubic-spline node count (`fish flag 61`), length-based selectivity (`fish flag 26 = 3`), non-decreasing tails (`fish flag 16 = 1`), dome/terminal-zero cutoffs (`fish flags 16 = 2` and `3`), young-zero selectivity (`fish flag 75`), monotone penalty weight (`fish flag 56`), and spline lower-bound penalty (`parest flag 359`).",
  "",
  "Design: first vary one axis at a time, then add targeted crosses for node count x monotone-tail penalty, spline-bound x tail, dome/cutoff x tail, and young-zero x tail. This keeps the grid broad enough to diagnose interactions without launching every mathematically possible combination.",
  "",
  "### Scenario Families",
  "",
  markdown_table(axis_summary),
  "",
  "### Scenario Table",
  "",
  markdown_table(detail, code_cols = "Model")
), collapse = "\n")

step_detail <- transform(detail, Switches = vapply(specs, switch_count, character(1)))
step_detail <- step_detail[, c("Model", "Axis", "Change", "Switches", "Reason")]
step_body <- paste(c(
  sprintf("These %d disabled-by-default rows all start from `steps/13-LengthBasedSel/model`. They are run only when selected explicitly with `STEP_SELECT`, so the normal `all` run stays unchanged. Each sensitivity appends its switches after the base Step 13 selectivity block; MFCL's sequential option parsing therefore uses the appended values as the final settings.", scenario_count),
  "",
  "Useful switch shorthand:",
  "",
  "| Switch | Meaning in this grid |",
  "| --- | --- |",
  "| `-999 61 N` | Number of cubic-spline nodes for length-specific selectivity. Step 13 baseline is 5 nodes. |",
  "| `-fishery 16 1` | Non-decreasing soft penalty for that fishery's selectivity tail. Valid with length-specific spline selectivity in ongoing-dev. |",
  "| `-fishery 16 2` with `-fishery 3 cutoff` | Dome/terminal-zero style constraint for selected gears. Sensitivities change or remove these cutoffs. |",
  "| `-fishery 56 value` | Non-decreasing penalty strength. Source default is effectively `1000000` when unset. |",
  "| `-fishery 75 value` | Young-age selectivity zero setting used by that MFCL option. |",
  "| `1 359 value` | Spline lower-bound stabilizer, penalizing very low spline coefficients rather than forcing monotonicity. |",
  "",
  "### Scenario Families",
  "",
  markdown_table(axis_summary),
  "",
  "### Scenario Table",
  "",
  markdown_table(step_detail, code_cols = "Model")
), collapse = "\n")

root_path <- "README.md"
root_lines <- readLines(root_path, warn = FALSE)
root_lines <- replace_section(root_lines, "## Branch Focus", root_body)
root_lines <- sub("`13b`-`13[[:alnum:]]+`", substep_range, root_lines)
writeLines(root_lines, root_path, useBytes = TRUE)

step_path <- file.path("steps", "13-LengthBasedSel", "README.md")
step_lines <- readLines(step_path, warn = FALSE)
step_lines <- replace_section(step_lines, "## Length-Based Sensitivity Grid", step_body)
writeLines(step_lines, step_path, useBytes = TRUE)

message("Updated length-based selectivity README sections for ", length(specs), " scenarios.")
