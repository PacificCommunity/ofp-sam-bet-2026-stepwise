# Public BET 2026 stepwise run matrix.
#
# Every row points at a self-contained steps/<step_id>/model/ directory. The
# scientific parent records comparison lineage only; it is not a run-time file
# dependency. Select one or more rows with the exact values in STEP_SELECT.

stepwise_run <- list(
  # Run all 29 independent models unless STEP_SELECT is supplied.
  default_step_select = "all",
  numbered_groups = 19L,
  model_rows = 29L,
  selected_path_models = 18L,

  # Short Kflow group label for one stepwise -> results -> report chain.
  flow_group = "bet-2026-stepwise-2307-corrected",

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
      "Diagnostic rerun", "01 2023 diagnostic rerun", "01-diag2023",
      region_count = 9L,
      mfcl_program_path = "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0"
    ),
    model_row(
      "02a-NewExe1003", "02-Executable", "01-Diag2023",
      TRUE, "carry", "run the current MFCL executable against the exact Step 01 scientific controls and 1003 ini",
      "Updated executable", "02a Current executable with ini 1003", "02a-newexe1003",
      "Executable-only comparison: retain Step 01 F33-F41 CPUE flag-92 values 88/53/130/109/76/93/121/77/23 and global `2 94 1 2 128 10`; change only executable invocation/safety plus reporting-only compatibility.",
      region_count = 9L
    ),
    model_row(
      "02b-Ini1007", "02-Executable", "02a-NewExe1003",
      TRUE, "carry", "convert the ini layout from 1003 to 1007",
      "Updated INI format", "02b MFCL ini format 1007", "02b-ini1007",
      region_count = 9L
    ),
    model_row(
      "02c-LengthWeight", "02-Executable", "02b-Ini1007",
      TRUE, "carry", "apply BET 2026 bias-corrected length-weight parameters",
      "Length-weight update", "02c Updated length-weight relationship", "02c-lengthweight",
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
      "Five-region structure", "04 Five-region assessment structure", "04-newstructure"
    ),
    model_row(
      "05-ConvertToLength", "05-ConvertToLength", "04-NewStructure",
      TRUE, "carry", "convert the existing weight compositions to length",
      "Length conversion", "05 Convert weight to length compositions", "05-converttolength"
    ),
    model_row(
      "06-AddLengthData", "06-AddLengthData", "05-ConvertToLength",
      TRUE, "carry", "add the additional length-composition data",
      "Additional length data", "06 Add length-composition data", "06-addlengthdata"
    ),
    model_row(
      "07-DataTo2024", "07-DataTo2024", "06-AddLengthData",
      TRUE, "carry",
      "extend data through 2024 and integrate the latest RRPTTP26 reporting-rate penalties",
      "Data through 2024", "07 Data through 2024 and updated tag reporting rates", "07-datato2024-rrpttp26",
      "Latest RRPTTP26 penalties are embedded here and inherited by every descendant"
    ),
    model_row(
      "08-RegionalCPUE", "08-RegionalCPUE", "07-DataTo2024",
      TRUE, "carry",
      "add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty",
      "Regional CPUE", "08 Regional CPUE likelihood and weighting", "08-regional-cpue-regw100",
      "Authoritative regional CPUE source and REGW100 only; the source has two fewer F32 1952 quarterly records than Step 07 and is copied without transformation; no selectivity change."
    ),
    model_row(
      "09a-BASE075", "09-CompositionWeighting", "08-RegionalCPUE",
      FALSE, "stop", "apply the BASE075 composition-weighting alternative",
      "Common age weighting", "09a Baseline age-length weighting", "09a-base075"
    ),
    model_row(
      "09b-REG075", "09-CompositionWeighting", "08-RegionalCPUE",
      FALSE, "stop", "apply the REG075 composition-weighting alternative",
      "Regional age weighting", "09b Regional age-length weighting", "09b-reg075"
    ),
    model_row(
      "09c-SUB075", "09-CompositionWeighting", "08-RegionalCPUE",
      TRUE, "carry", "apply the selected SUB075 composition weighting",
      "Sub-basin age weighting", "09c Sub-basin age-length weighting", "09c-sub075"
    ),
    model_row(
      "10-MIX015", "10-TagMixing", "09c-SUB075",
      TRUE, "carry", "apply the MIX015 tag-mixing setting",
      "Tag mixing", "10 Tag-mixing periods", "10-mix015"
    ),
    model_row(
      "11-TAGF2ON", "11-TagFlags", "10-MIX015",
      TRUE, "carry",
      "set tag-flag column 2 to 1 so reporting-rate effects are excluded for each release group throughout its configured mixing periods",
      "Tag reporting rates", "11 Reporting-rate mixing-period treatment", "11-tagf2on-col2"
    ),
    model_row(
      "12-TimeVaryingCV", "12-TimeVaryingCV", "11-TAGF2ON",
      TRUE, "carry", "apply normalized time-varying CPUE relative-variance multipliers from the frequency data",
      "Time-varying CV", "12 Time-varying CPUE uncertainty", "12-timevaryingcv"
    ),
    model_row(
      "13-EffortCreep", "13-EffortCreep", "12-TimeVaryingCV",
      TRUE, "carry", "apply the BET 2026 effort-creep series",
      "Effort creep", "13 Effort-creep adjustment", "13-effortcreep"
    ),
    model_row(
      "14-CPUESigma", "14-CPUESigma", "13-EffortCreep",
      TRUE, "carry",
      "fix index-specific CPUE observation-error scales calibrated from preliminary MLE fits",
      "CPUE sigma", "14 Fixed CPUE observation-error calibration", "14-fixed-cpue-observation-error",
      "Preliminary fits across alternative configurations produced similar index-specific MLE sigma estimates. Carry fish flag 92 values for R1-R5 of 35, 24, 21, 24, and 23, corresponding to executed error scales 0.35, 0.24, 0.21, 0.24, and 0.23, so later comparisons retain consistent CPUE weighting."
    ),
    model_row(
      "15-SelectivityUpdate", "15-SelectivityUpdate", "14-CPUESigma",
      TRUE, "carry",
      "apply the intended broad selectivity bundle across F15-F33",
      "Selectivity update", "15 Fleet-specific selectivity update", "15-selectivity-update",
      "Unshare F15-F28 and apply fleet-specific terminal/dome controls. F25/F26 each use terminal age 25, dome flag 2, seven spline nodes, and youngest-tail flag 0. Separate F29-F33 selectivity groups in staged run 5. These controls are one assessment-specific bundle; DM grouping is unchanged."
    ),
    model_row(
      "16a-DOMDiv200", "16-CompositionWeighting", "15-SelectivityUpdate",
      FALSE, "carry", "apply the assessment-specific DOM divisor 200 to F21-F23",
      "DOM downweighting", "16a F21-F23 length-composition downweighting", "16a-dom-f21-f23-div200",
      "Alternative length-composition weighting branch from Step 15. Only F21-F23 receive flag-49 divisor 200."
    ),
    model_row(
      "16b-Francis", "16-CompositionWeighting", "16a-DOMDiv200",
      FALSE, "stop", "inherit 16a and replace all LF divisors with the Francis composition-data weighting comparison",
      "Francis weighting", "16b Francis length-composition weighting", "16b-francis",
      "Alternative length-composition weighting treatment. Francis flag-49 divisors replace every 16a value for all 33 fisheries, including F21-F23 = 114/398/705 rather than 200/200/200."
    ),
    model_row(
      "16c-DMG8Nmax25", "16-CompositionWeighting", "15-SelectivityUpdate",
      TRUE, "final",
      "branch directly from Step 15 and use a Dirichlet-multinomial likelihood with G8 grouping and Nmax 25",
      "Dirichlet-multinomial", "16c DM length-composition weighting", "16c-dm-length-composition-weighting",
      "Selected length-composition weighting treatment. This branch does not inherit divisor 200 or Francis controls. Nmax=25 caps internally estimated composition information to limit excessive dominance over CPUE; its scale reflects preliminary effective-sample-size behavior.",
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
  "15-SelectivityUpdate" = "Apply the intended broad fleet-specific selectivity bundle: unshare F15-F28, set terminal/dome controls, use seven-node F25/F26 tails, and separate F29-F33.",
  "16a-DOMDiv200" = "Evaluate divisor-200 downweighting for lower-quality, previously unweighted DOM length compositions from F21-F23.",
  "16b-Francis" = "Evaluate Francis weighting as a substitute for every fishery-specific LF divisor on the DOM branch.",
  "16c-DMG8Nmax25" = "Estimate composition overdispersion within the model while limiting excessive length-frequency influence, without inheriting DOM or Francis divisors."
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
stepwise_models$dm_grouping[stepwise_models$step_id == "16c-DMG8Nmax25"] <- "G8PSSET"
stepwise_models$dm_nmax <- NA_integer_
stepwise_models$dm_nmax[stepwise_models$step_id == "16c-DMG8Nmax25"] <- 25L
stepwise_models$regional_scaling_weight <- NA_integer_
stepwise_models$regional_scaling_weight[step_number >= 8L] <- 100L
stepwise_models$reporting_rate_prior <- ifelse(step_number >= 7L, "RRPTTP26", "")

# Dedicated sensitivity branch from the corrected Step 16c model.
sensitivity_models <- do.call(
  rbind,
  list(
    model_row(
      "17a-F15FormRelaxed", "17-SelectivityFormSensitivity", "16c-DMG8Nmax25",
      FALSE, "sensitivity",
      "remove the F15 HL.PH.2 dome/old-age-tail selectivity-form penalty",
      "F15 form relaxed",
      "BET 2026 selectivity-form sensitivity | F15",
      "17a-f15-selectivity-form-relaxed",
      "Fishery flag 16 changes from 2 to 0 for F15 only; all other Step 16c inputs and controls are unchanged."
    ),
    model_row(
      "17b-F22FormRelaxed", "17-SelectivityFormSensitivity", "16c-DMG8Nmax25",
      FALSE, "sensitivity",
      "remove the F22 DOM.PH.2 dome/old-age-tail selectivity-form penalty",
      "F22 form relaxed",
      "BET 2026 selectivity-form sensitivity | F22",
      "17b-f22-selectivity-form-relaxed",
      "Fishery flag 16 changes from 2 to 0 for F22 only; all other Step 16c inputs and controls are unchanged."
    ),
    model_row(
      "17c-F15F22FormRelaxed", "17-SelectivityFormSensitivity", "16c-DMG8Nmax25",
      FALSE, "sensitivity",
      "remove the F15 HL.PH.2 and F22 DOM.PH.2 dome/old-age-tail selectivity-form penalties",
      "F15/F22 forms relaxed",
      "BET 2026 selectivity-form sensitivity | F15 + F22",
      "17c-f15-f22-selectivity-form-relaxed",
      "Fishery flag 16 changes from 2 to 0 for F15 and F22 only; all other Step 16c inputs and controls are unchanged."
    ),
    model_row(
      "17d-AllSelectivityFormRelaxed", "17-SelectivityFormSensitivity", "16c-DMG8Nmax25",
      FALSE, "sensitivity",
      "remove every active fishery-specific dome/old-age-tail selectivity-form penalty",
      "All forms relaxed",
      "BET 2026 selectivity-form boundary sensitivity | all fisheries",
      "17d-all-selectivity-form-relaxed",
      "All 14 active fishery flag-16 controls change from 2 to 0; every other Step 16c input and control is unchanged. This is a boundary sensitivity, not a preferred model."
    ),
    model_row(
      "18-GroupedSelectivityRobustness", "18-SelectivityRobustness", "17d-AllSelectivityFormRelaxed",
      FALSE, "sensitivity",
      "share regional-index selectivity with matched extraction fisheries and reduce selected spline dimensions",
      "Grouped selectivity robustness",
      "BET 2026 selectivity robustness sensitivity | grouped regional index selectivity",
      "18-grouped-selectivity-robustness",
      "Full native-MFCL doitall fit using the Job 14363 configuration. F29/F30/F31/F32 share selectivity with F2/F4/F7/F8 respectively; F33 remains independent. F1, F3, F5 and F33 use four spline nodes, F15 retains five, F25/F26 retain seven, and F29-F33 retain separate flag-99 catchability groups."
    ),
    model_row(
      "19a-R1F2F3F29SharedSelectivity", "19-SelectivityRobustness", "18-GroupedSelectivityRobustness",
      FALSE, "sensitivity",
      "share one four-node Region 1 selectivity among F2, F3 and F29 while retaining independent index catchability",
      "R1 F2/F3/F29 selectivity shared",
      "BET 2026 selectivity robustness sensitivity | R1 F2/F3/F29 shared",
      "19a-r1-f2-f3-f29-selectivity-shared",
      "Full native-MFCL doitall fit using the Job 15363 configuration. F2 LL.EAST.1, F3 LL.US.1 and F29 Index R1 share one four-node selectivity. F29 retains its independent flag-99 catchability group; fixed M, DM G8 Nmax25 and every other Job 15363 input and control are unchanged."
    ),
    model_row(
      "19-GroupedSelectivityEstimatedM", "19-NaturalMortalitySensitivity", "18-GroupedSelectivityRobustness",
      FALSE, "sensitivity",
      "estimate the Lorenzen natural-mortality intercept from Phase 10",
      "Grouped selectivity + estimated M",
      "BET 2026 grouped-selectivity sensitivity | estimated Lorenzen M from -2.5",
      "19-grouped-selectivity-estimated-m",
      "Separate full native-MFCL doitall sensitivity. Set age_pars(5,1)=-2.5 in bet.ini, hold it fixed through Phase 9, and estimate the Lorenzen intercept from Phase 10 with flag 121=1 while retaining the length slope. All Step 18 DM/G8/Nmax25, selectivity, CPUE, tag and recruitment controls remain unchanged."
    )
  )
)
sensitivity_models$report_purpose <- c(
  "Test sensitivity to the dominant F22 dome/old-age-tail selectivity-form penalty.",
  "Test sensitivity to the dominant F15 dome/old-age-tail selectivity-form penalty.",
  "Test their combined influence on fit, profile curvature and Hessian stability.",
  "Bound the influence of all active fishery-specific dome/old-age-tail penalties; this is not a preferred model.",
  "Test whether fishery-informed selectivity sharing and lower spline dimension improve robustness while retaining the Job 14363 model specification.",
  "Test whether a common four-node F2/F3/F29 Region 1 selectivity removes the retrospective alternative mode without sharing index catchability.",
  "Evaluate the separate sensitivity of the grouped-selectivity configuration to estimating the Lorenzen natural-mortality intercept from a -2.5 starting value."
)
sensitivity_models$age_length_variant <- "SUB075"
sensitivity_models$tag_flag2 <- 1L
sensitivity_models$dm_grouping <- "G8PSSET"
sensitivity_models$dm_nmax <- 25L
sensitivity_models$regional_scaling_weight <- 100L
sensitivity_models$reporting_rate_prior <- "RRPTTP26"
sensitivity_models <- sensitivity_models[, names(stepwise_models), drop = FALSE]
stepwise_models <- rbind(stepwise_models, sensitivity_models)
rownames(stepwise_models) <- NULL
stepwise_run$numbered_groups <- 19L
stepwise_run$model_rows <- nrow(stepwise_models)
stepwise_run$selected_path_models <- sum(stepwise_models$selected & stepwise_models$enabled)
