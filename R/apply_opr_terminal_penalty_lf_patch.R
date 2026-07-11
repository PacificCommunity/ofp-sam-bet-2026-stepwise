## Apply one generated Step 11/12 sensitivity to a staged model directory.
## This file is sourced by steps/<generated>/patch.R after the parent model has
## been copied. All input edits are deterministic and validated before MFCL is
## launched.

patch_words <- function(line) {
  text <- trimws(sub("#.*$", "", line))
  if (!nzchar(text)) character() else strsplit(text, "[[:space:]]+")[[1L]]
}

patch_eol <- function(path) {
  raw <- readBin(path, what = "raw", n = min(file.info(path)$size, 65536L))
  if (length(raw) >= 2L && any(raw[-length(raw)] == as.raw(13L) & raw[-1L] == as.raw(10L))) "\r\n" else "\n"
}

patch_write_lines <- function(lines, path) {
  writeLines(lines, path, sep = patch_eol(path), useBytes = TRUE)
}

patch_replace_token <- function(line, index, value) {
  matches <- gregexpr("\\S+", line, perl = TRUE)[[1L]]
  widths <- attr(matches, "match.length")
  if (!length(matches) || matches[[1L]] < 0L || index > length(matches)) {
    stop("Cannot replace token ", index, " in line: ", line, call. = FALSE)
  }
  start <- matches[[index]]
  end <- start + widths[[index]] - 1L
  paste0(
    if (start > 1L) substr(line, 1L, start - 1L) else "",
    as.character(value),
    if (end < nchar(line)) substr(line, end + 1L, nchar(line)) else ""
  )
}

patch_phase_bounds <- function(lines, phase) {
  start <- grep(paste0("<<", phase, "$"), lines)
  end <- which(trimws(lines) == phase)
  end <- end[end > start]
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    stop("Expected exactly one ", phase, " heredoc.", call. = FALSE)
  }
  c(start = start, end = end)
}

patch_insert_phase <- function(lines, phase, block) {
  bounds <- patch_phase_bounds(lines, phase)
  c(lines[seq_len(bounds[["end"]] - 1L)], block, lines[bounds[["end"]]:length(lines)])
}

patch_append_phase12 <- function(lines, spec) {
  if (any(trimws(lines) == "PHASE12")) stop("PHASE12 already exists.", call. = FALSE)
  c(
    lines,
    "",
    "# ----------",
    "#  PHASE 12 - matched terminal-recruitment refinement",
    "# ----------",
    "# Every generated OPR sensitivity receives this 1,000-evaluation phase.",
    "# Weight zero is the matched optimisation control.",
    "$program_path bet.frq 11.par 12.par -file - <<PHASE12",
    sprintf("  1 202 %d  # terminal window in calendar years; age_flag(57)=4 quarters/year", spec$terminal_years),
    sprintf("  1 397 %d  # terminal-recruitment penalty weight = flag/10 = %g", spec$terminal_penalty_flag, spec$terminal_penalty_weight),
    "  1 1 1000  # matched function-evaluation budget",
    "  1 50 $phase10_11_convergence",
    "  1 246 1   # indepvar.rpt",
    "PHASE12"
  )
}

patch_selectivity_block <- function(profile) {
  switch(
    profile,
    baseline = character(),
    review_exact = c(
      "# Exact LF-review controls. F20 and F17 remain diagnostic because their paired fisheries share selectivity groups.",
      "  -20 16 0  -20 3 37",
      "  -28 16 0  -28 3 37",
      "  -26 75 1",
      "  -12 75 2",
      "  -17 16 2  -17 3 6"
    ),
    group_consistent = c(
      "# LF-review controls propagated to fisheries sharing selectivity groups.",
      "  -20 16 0  -20 3 37",
      "  -27 16 0  -27 3 37",
      "  -28 16 0  -28 3 37",
      "  -26 75 1",
      "  -12 75 2",
      "  -17 16 2  -17 3 6",
      "  -18 16 2  -18 3 6"
    ),
    large_fish_group = c(
      "# Isolated large-fish tail treatment, kept consistent within the F20/F27 selectivity group.",
      "  -20 16 0  -20 3 37",
      "  -27 16 0  -27 3 37",
      "  -28 16 0  -28 3 37"
    ),
    young_age = c(
      "# Isolated zero-selectivity treatment for unobserved young age classes.",
      "  -26 75 1",
      "  -12 75 2"
    ),
    f17_group = c(
      "# Isolated upper-age treatment, kept consistent within the F17/F18 selectivity group.",
      "  -17 16 2  -17 3 6",
      "  -18 16 2  -18 3 6"
    ),
    stop("Unknown fish profile: ", profile, call. = FALSE)
  )
}

