## Helpers that patch generated `doitall.sh` controls for stepwise variants.

replace_one_line <- function(lines, pattern, replacement) {
  hit <- grep(pattern, lines)
  if (length(hit) != 1L) {
    stop("Expected one doitall line matching: ", pattern, call. = FALSE)
  }
  lines[[hit]] <- replacement
  lines
}

set_doitall_fishery_flag <- function(lines, fishery, flag, value) {
  pattern <- sprintf("(^|[[:space:]])-%d[[:space:]]+%d[[:space:]]+", fishery, flag)
  hit <- grep(pattern, lines)
  if (length(hit) != 1L) {
    stop(
      "Expected one doitall fishery flag for fishery ", fishery,
      " and flag ", flag,
      call. = FALSE
    )
  }
  line <- lines[[hit]]
  comment <- regmatches(line, regexpr("[[:space:]]+#.*$", line))
  body <- sub("[[:space:]]+#.*$", "", line)
  words <- read_words(body)
  targets <- which(
    seq_along(words) <= length(words) - 2L &
      words == paste0("-", fishery) &
      words[seq_along(words) + 1L] == as.character(flag)
  )
  if (length(targets) != 1L) {
    stop(
      "Expected one doitall triplet for fishery ", fishery,
      " and flag ", flag,
      call. = FALSE
    )
  }
  words[[targets + 2L]] <- as.character(value)
  lines[[hit]] <- paste0(
    "  ",
    paste(words, collapse = " "),
    if (length(comment)) comment else ""
  )
  lines
}

write_program_path_doitall <- function(from, to) {
  lines <- readLines(from, warn = FALSE)
  if (!length(lines) || !grepl("^#!", lines[[1]])) {
    lines <- c("#!/bin/sh", lines)
  }
  if (!any(grepl("^set -eu$", lines))) {
    lines <- append(lines, "set -eu", after = 1L)
  }
  if (!any(grepl("^program_path=", lines))) {
    lines <- append(lines, c(
      "",
      "program_path=${PROGRAM_PATH:-}",
      "",
      "if [ -z \"$program_path\" ]; then",
      "  echo \"PROGRAM_PATH is not set. Exiting.\"",
      "  exit 1",
      "fi"
    ), after = 2L)
  }
  lines <- sub("^program_path=[$][{]PROGRAM_PATH[}]$", "program_path=${PROGRAM_PATH:-}", lines)
  lines <- sub("^([[:space:]]*)mfclo64([[:space:]])", "\\1$program_path\\2", lines)
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
  invisible(to)
}

apply_2023_newexe_controls <- function(lines) {
  cpue_cv <- c(
    "33" = 24L,
    "34" = 31L,
    "35" = 20L,
    "36" = 21L,
    "37" = 26L,
    "38" = 23L,
    "39" = 20L,
    "40" = 25L,
    "41" = 47L
  )
  for (fishery in names(cpue_cv)) {
    lines <- set_doitall_fishery_flag(
      lines,
      fishery = as.integer(fishery),
      flag = 92L,
      value = cpue_cv[[fishery]]
    )
  }
  old_initial_z <- "^[[:space:]]*2[[:space:]]+94[[:space:]]+1[[:space:]]+2[[:space:]]+128[[:space:]]+10([[:space:]]|$)"
  new_initial_z <- "^[[:space:]]*2[[:space:]]+94[[:space:]]+1[[:space:]]+2[[:space:]]+128[[:space:]]+100([[:space:]]|$)"
  if (any(grepl(old_initial_z, lines))) {
    lines <- replace_one_line(
      lines,
      old_initial_z,
      "  2 94 1 2 128 100  # initial Z = 1.0*M, i.e. initial F = 0"
    )
  } else if (!any(grepl(new_initial_z, lines))) {
    stop("Expected one current-executable initial Z line in doitall.sh", call. = FALSE)
  }
  lines
}

