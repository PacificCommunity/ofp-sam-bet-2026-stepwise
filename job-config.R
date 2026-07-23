# Public BET 2026 stepwise run matrix.
#
# Every row points at a self-contained steps/<step_id>/model/ directory. The
# scientific parent records comparison lineage only; it is not a run-time file
# dependency. Select one or more rows with the exact values in STEP_SELECT.

stepwise_run <- list(
  # Run all 23 independent models unless STEP_SELECT is supplied.
  default_step_select = "all",
  numbered_groups = 20L,
  model_rows = 23L,
  selected_path_models = 20L,

  # Short Kflow group label for one stepwise -> results -> report chain.
  flow_group = "bet-2026-stepwise-pathway",

  # TRUE runs downstream plot/report after stepwise succeeds.
  trigger_next = FALSE
)

model_row <- function(step_id,
                      major_step,
                      scientific_parent_id,
                      selected,
                      carry_status,
                      change_axis,
                      model_label,
                      job_title,
                      job_key,
                      control_notes = "",
                      region_count = 5L,
                      mfcl_program_path = "/home/mfcl/mfclo64",
                      fitted_job_id = "",
                      hessian_merge_job_id = "") {
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

# Sibling alternatives share the same scientific_parent_id. selected identifies
# the adopted BET 2026 route; carry_status says whether that row is inherited by
# a later row. All alternatives remain enabled and independently runnable.
stepwise_models <- do.call(
  rbind,
  list(
    model_row(
      "01-Diag2023", "01-Diagnostic", "external-2023-diagnostic-archive",
      TRUE, "carry", "rerun the 2023 diagnostic anchor",
      "2023 diagnostic rerun", "01 2023 diagnostic rerun", "01-diag2023",
      region_count = 9L,
      mfcl_program_path = "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0"
    ),
    model_row(
      "02-NewExe1003", "02-Compatibility", "01-Diag2023",
      TRUE, "carry", "run the current MFCL executable against the exact Step 01 scientific controls and 1003 ini",
      "Updated executable", "02 Current executable with ini 1003", "02-newexe1003",
      "Executable-only comparison: retain Step 01 F33-F41 CPUE flag-92 values 88/53/130/109/76/93/121/77/23 and global `2 94 1 2 128 10`; change only executable invocation/safety plus reporting-only compatibility.",
      region_count = 9L
    ),
    model_row(
      "03-Ini1007", "03-Compatibility", "02-NewExe1003",
      TRUE, "carry", "convert the ini layout from 1003 to 1007",
      "Updated INI format", "03 MFCL ini format 1007", "03-ini1007",
      region_count = 9L
    ),
    model_row(
      "04-FixM", "04-FixM", "03-Ini1007",
      TRUE, "carry", "fix natural mortality at -2.54930339768360 on the M scale",
      "Fixed natural mortality", "04 Fixed natural mortality", "04-fixm",
      region_count = 9L
    ),
    model_row(
      "05-LengthWeight", "05-LengthWeight", "04-FixM",
      TRUE, "carry", "apply BET 2026 bias-corrected length-weight parameters after fixing natural mortality",
      "Length-weight update", "05 Updated length-weight relationship", "05-lengthweight",
      region_count = 9L
    ),
    model_row(
      "06-NewStructure", "06-NewStructure", "05-LengthWeight",
      TRUE, "carry", "adopt the five-region and 33-fishery structure",
      "Five-region structure", "06 Five-region assessment structure", "06-newstructure"
    ),
    model_row(
      "07-ConvertToLength", "07-ConvertToLength", "06-NewStructure",
      TRUE, "carry", "convert the existing weight compositions to length",
      "Length conversion", "07 Convert weight to length compositions", "07-converttolength"
    ),
    model_row(
      "08-AddLengthData", "08-AddLengthData", "07-ConvertToLength",
      TRUE, "carry", "add the additional length-composition data",
      "Additional length data", "08 Add length-composition data", "08-addlengthdata"
    ),
    model_row(
      "09-TailCompression1Pct", "09-TailCompression", "08-AddLengthData",
      TRUE, "carry",
      "activate 1% length-frequency tail aggregation by changing parest flag 313 from 0 to 1",
      "1% tail compression", "09 Activate 1% LF tail compression", "09-tail-compression-1pct",
      "Change only global parest flag 313 from 0 to 1. Flag 311 remains 1 and weight-frequency flag 303 remains 0. The normal-likelihood path and comparison branches retain this setting through Step 20b; the selected DM Step 20c resets flag 313 to 0 because flag 320 controls DM support."
    ),
    model_row(
      "10-DataTo2024", "10-DataTo2024", "09-TailCompression1Pct",
      TRUE, "carry",
      "extend data through 2024 and remap the carried RRPTTP26 reporting-rate specification to the updated tag releases",
      "Data through 2024", "10 Data through 2024 and updated tag reporting rates", "10-datato2024-rrpttp26",
      "The RRPTTP26 specification introduced with the five-region structure is remapped to the updated tag releases and inherited by every descendant"
    ),
    model_row(
      "11-RegionalCPUE", "11-RegionalCPUE", "10-DataTo2024",
      TRUE, "carry",
      "add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty",
      "Regional CPUE", "11 Regional CPUE likelihood and weighting", "11-regional-cpue-regw100",
      "Authoritative regional CPUE source and REGW100 only; the source has two fewer F32 1952 quarterly records than Step 10 and is copied without transformation; no selectivity change."
    ),
    model_row(
      "12-TimeVaryingCV", "12-TimeVaryingCV", "11-RegionalCPUE",
      TRUE, "carry",
      "apply normalized time-varying CPUE relative-variance multipliers",
      "Time-varying CPUE uncertainty",
      "12 Time-varying CPUE uncertainty", "12-timevarying-cpue-uncertainty",
      "Apply the normalized F29-F33 relative-variance schedule while retaining the incoming CPUE observation-error scales. The fixed production scales are introduced separately in Step 13."
    ),
    model_row(
      "13-CPUEErrorCalibration", "13-CPUEErrorCalibration", "12-TimeVaryingCV",
      TRUE, "carry",
      "calibrate the five regional CPUE observation-error scales using stable preliminary maximum-likelihood fits",
      "CPUE observation-error calibration",
      "13 CPUE observation-error calibration", "13-cpue-observation-error-calibration",
      "Across multiple preliminary settings, the index-specific maximum-likelihood estimates changed little and converged near 0.354, 0.237, 0.212, 0.239, and 0.225. Apply the calibrated R1-R5 scales 0.35, 0.24, 0.21, 0.24, and 0.23 and carry them through every later step."
    ),
    model_row(
      "14-NewAgeData", "14-AgeData", "13-CPUEErrorCalibration",
      TRUE, "carry", "add the new age data using the common BASE075 weighting",
      "New age data", "14 New age data with common weighting", "14-new-age-data-base075"
    ),
    model_row(
      "15a-REG075", "15-AgeLengthWeighting", "14-NewAgeData",
      FALSE, "stop", "apply the REG075 composition-weighting alternative",
      "Regional age weighting", "15a Regional age-length weighting", "15a-reg075"
    ),
    model_row(
      "15b-SUB075", "15-AgeLengthWeighting", "14-NewAgeData",
      TRUE, "carry", "apply the selected SUB075 composition weighting",
      "Sub-basin age weighting", "15b Sub-basin age-length weighting", "15b-sub075"
    ),
    model_row(
      "16-SelectivityUpdate", "16-SelectivityUpdate", "15b-SUB075",
      TRUE, "carry",
      "configure fleet-specific selectivity for the revised fishery structure with dome/old-age-tail form penalties off for all 14 applicable fisheries",
      "Fleet-specific selectivity", "16 Fleet-specific selectivity configuration", "16-selectivity-update",
      "Apply the Job 14363 selectivity choice: unshare F15-F28, retain fleet-specific terminal ages and F25/F26 seven-node/youngest-tail settings, separate F29-F33 in staged run 5, and set fishery flag 16 from 2 to 0 for F12, F13, F15-F19, and F21-F27."
    ),
    model_row(
      "17-MIX015", "17-TagMixing", "16-SelectivityUpdate",
      TRUE, "carry",
      "apply release-group-specific MIX015 tag-mixing periods",
      "Release-group-specific tag mixing periods",
      "17 Release-group-specific tag-mixing periods", "17-mix015",
      "Replace tag_flags(:,1) with the release-group-specific MIX015 periods. Keep tag_flags(:,2)=0 so the reporting-rate exclusion effect is isolated separately in Step 18."
    ),
    model_row(
      "18-TagReportingExclusion", "18-TagReportingExclusion", "17-MIX015",
      TRUE, "carry",
      "exclude reporting-rate effects during each configured release-group mixing period",
      "Reporting-rate exclusion",
      "18 Reporting-rate exclusion during tag mixing", "18-tag-reporting-exclusion",
      "Keep the Step 17 release-group-specific periods and change only tag_flags(:,2) from 0 to 1. Reporting-rate values, groups, targets, and penalties remain unchanged."
    ),
    model_row(
      "19-EffortCreep", "19-EffortCreep", "18-TagReportingExclusion",
      TRUE, "carry", "apply the BET 2026 effort-creep series",
      "Effort creep", "19 Effort-creep adjustment", "19-effortcreep"
    ),
    model_row(
      "20a-DOMDiv200", "20-CompositionWeighting", "19-EffortCreep",
      FALSE, "stop", "apply the assessment-specific DOM divisor 200 to F21-F23",
      "DOM downweighting", "20a F21-F23 length-composition downweighting", "20a-dom-f21-f23-div200",
      "Alternative length-composition weighting branch from Step 19. Only F21-F23 receive flag-49 divisor 200; the selected Step 16 fleet-specific, form-penalties-off setting is retained."
    ),
    model_row(
      "20b-Francis", "20-CompositionWeighting", "19-EffortCreep",
      FALSE, "stop", "apply the independent Francis composition-data weighting comparison",
      "Francis reweighting", "20b Francis length-composition reweighting", "20b-francis",
      "Independent alternative length-composition weighting treatment branched directly from Step 19. Francis flag-49 divisors are applied for all 33 fisheries, including F21-F23 = 114/398/705; the 20a divisor-200 treatment is not inherited."
    ),
    model_row(
      "20c-DMG8Nmax25", "20-CompositionWeighting", "19-EffortCreep",
      TRUE, "final",
      "branch directly from Step 19 and use a Dirichlet-multinomial likelihood with G8 grouping and Nmax 25",
      "DM weighting", "20c Final DM weighting model (Job 14363 settings)", "20c-dm-length-composition-weighting",
      "Selected final weighting treatment. This branch does not inherit divisor 200 or Francis controls. It retains the Job 14363 fleet-specific selectivity setting with form penalties off, plus the selected tag settings. Flag 313 is reset to 0 because the DM likelihood does not read that percentage threshold and to avoid unrelated percentage-tail preprocessing; flag 320=5 controls DM support, matching the Job 14363 numeric controls.",
      fitted_job_id = "14363"
    )
  )
)

rownames(stepwise_models) <- NULL

# Concise, publication-facing rationale used by the model-development report.
# These statements summarise the documented assessment choices without exposing
# workflow-specific implementation details.
stepwise_report_purpose <- c(
  "01-Diag2023" = "Provide a reproducible 2023 assessment anchor for all subsequent comparisons.",
  "02-NewExe1003" = "Isolate the effect of the current MFCL executable while retaining the historical input format.",
  "03-Ini1007" = "Adopt the current input layout without changing the assessment data or biological assumptions.",
  "04-FixM" = "Carry the selected diagnostic estimate of natural mortality forward before updating other biological conversions.",
  "05-LengthWeight" = "Update biomass conversion using the BET 2026 bias-corrected length-weight relationship after fixing natural mortality.",
  "06-NewStructure" = "Represent spatial and fishery heterogeneity using the five-region, 33-fishery assessment structure.",
  "07-ConvertToLength" = "Place composition observations on the length scale used by the subsequent assessment configuration.",
  "08-AddLengthData" = "Incorporate the additional length-composition observations available for the 2026 assessment.",
  "09-TailCompression1Pct" = "Aggregate length-frequency tails below 1% only after all compositions are on the length scale.",
  "10-DataTo2024" = "Update the observation window through 2024 and apply the current reporting-rate information.",
  "11-RegionalCPUE" = "Introduce regional abundance information and its relative weighting without changing selectivity.",
  "12-TimeVaryingCV" = "Apply the normalized BET 2026 time-varying CPUE uncertainty schedule without simultaneously changing the index-specific observation-error scales.",
  "13-CPUEErrorCalibration" = "Use stable preliminary maximum-likelihood results to calibrate the R1-R5 CPUE observation-error scales to 0.35, 0.24, 0.21, 0.24, and 0.23; retain those calibrated values thereafter.",
  "14-NewAgeData" = "Add the new age data using a common initial weighting before evaluating spatial weighting treatments.",
  "15a-REG075" = "Evaluate region-level age-data weighting after the new age data are introduced.",
  "15b-SUB075" = "Evaluate and retain sub-basin age-data weighting for subsequent model development.",
  "16-SelectivityUpdate" = "Configure selectivity for the revised fishery structure and switch off flag-16 form penalties for all 14 applicable fisheries, avoiding unnecessary older-age shape constraints once selectivity is fleet-specific.",
  "17-MIX015" = "Apply release-group-specific tag-mixing periods while leaving the reporting-rate exclusion flag off, so the two tag assumptions remain separately testable.",
  "18-TagReportingExclusion" = "Exclude reporting-rate effects during each configured release-group mixing period without changing the reporting-rate values, groups, targets, or priors.",
  "19-EffortCreep" = "Account for gradual changes in fishing efficiency in the regional index fisheries.",
  "20a-DOMDiv200" = "Evaluate divisor-200 downweighting for lower-quality, previously unweighted DOM length compositions from F21-F23.",
  "20b-Francis" = "Evaluate fishery-specific Francis reweighting as an independent alternative from the Step 19 effort-creep model.",
  "20c-DMG8Nmax25" = "Estimate composition overdispersion with G8 grouping and Nmax 25; reset the DM-unused percentage threshold in flag 313 to 0, while flag 320 controls DM support."
)
stepwise_models$report_purpose <- unname(
  stepwise_report_purpose[stepwise_models$step_id]
)
stopifnot(
  !anyNA(stepwise_models$report_purpose),
  all(nzchar(stepwise_models$report_purpose))
)

# Explicit cumulative state used by the static validator and public manifests.
path_stage <- c(
  "01-Diag2023" = 1L, "02-NewExe1003" = 2L, "03-Ini1007" = 3L,
  "04-FixM" = 4L, "05-LengthWeight" = 5L, "06-NewStructure" = 6L,
  "07-ConvertToLength" = 7L, "08-AddLengthData" = 8L,
  "09-TailCompression1Pct" = 9L, "10-DataTo2024" = 10L,
  "11-RegionalCPUE" = 11L, "12-TimeVaryingCV" = 12L,
  "13-CPUEErrorCalibration" = 13L, "14-NewAgeData" = 14L,
  "15a-REG075" = 15L, "15b-SUB075" = 15L,
  "16-SelectivityUpdate" = 16L, "17-MIX015" = 17L,
  "18-TagReportingExclusion" = 18L, "19-EffortCreep" = 19L,
  "20a-DOMDiv200" = 20L, "20b-Francis" = 20L,
  "20c-DMG8Nmax25" = 20L
)
stepwise_models$path_stage <- unname(path_stage[stepwise_models$step_id])
stepwise_models$age_length_variant <- ""
stepwise_models$age_length_variant[stepwise_models$step_id == "14-NewAgeData"] <- "BASE075"
stepwise_models$age_length_variant[stepwise_models$step_id == "15a-REG075"] <- "REG075"
stepwise_models$age_length_variant[
  stepwise_models$step_id == "15b-SUB075" | stepwise_models$path_stage >= 16L
] <- "SUB075"
stepwise_models$tag_flag2 <- NA_integer_
stepwise_models$tag_flag2[stepwise_models$path_stage >= 3L] <- 0L
stepwise_models$tag_flag2[stepwise_models$path_stage >= 18L] <- 1L
stepwise_models$dm_grouping <- ""
stepwise_models$dm_grouping[stepwise_models$step_id == "20c-DMG8Nmax25"] <- "G8PSSET"
stepwise_models$dm_nmax <- NA_integer_
stepwise_models$dm_nmax[stepwise_models$step_id == "20c-DMG8Nmax25"] <- 25L
stepwise_models$regional_scaling_weight <- NA_integer_
stepwise_models$regional_scaling_weight[stepwise_models$path_stage >= 11L] <- 100L
stepwise_models$reporting_rate_prior <- ifelse(
  stepwise_models$path_stage >= 10L,
  "RRPTTP26 (98 release groups)",
  ifelse(
    stepwise_models$path_stage >= 6L,
    "RRPTTP26 (96 release groups)",
    ""
  )
)
stepwise_models$fixed_natural_mortality <- stepwise_models$path_stage >= 4L
stepwise_models$length_weight_updated <- stepwise_models$path_stage >= 5L
stepwise_models$tail_compression_percent <- ifelse(
  stepwise_models$path_stage >= 9L &
    stepwise_models$step_id != "20c-DMG8Nmax25", 1, 0
)
stepwise_models$fixed_cpue_sigma <- stepwise_models$path_stage >= 13L
stepwise_models$selectivity_update <- stepwise_models$path_stage >= 16L
stepwise_models$all_selectivity_forms_relaxed <- stepwise_models$path_stage >= 16L
rownames(stepwise_models) <- NULL
stepwise_run$numbered_groups <- 20L
stepwise_run$model_rows <- nrow(stepwise_models)
stepwise_run$selected_path_models <- sum(stepwise_models$selected & stepwise_models$enabled)
