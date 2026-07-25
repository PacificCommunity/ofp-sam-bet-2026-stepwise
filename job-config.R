# Public BET 2026 stepwise run matrix.
#
# Every row points at a self-contained steps/<step_id>/model/ directory. The
# scientific parent records comparison lineage only; it is not a run-time file
# dependency. Select one or more rows with the exact values in STEP_SELECT.

stepwise_run <- list(
  # Run all 30 independent models unless STEP_SELECT is supplied.
  default_step_select = "all",
  numbered_groups = 22L,
  model_rows = 30L,
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
      TRUE, "carry", "fix Lorenzen natural-mortality scaling to the 2023 diagnostic-model estimate",
      "Diagnostic natural-mortality estimate fixed",
      "04 Fix natural mortality to diagnostic estimate", "04-fixm",
      region_count = 9L
    ),
    model_row(
      "05-LengthWeight", "05-LengthWeight", "04-FixM",
      TRUE, "carry", "update the BET 2026 bias-corrected length-weight parameters",
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
      TRUE, "carry", "replace the mixed size-composition input with the reweighted weight-as-length length-frequency dataset",
      "Weight-as-length LF input", "07 Reweighted weight-as-length LF input", "07-converttolength"
    ),
    model_row(
      "08-AddLengthData", "08-AddLengthData", "07-ConvertToLength",
      TRUE, "carry", "use observed length compositions where their catch coverage exceeds that of weight samples",
      "Observed-length supplementation",
      "08 Weight-as-length plus observed-length compositions", "08-addlengthdata"
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
      "set the five regional CPUE observation-error scales to maximum-likelihood estimates",
      "CPUE observation-error calibration",
      "13 CPUE observation-error calibration", "13-cpue-observation-error-calibration",
      "Across multiple exploratory settings, the index-specific maximum-likelihood estimates changed little and converged near 0.354, 0.237, 0.212, 0.239, and 0.225. Apply the calibrated R1-R5 scales 0.35, 0.24, 0.21, 0.24, and 0.23 and carry them through every later step."
    ),
    model_row(
      "14-NewAgeData", "14-AgeData", "13-CPUEErrorCalibration",
      TRUE, "carry", "add the new conditional age-at-length data with a weighting factor of 0.75 from the 2023 BET assessment",
      "New conditional age-at-length data",
      "14 New conditional age-at-length data (weight 0.75)", "14-new-age-data-base075"
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
      "revise fishery-specific selectivity for the 33-fishery structure with dome/old-age-tail form penalties off for all 14 applicable fisheries",
      "Revised fishery-specific selectivity", "16 Revised fishery-specific selectivity", "16-selectivity-update",
      "Apply the Job 14363 selectivity choice: unshare F15-F28, retain fishery-specific terminal ages and F25/F26 seven-node/youngest-tail settings, separate F29-F33 in staged run 5, and set fishery flag 16 from 2 to 0 for F12, F13, F15-F19, and F21-F27."
    ),
    model_row(
      "17-MIX015", "17-TagMixing", "16-SelectivityUpdate",
      TRUE, "carry",
      "apply release-group-specific MIX015 tag-mixing periods",
      "Release-group-specific tag mixing periods",
      "17 Release-group-specific tag-mixing periods", "17-mix015",
      "Replace tag_flags(:,1) with the release-group-specific MIX015 periods. Keep tag_flags(:,2)=0 so the treatment of reporting rates during those periods is evaluated separately in Step 18."
    ),
    model_row(
      "18-TagReportingExclusion", "18-TagReportingExclusion", "17-MIX015",
      TRUE, "carry",
      "exclude reporting rates only during each release group's configured tag-mixing period",
      "Tag reporting rates omitted in pre-mixing window",
      "18 Tag reporting rates omitted in pre-mixing window", "18-tag-reporting-exclusion",
      "Keep the Step 17 release-group-specific periods and change only tag_flags(:,2) from 0 to 1. This removes reporting rates from predicted recaptures within the pre-mixing windows; post-mixing treatment and all reporting-rate values, groups, targets, and penalties remain unchanged."
    ),
    model_row(
      "19-EffortCreep", "19-EffortCreep", "18-TagReportingExclusion",
      TRUE, "carry", "apply the BET 2026 effort-creep series",
      "Effort creep", "19 Effort-creep adjustment", "19-effortcreep"
    ),
    model_row(
      "20a-DOMDiv200", "20-CompositionWeighting", "19-EffortCreep",
      FALSE, "stop", "apply divisor 200 to length compositions from the three domestic fisheries F21-F23",
      "Three domestic fisheries downweighted",
      "20a F21-F23 length-composition downweighting", "20a-dom-f21-f23-div200",
      "Alternative length-composition weighting branch from Step 19. Only F21-F23 receive flag-49 divisor 200; the selected Step 16 revised fishery-specific, form-penalties-off setting is retained."
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
      "Selected final weighting treatment. This branch does not inherit divisor 200 or Francis controls. It retains the Job 14363 revised fishery-specific selectivity setting with form penalties off, plus the selected tag settings. Nmax=25 is the asymptotic effective-sample-size upper bound and lies just above the 22.22-23.81 range of 95th-percentile composition-level Francis ESS across 2,399 positive LF compositions in matched robust-normal fits. Flag 313 is reset to 0 because the DM likelihood does not read that percentage threshold and to avoid unrelated percentage-tail preprocessing; flag 320=5 controls DM support, matching the Job 14363 numeric controls.",
      fitted_job_id = "14363"
    ),
    model_row(
      "21a-R1F2F3F29Shared-MIX015", "21-SelectivityMixingSensitivity",
      "20c-DMG8Nmax25",
      FALSE, "stop",
      "apply the Job 15984 R1 selectivity grouping with SC22-IP10 K=0.15 mixing periods",
      "R1 grouped selectivity; K=0.15",
      "21a Final DM sensitivity | R1 F2/F3/F29 shared, SC22 K=0.15",
      "21a-r1-f2-f3-f29-shared-mix015",
      "Independent full native-MFCL doitall fit. F2, F3 and F29 share one four-node Region 1 selectivity; F30/F4, F31/F7 and F32/F8 remain paired; F33 and F29-F33 catchability groups remain independent. Fixed M, DM G8 Nmax25, reporting-rate settings and all other final-model controls are retained."
    ),
    model_row(
      "21b-R1F2F3F29Shared-MIX005", "21-SelectivityMixingSensitivity",
      "21a-R1F2F3F29Shared-MIX015",
      FALSE, "stop",
      "retain the Job 15984 R1 selectivity grouping and change only SC22-IP10 mixing periods from K=0.15 to K=0.05",
      "R1 grouped selectivity; K=0.05",
      "21b Final DM sensitivity | R1 F2/F3/F29 shared, SC22 K=0.05",
      "21b-r1-f2-f3-f29-shared-mix005",
      "Independent full native-MFCL doitall fit. The model is identical to Step 21a except that tag_flags(:,1) comes from the SC22-IP10 K=0.05 INI. Fixed M, DM G8 Nmax25, reporting-rate settings, selectivity grouping and all other controls are retained."
    ),
    model_row(
      "22a-R1F2F3F29Shared-MIX015-TAGW500", "22-TagLikelihoodWeightSensitivity",
      "21a-R1F2F3F29Shared-MIX015",
      FALSE, "stop",
      "retain SC22 K=0.15 and multiply the tag-return likelihood by 0.50",
      "K=0.15; tag weight 0.50",
      "22a Final DM sensitivity | SC22 K=0.15, tag-return weight 0.50",
      "22a-r1-shared-mix015-tagw500",
      "Independent full native-MFCL doitall fit. Parest flag 177=500 multiplies the tag-return likelihood by 0.50. Reporting-rate priors, fixed M, DM G8 Nmax25, Job 15984 selectivity grouping and all other settings are retained."
    ),
    model_row(
      "22b-R1F2F3F29Shared-MIX015-TAGW250", "22-TagLikelihoodWeightSensitivity",
      "21a-R1F2F3F29Shared-MIX015",
      FALSE, "stop",
      "retain SC22 K=0.15 and multiply the tag-return likelihood by 0.25",
      "K=0.15; tag weight 0.25",
      "22b Final DM sensitivity | SC22 K=0.15, tag-return weight 0.25",
      "22b-r1-shared-mix015-tagw250",
      "Independent full native-MFCL doitall fit. Parest flag 177=250 multiplies the tag-return likelihood by 0.25. Reporting-rate priors, fixed M, DM G8 Nmax25, Job 15984 selectivity grouping and all other settings are retained."
    ),
    model_row(
      "22c-R1F2F3F29Shared-MIX005-TAGW500", "22-TagLikelihoodWeightSensitivity",
      "21b-R1F2F3F29Shared-MIX005",
      FALSE, "stop",
      "retain SC22 K=0.05 and multiply the tag-return likelihood by 0.50",
      "K=0.05; tag weight 0.50",
      "22c Final DM sensitivity | SC22 K=0.05, tag-return weight 0.50",
      "22c-r1-shared-mix005-tagw500",
      "Independent full native-MFCL doitall fit. Parest flag 177=500 multiplies the tag-return likelihood by 0.50. Reporting-rate priors, fixed M, DM G8 Nmax25, Job 15984 selectivity grouping and all other settings are retained."
    ),
    model_row(
      "22d-R1F2F3F29Shared-MIX005-TAGW250", "22-TagLikelihoodWeightSensitivity",
      "21b-R1F2F3F29Shared-MIX005",
      FALSE, "stop",
      "retain SC22 K=0.05 and multiply the tag-return likelihood by 0.25",
      "K=0.05; tag weight 0.25",
      "22d Final DM sensitivity | SC22 K=0.05, tag-return weight 0.25",
      "22d-r1-shared-mix005-tagw250",
      "Independent full native-MFCL doitall fit. Parest flag 177=250 multiplies the tag-return likelihood by 0.25. Reporting-rate priors, fixed M, DM G8 Nmax25, Job 15984 selectivity grouping and all other settings are retained."
    ),
    model_row(
      "S01-SelectivityStability-MIX015", "S01-SelectivityStability",
      "21a-R1F2F3F29Shared-MIX015",
      FALSE, "stop",
      "test extraction-based selectivity sharing while keeping all regional index selectivities independent",
      "Selectivity-stability sensitivity; K=0.15",
      "S01 Selectivity-stability sensitivity | independent indices",
      "s01-selectivity-stability-mix015",
      paste(
        "Independent full native-MFCL doitall fit. F2/F3 and F7/F9 share",
        "extraction-fishery selectivities. F19, F25, F26 and F29-F33 remain",
        "independent, and all Job 15989 node settings are retained. Fixed M,",
        "DM G8 Nmax25, SC22-IP10 K=0.15 tag settings, reporting-rate priors",
        "and all non-selectivity controls are unchanged."
      )
    )
  )
)

