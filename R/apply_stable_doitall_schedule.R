## Replace the inherited short Phase 3-7 sequence with a numerically staged
## schedule. The final scientific flags are unchanged; only the order and
## numerical optimization controls are altered.
##
## Design:
##   * open one major block at a time;
##   * use a deliberately loose MGC 1e-1 while a new block is introduced;
##   * retain quasi-Newton for the smaller Phase-1/2 systems, then use the
##     source-supported limited-memory Newton minimizer with 400 saved terms
##     after recruitment opens the >1,000-parameter system;
##   * follow high-dimensional blocks with a same-objective, same-dimension
##     gradient-rescaled run (parest flag 152=1);
##   * reset gradient scaling before the next parameter block;
##   * finish with a rescaled 1e-4 run and a native-scale 1e-4 run.
##
## The exact tuna-flow v2.6 source (testnewl3.cpp at a5a83cd) maps flag 50
## to 10^flag50, selects limited-memory Newton with flag 351=1, uses flag 192
## as the saved-term count, and reads gradient.rpt only when flag 152>0.
## It disables scaling if the active-parameter count differs. Therefore
## flag 152 is used only after both the objective and active dimension are
## unchanged, whereas the minimizer switch is safe because it changes only
## the numerical algorithm.

stable_schedule_sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

stable_phase_bounds <- function(lines, label) {
  start <- grep(paste0("<<", label, "$"), lines)
  end <- grep(paste0("^", label, "$"), lines)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    stop("Malformed or duplicated ", label, " block.", call. = FALSE)
  }
  c(start = start, end = end)
}

stable_phase_body <- function(lines, label) {
  bounds <- stable_phase_bounds(lines, label)
  trimws(lines[(bounds[["start"]] + 1L):(bounds[["end"]] - 1L)])
}

stable_replace_phase_body <- function(lines, label, replacement) {
  bounds <- stable_phase_bounds(lines, label)
  c(
    lines[seq_len(bounds[["start"]])],
    replacement,
    lines[seq.int(bounds[["end"]], length(lines))]
  )
}

