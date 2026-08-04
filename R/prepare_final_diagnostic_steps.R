## Frozen late-step recipes linking the stepwise pathway to the two public
## Diagnostic archives. These helpers copy exact Git blobs at locked commits;
## they never read the diagnostic repository working tree.

stepwise_git_blob_to_file <- function(repo, commit, path, destination) {
  repo <- normalizePath(repo, winslash = "/", mustWork = TRUE)
  spec <- paste0(commit, ":", path)
  error_file <- tempfile("git-blob-error-")
  on.exit(unlink(error_file), add = TRUE)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  status <- system2(
    "git", c("-C", repo, "cat-file", "blob", spec),
    stdout = destination, stderr = error_file
  )
  if (!identical(status, 0L)) {
    message <- if (file.exists(error_file)) {
      paste(readLines(error_file, warn = FALSE), collapse = " ")
    } else {
      "unknown git cat-file error"
    }
    stop("Could not extract ", spec, " from ", repo, ": ", message, call. = FALSE)
  }
  invisible(destination)
}

stepwise_copy_tree <- function(from, to) {
  if (!dir.exists(from)) stop("Missing model tree: ", from, call. = FALSE)
  unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  sources <- list.files(from, all.files = TRUE, no.. = TRUE, full.names = TRUE)
  if (length(sources) && !all(file.copy(sources, to, recursive = TRUE, copy.date = TRUE))) {
    stop("Could not copy model tree from ", from, " to ", to, call. = FALSE)
  }
  invisible(to)
}

