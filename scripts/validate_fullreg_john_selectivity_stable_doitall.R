fail <- function(...) stop(..., call. = FALSE)

sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    fail("sha256sum failed for ", path, ": ", paste(output, collapse = "\n"))
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

phase_body <- function(lines, label) {
  start <- grep(paste0("<<", label, "$"), lines)
  end <- grep(paste0("^", label, "$"), lines)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    fail("Malformed ", label, " block.")
  }
  trimws(lines[(start + 1L):(end - 1L)])
}

effective_phase1_fish_flags <- function(lines) {
  flags <- c(3L, 16L, 24L, 26L, 57L, 61L, 62L, 75L)
  result <- matrix(
    0L,
    nrow = 33L,
    ncol = length(flags),
    dimnames = list(as.character(seq_len(33L)), as.character(flags))
  )
  body <- phase_body(lines, "PHASE1")
  for (line in body) {
    clean <- trimws(sub("#.*$", "", line))
    if (!nzchar(clean)) next
    tokens <- strsplit(clean, "[[:space:]]+")[[1L]]
    if (length(tokens) %% 3L != 0L ||
        any(!grepl("^-?[0-9]+$", tokens))) {
      next
    }
    values <- as.integer(tokens)
    triples <- matrix(values, ncol = 3L, byrow = TRUE)
    for (i in seq_len(nrow(triples))) {
      target <- triples[i, 1L]
      flag <- triples[i, 2L]
      value <- triples[i, 3L]
      if (!flag %in% flags) next
      if (target == -999L) {
        result[, as.character(flag)] <- value
      } else if (target <= -1L && target >= -33L) {
        result[as.character(abs(target)), as.character(flag)] <- value
      }
    }
  }
  result
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(
  root, "job-config-fullreg-john-selectivity-stable-doitall.R"
)
task_path <- file.path(
  root, "kflow-fullreg-john-selectivity-stable-doitall.yaml"
)
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
step_ids <- c("FULLREG-JOHN-SEL-STD", "FULLREG-JOHN-SEL-OPR")
patch_paths <- file.path(root, "steps", step_ids, "patch.R")
helper_paths <- file.path(
  root,
  "R",
  c(
    "apply_f15_lf_qc.R",
    "apply_dom_lf_qc.R",
    "apply_full_period_reg_scaling.R",
    "apply_movement_prior_penalty.R",
    "apply_opr_sensitivity.R",
    "apply_john_selectivity_sensitivity.R",
    "apply_stable_doitall_schedule.R",
    "prepare_common.R",
    "prepare_doitall.R"
  )
)
source_names <- c(
  "doitall.sh", "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
  "bet.reg_scaling", "bet.reg_scaling.full", "mfcl.cfg"
)
required_files <- c(
  config_path, task_path, patch_paths, helper_paths,
  file.path(source_dir, source_names),
  file.path(root, "scripts", "register_kflow_task.py"),
  file.path(root, "run.sh")
)
missing <- required_files[!file.exists(required_files)]
if (length(missing)) {
  fail("Missing stable-doitall file(s): ", paste(missing, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)
if (!is.data.frame(models) || nrow(models) != 2L) {
  fail("Expected exactly two independent model rows.")
}
if (!identical(models$step_id, step_ids) ||
    !identical(models$STEP_SELECT, step_ids) ||
    !identical(models$independent_fit, c(TRUE, TRUE)) ||
    !identical(models$scientific_parent_mode, rep("metadata-only", 2))) {
  fail("Unexpected row identity, independence or parent mode.")
}
if (!identical(models$run_mode, rep("doitall", 2)) ||
    !identical(models$run_script, rep("doitall.sh", 2)) ||
    !identical(models$input_par, rep("", 2)) ||
    !identical(models$par_source_job, rep("", 2)) ||
    !identical(models$kflow_input_jobs, rep("", 2))) {
  fail("Both rows must start independently from bet.ini via doitall.")
}
if (!identical(models$regional_recruitment_penalty, rep("0.1", 2)) ||
    !identical(models$movement_prior_penalty, rep("0.1", 2)) ||
    !identical(models$opr_mode, c("off", "72-01-50-50-end2"))) {
  fail("Expected fixed rec/movement 0.1 and standard-versus-OPR rows only.")
}
if (!identical(models$selectivity_mode,
               rep("f2f3-nondecreasing-f33-spline4", 2)) ||
    !identical(models$f15_qc_mode, rep("lt70", 2)) ||
    !identical(models$dom_qc_mode, rep("gt90_midpoint", 2)) ||
    !identical(models$regional_scaling_mode, rep("full_period", 2)) ||
    !identical(models$f14_youngest_zero, rep("5", 2))) {
  fail("QC, full-reg, F14 or selectivity controls differ between rows.")
}
if (!identical(models$dm_nmax, rep("25", 2)) ||
    !identical(models$tag_tau_grouping, rep("common", 2)) ||
    !identical(models$tau_mode, rep("estimated-common", 2)) ||
    !identical(models$phase10_11_convergence, rep("-4", 2))) {
  fail("Expected Nmax25, common estimated tau and final MGC 1e-4.")
}
if (anyDuplicated(models$step_id) || anyDuplicated(models$job_key) ||
    anyDuplicated(models$model_label)) {
  fail("Step IDs, job keys and labels must be unique.")
}

task <- readLines(task_path, warn = FALSE)
required_task_text <- c(
  "name: bet-2026-fullreg-john-selectivity-stable-doitall-20260728",
  "branch: sensitivity/fullreg-john-selectivity-stable-doitall-20260728",
  "slot_requirements: 'regexp(\"^suvofp\", Machine)'",
  "command: Rscript --vanilla scripts/validate_fullreg_john_selectivity_stable_doitall.R && bash run.sh",
  "  CONFIG_R: job-config-fullreg-john-selectivity-stable-doitall.R",
  "  SELECTIVITY_MODE: f2f3-nondecreasing-f33-spline4",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  MOVEMENT_PRIOR_PENALTY: \"0.1\"",
  "  ESTIMATE_M_FINAL: \"false\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  MFCL_LIVE_LOG: \"false\""
)
missing_task <- required_task_text[!required_task_text %in% task]
if (length(missing_task)) {
  fail("Task YAML is missing exact control(s): ", paste(missing_task, collapse = " | "))
}

expected_source_hashes <- c(
  "doitall.sh" = "9a5922133fd749ff162972590897f47796e0423c18dc71d0e332828f37e92ccf",
  "bet.ini" = "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a",
  "bet.frq" = "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c",
  "bet.tag" = "b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f",
  "bet.age_length" = "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c",
  "bet.reg_scaling" = "6330fb6a36d63424c18f81cbc620c1d9607c2a5c43d0308d19941f12938ec9a1",
  "bet.reg_scaling.full" = "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed",
  "mfcl.cfg" = "2ec8a291fae62c6f37541aec1de37444626d42b3290b371bb42b63d510034eae"
)
actual_source_hashes <- vapply(
  file.path(source_dir, names(expected_source_hashes)),
  sha256,
  character(1L)
)
names(actual_source_hashes) <- names(expected_source_hashes)
bad_hashes <- names(expected_source_hashes)[
  actual_source_hashes != expected_source_hashes
]
if (length(bad_hashes)) {
  fail("Frozen source hash mismatch: ", paste(bad_hashes, collapse = ", "))
}

test_root <- tempfile("fullreg-john-stable-validation-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)
staged_hashes <- character(2)
for (i in seq_len(nrow(models))) {
  model_dir <- file.path(test_root, models$step_id[[i]])
  dir.create(model_dir, recursive = TRUE)
  copied <- file.copy(
    file.path(source_dir, source_names),
    file.path(model_dir, source_names),
    overwrite = TRUE
  )
  if (!all(copied)) fail("Could not stage validation inputs for row ", i, ".")

  Sys.setenv(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    DOM_QC_MODE = models$dom_qc_mode[[i]],
    REG_SCALING_MODE = models$regional_scaling_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]],
    SELECTIVITY_MODE = models$selectivity_mode[[i]]
  )
  patch_env <- new.env(parent = globalenv())
  patch_env$model_dir <- normalizePath(model_dir, mustWork = TRUE)
  patch_env$config <- list(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    DOM_QC_MODE = models$dom_qc_mode[[i]],
    REGIONAL_SCALING_MODE = models$regional_scaling_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]],
    SELECTIVITY_MODE = models$selectivity_mode[[i]]
  )
  sys.source(patch_paths[[i]], envir = patch_env)

  if (!identical(sha256(file.path(model_dir, "bet.frq")),
                 "9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3")) {
    fail("Staged F15/DOM FRQ hash mismatch for ", models$step_id[[i]], ".")
  }
  if (!identical(sha256(file.path(model_dir, "bet.reg_scaling")),
                 "4c43bf2c0853b02626047bd84d54a0b62942f9316bed8734f43b696fbe84c1b5")) {
    fail("Staged full-period regional-scaling hash mismatch.")
  }
  f15 <- utils::read.csv(
    file.path(model_dir, "f15-lf-qc-summary.csv"),
    stringsAsFactors = FALSE
  )
  if (nrow(f15) != 1L ||
      f15$f15_lf_rows_affected[[1L]] != 66L ||
      f15$removed_count[[1L]] != 1057 ||
      f15$f15_count_before[[1L]] != 41908 ||
      f15$f15_count_after[[1L]] != 40851 ||
      f15$renormalised[[1L]]) {
    fail("F15 <70 cm audit mismatch.")
  }
  dom <- utils::read.csv(
    file.path(model_dir, "dom-lf-qc-summary.csv"),
    stringsAsFactors = FALSE
  )
  if (nrow(dom) != 3L ||
      !identical(as.integer(dom$fishery), 21:23) ||
      sum(dom$removed_count) != 7904 ||
      any(dom$selectivity_changed) ||
      any(dom$renormalised)) {
    fail("DOM midpoint >90 cm audit mismatch.")
  }
  reg <- utils::read.csv(
    file.path(model_dir, "regional-scaling-full-period-summary.csv"),
    stringsAsFactors = FALSE
  )
  if (nrow(reg) != 1L ||
      reg$source_data_rows[[1L]] != 292L ||
      reg$active_data_rows[[1L]] != 290L ||
      reg$start_period[[1L]] != 3L ||
      reg$end_period[[1L]] != 292L ||
      reg$parest_flag_79[[1L]] != 290L ||
      reg$parest_flag_80[[1L]] != 0L) {
    fail("Full-period regional-scaling audit mismatch.")
  }
  sel <- utils::read.csv(
    file.path(model_dir, "john-selectivity-audit.csv"),
    stringsAsFactors = FALSE
  )
  if (nrow(sel) != 1L ||
      sel$f2_f3_shared_group[[1L]] != 2L ||
      sel$f2_f3_fish_flag_16[[1L]] != 1L ||
      sel$f2_f3_fish_flag_61[[1L]] != 4L ||
      sel$f2_f3_fish_flag_62[[1L]] != 0L ||
      sel$f2_f3_fish_flag_75[[1L]] != 2L ||
      sel$f33_fish_flag_16[[1L]] != 0L ||
      sel$f33_fish_flag_57[[1L]] != 3L ||
      sel$f33_fish_flag_61[[1L]] != 4L ||
      sel$f33_fish_flag_75[[1L]] != 2L) {
    fail("John selectivity audit mismatch.")
  }

  doitall_path <- file.path(model_dir, "doitall.sh")
  shell_check <- system2("bash", c("-n", doitall_path))
  if (!identical(as.integer(shell_check), 0L)) {
    fail("Staged doitall failed bash -n for ", models$step_id[[i]], ".")
  }
  lines <- readLines(doitall_path, warn = FALSE)
  fish <- effective_phase1_fish_flags(lines)
  grouping_flags <- as.character(c(3L, 16L, 26L, 57L, 61L, 62L, 75L))
  if (!identical(unname(fish["2", grouping_flags]),
                 unname(fish["3", grouping_flags])) ||
      fish["2", "24"] != 2L || fish["3", "24"] != 2L) {
    fail("F2/F3 shared-selectivity flags are not manual-compliant.")
  }
  if (!identical(
    unname(fish["2", c("3", "16", "24", "26", "57", "61", "62", "75")]),
    c(37L, 1L, 2L, 2L, 3L, 4L, 0L, 2L)
  )) {
    fail("F2/F3 effective selectivity settings are not the requested settings.")
  }
  if (!identical(
    unname(fish["33", c("3", "16", "24", "26", "57", "61", "62", "75")]),
    c(37L, 0L, 31L, 2L, 3L, 4L, 0L, 2L)
  )) {
    fail("F33 effective selectivity settings are not the requested spline.")
  }
  if (!identical(
    unname(fish[as.character(29:33), "24"]),
    27:31
  )) {
    fail("Index selectivity groups must be independent from Phase 1.")
  }
  if (any(grepl("^\\s*-[0-9]+\\s+24\\s+", phase_body(lines, "PHASE5")))) {
    fail("Phase 5 must not falsely re-open already independent selectivity groups.")
  }
  if (sum(trimws(lines) ==
          "2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient") != 1L ||
      sum(trimws(lines) == "2 27 -1  # movement-prior coefficient 0.1") != 1L ||
      sum(trimws(lines) == "1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound") != 1L ||
      sum(trimws(lines) == "1 121 0    # estimate no natural-mortality age_pars(5) coefficients; fix Lorenzen intercept and length slope at incoming .par values") != 1L) {
    fail("Rec0.1, move0.1, Nmax25 or fixed-M control is missing.")
  }
  if (sum(trimws(lines) ==
          "-14 75 5  # F14 HL.ID.2 youngest age classes fixed at zero selectivity") != 1L ||
      sum(trimws(lines) ==
          "-15 75 5  # F15 youngest age classes fixed at zero selectivity") != 1L) {
    fail("F14/F15 youngest-five-age selectivity controls are missing.")
  }

  expected_chain <- c(
    "$program_path bet.frq 02.par 03.par -file - <<PHASE3",
    "$program_path bet.frq 03.par 04a.par -file - <<PHASE4A",
    "$program_path bet.frq 04a.par 04b.par -file - <<PHASE4B",
    "$program_path bet.frq 04b.par 04c.par -file - <<PHASE4C",
    "$program_path bet.frq 04c.par 04.par -file - <<PHASE4D",
    "$program_path bet.frq 04.par 05.par -file - <<PHASE5",
    "$program_path bet.frq 05.par 06.par -file - <<PHASE6",
    "$program_path bet.frq 06.par 07a.par -file - <<PHASE7A",
    "$program_path bet.frq 07a.par 07.par -file - <<PHASE7B",
    "$program_path bet.frq 08.par 09a.par -file - <<PHASE9A",
    "$program_path bet.frq 09a.par 09.par -file - <<PHASE9B"
  )
  if (!all(expected_chain %in% lines)) {
    fail("Staged recruitment-to-growth PAR chain is incomplete.")
  }
  scaled_phases <- c("PHASE5", "PHASE7B", "PHASE9B", "PHASE11")
  for (label in scaled_phases) {
    if (sum(grepl("^1\\s+152\\s+1", phase_body(lines, label))) != 1L) {
      fail(label, " must use same-dimension gradient scaling.")
    }
  }
  opr_scaled <- sum(grepl("^1\\s+152\\s+1", phase_body(lines, "PHASE4A")))
  if (identical(models$opr_mode[[i]], "off") && opr_scaled != 0L) {
    fail("Standard Phase 4A changes dimension and may not reuse gradient scaling.")
  }
  if (!identical(models$opr_mode[[i]], "off") && opr_scaled != 1L) {
    fail("OPR Phase 4A must be a same-dimension rescaled stabilization.")
  }
  if (sum(grepl("^1\\s+152\\s+0", phase_body(lines, "PHASE12"))) != 1L ||
      sum(grepl("^1\\s+50\\s+\\$phase10_11_convergence",
                phase_body(lines, "PHASE12"))) != 1L ||
      sum(grepl("^1\\s+351\\s+0", phase_body(lines, "PHASE12"))) != 1L) {
    fail("Phase 12 must be the native-scale final MGC 1e-4 confirmation.")
  }
  if (sum(grepl("^1\\s+351\\s+0", phase_body(lines, "PHASE1"))) != 1L ||
      sum(grepl("^1\\s+351\\s+0", phase_body(lines, "PHASE2"))) != 1L ||
      sum(grepl("^1\\s+351\\s+1", phase_body(lines, "PHASE3"))) != 1L ||
      sum(grepl("^1\\s+192\\s+400", phase_body(lines, "PHASE3"))) != 1L ||
      sum(grepl("^1\\s+352\\s+0", phase_body(lines, "PHASE3"))) != 1L) {
    fail("QN-to-LMN400 optimizer transition is incomplete.")
  }
  if (sum(grepl("^1\\s+50\\s+-2", phase_body(lines, "PHASE10"))) != 1L) {
    fail("Phase 10 must hand common tau to the rescaled final fit at MGC 1e-2.")
  }

  plan <- utils::read.csv(
    file.path(model_dir, "doitall-phase-plan.csv"),
    stringsAsFactors = FALSE
  )
  expected_phases <- c(
    "1", "2", "3", "4A", "4B", "4C", "4D", "5",
    "6", "7A", "7B", "8", "9A", "9B", "10", "11", "12"
  )
  if (!identical(as.character(plan$phase), expected_phases) ||
      !isTRUE(all.equal(as.numeric(tail(plan$mgc, 2)), c(1e-4, 1e-4))) ||
      !identical(as.logical(tail(plan$gradient_rescaled, 2)), c(TRUE, FALSE)) ||
      !identical(
        as.character(plan$optimizer),
        c(
          "quasi-Newton", "quasi-Newton",
          rep("limited-memory Newton (400 terms)", 14L),
          "quasi-Newton"
        )
      )) {
    fail("Numerical phase-plan audit mismatch.")
  }
  staged_hashes[[i]] <- sha256(doitall_path)
}

if (identical(staged_hashes[[1L]], staged_hashes[[2L]])) {
  fail("Standard and OPR staged doitall scripts must differ.")
}

message(
  "Validated two independent full-reg John-selectivity stable-doitall rows: ",
  "F15/DOM QC, 290-row active regional scaling, grouped selectivity flags, ",
  "standard/OPR recruitment, QN-to-LMN400 staged numerical controls, ",
  "Nmax25, fixed M, ",
  "common tau, rec0.1/move0.1 and final native MGC 1e-4."
)
