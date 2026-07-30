# Public BET 2026 stepwise run matrix.
#
# Every row points to a self-contained steps/<step_id>/model directory. The
# scientific parent records comparison lineage only; model jobs never borrow
# runtime inputs from another row.

stepwise_run <- list(
  default_step_select = "all",
  numbered_groups = 19L,
  model_rows = 20L,
  selected_path_models = 19L,
  flow_group = "bet-2026-final-stepwise",
  trigger_next = FALSE
)

model_row <- function(step_id, major_step, scientific_parent_id, selected,
                      carry_status, change_axis, model_label, job_title,
                      job_key, control_notes = "", region_count = 5L,
                      mfcl_program_path = "/home/mfcl/mfclo64",
                      fitted_job_id = "", hessian_merge_job_id = "") {
  data.frame(
    step_id = step_id,
    STEP_SELECT = step_id,
    enabled = TRUE,
    major_step = major_step,
    substep = sub("-.*$", "", step_id),
    scientific_parent_id = scientific_parent_id,
    selected = selected,
    selection_status = if (selected) "selected" else "alternative",
    carry_status = carry_status,
    change_axis = change_axis,
    control_notes = control_notes,
    model_label = model_label,
    job_title = job_title,
    job_key = job_key,
    run_mode = "doitall",
    region_count = as.integer(region_count),
    kflow_cpus = 2L,
    kflow_memory = if (region_count == 9L) "12GB" else "8GB",
    kflow_disk = "8GB",
    mfcl_program_path = mfcl_program_path,
    input_par = "",
    frq = "bet.frq",
    output_par = "",
    expected_output = "auto-detected final MFCL .par plus model_payload.rds",
    output_artifact = paste0(job_key, ":auto-final-par+model-payload"),
    fitted_job_id = fitted_job_id,
    hessian_merge_job_id = hessian_merge_job_id,
    stringsAsFactors = FALSE
  )
}