apply_2023_current_baseline_tail_controls <- function(lines, fixm = FALSE) {
  if (isTRUE(fixm)) {
    lines <- replace_one_line(
      lines,
      "^[[:space:]]*1[[:space:]]+121[[:space:]]+1([[:space:]]|$)",
      "  1 121 0    # estimate scaling parameter for Lorenzen (age_pars(5,1)); off"
    )
  }
  phase11_start <- grep("<<PHASE11$", lines)
  phase11_end <- grep("^PHASE11$", lines)
  if (length(phase11_start) != 1L || length(phase11_end) != 1L || phase11_start >= phase11_end) {
    stop("Expected one PHASE11 block in the 2023 current baseline doitall", call. = FALSE)
  }
  phase11_block <- seq.int(phase11_start, phase11_end)
  if (!any(grepl("^[[:space:]]*1[[:space:]]+246[[:space:]]+1([[:space:]]|$)", lines[phase11_block]))) {
    lines <- append(lines, "  1 246 1   # indepvar.rpt", after = phase11_end - 1L)
  }
  lines
}

remove_tag_mixing_override <- function(lines) {
  target <- grep("-9999 1 2", lines, fixed = TRUE)
  if (length(target)) {
    lines[[target[[1]]]] <-
      "# Mixing periods are read from bet.ini tag flags for this step."
  }
  lines
}

write_2023_newexe_doitall <- function(from, to, fixm = FALSE, mix_from_ini = TRUE) {
  write_program_path_doitall(from, to)
  lines <- readLines(to, warn = FALSE)
  lines <- apply_2023_newexe_controls(lines)
  if (isTRUE(mix_from_ini)) {
    lines <- remove_tag_mixing_override(lines)
  }
  lines <- apply_phase10_11_convergence_switch(lines)
  lines <- apply_2023_current_baseline_tail_controls(lines, fixm = fixm)
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
  invisible(to)
}

write_2023_historical_doitall <- function(from, to) {
  lines <- readLines(from, warn = FALSE)
  lines <- apply_historical_phase10_11_convergence_switch(lines)
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
  invisible(to)
}

apply_size_based_selectivity <- function(lines) {
  replace_one_line(
    lines,
    "^[[:space:]]*-999[[:space:]]+26[[:space:]]+2[[:space:]]",
    "  -999 26 3  # use length-based selectivity"
  )
}

apply_time_varying_cpue_cv <- function(lines, index_fisheries = 29:33) {
  for (fishery in index_fisheries) {
    lines <- set_doitall_fishery_flag(lines, fishery = fishery, flag = 66L, value = 1L)
  }
  lines
}

