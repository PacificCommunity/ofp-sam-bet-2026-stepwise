## Build controlled terminal-2022 tag release-group sensitivities.
##
## The Job 15363 terminal-2022 retrospective peel is the reference cell:
## original release groups 59 and 60 are both retained. This script first
## reproduces that peel with mfclkit, then freezes the reference or removes
## G60, G59, or both while
## synchronously subsetting and renumbering the TAG, MFCL-1007 INI tag
## sections, and the FRQ tag-group dimension. All non-tag inputs and the
## complete native-MFCL doitall controls remain identical among variants.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
parent_step <- "18-GroupedSelectivityRobustness"
parent_model <- file.path(root, "steps", parent_step, "model")
if (!dir.exists(parent_model)) {
  stop("Missing Job 15363 parent model directory: ", parent_model, call. = FALSE)
}

mfclkit_source <- trimws(Sys.getenv("MFCLKIT_SOURCE_DIR", ""))
if (nzchar(mfclkit_source)) {
  if (!requireNamespace("pkgload", quietly = TRUE)) {
    stop("pkgload is required when MFCLKIT_SOURCE_DIR is supplied.", call. = FALSE)
  }
  pkgload::load_all(mfclkit_source, quiet = TRUE)
} else if (!requireNamespace("mfclkit", quietly = TRUE)) {
  stop("Install mfclkit or set MFCLKIT_SOURCE_DIR.", call. = FALSE)
}
if (!requireNamespace("FLR4MFCL", quietly = TRUE)) {
  stop("FLR4MFCL is required to build tag sensitivities.", call. = FALSE)
}
source(file.path(root, "R", "prepare_common.R"), local = environment())
source(file.path(root, "R", "prepare_mfcl_inputs.R"), local = environment())

`%||%` <- function(x, y) if (is.null(x) || !length(x) || is.na(x[[1L]])) y else x

mfclkit_sha <- tryCatch(
  {
    desc <- utils::packageDescription("mfclkit")
    as.character(desc[["RemoteSha"]] %||% "")
  },
  error = function(e) ""
)
if (!nzchar(mfclkit_sha) && nzchar(mfclkit_source)) {
  mfclkit_sha <- tryCatch(
    system2(
      "git", c("-C", mfclkit_source, "rev-parse", "HEAD"),
      stdout = TRUE, stderr = FALSE
    )[[1L]],
    error = function(e) ""
  )
}
expected_mfclkit_sha <- trimws(Sys.getenv(
  "MFCLKIT_EXPECTED_SHA",
  "a0fe04baa9c119353123367e5a652bb73d909b84"
))
if (!identical(tolower(mfclkit_sha), tolower(expected_mfclkit_sha))) {
  stop(
    "mfclkit source mismatch: expected ", expected_mfclkit_sha,
    ", found ", if (nzchar(mfclkit_sha)) mfclkit_sha else "<unknown>",
    call. = FALSE
  )
}

