#!/usr/bin/env Rscript
## Generate lightweight Step 11/12 sensitivity folders.
##
## Each folder contains only controls and documentation. At run time the
## current parent model is copied, then a deterministic patch is applied. This
## avoids committing roughly one hundred duplicate FRQ/INI/TAG datasets.

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
  c(
    sprintf("- OPR profile: `69-01-50-50`; terminal window: %d calendar year(s) = %d quarters.", row$terminal_years, 4L * row$terminal_years),
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
  if (row$fish_profile == "review_exact") {
    readme <- c(
      readme,
      "",
      "> The exact F20 and F17 controls are retained as a diagnostic. Those fisheries share selectivity groups with F27 and F18 in the current model; the `group_consistent` cases are the structurally preferred comparison."
    )
  }
  if (isTRUE(row$remove_2021_tags)) {
    readme <- c(
      readme,
      "",
      sprintf("> The deletion case removes `%s` and starts from a fresh `-makepar`. TAG, FRQ, all seven MFCL 1007 tag controls, the pooled reporting row, and `tag_rep_map.R` are patched together.", row$tag_deletion)
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