apply_opr <- function(lines, year_effect = 69L, season_effect = 1L,
                      region_effect = 50L, region_season_effect = 50L,
                      terminal_year_constraint = 2L) {
  phase3 <- grep("^[[:space:]]*2[[:space:]]+70[[:space:]]+1[[:space:]]", lines)
  if (length(phase3) != 1L) {
    stop("Expected one phase-3 recruitment flag block for OPR", call. = FALSE)
  }
  old_block <- lines[phase3:(phase3 + 2L)]
  expected <- c("2[[:space:]]+70[[:space:]]+1",
                "2[[:space:]]+71[[:space:]]+1",
                "2[[:space:]]+178[[:space:]]+1")
  if (!all(mapply(grepl, expected, old_block))) {
    stop("Unexpected phase-3 recruitment flag block for OPR", call. = FALSE)
  }
  new_block <- c(
    "# OPR settings. BET OPR screening rank-1 model: 69-01-50-50.",
    "  1 149 0   # turn off recruitment-deviation penalty for OPR",
    "  1 398 0   # turn off arithmetic-mean terminal fixed-recruitment option for OPR",
    "  1 400 0   # clear fixed terminal recruitment-deviate block for OPR",
    "  2 177 0   # turn off old total-pop scaling for OPR",
    "  2 32 0    # turn off overall population scaling parameter for OPR",
    "  2 113 0   # keep scaling init pop off during OPR transfer",
    sprintf("  1 155 %d  # orthogonal polynomial recruitment - year effect", year_effect),
    sprintf("  1 217 %d   # orthogonal polynomial recruitment - season effect", season_effect),
    sprintf("  1 216 %d  # orthogonal polynomial recruitment - region effect", region_effect),
    sprintf("  1 218 %d  # orthogonal polynomial recruitment - region-season interaction effect", region_season_effect),
    sprintf("  1 202 %d   # OPR end window: last %d real years use lower-degree/constant-end basis", terminal_year_constraint, terminal_year_constraint),
    "  1 210 0   # OPR region end window: 0 inherits parest_flag(202)",
    "  1 212 0   # OPR season end window: 0 inherits parest_flag(202)",
    "  1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)",
    "  2 30 1    # keep age_flag(30) on so current MFCL activates OPR coefficients",
    "  2 70 0    # turn off mean+deviate regional recruitment time series",
    "  2 71 0    # turn off regional recruitment distribution deviations",
    "  2 178 0   # turn off regional recruitment sum-product constraint",
    "  -100000 1 0  # turn off time-invariant recruitment distribution, region 1",
    "  -100000 2 0  # turn off time-invariant recruitment distribution, region 2",
    "  -100000 3 0  # turn off time-invariant recruitment distribution, region 3",
    "  -100000 4 0  # turn off time-invariant recruitment distribution, region 4",
    "  -100000 5 0  # turn off time-invariant recruitment distribution, region 5"
  )
  lines <- c(lines[seq_len(phase3 - 1L)], new_block, lines[(phase3 + 3L):length(lines)])

  phase3_cmd <- grep("<<PHASE3$", lines)
  phase3_end <- grep("^PHASE3$", lines)
  if (length(phase3_cmd) != 1L || length(phase3_end) != 1L || phase3_cmd >= phase3_end) {
    stop("Expected exactly one PHASE3 block after OPR insertion", call. = FALSE)
  }
  phase3_eval <- phase3_cmd + grep(
    "^[[:space:]]*1[[:space:]]+1[[:space:]]+[0-9]+([[:space:]]|$)",
    lines[(phase3_cmd + 1L):(phase3_end - 1L)]
  )
  if (length(phase3_eval) != 1L) {
    stop("Expected one PHASE3 function-evaluation line for OPR", call. = FALSE)
  }
  lines[[phase3_eval]] <- "  1 1 500  # function evaluations from the OPR screening doitall example"

  region_flags <- grep("^[[:space:]]*-100000[[:space:]]+[1-5][[:space:]]+1([[:space:]]|$)", lines)
  if (!length(region_flags)) {
    stop("Expected time-invariant recruitment distribution flags", call. = FALSE)
  }
  for (i in region_flags) {
    words <- read_words(lines[[i]])
    words[[3]] <- "0"
    lines[[i]] <- paste0("  ", paste(words, collapse = " "))
  }
  lines
}

apply_data_weighting <- function(lines) {
  lf <- grep("-999 49 20", lines, fixed = TRUE)
  wf <- grep("-999 50 20", lines, fixed = TRUE)
  if (length(lf) != 1L || length(wf) != 1L) {
    stop("Expected one global LF and WF divisor line", call. = FALSE)
  }
  lines[[lf]] <- sub("-999 49 20", "-999 49 40", lines[[lf]], fixed = TRUE)
  lines[[wf]] <- sub("-999 50 20", "-999 50 40", lines[[wf]], fixed = TRUE)
  lines[[lf]] <- sub("divide LF sample sizes by 20", "divide LF sample sizes by 40", lines[[lf]], fixed = TRUE)
  lines[[wf]] <- sub("divide WF sample sizes by 20", "divide WF sample sizes by 40", lines[[wf]], fixed = TRUE)
  lines
}