patch_tag_control_block <- function(spec) {
  likelihood_flag <- switch(
    spec$tag_likelihood,
    negative_binomial = 4L,
    recaptures_conditioned = 4L,
    binned_gamma = 5L,
    robust_binned_gamma = 6L,
    stop("Unknown tag likelihood: ", spec$tag_likelihood, call. = FALSE)
  )
  block <- c(
    "# Explicit tag-observation controls for this sensitivity.",
    sprintf("  1 111 %d  # tag observation likelihood", likelihood_flag),
    sprintf("  1 177 %d  # tag likelihood scalar: zero=full; otherwise flag/1000", spec$tag_weight_flag),
    sprintf("  1 249 %d  # recaptures-conditioned tag likelihood", as.integer(spec$tag_likelihood == "recaptures_conditioned")),
    sprintf("  1 360 %d  # assumed long-term tag loss", as.integer(spec$tag_loss_mode != "none"))
  )
  if (isTRUE(spec$estimate_tag_dispersion)) {
    block <- c(
      block,
      "  1 305 1   # estimate tag dispersion with explicit source-supported bounds",
      "  1 306 0   # use default bounds",
      "  -999 43 1 -999 44 1  # one pooled dispersion parameter"
    )
  } else {
    block <- c(block, "  -999 43 0 -999 44 0  # retain fixed tag dispersion")
  }
  if (spec$tag_likelihood %in% c("binned_gamma", "robust_binned_gamma")) {
    block <- c(
      block,
    "  1 325 110  # bin zero/small cells below 1.1 observed recaptures",
      sprintf("  1 326 %d  # robust-mixture fraction flag/1000", if (spec$tag_likelihood == "robust_binned_gamma") 50L else 0L)
    )
  }
  block
}

patch_ini_section_rows <- function(lines, marker) {
  marker_i <- which(trimws(lines) == marker)
  if (length(marker_i) != 1L) stop("Expected one INI section ", marker, call. = FALSE)
  comments <- which(grepl("^#", trimws(lines)) & seq_along(lines) > marker_i)
  if (!length(comments)) stop("Could not find end of INI section ", marker, call. = FALSE)
  idx <- seq.int(marker_i + 1L, comments[[1L]] - 1L)
  idx[nzchar(trimws(lines[idx]))]
}

patch_ini_matrix <- function(lines, marker, transform) {
  idx <- patch_ini_section_rows(lines, marker)
  values <- lapply(lines[idx], patch_words)
  widths <- unique(lengths(values))
  if (length(widths) != 1L) stop("Uneven matrix width at ", marker, call. = FALSE)
  matrix_values <- matrix(unlist(values, use.names = FALSE), nrow = length(values), byrow = TRUE)
  matrix_values <- transform(matrix_values)
  if (!is.matrix(matrix_values) || nrow(matrix_values) < 1L) stop("Invalid matrix transform at ", marker, call. = FALSE)
  replacement <- apply(matrix_values, 1L, paste, collapse = " ")
  c(
    if (idx[[1L]] > 1L) lines[seq_len(idx[[1L]] - 1L)] else character(),
    replacement,
    if (idx[[length(idx)]] < length(lines)) lines[seq.int(idx[[length(idx)]] + 1L, length(lines))] else character()
  )
}

