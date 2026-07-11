#!/usr/bin/env Rscript
## Generate lightweight Step 11/12 sensitivity folders.
##
## Each folder contains only controls and documentation. At run time the
## current parent model is copied, then a deterministic patch is applied. This
## avoids committing duplicate FRQ/INI/TAG datasets.

args <- commandArgs(trailingOnly = TRUE)
overwrite <- "--overwrite" %in% args
unknown <- setdiff(args, "--overwrite")
if (length(unknown)) stop("Unknown argument(s): ", paste(unknown, collapse = ", "), call. = FALSE)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
source(file.path(root, "R", "step12_opr_terminal_penalty_lf_config.R"))
spec <- opr_terminal_penalty_lf_model_spec()

if (overwrite) {
  removed <- opr_terminal_penalty_lf_cleanup_generated_steps(file.path(root, "steps"))
  if (length(removed)) message("Removed ", length(removed), " previously generated sensitivity folder(s).")
}

write_file <- function(path, lines) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path, useBytes = TRUE)
}

model_controls <- function(row) {
  if (row$parameterization == "standard") {
    return(c(
      sprintf("- Recruitment: ordinary quarterly deviations; final fixed block = %d quarter(s).", row$standard_terminal_quarters),
      sprintf("- Arithmetic-mean terminal treatment: `%s`.", tolower(as.character(row$standard_arithmetic_mean)))
    ))
  }
  endpoint_text <- if (row$terminal_years == 0L) {
    "no multi-year annual endpoint"
  } else {
    sprintf("%d calendar year(s) = %d quarters", row$terminal_years, 4L * row$terminal_years)
  }
  c(
    sprintf(
      "- OPR profile: `%d-%02d-%02d-%02d`; terminal window: %s; component endpoint: `%d`.",
      row$opr_year_coefficients,
      row$opr_season_coefficients,
      row$opr_region_coefficients,
      row$opr_interaction_coefficients,
      endpoint_text,
      row$component_terminal_years
    ),
    sprintf("- Legacy annual OPR override: `parest_flag(221)=%d`.", row$opr_legacy_year_override),
    sprintf("- Terminal penalty: requested weight `%g`; `parest_flag(397)=%d`; final matched phase: 1,000 evaluations.", row$terminal_penalty_weight, row$terminal_penalty_flag),
    sprintf("- OPR trend flag: `parest_flag(153)=%d`.", row$trend_flag)
  )
}

tag_controls <- function(row) {
  c(
    sprintf("- Tag likelihood scalar flag: `parest_flag(177)=%d`.", row$tag_weight_flag),
    sprintf("- Tag observation model: `%s`; estimate pooled dispersion: `%s`.", row$tag_likelihood, tolower(as.character(row$estimate_tag_dispersion))),
    sprintf(
      "- Tag-release deletion: `%s`; 2021 reporting-rate scope: `%s`%s.",
      row$tag_deletion,
      row$rr_2021_scope,
      if (row$rr_2021_scope == "shared") "" else sprintf("; target %.5f; penalty %g", row$rr_2021_target, row$rr_2021_penalty)
    ),
    sprintf("- Mixing-period reporting treatment: `%s`; dominant 2021 mixing period override: `%s`.", row$tag_rr_mixing_mode, if (is.na(row$tag_2021_mixing_period)) "none" else paste0(row$tag_2021_mixing_period, " quarters")),
    sprintf("- Long-term tag loss: `%s`%s.", row$tag_loss_mode, if (row$tag_loss_mode == "none") "" else sprintf(" at %.3f per quarter", row$tag_loss_rate))
  )
}