apply_regional_scaling_phase5 <- function(lines, weight = 50L,
                                          use_mean = TRUE,
                                          use_mvn = TRUE,
                                          periods_from_end = 240L,
                                          end_periods_from_end = 220L,
                                          start_period = 53L,
                                          end_period = 72L) {
  if (any(grepl("Regional-scaling MVN prior.", lines, fixed = TRUE))) {
    return(lines)
  }
  if (any(grepl("^[[:space:]]*1[[:space:]]+77[[:space:]]+", lines))) {
    stop("Regional-scaling flags already exist before the PHASE 5 insert", call. = FALSE)
  }
  start <- grep("<<PHASE5", lines, fixed = TRUE)
  if (length(start) != 1L) {
    stop("Expected one PHASE5 heredoc start before inserting regional scaling flags", call. = FALSE)
  }
  end <- which(seq_along(lines) > start & trimws(lines) == "PHASE5")
  if (length(end) != 1L) {
    stop("Expected one PHASE5 heredoc end before inserting regional scaling flags", call. = FALSE)
  }
  block <- c(
    "# Regional-scaling MVN prior.",
    "# PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass.",
    "# Ungroup index CPUE likelihood and remove grouped-sigma override.",
    "  -29 99 29  -29 94 0  # Index R1",
    "  -30 99 30  -30 94 0  # Index R2",
    "  -31 99 31  -31 94 0  # Index R3",
    "  -32 99 32  -32 94 0  # Index R4",
    "  -33 99 33  -33 94 0  # Index R5",
    "# Ungroup index selectivity for the regional-scaling prior.",
    "  -29 24 25  # Index R1",
    "  -30 24 26  # Index R2",
    "  -31 24 27  # Index R3",
    "  -32 24 28  # Index R4",
    "  -33 24 29  # Index R5",
    "# MFCL reads bet.reg_scaling when parest flag 77 is > 0.",
    sprintf("  1 77 %d   # MVN regional-scaling penalty weight; CV about 0.1", as.integer(weight)),
    sprintf("  1 78 %d    # use mean regional-scaling target", as.integer(isTRUE(use_mean))),
    sprintf(
      "  1 79 %d  # start regional-scaling prior at period %d; 1965-1969 CPUE covariance window",
      as.integer(periods_from_end),
      as.integer(start_period)
    ),
    sprintf(
      "  1 80 %d  # end regional-scaling prior at period %d; 1965-1969 CPUE covariance window",
      as.integer(end_periods_from_end),
      as.integer(end_period)
    ),
    sprintf("  1 81 %d    # use multivariate-normal regional-scaling penalty", as.integer(isTRUE(use_mvn)))
  )
  c(lines[seq_len(end - 1L)], block, lines[end:length(lines)])
}

apply_regional_index_selectivity_map <- function(path) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  if (any(grepl("Regional-scaling Prior_reg_biomass variants unshare index selectivity", lines, fixed = TRUE))) {
    return(invisible(FALSE))
  }
  marker <- grep(
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]",
    lines,
    fixed = TRUE
  )
  if (length(marker) != 1L) {
    stop("Expected one selectivity-name assignment in ", path, call. = FALSE)
  }
  block <- c(
    "",
    "# Regional-scaling Prior_reg_biomass variants unshare index selectivity groups.",
    "# In doitall this switch starts in PHASE 5; PHASE 1-4 retain the",
    "# current CPUE_scaling setup with one shared index selectivity group.",
    "fishery_map$selectivity_group[29:33] <- 25:29",
    "selectivity_names[25:29] <- paste0(\"Index R\", 1:5)",
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]"
  )
  lines <- c(lines[seq_len(marker)], block, lines[(marker + 1L):length(lines)])
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  invisible(TRUE)
}

phase10_11_convergence_block <- function(default = "-3") {
  c(
    "",
    sprintf("phase10_11_convergence=${BET_PHASE10_11_CONVERGENCE:-%s}", default),
    "case \"$phase10_11_convergence\" in",
    "  -[0-9]|-[0-9][0-9]|[0-9]|[0-9][0-9]) ;;",
    "  *)",
    "    echo \"BET_PHASE10_11_CONVERGENCE must be numeric, e.g. -3 for quick runs or -5 for strict runs.\" >&2",
    "    exit 1",
    "    ;;",
    "esac",
    "echo \"PHASE 10/11 convergence criterion: $phase10_11_convergence\""
  )
}