stepwise_models <- do.call(rbind, list(
  model_row(
    "01-Diag2023", "01-Diagnostic", "external-2023-diagnostic-archive",
    TRUE, "carry", "refit the 2023 diagnostic model",
    "2023 diagnostic-model refit", "01 2023 diagnostic-model refit",
    "01-diag2023", region_count = 9L,
    mfcl_program_path = "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0"
  ),
  model_row(
    "02-NewExeIni1007", "02-ExecutableIni", "01-Diag2023",
    TRUE, "carry", "update MFCL executable and INI format together",
    "New executable and INI 1007", "02 New executable and INI 1007",
    "02-new-exe-ini1007",
    paste(
      "Use the 2.2.7.9-based tuna-flow v2.5 executable and INI 1007.",
      "Convert F33-F41 flag-92 penalty values to CV values",
      "24/31/20/21/26/23/20/25/47 and change global age_flags(128)",
      "from 10 to 100 so the intended multiplier remains 1.0."
    ),
    region_count = 9L
  ),
  model_row(
    "03-FixM", "03-FixM", "02-NewExeIni1007",
    TRUE, "carry", "fix Lorenzen natural-mortality scaling",
    "Natural mortality fixed", "03 Fix natural mortality",
    "03-fix-m", region_count = 9L
  ),
  model_row(
    "04-LengthWeight", "04-LengthWeight", "03-FixM",
    TRUE, "carry", "update bias-corrected BET length-weight parameters",
    "Length-weight update", "04 BET 2026 length-weight update",
    "04-length-weight", region_count = 9L
  ),
  model_row(
    "05-NewStructure", "05-NewStructure", "04-LengthWeight",
    TRUE, "carry", "adopt the five-region, 33-fishery structure",
    "Five-region structure", "05 Five-region, 33-fishery structure",
    "05-new-structure"
  ),
  model_row(
    "06-ConvertToLength", "06-ConvertToLength", "05-NewStructure",
    TRUE, "carry", "replace weight compositions with reweighted weight-as-length data through 2021",
    "Weight-as-length compositions", "06 Convert weight data to length",
    "06-convert-to-length"
  ),
  model_row(
    "07-AddLengthData", "07-AddLengthData", "06-ConvertToLength",
    TRUE, "carry", "add observed length compositions where coverage exceeds weight samples",
    "Observed-length supplementation", "07 Add observed length data",
    "07-add-length-data"
  ),
  model_row(
    "08-DataTo2024", "08-DataTo2024", "07-AddLengthData",
    TRUE, "carry", "extend data through 2024 except CAAL",
    "Data through 2024", "08 Update data through 2024",
    "08-data-to-2024"
  ),
  model_row(
    "09-SizeDataQC", "09-SizeDataQC", "08-DataTo2024",
    TRUE, "carry", "apply PH/ID and domestic mixed-gear size-data rules",
    "PH/ID and domestic size-data rules", "09 PH/ID and domestic size-data rules",
    "09-size-data-qc",
    paste(
      "Set F15 length bins below 70 cm to zero without renormalisation;",
      "remove F21-F23 intervals with midpoint above 90 cm;",
      "set the youngest five selectivity ages to zero for both F14 and F15."
    )
  ),
  model_row(
    "10-RegionalCPUE", "10-RegionalCPUE", "09-SizeDataQC",
    TRUE, "carry", "use separate regional CPUE indices and regional scaling",
    "Regional CPUE and scaling", "10 Regional CPUE and scaling",
    "10-regional-cpue"
  ),
  model_row(
    "11-TimeVaryingCV", "11-TimeVaryingCV", "10-RegionalCPUE",
    TRUE, "carry", "apply time-varying CPUE uncertainty",
    "Time-varying CPUE uncertainty", "11 Time-varying CPUE uncertainty",
    "11-time-varying-cv"
  ),
  model_row(
    "12-CPUEErrorCalibration", "12-CPUEErrorCalibration", "11-TimeVaryingCV",
    TRUE, "carry", "fix regional CPUE log-scale observation-error SDs",
    "Fixed regional CPUE SDs", "12 Fix regional CPUE SDs",
    "12-cpue-error-sd",
    "Fix R1-R5 flag-92 values at 35/24/21/24/23, representing SDs 0.35/0.24/0.21/0.24/0.23."
  ),
  model_row(
    "13-NewAgeData", "13-AgeData", "12-CPUEErrorCalibration",
    TRUE, "carry", "add new CAAL data with weight 0.75",
    "New CAAL data", "13 New CAAL data, weight 0.75",
    "13-new-age-data"
  ),
  model_row(
    "14a-REG075", "14-AgeWeighting", "13-NewAgeData",
    FALSE, "stop", "apply regional CAAL reweighting",
    "Regional CAAL reweighting", "14a Regional CAAL reweighting",
    "14a-reg075"
  ),
  model_row(
    "14b-SUB075", "14-AgeWeighting", "13-NewAgeData",
    TRUE, "carry", "apply selected regions 3-and-4 combined CAAL reweighting",
    "Sub-basin CAAL reweighting", "14b Sub-basin CAAL reweighting",
    "14b-sub075"
  ),
  model_row(
    "15-SelectivityUpdate", "15-SelectivityUpdate", "14b-SUB075",
    TRUE, "carry", "revise fishery-specific selectivity",
    "Parsimonious fishery selectivity", "15 Parsimonious fishery-specific selectivity",
    "15-selectivity-update"
  ),
  model_row(
    "16-MIX020", "16-TagMixing", "15-SelectivityUpdate",
    TRUE, "carry", "apply release-group-specific K=0.20 mixing periods",
    "K=0.20 tag mixing periods", "16 K=0.20 release-group tag mixing",
    "16-mix020",
    "Copy only tag_flags(:,1) from SC22-IP10-regionMean@efe3107; retain all reporting-rate matrices."
  ),
  model_row(
    "17-TagReportingExclusion", "17-TagReportingExclusion", "16-MIX020",
    TRUE, "carry", "exclude reporting rates during pre-mixing windows",
    "Pre-mixing reporting-rate exclusion", "17 Pre-mixing reporting-rate exclusion",
    "17-tag-reporting-exclusion"
  ),
  model_row(
    "18-EffortCreep", "18-EffortCreep", "17-TagReportingExclusion",
    TRUE, "carry", "apply effort-creep adjustment to CPUE indices",
    "Effort-creep adjustment", "18 Effort-creep adjustment",
    "18-effort-creep"
  ),
  model_row(
    "19-DMG8Nmax25", "19-CompositionWeighting", "18-EffortCreep",
    TRUE, "final", "apply Dirichlet-multinomial composition weighting",
    "DM composition weighting", "19 DM composition weighting, G8 Nmax 25",
    "19-dm-g8-nmax25",
    paste(
      "Use Job 18518/18717 DM-noRE controls: G8, Nmax=25, fish_pars(22)",
      "fixed at 7 and eight grouped fish_pars(23) exponents estimated.",
      "Retain the original 2023 negative-binomial tag likelihood;",
      "tag tau is not estimated (parest 111=4; fish flags 43/44 inactive)."
    )
  )
))
rownames(stepwise_models) <- NULL

