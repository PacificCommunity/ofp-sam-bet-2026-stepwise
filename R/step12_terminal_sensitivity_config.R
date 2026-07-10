## Model specifications for the focused 71/72/73 OPR terminal-recruitment grid.
##
## The 2024 frequency data contain 73 real years (1952--2024). MFCL's
## orthpoly_constant_begin_end() normalises an end0 setting to a one-point
## endpoint, so 73 is the absolute coefficient ceiling. The endpoint-specific
## saturated annual cases are therefore 73/end0, 72/end2, and 71/end3.
##
## All variants start from the current main-branch Step 12 folder. Only the
## Phase 3 OPR controls in model/doitall.sh are changed; data, likelihood,
## selectivity, tag, growth, and CPUE settings remain byte-identical.

terminal_sensitivity_model_spec <- function() {
  rows <- list()
  row_index <- 0L

  window_tag <- function(value) {
    if (as.integer(value) == -1L) "Free" else as.character(as.integer(value))
  }

  add_opr <- function(family, anchor, rationale,
                      year, season, region, region_season,
                      year_end, component_end,
                      year_degree = 0L, component_degree = 0L) {
    row_index <<- row_index + 1L
    step_prefix <- sprintf("12f%03d", row_index)
    endpoint_tag <- paste0("Y", year_end, "-C", window_tag(component_end))
    count_tag <- sprintf("OPR%d-%02d-%02d-%02d", year, season, region, region_season)
    step_id <- paste(step_prefix, count_tag, endpoint_tag, sep = "-")
    controls <- sprintf(
      "%d-%02d-%02d-%02d; annual end%d; component end%s",
      year, season, region, region_season, year_end, window_tag(component_end)
    )

    rows[[length(rows) + 1L]] <<- data.frame(
      step_id = step_id,
      parent_step = "12-OrthogonalPoly",
      parameterization = "opr",
      family = family,
      anchor = anchor,
      model_label = paste("OPR", controls),
      title = paste(step_prefix, "OPR", controls),
      rationale = rationale,
      standard_terminal_periods = NA_integer_,
      standard_arithmetic_mean = NA,
      year_effect = as.integer(year),
      season_effect = as.integer(season),
      region_effect = as.integer(region),
      region_season_effect = as.integer(region_season),
      year_end_window = as.integer(year_end),
      year_end_degree = as.integer(year_degree),
      region_end_window = as.integer(component_end),
      region_end_degree = as.integer(component_degree),
      season_end_window = as.integer(component_end),
      season_end_degree = as.integer(component_degree),
      region_season_end_window = as.integer(component_end),
      region_season_end_degree = as.integer(component_degree),
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }

  ## Nine interpretable component profiles centred on the current
  ## 01-50-50 setting and the earlier 05/60 screening alternatives. These
  ## avoid an arbitrary full Cartesian product while separating season,
  ## region, and season-by-region interaction complexity.
  profiles <- list(
    list(code = "P01", season = 1L, region = 50L, interaction = 50L,
         rationale = "Uses the current Step 12 rank-1 component profile as the within-branch reference."),
    list(code = "P02", season = 5L, region = 50L, interaction = 50L,
         rationale = "Adds seasonal flexibility while holding both spatial blocks at the Step 12 values."),
    list(code = "P03", season = 1L, region = 40L, interaction = 40L,
         rationale = "Reduces both spatial OPR blocks together to test Hessian conditioning and fit loss."),
    list(code = "P04", season = 5L, region = 40L, interaction = 40L,
         rationale = "Combines the seasonal-5 alternative with a balanced spatial reduction."),
    list(code = "P05", season = 1L, region = 60L, interaction = 60L,
         rationale = "Raises both spatial OPR blocks together to test whether added spatial flexibility absorbs the terminal signal."),
    list(code = "P06", season = 5L, region = 60L, interaction = 60L,
         rationale = "Combines the seasonal-5 alternative with the higher spatial-complexity screen."),
    list(code = "P07", season = 1L, region = 40L, interaction = 50L,
         rationale = "Reduces only the regional block, isolating it from the season-by-region interaction."),
    list(code = "P08", season = 1L, region = 50L, interaction = 40L,
         rationale = "Reduces only the season-by-region block, isolating the main Hessian burden."),
    list(code = "P09", season = 3L, region = 50L, interaction = 50L,
         rationale = "Provides an intermediate seasonal count between the rank-1 and seasonal-5 screens.")
  )

  ## Schedule balance deliberately favours 73 and 72 while retaining the
  ## source-valid 71 comparisons. Component end=-1 explicitly disables the
  ## component endpoint; component 0 would merely inherit the global window.
  schedules <- list(
    list(code = "E01", year = 73L, year_end = 0L, component_end = -1L,
         rationale = "Tests the absolute 73-year saturation boundary with no multi-year endpoint tie in any OPR component."),
    list(code = "E02", year = 73L, year_end = 0L, component_end = 2L,
         rationale = "Keeps the fully saturated annual effect free while applying a two-year endpoint only to non-annual components."),
    list(code = "E03", year = 73L, year_end = 0L, component_end = 3L,
         rationale = "Keeps the fully saturated annual effect free while strengthening non-annual terminal pooling to three years."),
    list(code = "E04", year = 73L, year_end = 0L, component_end = 4L,
         rationale = "Keeps the fully saturated annual effect free while testing a four-year non-annual endpoint treatment."),
    list(code = "E05", year = 72L, year_end = 0L, component_end = -1L,
         rationale = "Tests one fewer annual coefficient than full saturation with all OPR components terminally free."),
    list(code = "E06", year = 72L, year_end = 0L, component_end = 2L,
         rationale = "Separates a near-saturated free annual effect from a two-year non-annual endpoint."),
    list(code = "E07", year = 72L, year_end = 0L, component_end = 3L,
         rationale = "Separates a near-saturated free annual effect from a stronger three-year non-annual endpoint."),
    list(code = "E08", year = 72L, year_end = 2L, component_end = 2L,
         rationale = "Tests the fully saturated annual basis conditional on a two-year endpoint in every OPR component."),
    list(code = "E09", year = 71L, year_end = 0L, component_end = -1L,
         rationale = "Provides a lower near-saturated comparison with no multi-year endpoint treatment."),
    list(code = "E10", year = 71L, year_end = 2L, component_end = 2L,
         rationale = "Tests 71 annual coefficients under the same two-year endpoint as the saturated 72/end2 case."),
    list(code = "E11", year = 71L, year_end = 3L, component_end = 3L,
         rationale = "Tests the fully saturated annual basis conditional on a three-year endpoint in every OPR component.")
  )

  for (schedule in schedules) {
    for (profile in profiles) {
      add_opr(
        family = "schedule-by-component-profile",
        anchor = paste(schedule$code, profile$code, sep = "-"),
        rationale = paste(schedule$rationale, profile$rationale),
        year = schedule$year,
        season = profile$season,
        region = profile$region,
        region_season = profile$interaction,
        year_end = schedule$year_end,
        component_end = schedule$component_end
      )
    }
  }

  ## Explicit all-effect boundary diagnostics. These are deliberately extreme
  ## and are reproducibility/identifiability tests, not preferred production
  ## candidates. Each count equals the source-derived capacity of its endpoint.
  add_opr(
    family = "all-effect-saturation", anchor = "B01-73-all-free",
    rationale = "Fully saturates year, season, region, and interaction effects at 73 coefficients with one-point endpoints; this is the maximum valid current-data model.",
    year = 73L, season = 73L, region = 73L, region_season = 73L,
    year_end = 0L, component_end = -1L
  )
  add_opr(
    family = "all-effect-saturation", anchor = "B02-72-all-end2",
    rationale = "Fully saturates every OPR effect at the 72-coefficient ceiling induced by a two-year endpoint.",
    year = 72L, season = 72L, region = 72L, region_season = 72L,
    year_end = 2L, component_end = 2L
  )
  add_opr(
    family = "all-effect-saturation", anchor = "B03-71-all-end3",
    rationale = "Fully saturates every OPR effect at the 71-coefficient ceiling induced by a three-year endpoint.",
    year = 71L, season = 71L, region = 71L, region_season = 71L,
    year_end = 3L, component_end = 3L
  )

  spec <- do.call(rbind, rows)
  signature_columns <- c(
    "year_effect", "season_effect", "region_effect", "region_season_effect",
    "year_end_window", "year_end_degree", "region_end_window", "region_end_degree",
    "season_end_window", "season_end_degree",
    "region_season_end_window", "region_season_end_degree"
  )
  signatures <- apply(spec[, signature_columns, drop = FALSE], 1L, paste, collapse = ":")
  if (anyDuplicated(spec$step_id) || anyDuplicated(signatures)) {
    stop("Focused OPR grid contains duplicate step IDs or control signatures", call. = FALSE)
  }
  expected_counts <- c("71" = 28L, "72" = 37L, "73" = 37L)
  actual_counts <- table(factor(spec$year_effect, levels = as.integer(names(expected_counts))))
  if (!identical(as.integer(actual_counts), unname(expected_counts))) {
    stop("Focused OPR grid annual-count balance changed unexpectedly", call. = FALSE)
  }
  if (any(spec$year_effect > 73L)) {
    stop("The 73-real-year dataset cannot support 74 OPR coefficients", call. = FALSE)
  }
  spec
}

terminal_sensitivity_control_step_ids <- function() {
  ## These two controls keep the focused result bundle self-contained. Step 11
  ## is the standard-recruitment reference; Step 12 is the current 69-01-50-50
  ## OPR production candidate. No newly generated variant uses 69.
  c("11-TimeVaryingCV", "12-OrthogonalPoly")
}

terminal_sensitivity_run_step_ids <- function(include_controls = TRUE) {
  ids <- terminal_sensitivity_model_spec()$step_id
  if (isTRUE(include_controls)) c(terminal_sensitivity_control_step_ids(), ids) else ids
}

terminal_sensitivity_hessian_nsplit <- function() {
  ## Above 50 models, use one Hessian job per fit to avoid multiplying the
  ## scheduler queue by Hessian partitions.
  if (length(terminal_sensitivity_run_step_ids()) > 50L) 1L else 2L
}

terminal_sensitivity_job_rows <- function() {
  spec <- terminal_sensitivity_model_spec()
  opr_parameter_count <-
    spec$year_effect + 3L * spec$season_effect +
    4L * spec$region_effect + 12L * spec$region_season_effect
  data.frame(
    step_id = spec$step_id,
    enabled = rep(FALSE, nrow(spec)),
    documentation_visible = rep(FALSE, nrow(spec)),
    major_step = rep("12-OPR717273TerminalSensitivity", nrow(spec)),
    substep = sub("-.*$", "", spec$step_id),
    change_axis = spec$rationale,
    model_label = spec$model_label,
    job_title = paste0("Sensitivity ", spec$step_id),
    job_key = tolower(gsub("[^A-Za-z0-9]+", "-", spec$step_id)),
    run_mode = rep("doitall", nrow(spec)),
    region_count = rep(5L, nrow(spec)),
    ## The three all-effect saturation boundaries have substantially larger
    ## OPR blocks and receive the same 12 GB fit allocation as diagnostics.
    kflow_memory = ifelse(opr_parameter_count >= 1200L, "12GB", "8GB"),
    mfcl_program_path = rep("", nrow(spec)),
    input_par = rep("", nrow(spec)),
    frq = rep("bet.frq", nrow(spec)),
    output_par = rep("", nrow(spec)),
    stringsAsFactors = FALSE
  )
}