replace_phase10_11_convergence_lines <- function(lines) {
  replace_phase <- function(lines, phase) {
    start <- grep(paste0("<<PHASE", phase), lines, fixed = TRUE)
    if (length(start) != 1L) {
      stop("Expected one PHASE", phase, " heredoc start in doitall.sh", call. = FALSE)
    }
    end <- which(seq_along(lines) > start & trimws(lines) == paste0("PHASE", phase))
    if (length(end) != 1L) {
      stop("Expected one PHASE", phase, " heredoc end in doitall.sh", call. = FALSE)
    }
    block_i <- seq.int(start, end)
    hit <- block_i[grepl("^[[:space:]]*1[[:space:]]+50[[:space:]]+", lines[block_i])]
    if (length(hit) != 1L) {
      stop("Expected one convergence line in PHASE", phase, " of doitall.sh", call. = FALSE)
    }
    lines[[hit]] <-
      "  1 50 $phase10_11_convergence  # convergence criteria; default quick -3, set BET_PHASE10_11_CONVERGENCE=-5 for strict"
    lines
  }

  lines <- replace_phase(lines, 10L)
  lines <- replace_phase(lines, 11L)
  lines
}

apply_historical_phase10_11_convergence_switch <- function(lines) {
  if (!length(lines) || !grepl("^#!", lines[[1]])) {
    lines <- c("#!/bin/sh", lines)
  }
  if (!any(grepl("^phase10_11_convergence=", lines))) {
    lines <- append(lines, phase10_11_convergence_block(), after = 1L)
  }
  replace_phase10_11_convergence_lines(lines)
}

apply_phase10_11_convergence_switch <- function(lines) {
  if (!any(grepl("^phase10_11_convergence=", lines))) {
    guard_start <- grep("^if \\[ -z \"\\$program_path\" \\]; then$", lines)
    if (length(guard_start) != 1L) {
      stop("Expected one PROGRAM_PATH guard in doitall.sh", call. = FALSE)
    }
    guard_end <- which(seq_along(lines) > guard_start & trimws(lines) == "fi")
    if (!length(guard_end)) {
      stop("Expected PROGRAM_PATH guard terminator in doitall.sh", call. = FALSE)
    }
    lines <- append(lines, phase10_11_convergence_block(), after = guard_end[[1]])
  }

  replace_phase10_11_convergence_lines(lines)
}

write_doitall <- function(from, to, mix_from_ini = FALSE,
                          size_based_selectivity = FALSE,
                          time_varying_cv = FALSE,
                          opr = FALSE,
                          data_weighting = FALSE,
                          regional_scaling = FALSE,
                          regional_scaling_periods = 292L,
                          regional_scaling_start_period = reg_scaling_active_start_period,
                          regional_scaling_end_period = reg_scaling_active_end_period) {
  # Start from the prior doitall and patch only the current step's controls.
  lines <- readLines(from, warn = FALSE)
  if (!any(grepl("^set -eu$", lines))) {
    lines <- append(lines, "set -eu", after = 1L)
  }
  lines <- apply_phase10_11_convergence_switch(lines)
  if (isTRUE(mix_from_ini)) {
    lines <- remove_tag_mixing_override(lines)
  }
  if (isTRUE(size_based_selectivity)) {
    lines <- apply_size_based_selectivity(lines)
  }
  if (isTRUE(time_varying_cv)) {
    lines <- apply_time_varying_cpue_cv(lines)
  }
  if (isTRUE(opr)) {
    lines <- apply_opr(lines)
  }
  if (isTRUE(data_weighting)) {
    lines <- apply_data_weighting(lines)
  }
  if (isTRUE(regional_scaling)) {
    lines <- apply_regional_scaling_phase5(
      lines,
      periods_from_end = regional_scaling_periods - regional_scaling_start_period + 1L,
      end_periods_from_end = regional_scaling_periods - regional_scaling_end_period,
      start_period = regional_scaling_start_period,
      end_period = regional_scaling_end_period
    )
  }
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
}

## Isolated BET 2026 stepwise control edits ---------------------------------

phase_heredoc_bounds <- function(lines, phase) {
  start <- grep(paste0("<<PHASE", phase, "[[:space:]]*$"), lines)
  end <- grep(paste0("^PHASE", phase, "[[:space:]]*$"), lines)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    stop("Expected one complete PHASE", phase, " block", call. = FALSE)
  }
  c(start = start, end = end)
}