patch_ini_tag_controls <- function(path, spec) {
  lines <- readLines(path, warn = FALSE)
  tag_idx <- patch_ini_section_rows(lines, "# tag flags")
  if (length(tag_idx) != 98L) stop("Expected 98 parent tag-flag rows.", call. = FALSE)
  tags <- matrix(unlist(lapply(lines[tag_idx], patch_words), use.names = FALSE), nrow = 98L, byrow = TRUE)
  if (ncol(tags) != 10L) stop("Expected ten tag flags per release.", call. = FALSE)
  if (spec$tag_rr_mixing_mode == "2021") tags[c(18L, 60L), 2L] <- "1"
  if (spec$tag_rr_mixing_mode == "group60") tags[60L, 2L] <- "1"
  if (spec$tag_rr_mixing_mode == "all") tags[, 2L] <- "1"
  if (!is.na(spec$tag_2021_mixing_period)) tags[60L, 1L] <- as.character(spec$tag_2021_mixing_period)
  lines[tag_idx] <- apply(tags, 1L, paste, collapse = " ")

  if (spec$rr_2021_scope != "shared") {
    rr_rows <- switch(
      spec$rr_2021_scope,
      campaign = c(18L, 60L),
      group60 = 60L,
      stop("Unknown 2021 reporting-rate scope: ", spec$rr_2021_scope, call. = FALSE)
    )
    rr_columns <- 25:28
    matrix_specs <- list(
      list(marker = "# tag fish rep", inherited = 0.52015, value = spec$rr_2021_target),
      list(marker = "# tag fish rep group flags", inherited = 17, value = 30),
      list(marker = "# tag_fish_rep active flags", inherited = 1, value = 1),
      list(marker = "# tag_fish_rep target", inherited = 52.015, value = 100 * spec$rr_2021_target),
      list(marker = "# tag_fish_rep penalty", inherited = 485.2, value = spec$rr_2021_penalty)
    )
    for (control in matrix_specs) {
      idx <- patch_ini_section_rows(lines, control$marker)
      values <- matrix(
        unlist(lapply(lines[idx], patch_words), use.names = FALSE),
        nrow = length(idx),
        byrow = TRUE
      )
      if (!identical(dim(values), c(99L, 33L))) {
        stop("Expected a 99x33 reporting-rate matrix at ", control$marker, ".", call. = FALSE)
      }
      inherited <- as.numeric(values[rr_rows, rr_columns, drop = FALSE])
      if (any(abs(inherited - control$inherited) > 1e-8)) {
        stop("Unexpected inherited 2021 reporting-rate values at ", control$marker, ".", call. = FALSE)
      }
      values[rr_rows, rr_columns] <- format(control$value, scientific = FALSE, trim = TRUE)
      lines[idx] <- apply(values, 1L, paste, collapse = " ")
    }
    group_idx <- patch_ini_section_rows(lines, "# tag fish rep group flags")
    groups <- matrix(unlist(lapply(lines[group_idx], patch_words), use.names = FALSE), nrow = length(group_idx), byrow = TRUE)
    if (max(suppressWarnings(as.integer(groups)), na.rm = TRUE) != 30L) {
      stop("The separated reporting-rate parameter did not create group 30.", call. = FALSE)
    }
  }

  if (spec$tag_loss_mode != "none") {
    shed_idx <- patch_ini_section_rows(lines, "# tag shed rate")
    shed <- unlist(lapply(lines[shed_idx], patch_words), use.names = FALSE)
    if (length(shed) != 98L) stop("Expected 98 inherited tag-loss values.", call. = FALSE)
    if (spec$tag_loss_mode == "all") shed[] <- format(spec$tag_loss_rate, scientific = FALSE, trim = TRUE)
    lines <- c(
      if (shed_idx[[1L]] > 1L) lines[seq_len(shed_idx[[1L]] - 1L)] else character(),
      paste(shed, collapse = " "),
      if (shed_idx[[length(shed_idx)]] < length(lines)) lines[seq.int(shed_idx[[length(shed_idx)]] + 1L, length(lines))] else character()
    )
  }
  patch_write_lines(lines, path)
}

