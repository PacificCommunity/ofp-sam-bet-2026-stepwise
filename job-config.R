# Public BET 2026 stepwise run matrix.
#
# Every row points at a self-contained steps/<step_id>/model/ directory. The
# scientific parent records comparison lineage only; it is not a run-time file
# dependency. Select one or more rows with the exact values in STEP_SELECT.

stepwise_run <- list(
  # Run all 22 independent models unless STEP_SELECT is supplied.
  default_step_select = "all",
  numbered_groups = 17L,
  model_rows = 22L,
  selected_path_models = 19L,

  # Short Kflow group label for one stepwise -> results -> report chain.
  flow_group = "bet-2026-stepwise-2307",

  # TRUE runs downstream plot/report after stepwise succeeds.
  trigger_next = TRUE
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
      "02a-NewExe1003", "02-Executable", "01-Diag2023",
      TRUE, "carry", "current MFCL executable with the 1003 ini",
      "Current executable with ini 1003", "02a Current executable with ini 1003", "02a-newexe1003",
      region_count = 9L
    ),
    model_row(
      "02b-Ini1007", "02-Executable", "02a-NewExe1003",
      TRUE, "carry", "convert the ini layout from 1003 to 1007",
      "MFCL ini format 1007", "02b MFCL ini format 1007", "02b-ini1007",
      region_count = 9L
    ),
    model_row(
      "02c-LengthWeight", "02-Executable", "02b-Ini1007",
      TRUE, "carry", "apply BET 2026 bias-corrected length-weight parameters",
      "Updated length-weight relationship", "02c Updated length-weight relationship", "02c-lengthweight",
      region_count = 9L
    ),
    model_row(
      "03-FixM", "03-FixM", "02c-LengthWeight",
      TRUE, "carry", "fix natural mortality at -2.54930339768360 on the M scale",
      "Fixed natural mortality", "03 Fixed natural mortality", "03-fixm",
      region_count = 9L
    ),
    model_row(
      "04-NewStructure", "04-NewStructure", "03-FixM",
      TRUE, "carry", "adopt the five-region and 33-fishery structure",
      "Five-region assessment structure", "04 Five-region assessment structure", "04-newstructure"
    ),
    model_row(
      "05-ConvertToLength", "05-ConvertToLength", "04-NewStructure",
      TRUE, "carry", "convert the existing weight compositions to length",
      "Length-composition conversion", "05 Convert weight to length compositions", "05-converttolength"
    ),
    model_row(
      "06-AddLengthData", "06-AddLengthData", "05-ConvertToLength",
      TRUE, "carry", "add the additional length-composition data",
      "Additional length-composition data", "06 Add length-composition data", "06-addlengthdata"
    ),
    model_row(
      "07-DataTo2024", "07-DataTo2024", "06-AddLengthData",
      TRUE, "carry",
      "extend data through 2024 and integrate the latest RRPTTP26 reporting-rate penalties",
      "Data through 2024 and updated tag reporting rates", "07 Data through 2024 and updated tag reporting rates", "07-datato2024-rrpttp26",
      "Latest RRPTTP26 penalties are embedded here and inherited by every descendant"
    ),
    model_row(
      "08-RegionalCPUE", "08-RegionalCPUE", "07-DataTo2024",
      TRUE, "carry",
      "add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty",
      "Regional CPUE likelihood and weighting", "08 Regional CPUE likelihood and weighting", "08-regional-cpue-regw100",
      "Regional CPUE data/likelihood and REGW100 only; no selectivity change"
    ),
    model_row(
      "09a-BASE075", "09-CompositionWeighting", "08-RegionalCPUE",
      FALSE, "stop", "apply the BASE075 composition-weighting alternative",
      "Baseline age-length weighting", "09a Baseline age-length weighting", "09a-base075"
    ),
    model_row(
      "09b-REG075", "09-CompositionWeighting", "08-RegionalCPUE",
      FALSE, "stop", "apply the REG075 composition-weighting alternative",
      "Regional age-length weighting", "09b Regional age-length weighting", "09b-reg075"
    ),
    model_row(
      "09c-SUB075", "09-CompositionWeighting", "08-RegionalCPUE",
      TRUE, "carry", "apply the selected SUB075 composition weighting",
      "Sub-basin age-length weighting", "09c Sub-basin age-length weighting", "09c-sub075"
    ),
    model_row(
      "10-MIX015", "10-TagMixing", "09c-SUB075",
      TRUE, "carry", "apply the MIX015 tag-mixing setting",
      "Tag-mixing periods", "10 Tag-mixing periods", "10-mix015"
    ),
    model_row(
      "11-TAGF2ON", "11-TagFlags", "10-MIX015",
      TRUE, "carry",
      "set tag-flag column 2 to 1 so reporting-rate effects are excluded for each release group throughout its configured mixing periods",
      "Reporting-rate mixing-period treatment", "11 Reporting-rate mixing-period treatment", "11-tagf2on-col2"
    ),
    model_row(
      "12-TimeVaryingCV", "12-TimeVaryingCV", "11-TAGF2ON",
      TRUE, "carry", "apply normalized time-varying CPUE relative-variance multipliers from the frequency data",
      "Time-varying CPUE uncertainty", "12 Time-varying CPUE uncertainty", "12-timevaryingcv"
    ),
    model_row(
      "13-EffortCreep", "13-EffortCreep", "12-TimeVaryingCV",
      TRUE, "carry", "apply the BET 2026 effort-creep series",
      "Effort-creep adjustment", "13 Effort-creep adjustment", "13-effortcreep"
    ),
    model_row(
      "14-CPUESigma", "14-CPUESigma", "13-EffortCreep",
      TRUE, "carry",
      "fix index-specific CPUE observation-error scales calibrated from preliminary MLE fits",
      "Fixed CPUE observation-error calibration", "14 Fixed CPUE observation-error calibration", "14-fixed-cpue-observation-error",
      "Preliminary fits across alternative configurations produced similar index-specific MLE sigma estimates. Carry fish flag 92 values for R1-R5 of 35, 24, 21, 24, and 23, corresponding to executed error scales 0.35, 0.24, 0.21, 0.24, and 0.23, so later comparisons retain consistent CPUE weighting."
    ),
    model_row(
      "15-SelectivityUpdate", "15-SelectivityUpdate", "14-CPUESigma",
      TRUE, "carry",
      "address persistent structured F25/F26 length-frequency misfit with independent seven-node cubic-spline selectivities and separate F29-F33 regional-index selectivities",
      "Fleet-specific selectivity update", "15 Fleet-specific selectivity update", "15-selectivity-update",
      "F25/F26 are spatially distinct associated purse-seine fisheries: retain their common associated-purse-seine G8 DM group but use independent smooth 7-node splines for different size availability. F29-F33 are regional index fisheries: separate selectivities to avoid masking regional size-availability differences while retaining their common index-oriented DM group. Grouping and node choices are assessment-specific and evaluated stepwise, not literature-mandated."
    ),
    model_row(
      "16-DOMDiv200", "16-DOM", "15-SelectivityUpdate",
      TRUE, "carry", "apply the assessment-specific DOM divisor 200 to F21-F23",
      "F21-F23 length-composition downweighting", "16 F21-F23 length-composition downweighting", "16-dom-f21-f23-div200"
    ),
    model_row(
      "17a-Francis", "17-CompositionLikelihood", "16-DOMDiv200",
      FALSE, "stop", "apply the Francis composition-data weighting comparison",
      "Francis length-composition weighting", "17a Francis length-composition weighting", "17a-francis"
    ),
    model_row(
      "17b-DMG8Nmax25", "17-CompositionLikelihood", "16-DOMDiv200",
      TRUE, "final",
      "use a Dirichlet-multinomial length-composition likelihood with G8 PSSET grouping and Nmax 25",
      "DM length-composition likelihood", "17b DM length-composition likelihood", "17b-dm-length-composition-likelihood",
      "Nmax=25 is the upper asymptote of the DM effective-sample-size transformation. Its scale was calibrated against the fishery-level Francis ESS diagnostics underlying the sibling Step 17a comparison, but MFCL estimates the DM parameter internally and approaches Nmax smoothly rather than clipping Francis ESS values. Steps 17a and 17b share Step 16 as their computational parent and are not sequential fits. G8 PSSET grouping and Nmax are assessment-specific stepwise choices.",
      fitted_job_id = "13328", hessian_merge_job_id = "13432"
    )
  )
)