append_phase_controls <- function(lines, phase, controls) {
  bounds <- phase_heredoc_bounds(lines, phase)
  append(lines, controls, after = bounds[["end"]] - 1L)
}

set_or_add_control_flag <- function(lines, actor, flag, value, phase = 1L,
                                    comment = "") {
  actor <- as.character(actor)
  flag <- as.integer(flag)
  pattern <- sprintf("(^|[[:space:]])%s[[:space:]]+%d[[:space:]]+", actor, flag)
  hit <- grep(pattern, lines)
  if (length(hit) > 1L) {
    stop("Expected at most one control for actor ", actor, " flag ", flag, call. = FALSE)
  }
  if (length(hit) == 1L) {
    line <- lines[[hit]]
    old_comment <- regmatches(line, regexpr("[[:space:]]+#.*$", line))
    body <- sub("[[:space:]]+#.*$", "", line)
    words <- read_words(body)
    target <- which(
      seq_along(words) <= length(words) - 2L &
        words == actor & words[seq_along(words) + 1L] == as.character(flag)
    )
    if (length(target) != 1L) {
      stop("Could not isolate actor ", actor, " flag ", flag, call. = FALSE)
    }
    words[[target + 2L]] <- as.character(value)
    lines[[hit]] <- paste0(
      "  ", paste(words, collapse = " "),
      if (nzchar(comment)) paste0("  # ", comment) else if (length(old_comment)) old_comment else ""
    )
    return(lines)
  }
  append_phase_controls(
    lines,
    phase,
    paste0("  ", actor, " ", flag, " ", value,
           if (nzchar(comment)) paste0("  # ", comment) else "")
  )
}

apply_regional_cpue_likelihood <- function(lines, index_fisheries = 29:33) {
  for (fishery in index_fisheries) {
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 99L, fishery, 1L,
      paste0("Index R", fishery - 28L, "; independent regional CPUE likelihood")
    )
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 94L, 0L, 1L,
      "no grouped-sigma override at the regional-CPUE introduction"
    )
  }
  lines
}

apply_regional_scaling_phase5 <- function(lines, weight = 100L,
                                          use_mean = TRUE,
                                          use_mvn = TRUE,
                                          periods_from_end = 240L,
                                          end_periods_from_end = 220L,
                                          start_period = 53L,
                                          end_period = 72L) {
  if (any(grepl("BET 2026 regional-scaling penalty only", lines, fixed = TRUE))) {
    return(lines)
  }
  block <- c(
    "# BET 2026 regional-scaling penalty only; CPUE likelihood was introduced in step 09.",
    sprintf("  1 77 %d  # MVN regional-scaling penalty weight", as.integer(weight)),
    sprintf("  1 78 %d  # use mean regional-scaling target", as.integer(isTRUE(use_mean))),
    sprintf("  1 79 %d  # start at source period %d", as.integer(periods_from_end), as.integer(start_period)),
    sprintf("  1 80 %d  # end at source period %d", as.integer(end_periods_from_end), as.integer(end_period)),
    sprintf("  1 81 %d  # use multivariate-normal penalty", as.integer(isTRUE(use_mvn)))
  )
  append_phase_controls(lines, 5L, block)
}

apply_index_selectivity_separation <- function(lines, index_fisheries = 29:33) {
  block <- c(
    "# Step 11: separate only the five regional-index selectivity groups.",
    sprintf(
      "  -%d 24 %d  # Index R%d; independent selectivity from PHASE5",
      index_fisheries, index_fisheries, index_fisheries - 28L
    )
  )
  append_phase_controls(lines, 5L, block)
}

apply_f25_f26_spline7 <- function(lines) {
  settings <- list(
    `25` = c(`16` = 2L, `3` = 25L, `24` = 25L, `26` = 2L, `57` = 3L, `61` = 7L, `75` = 0L),
    `26` = c(`16` = 2L, `3` = 26L, `24` = 26L, `26` = 2L, `57` = 3L, `61` = 7L, `75` = 0L)
  )
  for (fishery in names(settings)) {
    for (flag in names(settings[[fishery]])) {
      lines <- set_or_add_control_flag(
        lines, paste0("-", fishery), as.integer(flag), settings[[fishery]][[flag]], 1L,
        paste0("F", fishery, " independent seven-node cubic-spline selectivity")
      )
    }
  }
  lines
}

