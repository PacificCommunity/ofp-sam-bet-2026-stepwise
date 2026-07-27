fail <- function(...) stop(..., call. = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
config_path <- file.path(root, "job-config-f14-young5-rec-grid.R")
task_path <- file.path(root, "kflow-f14-young5-rec-grid.yaml")
source_dir <- file.path(root, "steps", "S03-CommonTagTau-MIX015", "model")
doitall_path <- file.path(source_dir, "doitall.sh")
f15_apply_path <- file.path(root, "R", "apply_f15_lf_qc.R")
movement_apply_path <- file.path(root, "R", "apply_movement_prior_penalty.R")
opr_apply_path <- file.path(root, "R", "apply_opr_sensitivity.R")
registrar_path <- file.path(root, "scripts", "register_kflow_task.py")
step_ids <- c(
  "F14-Y5-REC01",
  "F14-Y5-REC02",
  "F14-Y5-REC01-MOVE02",
  "F14-Y5-REC02-MOVE02",
  "F14-Y5-REC01-OPR",
  "F14-Y5-REC02-OPR",
  "F14-Y5-REC01-MOVE02-OPR",
  "F14-Y5-REC02-MOVE02-OPR"
)
patch_paths <- file.path(root, "steps", step_ids, "patch.R")
source_input_names <- c(
  "doitall.sh", "bet.ini", "bet.frq", "bet.tag", "bet.age_length",
  "bet.reg_scaling", "bet.reg_scaling.full"
)

required_files <- c(
  config_path, task_path, registrar_path, patch_paths,
  f15_apply_path, movement_apply_path, opr_apply_path,
  file.path(root, "R", c("prepare_common.R", "prepare_doitall.R")),
  file.path(source_dir, source_input_names)
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  fail("Missing F14 sensitivity file(s): ", paste(missing_files, collapse = ", "))
}

cfg <- new.env(parent = baseenv())
sys.source(config_path, envir = cfg)
models <- get("stepwise_models", envir = cfg)

expected_rec <- rep(c("0.1", "0.2"), 4)
expected_movement <- rep(c("0.1", "0.1", "0.2", "0.2"), 2)
expected_opr <- c(rep("off", 4), rep("72-01-50-50-end2", 4))
if (!is.data.frame(models) || nrow(models) != 8L) {
  fail("Expected exactly eight independent F14 sensitivity rows.")
}
if (!identical(models$step_id, step_ids) ||
    !identical(models$STEP_SELECT, step_ids)) {
  fail("Unexpected model row order or STEP_SELECT values.")
}
if (!identical(models$run_mode, rep("doitall", 8)) ||
    !identical(models$run_script, rep("doitall.sh", 8)) ||
    !identical(models$independent_fit, rep(TRUE, 8))) {
  fail("All eight rows must be independent doitall fits.")
}
if (!identical(models$scientific_parent_mode, rep("metadata-only", 8))) {
  fail("Scientific parents must be provenance metadata only.")
}
if (!identical(models$regional_recruitment_penalty, expected_rec) ||
    !identical(models$movement_prior_penalty, expected_movement) ||
    !identical(models$opr_mode, expected_opr)) {
  fail("The configured rec x movement x OPR grid is not the required 2 x 2 x 2.")
}
if (!identical(models$phase10_11_convergence, rep("-4", 8)) ||
    !identical(models$dm_nmax, rep("25", 8)) ||
    !identical(models$f14_youngest_zero, rep("5", 8))) {
  fail("Expected F14=5, Nmax=25 and MGC=1e-4 in all eight rows.")
}
if (!identical(models$f15_qc_mode, rep("lt70", 8)) ||
    !identical(models$tag_tau_grouping, rep("common", 8)) ||
    !identical(models$tau_mode, rep("estimated-common", 8))) {
  fail("F15 QC or tag-tau controls differ between rows.")
}
for (field in c(
  "input_par", "output_par", "par_source_job", "kflow_input_jobs",
  "expected_source_par_sha256", "job_par_max_evaluations"
)) {
  if (!identical(models[[field]], rep("", 8))) {
    fail(field, " must be empty: doitall may not attach or continue a previous PAR.")
  }
}
if (anyDuplicated(models$step_id) || anyDuplicated(models$job_key) ||
    anyDuplicated(models$model_label)) {
  fail("Step IDs, job keys and labels must be unique.")
}

expected_full_patch <- c(
  'source(file.path(getwd(), "R", "apply_f15_lf_qc.R"), local = TRUE)',
  'env_mode <- Sys.getenv("F15_QC_MODE", "")',
  'if (nzchar(env_mode) && !identical(env_mode, config$F15_QC_MODE)) {',
  '  stop("F15_QC_MODE environment/config mismatch.", call. = FALSE)',
  '}',
  'apply_f15_lf_qc(model_dir, config$F15_QC_MODE)',
  'source(file.path(getwd(), "R", "apply_movement_prior_penalty.R"), local = TRUE)',
  'env_movement <- Sys.getenv("MOVEMENT_PRIOR_PENALTY", "")',
  'if (nzchar(env_movement) && !identical(env_movement, config$MOVEMENT_PRIOR_PENALTY)) {',
  '  stop("MOVEMENT_PRIOR_PENALTY environment/config mismatch.", call. = FALSE)',
  '}',
  'apply_movement_prior_penalty(model_dir, config$MOVEMENT_PRIOR_PENALTY)',
  'source(file.path(getwd(), "R", "apply_opr_sensitivity.R"), local = TRUE)',
  'env_opr <- Sys.getenv("OPR_MODE", "")',
  'if (nzchar(env_opr) && !identical(env_opr, config$OPR_MODE)) {',
  '  stop("OPR_MODE environment/config mismatch.", call. = FALSE)',
  '}',
  'apply_opr_sensitivity(model_dir, config$OPR_MODE)'
)
for (patch_path in patch_paths[1:4]) {
  if (!identical(readLines(patch_path, warn = FALSE), expected_full_patch)) {
    fail("Unexpected full sensitivity patch content: ", patch_path)
  }
}
expected_proxy <- 'source(file.path(getwd(), "steps", "F14-Y5-REC01", "patch.R"), local = TRUE)'
for (patch_path in patch_paths[5:8]) {
  if (!identical(readLines(patch_path, warn = FALSE), expected_proxy)) {
    fail("Unexpected OPR sensitivity proxy patch content: ", patch_path)
  }
}

sha256 <- function(path) {
  out <- system2("sha256sum", path, stdout = TRUE)
  strsplit(out[[1L]], "[[:space:]]+")[[1L]][[1L]]
}
expected_hashes <- c(
  "doitall.sh" = "9a5922133fd749ff162972590897f47796e0423c18dc71d0e332828f37e92ccf",
  "bet.ini" = "4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a",
  "bet.frq" = "d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c",
  "bet.tag" = "b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f",
  "bet.age_length" = "426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c",
  "bet.reg_scaling" = "6330fb6a36d63424c18f81cbc620c1d9607c2a5c43d0308d19941f12938ec9a1",
  "bet.reg_scaling.full" = "dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed"
)
actual_hashes <- vapply(file.path(source_dir, names(expected_hashes)), sha256, character(1L))
names(actual_hashes) <- names(expected_hashes)
bad_hashes <- names(expected_hashes)[actual_hashes != expected_hashes]
if (length(bad_hashes)) {
  fail("Frozen source hash mismatch: ", paste(bad_hashes, collapse = ", "))
}

source_doitall <- readLines(doitall_path, warn = FALSE)
exact_count <- function(text) sum(trimws(source_doitall) == text)
required_controls <- c(
  "-14 24 12  # F14 selectivity-stability group" = 2L,
  "-15 24 13  # F15 selectivity-stability group" = 2L,
  "-14 75 5  # F14 HL.ID.2 youngest age classes fixed at zero selectivity" = 1L,
  "-15 75 5  # F15 youngest age classes fixed at zero selectivity" = 1L,
  "2 27 -1  # penalty wt 0.1 computed against prior" = 1L,
  "2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient" = 1L,
  "1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound" = 1L,
  "1 50 $phase10_11_convergence" = 2L
)
bad_controls <- names(required_controls)[
  vapply(names(required_controls), exact_count, integer(1L)) != required_controls
]
if (length(bad_controls)) {
  fail("Missing or duplicated source doitall control(s): ", paste(bad_controls, collapse = " | "))
}
if (!any(grepl("regional_recruitment_penalty_flag=0", source_doitall, fixed = TRUE)) ||
    !any(grepl("regional_recruitment_penalty_flag=2", source_doitall, fixed = TRUE))) {
  fail("Doitall does not map rec penalties 0.1 and 0.2 to age flag 110 correctly.")
}
if (!any(grepl("$program_path bet.frq bet.ini 00.par -makepar", source_doitall, fixed = TRUE))) {
  fail("Doitall no longer starts from bet.ini using -makepar.")
}

phase_lines <- function(lines, phase) {
  start <- grep(paste0("<<PHASE", phase, "$"), lines)
  end <- grep(paste0("^PHASE", phase, "$"), lines)
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    fail("Malformed PHASE", phase, " block in staged doitall.")
  }
  trimws(lines[(start + 1L):(end - 1L)])
}
expected_standard_phase3 <- c(
  "2 70 1   # activate time series of reg recruitment parameters",
  "2 71 1   # estimate temporal changes in recruitment distribution",
  "2 178 1  # constrain regional recruitments",
  "1 1 200"
)
required_opr_phase3 <- c(
  "1 155 72  # orthogonal polynomial recruitment - year effect",
  "1 217 1   # orthogonal polynomial recruitment - season effect",
  "1 216 50  # orthogonal polynomial recruitment - region effect",
  "1 218 50  # orthogonal polynomial recruitment - region-season interaction effect",
  "1 202 2   # OPR end window: last 2 real years use lower-degree/constant-end basis",
  "1 210 0   # OPR region end window: 0 inherits parest_flag(202)",
  "1 212 0   # OPR season end window: 0 inherits parest_flag(202)",
  "1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)",
  "2 30 1    # keep age_flag(30) on so current MFCL activates OPR coefficients",
  "2 70 0    # turn off mean+deviate regional recruitment time series",
  "2 71 0    # turn off regional recruitment distribution deviations",
  "2 178 0   # turn off regional recruitment sum-product constraint"
)

