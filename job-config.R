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
  flow_group = "bet-2026-stepwise-public",

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
      "Diag2023", "01 Diag2023", "01-diag2023",
      region_count = 9L,
      mfcl_program_path = "/home/mfcl/mfclo64_2023_diagnostic_2.2.2.0"
    ),
    model_row(
      "02a-NewExe1003", "02-Executable", "01-Diag2023",
      TRUE, "carry", "current MFCL executable with the 1003 ini",
      "NewExe1003", "02a NewExe1003", "02a-newexe1003",
      region_count = 9L
    ),
    model_row(
      "02b-Ini1007", "02-Executable", "02a-NewExe1003",
      TRUE, "carry", "convert the ini layout from 1003 to 1007",
      "Ini1007", "02b Ini1007", "02b-ini1007",
      region_count = 9L
    ),
    model_row(
      "02c-LengthWeight", "02-Executable", "02b-Ini1007",
      TRUE, "carry", "apply BET 2026 bias-corrected length-weight parameters",
      "LengthWeight", "02c LengthWeight", "02c-lengthweight",
      region_count = 9L
    ),
    model_row(
      "03-FixM", "03-FixM", "02c-LengthWeight",
      TRUE, "carry", "fix natural mortality from the mgc=-5 diagnostic fit",
      "FixM", "03 FixM", "03-fixm",
      region_count = 9L
    ),
    model_row(
      "04-NewStructure", "04-NewStructure", "03-FixM",
      TRUE, "carry", "adopt the five-region and 33-fishery structure",
      "NewStructure", "04 NewStructure", "04-newstructure"
    ),
    model_row(
      "05-ConvertToLength", "05-ConvertToLength", "04-NewStructure",
      TRUE, "carry", "convert the existing weight compositions to length",
      "ConvertToLength", "05 ConvertToLength", "05-converttolength"
    ),
    model_row(
      "06-AddLengthData", "06-AddLengthData", "05-ConvertToLength",
      TRUE, "carry", "add the additional length-composition data",
      "AddLengthData", "06 AddLengthData", "06-addlengthdata"
    ),
    model_row(
      "07-DataTo2024", "07-DataTo2024", "06-AddLengthData",
      TRUE, "carry",
      "extend data through 2024 and integrate the latest RRPTTP26 reporting-rate penalties",
      "DataTo2024-RRPTTP26", "07 DataTo2024 with RRPTTP26", "07-datato2024-rrpttp26",
      "Latest RRPTTP26 penalties are embedded here and inherited by every descendant"
    ),
    model_row(
      "08-RegionalCPUE", "08-RegionalCPUE", "07-DataTo2024",
      TRUE, "carry",
      "add regional CPUE data and likelihood plus the REGW100 regional-scaling penalty",
      "RegionalCPUE-REGW100", "08 Regional CPUE and REGW100", "08-regional-cpue-regw100",
      "Regional CPUE data/likelihood and REGW100 only; no selectivity change"
    ),
    model_row(
      "09a-BASE075", "09-CompositionWeighting", "08-RegionalCPUE",
      FALSE, "stop", "apply the BASE075 composition-weighting alternative",
      "BASE075", "09a BASE075", "09a-base075"
    ),
    model_row(
      "09b-REG075", "09-CompositionWeighting", "08-RegionalCPUE",
      FALSE, "stop", "apply the REG075 composition-weighting alternative",
      "REG075", "09b REG075", "09b-reg075"
    ),
    model_row(
      "09c-SUB075", "09-CompositionWeighting", "08-RegionalCPUE",
      TRUE, "carry", "apply the selected SUB075 composition weighting",
      "SUB075", "09c SUB075 selected", "09c-sub075"
    ),
    model_row(
      "10-MIX015", "10-TagMixing", "09c-SUB075",
      TRUE, "carry", "apply the MIX015 tag-mixing setting",
      "MIX015", "10 MIX015", "10-mix015"
    ),
    model_row(
      "11-TAGF2ON", "11-TagFlags", "10-MIX015",
      TRUE, "carry", "turn on tag flag column 2 only",
      "TAGF2ON", "11 TAGF2ON column 2", "11-tagf2on-col2"
    ),
    model_row(
      "12-TimeVaryingCV", "12-TimeVaryingCV", "11-TAGF2ON",
      TRUE, "carry", "apply time-varying CPUE CVs",
      "TimeVaryingCV", "12 TimeVaryingCV", "12-timevaryingcv"
    ),
    model_row(
      "13-EffortCreep", "13-EffortCreep", "12-TimeVaryingCV",
      TRUE, "carry", "apply the BET 2026 effort-creep series",
      "EffortCreep", "13 EffortCreep", "13-effortcreep"
    ),
    model_row(
      "14-CPUESigma", "14-CPUESigma", "13-EffortCreep",
      TRUE, "carry",
      "apply the common index-specific CPUE MLE sigma values",
      "CPUE MLE sigma", "14 CPUE MLE sigma", "14-cpue-mle-sigma",
      "Preliminary fits across alternative configurations produced similar index-specific MLE sigma estimates. Carry the common fish flag 92 values for R1-R5: 35, 24, 21, 24, and 23, so later stepwise comparisons retain consistent CPUE weighting."
    ),
    model_row(
      "15-SelectivityUpdate", "15-SelectivityUpdate", "14-CPUESigma",
      TRUE, "carry",
      "address persistent structured F25/F26 length-frequency misfit with independent seven-node cubic-spline selectivities and separate F29-F33 regional-index selectivities",
      "SelectivityUpdate", "15 Consolidated selectivity update", "15-selectivity-update",
      "F25/F26 are spatially distinct associated purse-seine fisheries: retain their common associated-purse-seine G8 DM group but use independent smooth 7-node splines for different size availability. F29-F33 are regional index fisheries: separate selectivities to avoid masking regional size-availability differences while retaining their common index-oriented DM group. Grouping and node choices are assessment-specific and evaluated stepwise, not literature-mandated."
    ),
    model_row(
      "16-DOMDiv200", "16-DOM", "15-SelectivityUpdate",
      TRUE, "carry", "apply the assessment-specific DOM divisor 200 to F21-F23",
      "DOMDiv200", "16 DOM F21-F23 divisor 200", "16-dom-f21-f23-div200"
    ),
    model_row(
      "17a-Francis", "17-CompositionLikelihood", "16-DOMDiv200",
      FALSE, "stop", "apply the Francis composition-data weighting comparison",
      "Francis", "17a Francis comparison", "17a-francis"
    ),
    model_row(
      "17b-DMG8Nmax25", "17-CompositionLikelihood", "16-DOMDiv200",
      TRUE, "final",
      "apply the DM likelihood, G8 PSSET grouping, and Nmax 25 as one bundled final configuration",
      "DM-G8PSSET-Nmax25-Final", "17b DM-G8PSSET-Nmax25 final", "17b-dm-g8psset-nmax25-final",
      "Nmax=25 is a rounded cap selected just above the 95th percentile of fishery-level Francis ESS estimates from preliminary fits; it is not 95% weighting. It limits extreme DM ESS while leaving about 95% of the empirical Francis ESS distribution uncapped. G8 PSSET grouping and the cap are assessment-specific stepwise choices.",
      fitted_job_id = "13328", hessian_merge_job_id = "13432"
    )
  )
)

rownames(stepwise_models) <- NULL

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