for (i in seq_len(nrow(spec))) {
  row <- spec[i, , drop = FALSE]
  step_dir <- file.path(root, "steps", row$step_id)
  if (dir.exists(step_dir)) {
    if (!overwrite) stop("Target exists; rerun with --overwrite: ", step_dir, call. = FALSE)
    stop(
      "Refusing to overwrite an unrecognised 11p/12p folder: ", step_dir,
      ". Remove or rename it explicitly if it is intentionally replaceable.",
      call. = FALSE
    )
  }
  dir.create(step_dir, recursive = TRUE, showWarnings = FALSE)

  write_file(
    file.path(step_dir, opr_terminal_penalty_lf_generator_marker()),
    "opr-terminal-penalty-lf-generator-v1"
  )

  write_file(file.path(step_dir, "patch.R"), c(
    "## Generated thin patch: the parent model is staged before this file runs.",
    "source(file.path(root, \"R\", \"apply_opr_terminal_penalty_lf_patch.R\"), local = TRUE)",
    "apply_opr_terminal_penalty_lf_patch(model_dir, step_id, root = root)"
  ))
  write_file(file.path(step_dir, "config.env"), c(
    "# Standalone defaults; job-config.R supplies the same values under Kflow.",
    paste0("SOURCE_DIR=steps/", row$parent_step, "/model"),
    "RUN_MODE=doitall",
    paste0("EXPECTED_FINAL_PAR=", row$expected_final_par),
    "FRQ=bet.frq"
  ))

  readme <- c(
    paste0("# ", row$step_id),
    "",
    row$rationale,
    "",
    "## Controls",
    "",
    model_controls(row),
    sprintf("- Selectivity profile: `%s`.", row$fish_profile),
    sprintf(
      "- Length-composition effective-sample-size divisor: `%s`; weight-composition divisors are unchanged.",
      if (row$length_comp_divisor == 0L) "inherited mixed 20/40" else paste0("uniform ", row$length_comp_divisor)
    ),
    tag_controls(row),
    "",
    "## Interpretation",
    "",
    "This is a sensitivity, not an accepted assessment configuration. Compare quarterly recruitment (including the quarter immediately outside the terminal window), tag observed/predicted residuals by release/fishery/year/time-at-liberty, length fits for fisheries 12/17/20/26/28 and their shared groups, objective components, population scale, gradients, and Hessian eigen diagnostics.",
    "",
    "Raw objectives are not directly comparable when the tag dataset or tag likelihood family differs. A reduced spike is evidence about the source of model pressure; it is not by itself a reason to discard data or select a model.",
    "",
    "## Reproducibility",
    "",
    sprintf("The runner copies `steps/%s/model`, applies `patch.R`, creates a new `00.par` with MFCL, and stores the compact payload, input hashes/specification, and one exact patched restart-input set with the base fit. Diagnostic delta outputs do not duplicate that restart set; parent data are not committed in this thin folder.", row$parent_step)
  )
  if (row$fish_profile == "group_consistent") {
    readme <- c(
      readme,
      "",
      "> This is the source-consistent reviewed default: it includes all five requested fishery changes and propagates the F20/F17 settings to F27/F18 because MFCL requires other selectivity flags to be identical within fish-flag-24 groups."
    )
  }
  if (row$fish_profile == "review_exact") {
    readme <- c(
      readme,
      "",
      "> This applies only the exact five listed fishery edits. It intentionally leaves the grouped F27/F18 partners unchanged and is retained as a flag-grouping diagnostic, not as the source-consistent default."
    )
  }
  if (isTRUE(row$remove_2021_tags)) {
    readme <- c(
      readme,
      "",
      sprintf("> The deletion case removes `%s` and starts from a fresh `-makepar`. TAG, FRQ, all seven MFCL 1007 tag controls, the pooled reporting row, and `tag_rep_map.R` are patched together.", row$tag_deletion)
    )
  }
  if (isTRUE(row$benchmark_protocol)) {
    readme <- c(
      readme,
      "",
      "> This is the single supplied executable benchmark reproduction. It is retained for numerical comparison only and is excluded from the 71/72/73 candidate set."
    )
  }
  if (row$family == "supplied-opr221-check") {
    readme <- c(
      readme,
      "",
      "> This is one half of a matched flag-221 compatibility check. Public ongoing-dev marks flag 221 obsolete; compare the two rows directly before interpreting either as a biological sensitivity."
    )
  }
  if (isTRUE(row$final_candidate)) {
    readme <- c(
      readme,
      "",
      "> This is a shortlisted structural screen, not an accepted assessment model. It must retain stable estimates, gradients, and Hessian diagnostics when rerun at `1e-5`."
    )
  }
  write_file(file.path(step_dir, "README.md"), readme)

  manifest <- data.frame(
    role = c("parent_model", "runtime_patch", "model_specification"),
    file = c(
      file.path("steps", row$parent_step, "model"),
      "patch.R",
      file.path("R", "step12_opr_terminal_penalty_lf_config.R")
    ),
    source = c("current branch", "current branch", "current branch"),
    note = c(
      "Copied at runtime; no fitted parent PAR is reused.",
      "Applies documented controls after staging and before -makepar.",
      row$rationale
    ),
    stringsAsFactors = FALSE
  )
  write.csv(manifest, file.path(step_dir, "input_manifest.csv"), row.names = FALSE)
}

grid <- spec
grid$tag_likelihood_weight <- ifelse(grid$tag_weight_flag == 0L, 1, grid$tag_weight_flag / 1000)
write.csv(grid, file.path(root, "docs", "opr-terminal-penalty-lf-sensitivity-grid.csv"), row.names = FALSE)

message(
  "Prepared ", nrow(spec), " generated sensitivities plus ",
  length(opr_terminal_penalty_lf_control_step_ids()), " unchanged controls (",
  length(opr_terminal_penalty_lf_run_step_ids()), " fits; Hessian nsplit=",
  opr_terminal_penalty_lf_hessian_nsplit(), ")."
)