patch_remove_tag_groups <- function(path, drop_groups = c(18L, 60L)) {
  lines <- readLines(path, warn = FALSE)
  markers <- grep("^#[[:space:]]*[0-9]+[[:space:]]*-[[:space:]]*RELEASE REGION", lines)
  n_before <- length(markers)
  if (n_before != 98L) stop("Expected 98 release blocks in TAG input.", call. = FALSE)
  keep <- setdiff(seq_len(n_before), drop_groups)

  header_data <- which(nzchar(trimws(lines)) & !grepl("^#", trimws(lines)))[[1L]]
  lines[[header_data]] <- patch_replace_token(lines[[header_data]], 1L, length(keep))
  recovery_marker <- grep("^#[[:space:]]*TAG RECOVERIES", lines)
  if (length(recovery_marker) != 1L) stop("Expected one TAG RECOVERIES section.", call. = FALSE)
  recovery_data <- which(
    seq_along(lines) > recovery_marker &
      seq_along(lines) < markers[[1L]] &
      nzchar(trimws(lines)) &
      !grepl("^#", trimws(lines))
  )
  if (length(recovery_data) != 1L) stop("Expected one TAG recovery-count vector.", call. = FALSE)
  recoveries <- patch_words(lines[[recovery_data]])
  if (length(recoveries) != n_before) stop("TAG recovery-count vector does not match release blocks.", call. = FALSE)
  lines[[recovery_data]] <- paste(recoveries[keep], collapse = " ")
  recovery_labels <- which(
    seq_along(lines) > recovery_marker & seq_along(lines) < recovery_data &
      grepl("^#[[:space:]]+[0-9]", lines)
  )
  if (length(recovery_labels) != 1L) stop("Expected one TAG recovery-label vector.", call. = FALSE)
  lines[[recovery_labels]] <- paste("#   ", paste(seq_along(keep), collapse = " "))

  markers <- grep("^#[[:space:]]*[0-9]+[[:space:]]*-[[:space:]]*RELEASE REGION", lines)
  ends <- c(markers[-1L] - 1L, length(lines))
  blocks <- lapply(seq_along(markers), function(i) lines[seq.int(markers[[i]], ends[[i]])])
  blocks <- blocks[keep]
  blocks <- lapply(seq_along(blocks), function(i) {
    blocks[[i]][[1L]] <- sub(
      "^#[[:space:]]*[0-9]+([[:space:]]*-[[:space:]]*RELEASE REGION)",
      paste0("#  ", i, "\\1"),
      blocks[[i]][[1L]],
      perl = TRUE
    )
    blocks[[i]]
  })
  prefix <- lines[seq_len(markers[[1L]] - 1L)]
  patch_write_lines(c(prefix, unlist(blocks, use.names = FALSE)), path)
  invisible(list(before = n_before, after = length(keep), keep = keep))
}

patch_frq_tag_count <- function(path, n_groups) {
  lines <- readLines(path, warn = FALSE)
  data_i <- which(nzchar(trimws(lines)) & !grepl("^#", trimws(lines)))[[1L]]
  words <- patch_words(lines[[data_i]])
  if (length(words) < 4L || as.integer(words[[4L]]) != 98L) stop("Unexpected FRQ tag-group header.", call. = FALSE)
  lines[[data_i]] <- patch_replace_token(lines[[data_i]], 4L, n_groups)
  patch_write_lines(lines, path)
}

patch_subset_ini_tag_groups <- function(path, keep_groups) {
  lines <- readLines(path, warn = FALSE)
  subset_rows <- function(lines, marker, rows) {
    idx <- patch_ini_section_rows(lines, marker)
    if (max(rows) > length(idx)) stop("Cannot subset ", marker, call. = FALSE)
    c(
      if (idx[[1L]] > 1L) lines[seq_len(idx[[1L]] - 1L)] else character(),
      lines[idx[rows]],
      if (idx[[length(idx)]] < length(lines)) lines[seq.int(idx[[length(idx)]] + 1L, length(lines))] else character()
    )
  }
  lines <- subset_rows(lines, "# tag flags", keep_groups)
  shed_idx <- patch_ini_section_rows(lines, "# tag shed rate")
  shed <- unlist(lapply(lines[shed_idx], patch_words), use.names = FALSE)
  if (length(shed) != 98L) stop("Expected 98 tag-loss values before subsetting.", call. = FALSE)
  lines <- c(
    if (shed_idx[[1L]] > 1L) lines[seq_len(shed_idx[[1L]] - 1L)] else character(),
    paste(shed[keep_groups], collapse = " "),
    if (shed_idx[[length(shed_idx)]] < length(lines)) lines[seq.int(shed_idx[[length(shed_idx)]] + 1L, length(lines))] else character()
  )
  for (marker in c(
    "# tag fish rep", "# tag fish rep group flags", "# tag_fish_rep active flags",
    "# tag_fish_rep target", "# tag_fish_rep penalty"
  )) {
    idx <- patch_ini_section_rows(lines, marker)
    if (length(idx) != 99L) stop("Expected 99 rows before subsetting ", marker, call. = FALSE)
    lines <- subset_rows(lines, marker, c(keep_groups, 99L))
  }
  patch_write_lines(lines, path)
}

patch_regenerate_tag_map <- function(model_dir, root) {
  source(file.path(root, "R", "prepare_common.R"), local = TRUE)
  source(file.path(root, "R", "prepare_mfcl_inputs.R"), local = TRUE)
  write_generated_tag_rep_map(model_dir)
}