rownames(stepwise_models) <- NULL

# Concise, publication-facing changes and rationale used by the
# model-development report. Detailed controls remain in control_notes and the
# generated step documentation.
stepwise_report_change <- c(
  "01-Diag2023" = "2023 diagnostic-model refit",
  "02-NewExe1003" = "MFCL executable updated from archived 2.2.2.0 to the campaign 2.2.7.9-based build",
  "03-Ini1007" = "MFCL INI file updated from format 1003 to 1007",
  "04-FixM" = "Lorenzen natural-mortality scaling fixed to the 2023 diagnostic-model estimate",
  "05-LengthWeight" = "BET 2026 bias-corrected length-weight parameters",
  "06-NewStructure" = "Five-region, 33-fishery structure",
  "07-ConvertToLength" = "Size-composition input replaced by the reweighted weight-as-length LF dataset",
  "08-AddLengthData" = "Weight-as-length plus observed-length compositions for longline fisheries",
  "09-TailCompression1Pct" = "1% length-frequency tail compression",
  "10-DataTo2024" = "Data through 2024",
  "11-RegionalCPUE" = "Regional CPUE indices and regional scaling",
  "12-TimeVaryingCV" = "Time-varying CPUE uncertainty",
  "13-CPUEErrorCalibration" = "Regional CPUE log-scale observation-error SDs fixed at 0.35, 0.24, 0.21, 0.24 and 0.23",
  "14-NewAgeData" = "New conditional age-at-length data (weighting factor = 0.75)",
  "15a-REG075" = "Regional age weighting",
  "15b-SUB075" = "Sub-basin age weighting",
  "16-SelectivityUpdate" = "Revised fishery-specific selectivity",
  "17-MIX015" = "Release-group-specific tag-mixing periods",
  "18-TagReportingExclusion" = "Tag reporting rates omitted in the pre-mixing window",
  "19-EffortCreep" = "Effort-creep adjustment",
  "20a-DOMDiv200" = "Downweighting of three domestic fisheries (F21-F23; divisor 200)",
  "20b-Francis" = "Francis composition reweighting",
  "20c-DMG8Nmax25" = "Dirichlet-multinomial (DM) composition weighting",
  "21a-R1F2F3F29Shared-MIX015" = "Job 15984 Region 1 selectivity grouping with SC22 K=0.15 mixing periods",
  "21b-R1F2F3F29Shared-MIX005" = "Job 15984 Region 1 selectivity grouping with SC22 K=0.05 mixing periods",
  "22a-R1F2F3F29Shared-MIX015-TAGW500" = "SC22 K=0.15 with tag-return likelihood weight 0.50",
  "22b-R1F2F3F29Shared-MIX015-TAGW250" = "SC22 K=0.15 with tag-return likelihood weight 0.25",
  "22c-R1F2F3F29Shared-MIX005-TAGW500" = "SC22 K=0.05 with tag-return likelihood weight 0.50",
  "22d-R1F2F3F29Shared-MIX005-TAGW250" = "SC22 K=0.05 with tag-return likelihood weight 0.25",
  "S01-SelectivityStability-MIX015" = "Extraction-based selectivity sharing with independent regional indices"
)
stepwise_report_purpose <- c(
  "01-Diag2023" = "Provide a reproducible reference for subsequent comparisons.",
  "02-NewExe1003" = "Isolate the executable effect while retaining the 1003-format INI and scientific inputs and controls.",
  "03-Ini1007" = "Use INI 1007, the latest format supported by the pinned campaign executable.",
  "04-FixM" = "Improve model stability, as agreed at the pre-assessment workshop (Lorenzen, 1996).",
  "05-LengthWeight" = "Update biomass conversion for the 2026 assessment.",
  "06-NewStructure" = "Represent revised spatial and fishery heterogeneity.",
  "07-ConvertToLength" = "Evaluate the selected weight-as-length LF dataset, in which all retained size compositions are length frequencies.",
  "08-AddLengthData" = "Evaluate the effect of using observed lengths where their catch coverage exceeded that of weight samples (Peatman et al., 2026).",
  "09-TailCompression1Pct" = "Stabilize information in sparsely sampled tail bins.",
  "10-DataTo2024" = "Extend the temporal coverage of the assessment.",
  "11-RegionalCPUE" = "Represent spatial variation in relative abundance.",
  "12-TimeVaryingCV" = "Account for temporal variation in the relative precision of the CPUE indices.",
  "13-CPUEErrorCalibration" = "Set the five regional log-scale observation-error standard deviations to values obtained by maximum-likelihood estimation and retain them in subsequent steps.",
  "14-NewAgeData" = "Use the 2023 BET assessment weighting as the reference treatment for the new age data (Day et al., 2023).",
  "15a-REG075" = "Test region-level spatial weighting.",
  "15b-SUB075" = "Represent finer sub-basin variation in age-data information.",
  "16-SelectivityUpdate" = "Align selectivity specifications with the revised 33-fishery structure.",
  "17-MIX015" = "Assign release-group-specific mixing periods using a Kolmogorov-dissimilarity cut-off of K = 0.15 (Scutt Phillips et al., 2026).",
  "18-TagReportingExclusion" = "Avoid applying poorly determined or assumed reporting rates within the pre-mixing windows, as recommended in the MULTIFAN-CL manual; post-mixing reporting-rate treatment is unchanged.",
  "19-EffortCreep" = "Account for gradual changes in fishing efficiency.",
  "20a-DOMDiv200" = "Test strong downweighting of length compositions from the Indonesian, Philippine and Vietnamese domestic fisheries.",
  "20b-Francis" = "Apply fishery-specific length-composition divisors calculated from standardized mean-length residuals using method TA1.8 of Francis (2011).",
  "20c-DMG8Nmax25" = "Estimate length-composition overdispersion internally using eight fishery groups and an effective-sample-size upper asymptote of 25.",
  "21a-R1F2F3F29Shared-MIX015" = "Evaluate the Job 15984 selectivity grouping using the current final DM inputs and SC22-IP10 K=0.15 mixing periods.",
  "21b-R1F2F3F29Shared-MIX005" = "Isolate sensitivity to the SC22-IP10 K=0.05 release-group mixing periods under the same grouped-selectivity final DM model.",
  "22a-R1F2F3F29Shared-MIX015-TAGW500" = "Evaluate tag-index conflict by halving the tag-return likelihood under K=0.15 while retaining reporting-rate priors.",
  "22b-R1F2F3F29Shared-MIX015-TAGW250" = "Evaluate a stronger tag-return downweighting under K=0.15 while retaining reporting-rate priors.",
  "22c-R1F2F3F29Shared-MIX005-TAGW500" = "Evaluate tag-index conflict by halving the tag-return likelihood under K=0.05 while retaining reporting-rate priors.",
  "22d-R1F2F3F29Shared-MIX005-TAGW250" = "Evaluate a stronger tag-return downweighting under K=0.05 while retaining reporting-rate priors.",
  "S01-SelectivityStability-MIX015" = "Test whether limited sharing among comparable longline extraction fisheries improves stability without coupling index selectivity to extraction-fishery composition processes or reducing the selected purse-seine flexibility."
)
stepwise_models$report_change <- unname(
  stepwise_report_change[stepwise_models$step_id]
)
stepwise_models$report_purpose <- unname(
  stepwise_report_purpose[stepwise_models$step_id]
)
stopifnot(
  !anyNA(stepwise_models$report_change),
  all(nzchar(stepwise_models$report_change)),
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
  "20c-DMG8Nmax25" = 20L,
  "21a-R1F2F3F29Shared-MIX015" = 21L,
  "21b-R1F2F3F29Shared-MIX005" = 21L,
  "22a-R1F2F3F29Shared-MIX015-TAGW500" = 22L,
  "22b-R1F2F3F29Shared-MIX015-TAGW250" = 22L,
  "22c-R1F2F3F29Shared-MIX005-TAGW500" = 22L,
  "22d-R1F2F3F29Shared-MIX005-TAGW250" = 22L,
  "S01-SelectivityStability-MIX015" = 23L
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
stepwise_models$tag_return_likelihood_weight <- 1
stepwise_models$tag_return_likelihood_weight[
  stepwise_models$step_id %in% c(
    "22a-R1F2F3F29Shared-MIX015-TAGW500",
    "22c-R1F2F3F29Shared-MIX005-TAGW500"
  )
] <- 0.50
stepwise_models$tag_return_likelihood_weight[
  stepwise_models$step_id %in% c(
    "22b-R1F2F3F29Shared-MIX015-TAGW250",
    "22d-R1F2F3F29Shared-MIX005-TAGW250"
  )
] <- 0.25
stepwise_models$dm_grouping <- ""
stepwise_models$dm_grouping[
  stepwise_models$step_id %in% c(
    "20c-DMG8Nmax25",
    "21a-R1F2F3F29Shared-MIX015",
    "21b-R1F2F3F29Shared-MIX005",
    "22a-R1F2F3F29Shared-MIX015-TAGW500",
    "22b-R1F2F3F29Shared-MIX015-TAGW250",
    "22c-R1F2F3F29Shared-MIX005-TAGW500",
    "22d-R1F2F3F29Shared-MIX005-TAGW250",
    "S01-SelectivityStability-MIX015"
  )
] <- "G8PSSET"
stepwise_models$dm_nmax <- NA_integer_
stepwise_models$dm_nmax[
  stepwise_models$step_id %in% c(
    "20c-DMG8Nmax25",
    "21a-R1F2F3F29Shared-MIX015",
    "21b-R1F2F3F29Shared-MIX005",
    "22a-R1F2F3F29Shared-MIX015-TAGW500",
    "22b-R1F2F3F29Shared-MIX015-TAGW250",
    "22c-R1F2F3F29Shared-MIX005-TAGW500",
    "22d-R1F2F3F29Shared-MIX005-TAGW250",
    "S01-SelectivityStability-MIX015"
  )
] <- 25L
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
    !stepwise_models$step_id %in% c(
      "20c-DMG8Nmax25",
      "21a-R1F2F3F29Shared-MIX015",
      "21b-R1F2F3F29Shared-MIX005",
      "22a-R1F2F3F29Shared-MIX015-TAGW500",
      "22b-R1F2F3F29Shared-MIX015-TAGW250",
      "22c-R1F2F3F29Shared-MIX005-TAGW500",
      "22d-R1F2F3F29Shared-MIX005-TAGW250",
      "S01-SelectivityStability-MIX015"
    ), 1, 0
)
stepwise_models$fixed_cpue_sigma <- stepwise_models$path_stage >= 13L
stepwise_models$selectivity_update <- stepwise_models$path_stage >= 16L
stepwise_models$all_selectivity_forms_relaxed <- stepwise_models$path_stage >= 16L
rownames(stepwise_models) <- NULL
stepwise_run$numbered_groups <- 22L
stepwise_run$model_rows <- nrow(stepwise_models)
stepwise_run$selected_path_models <- sum(stepwise_models$selected & stepwise_models$enabled)