rownames(stepwise_models) <- NULL

# Concise, publication-facing rationale used by the model-development report.
# These statements summarise the documented assessment choices without exposing
# workflow-specific implementation details.
stepwise_report_purpose <- c(
  "01-Diag2023" = "Provide a reproducible 2023 assessment anchor for all subsequent comparisons.",
  "02a-NewExe1003" = "Isolate the effect of the current MFCL executable while retaining the historical input format.",
  "02b-Ini1007" = "Adopt the current input layout without changing the assessment data or biological assumptions.",
  "02c-LengthWeight" = "Update biomass conversion using the BET 2026 bias-corrected length-weight relationship.",
  "03-FixM" = "Carry the selected diagnostic estimate of natural mortality forward without confounding later structural changes.",
  "04-NewStructure" = "Represent spatial and fishery heterogeneity using the five-region, 33-fishery assessment structure.",
  "05-ConvertToLength" = "Place composition observations on the length scale used by the subsequent assessment configuration.",
  "06-AddLengthData" = "Incorporate the additional length-composition observations available for the 2026 assessment.",
  "07-DataTo2024" = "Update the observation window through 2024 and apply the current reporting-rate information.",
  "08-RegionalCPUE" = "Introduce regional abundance information and its relative weighting without changing selectivity.",
  "09a-BASE075" = "Evaluate baseline age-length composition weighting as a sibling alternative.",
  "09b-REG075" = "Evaluate region-level age-length composition weighting as a sibling alternative.",
  "09c-SUB075" = "Evaluate and retain sub-basin age-length weighting for subsequent model development.",
  "10-MIX015" = "Apply the selected release-specific tag-mixing assumptions.",
  "11-TAGF2ON" = "Exclude reporting-rate effects during each release group's configured mixing period.",
  "12-TimeVaryingCV" = "Allow CPUE precision to vary through time using the normalized BET 2026 uncertainty schedule.",
  "13-EffortCreep" = "Account for gradual changes in fishing efficiency in the regional index fisheries.",
  "14-CPUESigma" = "Keep CPUE weighting consistent across later comparisons using common observation-error scales calibrated from preliminary maximum-likelihood fits.",
  "15-SelectivityUpdate" = "Represent persistent fishery-specific size-availability differences without forcing F25/F26 or regional indices to share selectivity.",
  "16-DOMDiv200" = "Limit the influence of lower-quality, previously unweighted DOM length compositions from F21-F23.",
  "17a-Francis" = "Evaluate fishery-specific Francis weighting as an alternative treatment of composition information.",
  "17b-DMG8Nmax25" = "Estimate composition overdispersion within the model while limiting excessive length-frequency influence on the integrated fit."
)
stepwise_models$report_purpose <- unname(
  stepwise_report_purpose[stepwise_models$step_id]
)
stopifnot(
  !anyNA(stepwise_models$report_purpose),
  all(nzchar(stepwise_models$report_purpose))
)