stepwise_report_change <- c(
  "01-Diag2023" = "2023 diagnostic-model refit",
  "02-NewExeIni1007" = "New MFCL executable (2.2.7.9-based) and INI 1007",
  "03-FixM" = "Lorenzen natural-mortality scaling fixed to the 2023 diagnostic estimate",
  "04-LengthWeight" = "BET 2026 bias-corrected length-weight parameters",
  "05-NewStructure" = "Five-region, 33-fishery structure",
  "06-ConvertToLength" = "Reweighted weight data converted to length frequencies through 2021",
  "07-AddLengthData" = "Weight-as-length plus observed-length compositions",
  "08-DataTo2024" = "Data updated through 2024 except CAAL",
  "09-SizeDataQC" = "PH/ID and domestic mixed-gear size-data rules",
  "10-RegionalCPUE" = "Regional CPUE indices and regional scaling",
  "11-TimeVaryingCV" = "Time-varying CPUE uncertainty",
  "12-CPUEErrorCalibration" = "Regional CPUE SDs fixed at 0.35, 0.24, 0.21, 0.24 and 0.23",
  "13-NewAgeData" = "New CAAL data with weight 0.75",
  "14a-REG075" = "Regional CAAL reweighting",
  "14b-SUB075" = "Sub-basin CAAL reweighting with regions 3 and 4 combined",
  "15-SelectivityUpdate" = "Parsimonious fishery-specific selectivity",
  "16-MIX020" = "Release-group-specific K=0.20 tag-mixing periods",
  "17-TagReportingExclusion" = "Pre-mixing reporting-rate exclusion",
  "18-EffortCreep" = "Effort-creep adjustment",
  "19-DMG8Nmax25" = "Dirichlet-multinomial composition weighting"
)

stepwise_report_purpose <- c(
  "01-Diag2023" = "Provide a reproducible reference for subsequent comparisons.",
  "02-NewExeIni1007" = "Isolate the combined executable and required INI-format update.",
  "03-FixM" = "Improve model stability as recommended at the PAW.",
  "04-LengthWeight" = "Update biomass conversion for the 2026 assessment.",
  "05-NewStructure" = "Represent the revised spatial and fishery definitions.",
  "06-ConvertToLength" = "Evaluate conversion of reweighted weight data to length.",
  "07-AddLengthData" = "Use observed lengths where their catch coverage exceeded weight samples.",
  "08-DataTo2024" = "Extend the temporal coverage of the assessment.",
  "09-SizeDataQC" = "Apply the agreed PH/ID and domestic mixed-gear size-data treatment.",
  "10-RegionalCPUE" = "Allow region-specific indices while penalising inconsistent regional abundance scaling.",
  "11-TimeVaryingCV" = "Account for temporal variation in CPUE precision.",
  "12-CPUEErrorCalibration" = "Retain the five maximum-likelihood CPUE observation-error SDs.",
  "13-NewAgeData" = "Use the 2023 BET age-data weighting as the reference treatment.",
  "14a-REG075" = "Test region-level spatial CAAL weighting.",
  "14b-SUB075" = "Apply the selected sub-basin CAAL weighting.",
  "15-SelectivityUpdate" = "Apply the Job 18717 parsimonious selectivity controls, with F14/F15 youngest-five-age constraints.",
  "16-MIX020" = "Assign Joe's region-mean release-group mixing periods at K=0.20.",
  "17-TagReportingExclusion" = "Avoid applying reporting rates in pre-mixing windows.",
  "18-EffortCreep" = "Account for gradual changes in fishing efficiency.",
  "19-DMG8Nmax25" = "Use Job 18717 DM-noRE G8/Nmax25 weighting with concentration intercepts fixed at 7."
)