apply_dom_lf_divisors <- function(lines, fisheries = 21:23, divisor = 200L) {
  for (fishery in fisheries) {
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 49L, as.integer(divisor), 1L,
      paste0("DOM F", fishery, " LF divisor; all non-DOM 40/20 controls retained")
    )
  }
  lines
}

apply_fixed_common_cpue_sigma <- function(lines, flag92,
                                          cpue_mle_sigma = numeric(),
                                          index_fisheries = 29:33) {
  flag92 <- as.integer(flag92)
  if (length(flag92) != length(index_fisheries) || any(flag92 <= 0L)) {
    stop("Fixed CPUE sigma controls must provide one positive flag-92 value per index", call. = FALSE)
  }
  if (length(cpue_mle_sigma) &&
      (length(cpue_mle_sigma) != length(index_fisheries) ||
       any(!is.finite(cpue_mle_sigma)) || any(cpue_mle_sigma <= 0))) {
    stop("CPUE MLE sigma values must match the five index fisheries", call. = FALSE)
  }
  for (i in seq_along(index_fisheries)) {
    fishery <- index_fisheries[[i]]
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 92L, flag92[[i]], 1L,
      paste0(
        "Job13328 CPUE MLE R", i, " sigma = ",
        if (length(cpue_mle_sigma)) sprintf("%.3f", cpue_mle_sigma[[i]]) else
          format(flag92[[i]] / 100, nsmall = 2L)
      )
    )
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 94L, 1L, 1L,
      "retain index-specific fixed sigma within the common calibration"
    )
  }
  lines
}

apply_francis_lf_divisors <- function(lines, divisors) {
  divisors <- as.numeric(divisors)
  if (length(divisors) != 33L || any(!is.finite(divisors)) || any(divisors <= 0)) {
    stop("Francis weighting requires a locked positive 33-fishery divisor vector", call. = FALSE)
  }
  for (fishery in seq_len(33L)) {
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 49L, format(divisors[[fishery]], trim = TRUE), 1L,
      paste0("Francis TA1.8 locked LF divisor for F", fishery)
    )
  }
  lines
}

dm_group_vector <- function(grouping) {
  if (identical(grouping, "G8PSSET")) {
    return(c(
      1L, 1L, 1L, 1L, 2L, 1L, 1L, 1L, 2L, 1L, 1L,
      3L, 7L, 6L, 6L, 7L, 3L, 3L, 4L, 5L, 7L, 7L, 7L,
      7L, 4L, 4L, 5L, 5L, 8L, 8L, 8L, 8L, 8L
    ))
  }
  stop("Unknown DM grouping: ", grouping, call. = FALSE)
}

apply_dm_likelihood <- function(lines, grouping, nmax) {
  nmax <- as.integer(nmax)
  if (!is.finite(nmax) || nmax <= 0L) stop("DM Nmax must be positive", call. = FALSE)
  groups <- dm_group_vector(grouping)
  if (length(groups) != 33L || any(groups <= 0L)) {
    stop("DM grouping must map all 33 fisheries", call. = FALSE)
  }
  lines <- set_or_add_control_flag(
    lines, "1", 141L, 11L, 1L,
    "Dirichlet-multinomial LF likelihood without random effects"
  )
  lines <- set_or_add_control_flag(
    lines, "1", 311L, 1L, 1L,
    "retain LF preprocessing gate"
  )
  lines <- set_or_add_control_flag(
    lines, "1", 320L, 5L, 1L,
    "DM LF tail compression retains at least five class intervals"
  )
  lines <- set_or_add_control_flag(
    lines, "1", 342L, nmax, 1L,
    paste0("final DM Nmax", nmax)
  )
  for (fishery in seq_len(33L)) {
    lines <- set_or_add_control_flag(
      lines, paste0("-", fishery), 68L, groups[[fishery]], 1L,
      paste0(grouping, " DM group for F", fishery)
    )
  }
  lines <- set_or_add_control_flag(
    lines, "-999", 69L, 1L, 1L,
    "estimate group-specific DM scalar exponent"
  )
  lines <- set_or_add_control_flag(
    lines, "-999", 89L, 0L, 1L,
    "stage relative sample-size exponent fixed at zero"
  )
  append_phase_controls(
    lines, 2L,
    "  -999 89 1  # estimate group-specific DM relative sample-size exponent (CEST)"
  )
}