stepwise_recursive_files <- function(model_dir) {
  paths <- list.files(model_dir, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  paths <- paths[file.exists(paths) & !dir.exists(paths)]
  substring(paths, nchar(normalizePath(model_dir, winslash = "/")) + 2L)
}

stepwise_write_locked_manifest <- function(step_dir, provenance) {
  model_dir <- file.path(step_dir, "model")
  files <- stepwise_recursive_files(model_dir)
  rows <- lapply(files, function(file) {
    record <- provenance[[file]]
    if (is.null(record)) {
      record <- list(
        role = "carried_audit", repository = stepwise_repository_url,
        commit = stepwise_base_commit,
        path = file.path("steps", "19a-DMG8Nmax25", "model", file),
        note = "Carried unchanged from Step 19a; not an MFCL fitting input."
      )
    }
    source_sha <- ""
    if (identical(record$repository, stepwise_repository_url) &&
        identical(record$commit, stepwise_base_commit) &&
        startsWith(record$path, "steps/19a-DMG8Nmax25/")) {
      source_file <- file.path(root, record$path)
      if (file.exists(source_file)) source_sha <- stepwise_sha256_file(source_file)
    }
    data.frame(
      role = record$role,
      file = file,
      source = paste0(record$repository, "/blob/", record$commit, "/", record$path),
      source_repository = record$repository,
      source_commit = record$commit,
      source_path = record$path,
      source_sha256 = source_sha,
      sha256 = stepwise_sha256_file(file.path(model_dir, file)),
      source_access = "public",
      provenance_status = "locked",
      note = record$note,
      stringsAsFactors = FALSE
    )
  })
  manifest <- do.call(rbind, rows)
  manifest <- manifest[order(manifest$role, manifest$file), , drop = FALSE]
  write.csv(manifest, file.path(step_dir, "input_manifest.csv"), row.names = FALSE)
  invisible(manifest)
}

stepwise_external_record <- function(commit, path, role = "diagnostic_recipe",
                                     note = "Exact file from the locked public Diagnostic recipe.") {
  list(
    role = role,
    repository = diagnostic_repository_url,
    commit = commit,
    path = path,
    note = note
  )
}

write_final_diagnostic_steps <- function(diagnostic_repo) {
  stepwise_repository_url <<- "https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise"
  diagnostic_repository_url <<- "https://github.com/PacificCommunity/ofp-sam-bet-2026-diagnostic"
  stepwise_base_commit <<- "b3bc4c5cb30200c7c5e7faa77ad26d3ebcef2eba"
  job19835_recipe_commit <- "2973795d47b255e015fee680608401f20160e80a"
  tau2_recipe_commit <- "770edf1e910b03b8a390c3cd1a1398d5ea25796e"
  diagnostic_main_commit <- "0d6db041478a582d44577d14915048d3ee60866b"

  ## 19b: exact Job 19835 seed-23 initialization on the unchanged 19a model.
  step19a_model <- file.path(root, "steps", "19a-DMG8Nmax25", "model")
  step19b_dir <- file.path(root, "steps", "19b-Job19835Seed23")
  step19b_model <- file.path(step19b_dir, "model")
  stepwise_copy_tree(step19a_model, step19b_model)
  seed_script_path <- paste0(
    "explorations/K020-tau-not-estimated-sel20c-f10-ndpen-weak-",
    "seed23-base/doitall.sh"
  )
  stepwise_git_blob_to_file(root, job19835_recipe_commit, seed_script_path,
                            file.path(step19b_model, "doitall.sh"))
  Sys.chmod(file.path(step19b_model, "doitall.sh"), mode = "0755")
  write.csv(
    data.frame(
      source_base_job = 19325L,
      promoted_recipe_job = 19835L,
      jitter_cv = 0.1,
      selected_seed = 23L,
      selection_rule = "minimum objective among converged jitter fits",
      objective = 89054.3397838085,
      maximum_gradient = 9.2968286e-05,
      terminal_depletion_2024 = 0.3287955046,
      stringsAsFactors = FALSE
    ),
    file.path(step19b_model, "seed23-selection-audit.csv"), row.names = FALSE
  )
  provenance19b <- list()
  provenance19b[["doitall.sh"]] <- list(
    role = "job19835_doitall", repository = stepwise_repository_url,
    commit = job19835_recipe_commit, path = seed_script_path,
    note = "Exact Job 19835 Phase-1/2/5 deterministic seed-23 initialization recipe."
  )
  provenance19b[["seed23-selection-audit.csv"]] <- list(
    role = "jitter_selection_audit", repository = stepwise_repository_url,
    commit = job19835_recipe_commit, path = paste0(dirname(seed_script_path), "/README.md"),
    note = "Seed 23 selected by lowest objective among converged Job 19325 jitters."
  )
  stepwise_write_locked_manifest(step19b_dir, provenance19b)
  write_readme(
    step19b_dir, "19b Previous Diagnostic: selected jitter seed 23",
    "Reproduce Job 19835 by promoting the best-objective converged Job 19325 jitter fit.",
    c(
      "All scientific inputs and MFCL controls are unchanged from Step 19a.",
      "The only fitting-path change is the exact CV=0.1 seed-23 initialization at Phases 1, 2 and 5.",
      "Seed 23 was selected by minimum objective among converged jitters, not by depletion."
    ),
    c(
      "bet.* / mfcl.cfg" = "Byte-identical Step 19a scientific inputs",
      "doitall.sh" = "Exact public Job 19835 reproducible seed-23 recipe",
      "seed23-selection-audit.csv" = "Selection rule and archived fit statistics"
    ),
    c(
      "Job 19835 objective 89054.3397838085; maximum gradient 9.2968286e-05.",
      "This is a historical comparison branch. Step 20 continues from ordinary-makepar Step 19a."
    ),
    status = "Ready to reproduce the previous Diagnostic Job 19835 on Suva."
  )

  ## 20-22: exact public tau=2 grid and Diagnostic recipes at locked commits.
  common_files <- c(
    "bet.age_length", "bet.frq", "bet.ini", "bet.reg_scaling", "bet.tag",
    "cpue_mle_sigma_audit.csv", "doitall.sh", "fishery_map.R", "mfcl.cfg",
    "tag_rep_map.R"
  )
  specifications <- list(
    list(
      id = "20-Tau2Fixed", commit = tau2_recipe_commit,
      input = "S0.80-F1", selectivity = "F1", title = "20 Tag tau fixed at 2",
      summary = "Fix direct negative-binomial tag tau at 2 from ordinary Step 19a initialization.",
      change = "Only the fitted-model tau treatment changes; seed 23 is not carried forward."
    ),
    list(
      id = "21-F33WeakPenalty", commit = tau2_recipe_commit,
      input = "S0.80-F2", selectivity = "F2", title = "21 F33 weak non-decreasing penalty",
      summary = "Retain Step 20 and add the weak F33 non-decreasing selectivity penalty.",
      change = "Only F33 flags 16 and 56 change, from 0/0 to 1/10000."
    ),
    list(
      id = "22-Diagnostic", commit = diagnostic_main_commit,
      input = "Diagnostic", selectivity = "Diagnostic", title = "22 BET 2026 Diagnostic model",
      summary = "Retain Step 21 and fix steepness at 0.90, reproducing public Diagnostic Job 21641.",
      change = "Only INI sv(29) changes from 0.80 to 0.90; age flag 162 remains zero."
    )
  )

  for (specification in specifications) {
    step_dir <- file.path(root, "steps", specification$id)
    model_dir <- file.path(step_dir, "model")
    unlink(model_dir, recursive = TRUE, force = TRUE)
    dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
    provenance <- list()
    for (file in common_files) {
      source_path <- file.path("model", file)
      stepwise_git_blob_to_file(
        diagnostic_repo, specification$commit, source_path,
        file.path(model_dir, file)
      )
      provenance[[file]] <- stepwise_external_record(specification$commit, source_path)
    }
    input_source <- file.path("model", "model-inputs", paste0(specification$input, ".conf"))
    input_target <- file.path("model-inputs", paste0(specification$input, ".conf"))
    stepwise_git_blob_to_file(
      diagnostic_repo, specification$commit, input_source,
      file.path(model_dir, input_target)
    )
    provenance[[input_target]] <- stepwise_external_record(
      specification$commit, input_source, "model_definition",
      "Locked fixed-steepness and selectivity-model choice."
    )
    selectivity_source <- file.path(
      "model", "selectivity-models", paste0(specification$selectivity, ".csv")
    )
    selectivity_target <- file.path(
      "selectivity-models", paste0(specification$selectivity, ".csv")
    )
    stepwise_git_blob_to_file(
      diagnostic_repo, specification$commit, selectivity_source,
      file.path(model_dir, selectivity_target)
    )
    provenance[[selectivity_target]] <- stepwise_external_record(
      specification$commit, selectivity_source, "selectivity_definition",
      "Complete explicit 33-fishery selectivity table."
    )

    if (identical(specification$id, "21-F33WeakPenalty")) {
      script_path <- file.path(model_dir, "doitall.sh")
      lines <- readLines(script_path, warn = FALSE)
      expected <- "requested_model_id=${MODEL_ID:-S0.80-F1}"
      if (sum(lines == expected) != 1L) {
        stop("Could not set the Step 21 default model ID in the locked tau=2 recipe.", call. = FALSE)
      }
      lines[lines == expected] <- "requested_model_id=${MODEL_ID:-S0.80-F2}"
      writeLines(lines, script_path, useBytes = TRUE)
      provenance[["doitall.sh"]]$note <- paste(
        provenance[["doitall.sh"]]$note,
        "The default model ID is deterministically set to S0.80-F2 for this standalone folder."
      )
    }
    Sys.chmod(file.path(model_dir, "doitall.sh"), mode = "0755")

    ## Preserve stepwise-only audit sidecars. They do not enter the MFCL fit.
    for (audit in c(
      "bet.reg_scaling.full", "f15-lf-qc-audit.csv", "f15-lf-qc-summary.csv",
      "dom-lf-qc-audit.csv", "dom-lf-qc-summary.csv"
    )) {
      copy_one(file.path(step19a_model, audit), file.path(model_dir, audit))
    }
    stepwise_write_locked_manifest(step_dir, provenance)
    write_readme(
      step_dir, specification$title, specification$summary,
      c(
        specification$change,
        "No seed, jitter or fitted checkpoint is used.",
        if (identical(specification$id, "22-Diagnostic")) {
          "The model files are extracted from the current public Diagnostic main recipe."
        } else {
          "The model files are extracted from the public fixed-tau exploration recipe."
        }
      ),
      stats::setNames(c(
        "bet.frq" = "Diagnostic FRQ with unused weight-frequency structure removed; no observation changed",
        "bet.ini" = if (identical(specification$id, "22-Diagnostic")) "Fixed h=0.90 Diagnostic INI" else "Fixed h=0.80 tau=2 exploration INI",
        "doitall.sh" = "Locked no-seed direct-tau fitting and audit recipe",
        "Fixed steepness/selectivity selection",
        "Explicit 33-fishery selectivity controls"
      ), c("bet.frq", "bet.ini", "doitall.sh", input_target, selectivity_target)),
      c(
        "Negative-binomial likelihood is retained.",
        "Tau is fixed with parest 111/305/306=4/1/0, fish flags 43/44=0 and all fish_pars(4)=0.",
        "DM G8/Nmax25, fixed concentration 7, M, mixing, reporting rates, CPUE and biological inputs are retained."
      ),
      status = if (identical(specification$id, "22-Diagnostic")) {
        "Locked to the public Diagnostic main and completed Job 21641 reference."
      } else {
        "Ready for an independent Suva fit."
      }
    )
  }
  invisible(TRUE)
}