stepwise_models$report_change <- unname(stepwise_report_change[stepwise_models$step_id])
stepwise_models$report_purpose <- unname(stepwise_report_purpose[stepwise_models$step_id])
stopifnot(!anyNA(stepwise_models$report_change), !anyNA(stepwise_models$report_purpose))

path_stage <- c(
  "01-Diag2023" = 1L, "02-NewExeIni1007" = 2L, "03-FixM" = 3L,
  "04-LengthWeight" = 4L, "05-NewStructure" = 5L,
  "06-ConvertToLength" = 6L, "07-AddLengthData" = 7L,
  "08-DataTo2024" = 8L, "09-SizeDataQC" = 9L,
  "10-RegionalCPUE" = 10L, "11-TimeVaryingCV" = 11L,
  "12-CPUEErrorCalibration" = 12L, "13-NewAgeData" = 13L,
  "14a-REG075" = 14L, "14b-SUB075" = 14L,
  "15-SelectivityUpdate" = 15L, "16-MIX020" = 16L,
  "17-TagReportingExclusion" = 17L, "18-EffortCreep" = 18L,
  "19-DMG8Nmax25" = 19L
)
stepwise_models$path_stage <- unname(path_stage[stepwise_models$step_id])
stepwise_models$age_length_variant <- ""
stepwise_models$age_length_variant[stepwise_models$step_id == "13-NewAgeData"] <- "BASE075"
stepwise_models$age_length_variant[stepwise_models$step_id == "14a-REG075"] <- "REG075"
stepwise_models$age_length_variant[
  stepwise_models$step_id == "14b-SUB075" | stepwise_models$path_stage >= 15L
] <- "SUB075"
stepwise_models$tag_flag2 <- NA_integer_
stepwise_models$tag_flag2[stepwise_models$path_stage >= 2L] <- 0L
stepwise_models$tag_flag2[stepwise_models$path_stage >= 17L] <- 1L
stepwise_models$dm_grouping <- ""
stepwise_models$dm_grouping[stepwise_models$step_id == "19-DMG8Nmax25"] <- "G8PSSET"
stepwise_models$dm_nmax <- NA_integer_
stepwise_models$dm_nmax[stepwise_models$step_id == "19-DMG8Nmax25"] <- 25L
stepwise_models$regional_scaling_weight <- NA_integer_
stepwise_models$regional_scaling_weight[stepwise_models$path_stage >= 10L] <- 100L
stepwise_models$reporting_rate_prior <- ifelse(
  stepwise_models$path_stage >= 8L, "RRPTTP26 (98 release groups)",
  ifelse(stepwise_models$path_stage >= 5L, "RRPTTP26 (96 release groups)", "")
)
stepwise_models$fixed_natural_mortality <- stepwise_models$path_stage >= 3L
stepwise_models$length_weight_updated <- stepwise_models$path_stage >= 4L
stepwise_models$tail_compression_percent <- 0
stepwise_models$fixed_cpue_sigma <- stepwise_models$path_stage >= 12L
stepwise_models$selectivity_update <- stepwise_models$path_stage >= 15L
stepwise_models$all_selectivity_forms_relaxed <- stepwise_models$path_stage >= 15L
stepwise_models$size_data_qc <- stepwise_models$path_stage >= 9L
rownames(stepwise_models) <- NULL

stepwise_run$model_rows <- nrow(stepwise_models)
stepwise_run$selected_path_models <- sum(stepwise_models$selected & stepwise_models$enabled)