apply_regional_index_selectivity_map <- function(path) {
  eol <- file_eol(path)
  lines <- readLines(path, warn = FALSE)
  marker <- grep(
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]",
    lines,
    fixed = TRUE
  )
  if (length(marker) != 1L) {
    stop("Expected one selectivity-name assignment in ", path, call. = FALSE)
  }
  block <- c(
    "",
    "# Step 11 separates only final regional-index selectivity groups.",
    "fishery_map$selectivity_group[29:33] <- 29:33",
    "selectivity_names[29:33] <- paste0(\"Index R\", 1:5)",
    "fishery_map$selectivity_name <- selectivity_names[fishery_map$selectivity_group]"
  )
  lines <- c(lines[seq_len(marker)], block, lines[(marker + 1L):length(lines)])
  writeLines(lines, path, sep = eol, useBytes = TRUE)
  invisible(TRUE)
}

# Supersedes the legacy broad sensitivity writer above. The 22-row public
# sequence deliberately excludes OPR and length-bin selectivity controls.
write_doitall <- function(from, to, mix_from_ini = FALSE,
                          regional_cpue = FALSE,
                          regional_scaling_weight = NA_integer_,
                          regional_scaling_periods = 292L,
                          regional_scaling_start_period = reg_scaling_active_start_period,
                          regional_scaling_end_period = reg_scaling_active_end_period,
                          index_selectivity = FALSE,
                          f25_f26_spline7 = FALSE,
                          time_varying_cv = FALSE,
                          effort_creep = FALSE,
                          dom_divisor200 = FALSE,
                          cpue_sigma_flag92 = integer(),
                          cpue_mle_sigma = numeric(),
                          francis_divisors = numeric(),
                          dm_grouping = "",
                          dm_nmax = NA_integer_) {
  lines <- readLines(from, warn = FALSE)
  if (!any(grepl("^set -eu$", lines))) lines <- append(lines, "set -eu", after = 1L)
  lines <- apply_phase10_11_convergence_switch(lines)
  if (isTRUE(mix_from_ini)) lines <- remove_tag_mixing_override(lines)
  if (isTRUE(regional_cpue)) lines <- apply_regional_cpue_likelihood(lines)
  if (!is.na(regional_scaling_weight)) {
    lines <- apply_regional_scaling_phase5(
      lines,
      weight = regional_scaling_weight,
      periods_from_end = regional_scaling_periods - regional_scaling_start_period + 1L,
      end_periods_from_end = regional_scaling_periods - regional_scaling_end_period,
      start_period = regional_scaling_start_period,
      end_period = regional_scaling_end_period
    )
  }
  if (isTRUE(index_selectivity)) lines <- apply_index_selectivity_separation(lines)
  if (isTRUE(f25_f26_spline7)) lines <- apply_f25_f26_spline7(lines)
  if (isTRUE(time_varying_cv)) lines <- apply_time_varying_cpue_cv(lines)
  if (isTRUE(dom_divisor200)) lines <- apply_dom_lf_divisors(lines)
  if (length(cpue_sigma_flag92)) {
    lines <- apply_fixed_common_cpue_sigma(
      lines, cpue_sigma_flag92, cpue_mle_sigma = cpue_mle_sigma
    )
  }
  if (length(francis_divisors)) lines <- apply_francis_lf_divisors(lines, francis_divisors)
  if (nzchar(dm_grouping)) lines <- apply_dm_likelihood(lines, dm_grouping, dm_nmax)
  writeLines(lines, to, useBytes = TRUE)
  Sys.chmod(to, mode = "0755")
  invisible(to)
}