test_root <- tempfile("f14-young5-grid-validation-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE, force = TRUE), add = TRUE)
staged_f15_hashes <- character(nrow(models))
staged_movement_flags <- character(nrow(models))
for (i in seq_len(nrow(models))) {
  model_dir <- file.path(test_root, models$step_id[[i]])
  dir.create(model_dir, recursive = TRUE)
  copied <- file.copy(
    file.path(source_dir, source_input_names),
    file.path(model_dir, source_input_names),
    overwrite = TRUE
  )
  if (!all(copied)) fail("Could not stage validation inputs for ", models$step_id[[i]], ".")

  patch_env <- new.env(parent = globalenv())
  patch_env$model_dir <- normalizePath(model_dir, mustWork = TRUE)
  patch_env$config <- list(
    F15_QC_MODE = models$f15_qc_mode[[i]],
    MOVEMENT_PRIOR_PENALTY = models$movement_prior_penalty[[i]],
    OPR_MODE = models$opr_mode[[i]]
  )
  sys.source(patch_paths[[i]], envir = patch_env)

  f15_summary <- utils::read.csv(
    file.path(model_dir, "f15-lf-qc-summary.csv"),
    stringsAsFactors = FALSE
  )
  if (nrow(f15_summary) != 1L ||
      !identical(f15_summary$output_sha256[[1L]],
                 "3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60") ||
      !identical(as.integer(f15_summary$f15_lf_rows_affected[[1L]]), 66L) ||
      !isTRUE(all.equal(f15_summary$removed_count[[1L]], 1057)) ||
      !isTRUE(all.equal(f15_summary$f15_count_before[[1L]], 41908)) ||
      !isTRUE(all.equal(f15_summary$f15_count_after[[1L]], 40851)) ||
      !identical(f15_summary$renormalised[[1L]], FALSE) ||
      !identical(f15_summary$catch_or_effort_changed[[1L]], FALSE)) {
    fail("F15 <70 cm QC audit failed for ", models$step_id[[i]], ".")
  }
  staged_f15_hashes[[i]] <- sha256(file.path(model_dir, "bet.frq"))

  for (name in setdiff(names(expected_hashes), c("bet.frq", "doitall.sh"))) {
    if (!identical(sha256(file.path(model_dir, name)), expected_hashes[[name]])) {
      fail("Patch unexpectedly changed ", name, " for ", models$step_id[[i]], ".")
    }
  }

  staged <- readLines(file.path(model_dir, "doitall.sh"), warn = FALSE)
  expected_flag <- if (identical(models$movement_prior_penalty[[i]], "0.1")) "-1" else "-2"
  movement_line <- paste0(
    "2 27 ", expected_flag, "  # penalty wt ",
    models$movement_prior_penalty[[i]], " computed against prior"
  )
  if (sum(trimws(staged) == movement_line) != 1L ||
      sum(grepl("^\\s*2\\s+27\\s+", staged)) != 1L) {
    fail("Movement-prior staged control failed for ", models$step_id[[i]], ".")
  }
  staged_movement_flags[[i]] <- expected_flag
  if (sum(trimws(staged) ==
          "2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient") != 1L) {
    fail("OPR/movement patch removed the rec-penalty switch for ", models$step_id[[i]], ".")
  }
  if (sum(trimws(staged) ==
          "-14 75 5  # F14 HL.ID.2 youngest age classes fixed at zero selectivity") != 1L ||
      sum(trimws(staged) ==
          "-15 75 5  # F15 youngest age classes fixed at zero selectivity") != 1L) {
    fail("F14/F15 youngest-five-age zero-selectivity controls failed for ", models$step_id[[i]], ".")
  }

  p3 <- phase_lines(staged, 3L)
  p5 <- phase_lines(staged, 5L)
  if (identical(models$opr_mode[[i]], "off")) {
    if (!identical(p3, expected_standard_phase3) ||
        any(grepl("orthogonal polynomial recruitment", staged, fixed = TRUE))) {
      fail("Standard recruitment row was not preserved for ", models$step_id[[i]], ".")
    }
    for (region in 1:5) {
      if (sum(grepl(
        paste0("^-100000 ", region, " 1([[:space:]]|$)"), p5
      )) != 1L) {
        fail("Standard Phase-5 region flag failed for ", models$step_id[[i]], ".")
      }
    }
  } else {
    if (!all(required_opr_phase3 %in% p3) ||
        length(p3) != 25L ||
        any(expected_standard_phase3 %in% p3)) {
      fail("Exact 72-01-50-50 end2 OPR block failed for ", models$step_id[[i]], ".")
    }
    for (region in 1:5) {
      if (sum(grepl(
        paste0("^-100000 ", region, " 0([[:space:]]|$)"), p5
      )) != 1L) {
        fail("OPR Phase-5 region flag failed for ", models$step_id[[i]], ".")
      }
    }
  }
}
if (!identical(staged_f15_hashes, rep(
  "3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60",
  8
))) {
  fail("All eight rows must stage the identical verified F15 <70 cm FRQ.")
}
if (!identical(staged_movement_flags, c("-1", "-1", "-2", "-2", "-1", "-1", "-2", "-2"))) {
  fail("Staged movement flags do not match the 2 x 2 x 2 grid.")
}

registrar <- readLines(registrar_path, warn = FALSE)
for (mapping in c(
  '("phase10_11_convergence", "BET_PHASE10_11_CONVERGENCE")',
  '("regional_recruitment_penalty", "REGIONAL_RECRUITMENT_PENALTY")',
  '("movement_prior_penalty", "MOVEMENT_PRIOR_PENALTY")',
  '("opr_mode", "OPR_MODE")',
  '"input_jobs": split_job_refs(row.get("kflow_input_jobs"))'
)) {
  if (!any(grepl(mapping, registrar, fixed = TRUE))) {
    fail("Kflow registrar is missing per-row wiring: ", mapping)
  }
}

task <- readLines(task_path, warn = FALSE)
required_task <- c(
  "name: bet-2026-f14-young5-rec-grid-20260728",
  "branch: sensitivity/job17513-f14-young5-rec-grid-20260728",
  "command: Rscript --vanilla scripts/validate_f14_young5_rec_grid.R && bash run.sh",
  "  CONFIG_R: job-config-f14-young5-rec-grid.R",
  "  STEP_SELECT: F14-Y5-REC01",
  "  RUN_MODE: doitall",
  "  F15_QC_MODE: lt70",
  "  DM_NMAX: \"25\"",
  "  REGIONAL_RECRUITMENT_PENALTY: \"0.1\"",
  "  MOVEMENT_PRIOR_PENALTY: \"0.1\"",
  "  OPR_MODE: \"off\"",
  "  BET_PHASE10_11_CONVERGENCE: \"-4\"",
  "  model_count: 8",
  "  movement_prior_penalties: \"0.1,0.2\"",
  "  recruitment_structures: \"standard,OPR 72-01-50-50 end2\"",
  "  common_tag_tau_estimated: true",
  "  natural_mortality_fixed: true",
  "  execution: \"independent doitall from bet.ini for all eight rows\""
)
missing_task <- setdiff(required_task, task)
if (length(missing_task)) {
  fail("Kflow task defaults/metadata are incomplete: ", paste(missing_task, collapse = " | "))
}
if (any(grepl("^input_jobs:", task))) {
  fail("The task must not attach a previous job; all rows are doitall.")
}

cat(
  "Validated eight independent F14 youngest-five-age doitall sensitivities: ",
  "rec 0.1/0.2 x movement prior 0.1/0.2 x standard/OPR 72-01-50-50 end2; ",
  "all rows use the identical verified F15 <70 cm FRQ, Nmax=25, MGC 1e-4, ",
  "common estimated tag tau, fixed M, and no previous PAR inputs.\n",
  sep = ""
)