apply_stable_doitall_schedule <- function(
  model_dir,
  recruitment_mode,
  script_name = "doitall.sh"
) {
  allowed_modes <- c("off", "72-01-50-50-end2")
  if (!recruitment_mode %in% allowed_modes) {
    stop(
      "Stable doitall recruitment mode must be one of: ",
      paste(allowed_modes, collapse = ", "), ".", call. = FALSE
    )
  }

  path <- file.path(model_dir, script_name)
  if (!file.exists(path)) stop("Missing staged doitall script: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE)
  source_sha <- stable_schedule_sha256(path)

  required_once <- c(
    "1 79 290  # full index-supported start: model period 3 (1952Q3)",
    "1 80 0  # full-period end bound: default final model period 292 (2024Q4)",
    "2 27 -1  # penalty wt 0.1 computed against prior",
    "-29 99 29  # Index R1; separate stationary-catchability/likelihood group from staged run 5",
    "-30 99 30  # Index R2; separate stationary-catchability/likelihood group from staged run 5",
    "-31 99 31  # Index R3; separate stationary-catchability/likelihood group from staged run 5",
    "-32 99 32  # Index R4; separate stationary-catchability/likelihood group from staged run 5",
    "-33 99 33  # Index R5; separate stationary-catchability/likelihood group from staged run 5"
  )
  bad_once <- required_once[
    vapply(required_once, function(x) sum(trimws(lines) == x), integer(1L)) != 1L
  ]
  if (length(bad_once)) {
    stop(
      "Stable schedule baseline control missing or duplicated: ",
      paste(bad_once, collapse = " | "), ".", call. = FALSE
    )
  }

  expected_phase2 <- c(
    "1 1 100  # set max. number of function evaluations per phase to 100",
    "1 50 0   # set convergence criterion to 1",
    "2 113 0  # scaling init pop - turned off",
    "1 190 1  # write plot-xxx.par.rep",
    "-999 89 1  # estimate group-specific DM relative sample-size exponent (CEST)"
  )
  if (!identical(stable_phase_body(lines, "PHASE2"), expected_phase2)) {
    stop("Doitall Phase 2 is not the verified full-reg baseline.", call. = FALSE)
  }

  phase3 <- stable_phase_body(lines, "PHASE3")
  standard_phase3 <- c(
    "2 70 1   # activate time series of reg recruitment parameters",
    "2 71 1   # estimate temporal changes in recruitment distribution",
    "2 178 1  # constrain regional recruitments",
    "1 1 200"
  )
  if (identical(recruitment_mode, "off")) {
    if (!identical(phase3, standard_phase3)) {
      stop("Standard recruitment Phase 3 is not the verified baseline.", call. = FALSE)
    }
    phase3_staged <- c(
      "  2 70 1   # activate time series of regional recruitment parameters",
      "  2 71 1   # estimate temporal changes in recruitment distribution",
      "  2 178 1  # constrain regional recruitments",
      "  1 152 0  # native parameter scaling while opening a new block",
      "  1 351 1  # high-dimensional fit: limited-memory Newton",
      "  1 192 400 # retain 400 recent update pairs (manual recommendation)",
      "  1 352 0   # use the source-recommended default angle bound",
      "  1 1 2000 # recruitment block evaluation budget",
      "  1 50 -1  # loose MGC 1e-1 while opening recruitment"
    )
    phase4a_controls <- c(
      "  -100000 1 1  # estimate time-invariant recruitment distribution, region 1",
      "  -100000 2 1  # estimate time-invariant recruitment distribution, region 2",
      "  -100000 3 1  # estimate time-invariant recruitment distribution, region 3",
      "  -100000 4 1  # estimate time-invariant recruitment distribution, region 4",
      "  -100000 5 1  # estimate time-invariant recruitment distribution, region 5",
      "  1 152 0  # active dimension changed; do not reuse the prior gradient scale",
      "  1 1 1500 # average regional-recruitment evaluation budget",
      "  1 50 -1  # loose MGC 1e-1 while opening average recruitment"
    )
    phase4a_label <- "average regional recruitment distribution"
  } else {
    required_opr <- c(
      "1 155 72  # orthogonal polynomial recruitment - year effect",
      "1 217 1   # orthogonal polynomial recruitment - season effect",
      "1 216 50  # orthogonal polynomial recruitment - region effect",
      "1 218 50  # orthogonal polynomial recruitment - region-season interaction effect",
      "1 202 2   # OPR end window: last 2 real years use lower-degree/constant-end basis",
      "2 70 0    # turn off mean+deviate regional recruitment time series",
      "2 71 0    # turn off regional recruitment distribution deviations",
      "2 178 0   # turn off regional recruitment sum-product constraint",
      "1 1 500  # function evaluations for the BET 2026 OPR transfer"
    )
    missing_opr <- required_opr[!required_opr %in% phase3]
    if (length(missing_opr) || any(grepl("^1\\s+50\\s+", phase3))) {
      stop("OPR Phase 3 is not the verified 72-01-50-50 end2 transfer.", call. = FALSE)
    }
    phase3_staged <- phase3
    eval_index <- which(
      phase3_staged ==
        "1 1 500  # function evaluations for the BET 2026 OPR transfer"
    )
    if (length(eval_index) != 1L) stop("Could not uniquely update OPR evaluations.", call. = FALSE)
    phase3_staged[[eval_index]] <-
      "1 1 2500  # OPR transfer evaluation budget"
    phase3_staged <- paste0("  ", phase3_staged)
    phase3_staged <- c(
      phase3_staged,
      "  1 152 0  # OPR changes active dimension; retain native scaling",
      "  1 351 1  # high-dimensional fit: limited-memory Newton",
      "  1 192 400 # retain 400 recent update pairs (manual recommendation)",
      "  1 352 0   # use the source-recommended default angle bound",
      "  1 50 -1  # loose MGC 1e-1 while opening OPR recruitment"
    )
    phase4a_controls <- c(
      "  1 152 1  # same OPR dimension: rescale using Phase-3 gradient.rpt",
      "  1 1 2500 # OPR recruitment stabilization budget",
      "  1 50 -2  # stabilize OPR recruitment to MGC 1e-2"
    )
    phase4a_label <- "same-dimension OPR recruitment stabilization"
  }

  new_middle <- c(
    "# -------------------------------",
    "#  PHASE 3 - recruitment structure",
    "# -------------------------------",
    "",
    "$program_path bet.frq 02.par 03.par -file - <<PHASE3",
    phase3_staged,
    "PHASE3",
    "",
    "# ----------------------------------------------------",
    paste0("#  PHASE 4A - ", phase4a_label),
    "# ----------------------------------------------------",
    "",
    "$program_path bet.frq 03.par 04a.par -file - <<PHASE4A",
    phase4a_controls,
    "PHASE4A",
    "",
    "# ------------------------------------------------",
    "#  PHASE 4B - full-period regional-scaling penalty",
    "# ------------------------------------------------",
    "",
    "$program_path bet.frq 04a.par 04b.par -file - <<PHASE4B",
    "  1 152 0  # objective changed; return to native parameter scaling",
    "  1 77 100 # REGW regional-scaling penalty weight",
    "  1 78 1   # use mean regional-scaling target",
    "  1 79 290 # model periods 3-292 (1952Q3-2024Q4)",
    "  1 80 0   # end at the final model period",
    "  1 81 1   # multivariate-normal regional-scaling penalty",
    "  1 1 1500 # regional-scaling penalty evaluation budget",
    "  1 50 -1  # loose MGC 1e-1 after changing the penalty surface",
    "PHASE4B",
    "",
    "# -------------------------------------------------",
    "#  PHASE 4C - separate regional-index CPUE groups",
    "# -------------------------------------------------",
    "",
    "$program_path bet.frq 04b.par 04c.par -file - <<PHASE4C",
    "  -29 99 29  # Index R1 stationary-catchability/likelihood group",
    "  -30 99 30  # Index R2 stationary-catchability/likelihood group",
    "  -31 99 31  # Index R3 stationary-catchability/likelihood group",
    "  -32 99 32  # Index R4 stationary-catchability/likelihood group",
    "  -33 99 33  # Index R5 stationary-catchability/likelihood group",
    "  -29 94 0   # Index R1 uses its own flag-92 error scale",
    "  -30 94 0   # Index R2 uses its own flag-92 error scale",
    "  -31 94 0   # Index R3 uses its own flag-92 error scale",
    "  -32 94 0   # Index R4 uses its own flag-92 error scale",
    "  -33 94 0   # Index R5 uses its own flag-92 error scale",
    "  1 152 0  # active dimension changed; do not reuse prior gradient scale",
    "  1 1 1800 # separated-index evaluation budget",
    "  1 50 -1  # loose MGC 1e-1 while opening index parameters",
    "PHASE4C",
    "",
    "# --------------------------------------",
    "#  PHASE 4D - spatial movement parameters",
    "# --------------------------------------",
    "",
    "$program_path bet.frq 04c.par 04.par -file - <<PHASE4D",
    "  2 68 1   # estimate movement coefficients",
    "  2 69 1   # activate the generic movement parameterization",
    "  2 27 -1  # movement-prior coefficient 0.1",
    "  1 152 0  # movement changes active dimension; use native scaling",
    "  1 1 2500 # movement-block evaluation budget",
    "  1 50 -1  # loose MGC 1e-1 while opening movement",
    "PHASE4D",
    "",
    "# -------------------------------------------------------",
    "#  PHASE 5 - same-dimension spatial-block stabilization",
    "# -------------------------------------------------------",
    "",
    "$program_path bet.frq 04.par 05.par -file - <<PHASE5",
    "  1 152 1  # same dimension: rescale with Phase-4D gradient.rpt",
    "  1 1 4000 # joint recruitment/REGW/index/movement stabilization budget",
    "  1 50 -2  # stabilize the complete spatial block to MGC 1e-2",
    "PHASE5",
    "",
    "# -----------------------------------------",
    "#  PHASE 6 - mean growth-curve parameters",
    "# -----------------------------------------",
    "",
    "$program_path bet.frq 05.par 06.par -file - <<PHASE6",
    "  1 152 0  # growth changes active dimension; return to native scaling",
    "  1 240 1  # fit to age-length data",
    "  1 14 1   # estimate von Bertalanffy K",
    "  1 12 1   # estimate mean length of age 1",
    "  1 13 1   # estimate length of age n",
    "  1 1 1800 # mean-growth evaluation budget",
    "  1 50 -1  # loose MGC 1e-1 while opening mean growth",
    "PHASE6",
    "",
    "# ----------------------------------------",
    "#  PHASE 7A - length-at-age variance",
    "# ----------------------------------------",
    "",
    "$program_path bet.frq 06.par 07a.par -file - <<PHASE7A",
    "  1 152 0  # variance parameters change dimension; use native scaling",
    "  1 15 1   # estimate overall SD of length-at-age",
    "  1 16 1   # estimate length-dependent SD",
    "  1 173 0  # no independent young-age mean lengths",
    "  1 182 0  # retain existing growth-variance penalty setting",
    "  1 184 0  # retain existing growth-variance parameterization",
    "  1 1 1500 # length-variance evaluation budget",
    "  1 50 -1  # loose MGC 1e-1 while opening length variance",
    "PHASE7A",
    "",
    "# ---------------------------------------------------",
    "#  PHASE 7B - same-dimension growth stabilization",
    "# ---------------------------------------------------",
    "",
    "$program_path bet.frq 07a.par 07.par -file - <<PHASE7B",
    "  1 152 1  # same dimension: rescale with Phase-7A gradient.rpt",
    "  1 1 3000 # complete growth-block stabilization budget",
    "  1 50 -2  # stabilize growth and length variance to MGC 1e-2",
    "PHASE7B"
  )

  phase3_header <- which(trimws(lines) == "#  PHASE 3")
  phase7_end <- grep("^PHASE7$", lines)
  if (length(phase3_header) != 1L || length(phase7_end) != 1L ||
      phase3_header <= 1L || phase3_header >= phase7_end) {
    stop("Could not uniquely locate the inherited Phase 3-7 section.", call. = FALSE)
  }
  section_start <- phase3_header - 1L
  lines <- c(
    lines[seq_len(section_start - 1L)],
    new_middle,
    lines[seq.int(phase7_end + 1L, length(lines))]
  )

  phase1_end <- grep("^PHASE1$", lines)
  if (length(phase1_end) != 1L) stop("Could not locate PHASE1 end.", call. = FALSE)
  phase1_body <- stable_phase_body(lines, "PHASE1")
  if (any(grepl("^1\\s+1\\s+", phase1_body)) ||
      any(grepl("^1\\s+50\\s+", phase1_body))) {
    stop("Phase 1 already has conflicting optimizer controls.", call. = FALSE)
  }
  lines <- append(
    lines,
    c(
      "  1 152 0  # native parameter scaling for the initial block",
      "  1 1 1500 # initial active-parameter evaluation budget",
      "  1 50 -1  # loose MGC 1e-1 before later blocks are opened"
    ),
    after = phase1_end - 1L
  )

  lines <- stable_replace_phase_body(
    lines,
    "PHASE2",
    c(
      "  1 1 1200 # DM relative-sample-size exponent evaluation budget",
      "  1 50 -1  # loose MGC 1e-1 after opening the DM CEST exponent",
      "  1 152 0  # active dimension changed; retain native scaling",
      "  1 351 0  # retain quasi-Newton for the smaller pre-recruitment system",
      "  2 113 0  # scaling init pop - turned off",
      "  1 190 1  # write plot-xxx.par.rep",
      "  -999 89 1 # estimate group-specific DM relative-sample-size exponent (CEST)"
    )
  )

  phase8 <- stable_phase_body(lines, "PHASE8")
  phase8_eval <- which(phase8 == "1 1 500    # function evaluations")
  phase8_mgc <- which(phase8 == "1 50 -2    # convergence criteria")
  if (length(phase8_eval) != 1L || length(phase8_mgc) != 1L) {
    stop("Could not identify Phase 8 optimizer controls.", call. = FALSE)
  }
  phase8[[phase8_eval]] <- "1 1 1800   # SRR-opening evaluation budget"
  phase8[[phase8_mgc]] <- "1 50 -1    # loose MGC 1e-1 while opening SRR"
  phase8 <- append(
    phase8,
    "1 152 0    # SRR changes active dimension; return to native scaling",
    after = 0L
  )
  lines <- stable_replace_phase_body(lines, "PHASE8", paste0("  ", phase8))

  phase9 <- stable_phase_body(lines, "PHASE9")
  phase9_eval <- which(phase9 == "1 1 500    # function evaluations")
  phase9_mgc <- which(phase9 == "1 50 -2    # convergence criteria")
  phase9_command <- which(
    lines == "$program_path bet.frq 08.par 09.par -file - <<PHASE9"
  )
  phase9_end <- grep("^PHASE9$", lines)
  if (length(phase9_eval) != 1L || length(phase9_mgc) != 1L ||
      length(phase9_command) != 1L || length(phase9_end) != 1L ||
      phase9_command >= phase9_end) {
    stop("Could not identify Phase 9 optimizer controls.", call. = FALSE)
  }
  phase9[[phase9_eval]] <- "1 1 2000   # relaxed-SRR native-scale budget"
  phase9[[phase9_mgc]] <- "1 50 -2    # stabilize changed SRR surface to MGC 1e-2"
  phase9a <- c(
    "$program_path bet.frq 08.par 09a.par -file - <<PHASE9A",
    "  1 152 0    # SRR penalty and F bound changed; retain native scaling",
    paste0("  ", phase9),
    "PHASE9A",
    "",
    "# ------------------------------------------------",
    "#  PHASE 9B - same-objective SRR stabilization",
    "# ------------------------------------------------",
    "",
    "$program_path bet.frq 09a.par 09.par -file - <<PHASE9B",
    "  1 152 1    # same objective/dimension: rescale with Phase-9A gradient",
    "  1 1 3000   # rescaled relaxed-SRR stabilization budget",
    "  1 50 -3    # stabilize complete SRR block to MGC 1e-3",
    "PHASE9B"
  )
  lines <- c(
    lines[seq_len(phase9_command - 1L)],
    phase9a,
    lines[seq.int(phase9_end + 1L, length(lines))]
  )

  phase10 <- stable_phase_body(lines, "PHASE10")
  phase10_eval <- which(
    phase10 == "1 1 3000   # stabilize the newly opened common tau parameter"
  )
  if (length(phase10_eval) != 1L ||
      sum(phase10 == "1 50 -3") != 1L ||
      any(grepl("^1\\s+152\\s+", phase10))) {
    stop("Could not identify Phase 10 optimizer controls.", call. = FALSE)
  }
  phase10[[phase10_eval]] <-
    "1 1 3000   # native-scale common-tau evaluation budget"
  phase10[phase10 == "1 50 -3"] <-
    "1 50 -2    # hand tau to the rescaled final phase at MGC 1e-2"
  phase10 <- append(
    phase10,
    "1 152 0    # tau changes active dimension; retain native scaling",
    after = 0L
  )
  lines <- stable_replace_phase_body(lines, "PHASE10", paste0("  ", phase10))

  phase11 <- stable_phase_body(lines, "PHASE11")
  expected_phase11 <- c(
    "1 1 10000",
    "1 50 $phase10_11_convergence",
    "1 121 $mortality_phase11_flag  # estimate M only in the final two phases when requested"
  )
  if (!identical(phase11, expected_phase11)) {
    stop("Phase 11 is not the verified final baseline.", call. = FALSE)
  }
  lines <- stable_replace_phase_body(
    lines,
    "PHASE11",
    c(
      "  1 152 1  # same dimension as Phase 10: gradient-rescaled final run",
      "  1 1 10000",
      "  1 50 $phase10_11_convergence",
      "  1 121 $mortality_phase11_flag  # retain requested fixed/estimated M treatment"
    )
  )

  phase12 <- stable_phase_body(lines, "PHASE12")
  expected_phase12 <- c(
    "1 1 5000",
    "1 50 $phase10_11_convergence",
    "1 121 $mortality_phase11_flag  # retain the requested final-phase M treatment",
    "1 246 1   # write indepvar.rpt"
  )
  if (!identical(phase12, expected_phase12)) {
    stop("Phase 12 is not the verified final baseline.", call. = FALSE)
  }
  lines <- stable_replace_phase_body(
    lines,
    "PHASE12",
    c(
      "  1 152 0  # native-scale confirmation run for interpretable final MGC",
      "  1 351 0  # independent quasi-Newton confirmation of the LMN solution",
      "  1 1 7000",
      "  1 50 $phase10_11_convergence",
      "  1 121 $mortality_phase11_flag  # retain the requested final-phase M treatment",
      "  1 246 1   # write indepvar.rpt"
    )
  )

  writeLines(lines, path, useBytes = TRUE)
  Sys.chmod(path, mode = "0755")

  output_sha <- stable_schedule_sha256(path)
  if (identical(source_sha, output_sha)) {
    stop("Stable phase schedule did not modify doitall.sh.", call. = FALSE)
  }

  phase_plan <- data.frame(
    phase = c(
      "1", "2", "3", "4A", "4B", "4C", "4D", "5",
      "6", "7A", "7B", "8", "9A", "9B", "10", "11", "12"
    ),
    opens_or_changes = c(
      "initial active block including revised selectivity",
      "DM relative-sample-size exponent",
      if (identical(recruitment_mode, "off")) {
        "mean-plus-deviation regional recruitment"
      } else {
        "OPR 72-01-50-50 end2 recruitment"
      },
      phase4a_label,
      "full-period regional-scaling penalty",
      "separate regional-index CPUE groups",
      "movement",
      "same-dimension spatial stabilization",
      "mean growth",
      "length-at-age variance",
      "same-dimension growth stabilization",
      "stock-recruitment relationship",
      "relaxed SRR penalty and F-bound change",
      "same-objective relaxed-SRR stabilization",
      "common estimated tag tau",
      "same-dimension gradient-rescaled final fit",
      "native-scale final confirmation and indepvar.rpt"
    ),
    max_evaluations = c(
      1500L, 1200L, if (identical(recruitment_mode, "off")) 2000L else 2500L,
      if (identical(recruitment_mode, "off")) 1500L else 2500L,
      1500L, 1800L, 2500L, 4000L, 1800L, 1500L, 3000L,
      1800L, 2000L, 3000L, 3000L, 10000L, 7000L
    ),
    mgc = c(
      "1e-1", "1e-1", "1e-1",
      if (identical(recruitment_mode, "off")) "1e-1" else "1e-2",
      "1e-1", "1e-1", "1e-1", "1e-2", "1e-1", "1e-1",
      "1e-2", "1e-1", "1e-2", "1e-3", "1e-2", "1e-4", "1e-4"
    ),
    gradient_rescaled = c(
      FALSE, FALSE, FALSE, identical(recruitment_mode, "72-01-50-50-end2"),
      FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, TRUE,
      FALSE, FALSE, TRUE, FALSE, TRUE, FALSE
    ),
    optimizer = c(
      "quasi-Newton", "quasi-Newton",
      rep("limited-memory Newton (400 terms)", 14L),
      "quasi-Newton"
    ),
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    phase_plan,
    file.path(model_dir, "doitall-phase-plan.csv"),
    row.names = FALSE
  )
  audit <- data.frame(
    recruitment_mode = recruitment_mode,
    final_mgc = "1e-4",
    final_gradient_scaling = "native",
    optimizer_path = "QN phases 1-2; LMN400 phases 3-11; QN phase 12",
    mfcl_source_commit = "a5a83cd6e8aef512d22890234c40b0fa465843eb",
    manual_commit = "4503c2abd234f3be95ec73e4375cf19df69859e2",
    source_sha256 = source_sha,
    output_sha256 = output_sha,
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    audit,
    file.path(model_dir, "stable-doitall-audit.csv"),
    row.names = FALSE
  )
  message(
    "[doitall] staged recruitment -> REGW -> index CPUE -> movement -> growth; ",
    "rescaled and native final MGC 1e-4; SHA=", output_sha
  )
  invisible(audit)
}