# Explicit cumulative state used by the static validator and public manifests.
step_number <- suppressWarnings(as.integer(sub("[^0-9].*$", "", stepwise_models$step_id)))
stepwise_models$age_length_variant <- ""
stepwise_models$age_length_variant[stepwise_models$step_id == "09a-BASE075"] <- "BASE075"
stepwise_models$age_length_variant[stepwise_models$step_id == "09b-REG075"] <- "REG075"
stepwise_models$age_length_variant[
  stepwise_models$step_id == "09c-SUB075" | step_number >= 10L
] <- "SUB075"
stepwise_models$tag_flag2 <- NA_integer_
stepwise_models$tag_flag2[step_number >= 2L & stepwise_models$step_id != "02a-NewExe1003"] <- 0L
stepwise_models$tag_flag2[step_number >= 11L] <- 1L
stepwise_models$dm_grouping <- ""
stepwise_models$dm_grouping[stepwise_models$step_id == "17b-DMG8Nmax25"] <- "G8PSSET"
stepwise_models$dm_nmax <- NA_integer_
stepwise_models$dm_nmax[stepwise_models$step_id == "17b-DMG8Nmax25"] <- 25L
stepwise_models$regional_scaling_weight <- NA_integer_
stepwise_models$regional_scaling_weight[step_number >= 8L] <- 100L
stepwise_models$reporting_rate_prior <- ifelse(step_number >= 7L, "RRPTTP26", "")