patch_write_provenance <- function(model_dir, spec) {
  inputs <- c("bet.frq", "bet.ini", "bet.tag", "doitall.sh", "tag_rep_map.R", "fishery_map.R")
  inputs <- inputs[file.exists(file.path(model_dir, inputs))]
  hashes <- data.frame(
    file = inputs,
    bytes = as.numeric(file.info(file.path(model_dir, inputs))$size),
    md5 = unname(tools::md5sum(file.path(model_dir, inputs))),
    stringsAsFactors = FALSE
  )
  write.csv(hashes, file.path(model_dir, "sensitivity-input-hashes.csv"), row.names = FALSE)
  write.csv(spec, file.path(model_dir, "sensitivity-spec.csv"), row.names = FALSE)
}

apply_opr_terminal_penalty_lf_patch <- function(model_dir, step_id, root = getwd()) {
  source(file.path(root, "R", "step12_opr_terminal_penalty_lf_config.R"), local = TRUE)
  spec_all <- opr_terminal_penalty_lf_model_spec()
  spec <- spec_all[spec_all$step_id == step_id, , drop = FALSE]
  if (nrow(spec) != 1L) stop("Expected one sensitivity specification for ", step_id, call. = FALSE)

  doitall <- file.path(model_dir, "doitall.sh")
  ini <- file.path(model_dir, "bet.ini")
  frq <- file.path(model_dir, "bet.frq")
  tag <- file.path(model_dir, "bet.tag")
  required <- c(doitall, ini, frq, tag)
  if (!all(file.exists(required))) stop("Staged parent model is incomplete for ", step_id, call. = FALSE)

  ## INI/TAG/FRQ edits occur before -makepar, so a 98-group fitted PAR is never
  ## reused for a 96-group deletion model.
  patch_ini_tag_controls(ini, spec)
  regenerate_tag_map <- spec$rr_2021_scope != "shared"
  if (isTRUE(spec$remove_2021_tags)) {
    drop_groups <- switch(
      spec$tag_deletion,
      group18 = 18L,
      group60 = 60L,
      both = c(18L, 60L),
      stop("Unknown tag deletion mode: ", spec$tag_deletion, call. = FALSE)
    )
    removed <- patch_remove_tag_groups(tag, drop_groups)
    patch_frq_tag_count(frq, removed$after)
    patch_subset_ini_tag_groups(ini, removed$keep)
    regenerate_tag_map <- TRUE
  }
  if (isTRUE(regenerate_tag_map)) patch_regenerate_tag_map(model_dir, root)

  lines <- readLines(doitall, warn = FALSE)
  phase1 <- c(
    "# ------------------------------------------------------------",
    "# Generated sensitivity overrides (last setting wins in PHASE 1)",
    patch_selectivity_block(spec$fish_profile),
    patch_tag_control_block(spec)
  )
  if (spec$parameterization == "standard") {
    phase1 <- c(
      phase1,
      "# Ordinary recruitment-deviation terminal treatment.",
      sprintf("  1 400 %d  # fixed terminal quarterly recruitment deviations", spec$standard_terminal_quarters),
      sprintf("  1 398 %d  # arithmetic-mean terminal treatment", as.integer(isTRUE(spec$standard_arithmetic_mean) && spec$standard_terminal_quarters > 0L))
    )
  }
  lines <- patch_insert_phase(lines, "PHASE1", phase1)

  if (spec$parameterization == "opr") {
    phase3 <- c(
      "# Generated OPR terminal controls; terminal penalty starts only in PHASE 12.",
      sprintf("  1 202 %d", spec$terminal_years),
      "  1 397 0",
      sprintf("  1 153 %d  # OPR trend penalty: -1 off, 0 default 0.01, positive flag/10", spec$trend_flag)
    )
    lines <- patch_insert_phase(lines, "PHASE3", phase3)
    lines <- patch_append_phase12(lines, spec)
  }
  patch_write_lines(lines, doitall)
  Sys.chmod(doitall, mode = "0755")
  shell_status <- system2("bash", c("-n", doitall), stdout = FALSE, stderr = FALSE)
  if (!identical(shell_status, 0L)) stop("bash -n failed for patched doitall.sh", call. = FALSE)

  patch_write_provenance(model_dir, spec)
  invisible(spec)
}