sha256 <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && !identical(as.integer(status), 0L)) {
    stop("sha256sum failed for ", path, call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

copy_case <- function(from, to) {
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  old <- list.files(to, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  if (length(old)) unlink(old, recursive = TRUE, force = TRUE)
  files <- list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  ok <- file.copy(files, to, recursive = TRUE, overwrite = TRUE, copy.mode = TRUE)
  if (length(ok) && !all(ok)) {
    stop("Failed to copy the terminal-2022 reference case into ", to, call. = FALSE)
  }
}

subset_tag_groups <- function(tag, keep_groups) {
  keep_groups <- sort(unique(as.integer(keep_groups)))
  old_groups <- sort(unique(as.integer(tag@releases$rel.group)))
  if (!length(keep_groups) || !all(keep_groups %in% old_groups)) {
    stop("Invalid tag release-group subset.", call. = FALSE)
  }
  releases <- tag@releases[
    tag@releases$rel.group %in% keep_groups, , drop = FALSE
  ]
  recaptures <- tag@recaptures[
    tag@recaptures$rel.group %in% keep_groups, , drop = FALSE
  ]
  new_ids <- stats::setNames(seq_along(keep_groups), keep_groups)
  releases$rel.group <- unname(new_ids[as.character(releases$rel.group)])
  recaptures$rel.group <- unname(new_ids[as.character(recaptures$rel.group)])
  tag@release_groups <- length(keep_groups)
  tag@releases <- releases
  tag@recaptures <- recaptures
  tag@recoveries <- tabulate(recaptures$rel.group, length(keep_groups))
  tag
}

baseline_dir <- tempfile("bet-terminal2022-reference-")
on.exit(unlink(baseline_dir, recursive = TRUE, force = TRUE), add = TRUE)
baseline_info <- mfclkit::mfk_apply_retro_peel(
  input_dir = parent_model,
  output_dir = baseline_dir,
  peel = 2L,
  remove_par_files = TRUE,
  rewrite_par = FALSE,
  makepar_start = FALSE,
  run_messages = FALSE
)
if (!identical(as.integer(baseline_info$terminal_year), 2024L) ||
    !identical(as.integer(baseline_info$new_max_year), 2022L) ||
    !identical(as.integer(baseline_info$frq_records_after), 7198L)) {
  stop("The generated terminal-2022 reference does not match Job 15498 peel 2.", call. = FALSE)
}

baseline_tag_path <- file.path(baseline_dir, "bet.tag")
baseline_tag <- FLR4MFCL::read.MFCLTag(baseline_tag_path)
if (!identical(as.integer(baseline_tag@release_groups), 98L) ||
    !identical(as.integer(baseline_tag@range[["maxyear"]]), 2022L)) {
  stop("Unexpected terminal-2022 baseline tag dimensions.", call. = FALSE)
}

release_summary <- unique(
  baseline_tag@releases[
    baseline_tag@releases$rel.group %in% c(59L, 60L),
    c("rel.group", "region", "year", "month", "program"),
    drop = FALSE
  ]
)
release_summary <- release_summary[order(release_summary$rel.group), , drop = FALSE]
expected_release_summary <- data.frame(
  rel.group = c(59L, 60L),
  region = c(4L, 4L),
  year = c(2020L, 2021L),
  month = c(8L, 8L),
  program = c("PTTP", "PTTP"),
  stringsAsFactors = FALSE
)
rownames(release_summary) <- NULL
if (!isTRUE(all.equal(
  release_summary, expected_release_summary, check.attributes = FALSE
))) {
  stop("Original tag groups 59/60 do not match the audited PTTP releases.", call. = FALSE)
}

release_totals <- stats::aggregate(
  lendist ~ rel.group,
  baseline_tag@releases[baseline_tag@releases$rel.group %in% c(59L, 60L), ],
  sum
)
recapture_totals <- stats::aggregate(
  recap.number ~ rel.group,
  baseline_tag@recaptures[baseline_tag@recaptures$rel.group %in% c(59L, 60L), ],
  sum
)
release_summary <- merge(release_summary, release_totals, by = "rel.group", sort = TRUE)
release_summary <- merge(release_summary, recapture_totals, by = "rel.group", sort = TRUE)
names(release_summary)[names(release_summary) == "lendist"] <- "corrected_releases"
names(release_summary)[names(release_summary) == "recap.number"] <- "recaptures_through_2022"

variants <- list(
  "20-Terminal2022TagReference" = integer(),
  "20a-Terminal2022TagG60Excluded" = 60L,
  "20b-Terminal2022TagG59Excluded" = 59L,
  "20c-Terminal2022TagG59G60Excluded" = c(59L, 60L)
)
parent_commit <- "b27d150c1448c9c79654c906cc8096082b401636"
parent_repository <- "https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise"
parent_manifest <- utils::read.csv(
  file.path(root, "steps", parent_step, "input_manifest.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character()
)
parent_cpue_manifest <- parent_manifest[
  parent_manifest$role == "cpue_mle_sigma", , drop = FALSE
]
if (nrow(parent_cpue_manifest) != 1L) {
  stop("Step 18 must contain one CPUE MLE sigma provenance row.", call. = FALSE)
}

patch_ini <- getFromNamespace("mfk_retro_patch_1007_tag_sections", "mfclkit")
patch_frq <- getFromNamespace("mfk_retro_patch_frq_text", "mfclkit")

for (step_id in names(variants)) {
  excluded <- variants[[step_id]]
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  copy_case(baseline_dir, model_dir)
  unlink(file.path(model_dir, "retro_input_info.rds"), force = TRUE)

  keep_groups <- setdiff(seq_len(baseline_tag@release_groups), excluded)
  ini_info <- patch_ini(file.path(model_dir, "bet.ini"), keep_groups)
  frq_info <- patch_frq(
    file.path(model_dir, "bet.frq"),
    max_year = 2022L,
    n_tag_groups = length(keep_groups)
  )
  sensitivity_tag <- subset_tag_groups(baseline_tag, keep_groups)
  FLR4MFCL::write(sensitivity_tag, file = file.path(model_dir, "bet.tag"))
  write_generated_tag_rep_map(model_dir)
  Sys.chmod(file.path(model_dir, "doitall.sh"), mode = "0755")

  if (!identical(as.integer(sensitivity_tag@release_groups), length(keep_groups)) ||
      !identical(as.integer(ini_info$n_tag_groups_after), length(keep_groups)) ||
      !identical(as.integer(frq_info$terminal_year_after), 2022L) ||
      !identical(as.integer(frq_info$records_after), 7198L)) {
    stop("Cross-file tag sensitivity validation failed for ", step_id, call. = FALSE)
  }

  metadata <- release_summary
  metadata$excluded <- metadata$rel.group %in% excluded
  metadata$variant <- step_id
  metadata$terminal_year <- 2022L
  metadata$reference_release_groups <- 98L
  metadata$fitted_release_groups <- length(keep_groups)
  metadata$mfclkit_commit <- mfclkit_sha
  metadata <- metadata[, c(
    "variant", "terminal_year", "rel.group", "program", "region", "year",
    "month", "corrected_releases", "recaptures_through_2022", "excluded",
    "reference_release_groups", "fitted_release_groups", "mfclkit_commit"
  )]
  utils::write.csv(
    metadata,
    file.path(model_dir, "tag_group_sensitivity_audit.csv"),
    row.names = FALSE,
    na = ""
  )

  group_mapping <- data.frame(
    original_release_group = seq_len(baseline_tag@release_groups),
    retained = seq_len(baseline_tag@release_groups) %in% keep_groups,
    fitted_release_group = match(
      seq_len(baseline_tag@release_groups), keep_groups
    ),
    stringsAsFactors = FALSE
  )
  utils::write.csv(
    group_mapping,
    file.path(model_dir, "tag_group_renumbering.csv"),
    row.names = FALSE,
    na = ""
  )

  tracked_files <- c("bet.frq", "bet.ini", "bet.tag", "bet.age_length", "doitall.sh")
  roles <- c("frq", "ini", "tag", "age_length", "doitall")
  exclusion_label <- if (length(excluded)) {
    paste(excluded, collapse = ", ")
  } else {
    "none"
  }
  notes <- c(
    paste0(
      "Terminal-2022 Job 15363 retrospective input with original release-group ",
      "exclusion(s): ", exclusion_label, "."
    ),
    paste0(
      "MFCL-1007 tag sections synchronized for original release-group ",
      "exclusion(s): ", exclusion_label, "."
    ),
    paste0(
      "Terminal-2022 tag input with original release-group exclusion(s): ",
      exclusion_label, "; retained groups are contiguous."
    ),
    "Terminal-2022 Job 15363 retrospective age-length input; identical among sensitivity cells.",
    "Complete Job 15363 native-MFCL doitall controls; unchanged."
  )
  manifest <- data.frame(
    role = roles,
    file = tracked_files,
    source = file.path("steps", parent_step, "model", tracked_files),
    source_repository = parent_repository,
    source_commit = parent_commit,
    source_path = file.path("steps", parent_step, "model", tracked_files),
    source_sha256 = vapply(
      file.path(parent_model, tracked_files), sha256, character(1)
    ),
    sha256 = vapply(file.path(model_dir, tracked_files), sha256, character(1)),
    source_access = "public",
    provenance_status = "locked",
    note = notes,
    stringsAsFactors = FALSE
  )
  manifest <- rbind(
    manifest,
    parent_cpue_manifest,
    data.frame(
      role = c("scientific_parent", "tag_sensitivity_builder"),
      file = c("JOB15498/peel_2", "mfclkit"),
      source = c(
        "Job 15363 terminal-2022 retrospective peel",
        "PacificCommunity/ofp-sam-mfclkit"
      ),
      source_repository = c(parent_repository, "https://github.com/PacificCommunity/ofp-sam-mfclkit"),
      source_commit = c(parent_commit, mfclkit_sha),
      source_path = c(file.path("steps", parent_step, "model"), "R/retro.R"),
      source_sha256 = c("", ""),
      sha256 = c("", ""),
      source_access = c("public", "public"),
      provenance_status = c("locked", "locked"),
      note = c(
        "Job 15498 peel 2 identifies the terminal-2022 comparison point; all four cells are rerun under one common convergence setting.",
        "Used to reproduce the terminal-2022 peel and synchronize TAG/INI/FRQ release-group handling."
      ),
      stringsAsFactors = FALSE
    )
  )
  generated_files <- c(
    "model/tag_group_sensitivity_audit.csv",
    "model/tag_group_renumbering.csv",
    "model/tag_rep_map.R"
  )
  manifest <- rbind(
    manifest,
    data.frame(
      role = c(
        "tag_sensitivity_audit", "tag_group_renumbering",
        "tag_reporting_rate_audit"
      ),
      file = generated_files,
      source = rep("R/build_terminal2022_tag_group_sensitivities.R", 3L),
      source_repository = rep(parent_repository, 3L),
      source_commit = rep("", 3L),
      source_path = rep("R/build_terminal2022_tag_group_sensitivities.R", 3L),
      source_sha256 = rep("", 3L),
      sha256 = vapply(file.path(step_dir, generated_files), sha256, character(1)),
      source_access = rep("public", 3L),
      provenance_status = rep("generated", 3L),
      note = c(
        "Original G59/G60 release metadata and inclusion status.",
        "One-pass mapping from original to fitted release-group numbers.",
        "Regenerated from the synchronized bet.ini and bet.tag files."
      ),
      stringsAsFactors = FALSE
    )
  )
  utils::write.csv(
    manifest,
    file.path(step_dir, "input_manifest.csv"),
    row.names = FALSE,
    na = ""
  )
}

message(
  "Built terminal-2022 tag sensitivities: ",
  paste(names(variants), collapse = ", ")
)
