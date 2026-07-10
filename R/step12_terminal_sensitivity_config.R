## Model specifications for the 2024 terminal-recruitment sensitivity grid.
##
## The grid deliberately starts from the current main-branch step 11 and step
## 12 folders.  It changes only the terminal recruitment controls in doitall.
## All fishery, tag, age-length, CPUE-CV, regional-scaling, and selectivity
## inputs remain identical to the corresponding parent model.

terminal_sensitivity_model_spec <- function() {
  standard <- data.frame(
    step_id = c(
      "11b-DevEnd0",
      "11c-DevEnd1Arithmetic",
      "11d-DevEnd2Arithmetic",
      "11e-DevEnd4Arithmetic",
      "11f-DevEnd6ZeroDev"
    ),
    parent_step = rep("11-TimeVaryingCV", 5L),
    parameterization = rep("standard", 5L),
    model_label = c(
      "Devs terminal free",
      "Devs end1 arithmetic",
      "Devs end2 arithmetic",
      "Devs end4 arithmetic",
      "Devs end6 zero-dev"
    ),
    title = c(
      "11b Standard recruitment deviations: terminal periods free",
      "11c Standard recruitment deviations: one terminal quarter fixed to arithmetic mean",
      "11d Standard recruitment deviations: two terminal quarters fixed to arithmetic mean",
      "11e Standard recruitment deviations: four terminal quarters fixed to arithmetic mean",
      "11f Standard recruitment deviations: six terminal quarters fixed at zero deviation"
    ),
    rationale = c(
      "Tests whether removing the existing terminal fixed-recruitment treatment creates the OPR-like terminal spike.",
      "Tests the smallest non-zero standard terminal constraint: one quarterly recruitment period.",
      "Tests a half-year standard terminal constraint while preserving the arithmetic-mean target.",
      "Tests a one-year standard terminal constraint while preserving the arithmetic-mean target.",
      "Separates the arithmetic-mean replacement from the fixed-terminal-deviation mechanism used by the standard model."
    ),
    standard_terminal_periods = c(0L, 1L, 2L, 4L, 6L),
    standard_arithmetic_mean = c(FALSE, TRUE, TRUE, TRUE, FALSE),
    year_effect = rep(NA_integer_, 5L),
    season_effect = rep(NA_integer_, 5L),
    region_effect = rep(NA_integer_, 5L),
    region_season_effect = rep(NA_integer_, 5L),
    year_end_window = rep(NA_integer_, 5L),
    year_end_degree = rep(NA_integer_, 5L),
    region_end_window = rep(NA_integer_, 5L),
    region_end_degree = rep(NA_integer_, 5L),
    season_end_window = rep(NA_integer_, 5L),
    season_end_degree = rep(NA_integer_, 5L),
    region_season_end_window = rep(NA_integer_, 5L),
    region_season_end_degree = rep(NA_integer_, 5L),
    stringsAsFactors = FALSE
  )

  opr_row <- function(step_id, model_label, title, rationale,
                      year = 69L, season = 1L, region = 50L, region_season = 50L,
                      year_end = 2L, year_degree = 0L,
                      region_end = year_end, region_degree = year_degree,
                      season_end = year_end, season_degree = year_degree,
                      region_season_end = year_end, region_season_degree = year_degree) {
    data.frame(
      step_id = step_id,
      parent_step = "12-OrthogonalPoly",
      parameterization = "opr",
      model_label = model_label,
      title = title,
      rationale = rationale,
      standard_terminal_periods = NA_integer_,
      standard_arithmetic_mean = NA,
      year_effect = as.integer(year),
      season_effect = as.integer(season),
      region_effect = as.integer(region),
      region_season_effect = as.integer(region_season),
      year_end_window = as.integer(year_end),
      year_end_degree = as.integer(year_degree),
      region_end_window = as.integer(region_end),
      region_end_degree = as.integer(region_degree),
      season_end_window = as.integer(season_end),
      season_end_degree = as.integer(season_degree),
      region_season_end_window = as.integer(region_season_end),
      region_season_end_degree = as.integer(region_season_degree),
      stringsAsFactors = FALSE
    )
  }

  ## Endpoint and annual-saturation mechanisms.
  endpoint_grid <- list(
    opr_row("12b-OPR69YearEnd0", "OPR 69 year-end0", "12b OPR: annual endpoint disabled, non-annual endpoints retained at two years", "Separates the annual terminal tie from the existing two-year regional, seasonal, and season-by-region endpoint ties.", year_end = 0L, region_end = 2L, season_end = 2L, region_season_end = 2L),
    opr_row("12c-OPR69AllEnd0", "OPR 69 all-end0", "12c OPR: no multi-year endpoint ties for all recruitment effects", "Tests whether removing all multi-year endpoint pooling, rather than the annual endpoint alone, changes the terminal spike.", year_end = 0L, region_end = -1L, season_end = -1L, region_season_end = -1L, region_degree = 0L, season_degree = 0L, region_season_degree = 0L),
    opr_row("12d-OPR69AllEnd3", "OPR 69 all-end3", "12d OPR: all recruitment effects share a three-year endpoint", "Tests the smallest all-component extension that visibly suppresses the spike in the earlier screen.", year_end = 3L),
    opr_row("12e-OPR69AllEnd4", "OPR 69 all-end4", "12e OPR: all recruitment effects share a four-year endpoint", "Tests a longer all-component endpoint while retaining one annual degree below the constrained saturation ceiling.", year_end = 4L),
    opr_row("12f-OPR69AllEnd5", "OPR 69 all-end5", "12f OPR: all recruitment effects share a five-year endpoint", "Tests the constrained annual-saturation case: 69 coefficients with five terminal real years pooled.", year_end = 5L),
    opr_row("12g-OPR73YearEnd0", "OPR 73 year-end0", "12g OPR: saturated annual effect with annual endpoint disabled", "Tests 73 independent annual coefficients; non-annual effects retain their two-year endpoint controls.", year = 73L, year_end = 0L, region_end = 2L, season_end = 2L, region_season_end = 2L),
    opr_row("12h-OPR72AllEnd2", "OPR 72 all-end2", "12h OPR: saturated annual effect conditional on a two-year endpoint", "Tests the annual saturation ceiling for 73 years with a two-year endpoint: 72 coefficients.", year = 72L, year_end = 2L),
    opr_row("12i-OPR71AllEnd3", "OPR 71 all-end3", "12i OPR: saturated annual effect conditional on a three-year endpoint", "Tests the annual saturation ceiling for 73 years with a three-year endpoint: 71 coefficients.", year = 71L, year_end = 3L),
    opr_row("12j-OPR70AllEnd4", "OPR 70 all-end4", "12j OPR: saturated annual effect conditional on a four-year endpoint", "Tests the annual saturation ceiling for 73 years with a four-year endpoint: 70 coefficients.", year = 70L, year_end = 4L),
    opr_row("12k-OPR69AllEnd3Degree2", "OPR 69 end3 degree2", "12k OPR: three-year endpoint with linear annual and component trends retained", "Allows the linear basis term to vary across the three-year endpoint while flattening quadratic and higher terms.", year_end = 3L, year_degree = 2L),
    opr_row("12l-OPR69AllEnd3Degree3", "OPR 69 end3 degree3", "12l OPR: three-year endpoint with linear and quadratic trends retained", "Allows linear and quadratic basis terms to vary across the three-year endpoint while flattening cubic and higher terms.", year_end = 3L, year_degree = 3L),
    opr_row("12m-OPR69YearEnd3", "OPR 69 year-end3", "12m OPR: extend only the annual effect endpoint to three years", "Identifies whether extending only the common annual recruitment signal removes the spike with less scale movement.", year_end = 3L, region_end = 2L, season_end = 2L, region_season_end = 2L),
    opr_row("12n-OPR69RegionEnd3", "OPR 69 region-end3", "12n OPR: extend only the regional effect endpoint to three years", "Identifies whether the regional OPR temporal basis, rather than the annual basis, drives the terminal behavior.", year_end = 2L, region_end = 3L, season_end = 2L, region_season_end = 2L),
    opr_row("12o-OPR69SeasonEnd3", "OPR 69 season-end3", "12o OPR: extend only the seasonal effect endpoint to three years", "Identifies whether the seasonal OPR temporal basis drives the terminal behavior.", year_end = 2L, region_end = 2L, season_end = 3L, region_season_end = 2L),
    opr_row("12p-OPR69SeasonRegionEnd3", "OPR 69 season-region-end3", "12p OPR: extend only the season-by-region endpoint to three years", "Identifies whether the large season-by-region OPR temporal basis drives the terminal behavior.", year_end = 2L, region_end = 2L, season_end = 2L, region_season_end = 3L)
  )

  ## Settings retained from the original BET OPR screening family.
  screening_grid <- list(
    opr_row("12q-OPR69Season5End2", "OPR 69-05-50-50 end2", "12q OPR: 69-05-50-50 with two-year endpoint", "Tests the screening season-effect alternative without changing regional complexity.", season = 5L, year_end = 2L),
    opr_row("12r-OPR69Season5End3", "OPR 69-05-50-50 end3", "12r OPR: 69-05-50-50 with three-year endpoint", "Tests whether the seasonal-effect alternative needs a longer shared endpoint to avoid the terminal spike.", season = 5L, year_end = 3L),
    opr_row("12s-OPR69Season5End4", "OPR 69-05-50-50 end4", "12s OPR: 69-05-50-50 with four-year endpoint", "Separates added seasonal flexibility from a stronger endpoint treatment.", season = 5L, year_end = 4L),
    opr_row("12t-OPR69Region60End2", "OPR 69-01-60-60 end2", "12t OPR: 69-01-60-60 with two-year endpoint", "Tests the screening regional and season-by-region complexity alternative at the reference endpoint.", region = 60L, region_season = 60L, year_end = 2L),
    opr_row("12u-OPR69Region60End3", "OPR 69-01-60-60 end3", "12u OPR: 69-01-60-60 with three-year endpoint", "Tests whether the higher regional complexity needs a longer shared endpoint.", region = 60L, region_season = 60L, year_end = 3L),
    opr_row("12v-OPR69Region60End4", "OPR 69-01-60-60 end4", "12v OPR: 69-01-60-60 with four-year endpoint", "Separates high regional flexibility from the strongest pre-saturation endpoint in this family.", region = 60L, region_season = 60L, year_end = 4L),
    opr_row("12w-OPR69Season5Region60End2", "OPR 69-05-60-60 end2", "12w OPR: 69-05-60-60 with two-year endpoint", "Tests the combined high-season and high-regional screening alternative at the reference endpoint.", season = 5L, region = 60L, region_season = 60L, year_end = 2L),
    opr_row("12x-OPR69Season5Region60End3", "OPR 69-05-60-60 end3", "12x OPR: 69-05-60-60 with three-year endpoint", "Tests whether a three-year endpoint stabilizes the combined high-flexibility screening setting.", season = 5L, region = 60L, region_season = 60L, year_end = 3L),
    opr_row("12y-OPR69Season5Region60End4", "OPR 69-05-60-60 end4", "12y OPR: 69-05-60-60 with four-year endpoint", "Tests the combined high-flexibility setting with the longer endpoint treatment.", season = 5L, region = 60L, region_season = 60L, year_end = 4L)
  )

  ## Annual parameter-count grid: the main OPR reduction / Hessian trade-off.
  annual_count_grid <- list(
    opr_row("12z-OPR55AllEnd2", "OPR 55-01-50-50 end2", "12z OPR: 55 annual coefficients with two-year endpoint", "Tests a materially smaller annual OPR block for Hessian conditioning and terminal stability.", year = 55L, year_end = 2L),
    opr_row("12aa-OPR60AllEnd2", "OPR 60-01-50-50 end2", "12aa OPR: 60 annual coefficients with two-year endpoint", "Tests a moderate annual parameter reduction at the reference endpoint.", year = 60L, year_end = 2L),
    opr_row("12ab-OPR65AllEnd2", "OPR 65-01-50-50 end2", "12ab OPR: 65 annual coefficients with two-year endpoint", "Tests a small annual parameter reduction at the reference endpoint.", year = 65L, year_end = 2L),
    opr_row("12ac-OPR70AllEnd2", "OPR 70-01-50-50 end2", "12ac OPR: 70 annual coefficients with two-year endpoint", "Tests increased annual flexibility short of the two-year endpoint saturation ceiling.", year = 70L, year_end = 2L),
    opr_row("12ae-OPR55AllEnd3", "OPR 55-01-50-50 end3", "12ae OPR: 55 annual coefficients with three-year endpoint", "Tests whether a smaller annual block plus endpoint pooling improves Hessian conditioning without large scale change.", year = 55L, year_end = 3L),
    opr_row("12af-OPR60AllEnd3", "OPR 60-01-50-50 end3", "12af OPR: 60 annual coefficients with three-year endpoint", "Tests a moderate annual reduction with the minimum all-component endpoint extension.", year = 60L, year_end = 3L),
    opr_row("12ag-OPR65AllEnd3", "OPR 65-01-50-50 end3", "12ag OPR: 65 annual coefficients with three-year endpoint", "Tests a small annual reduction with three-year endpoint pooling.", year = 65L, year_end = 3L),
    opr_row("12ah-OPR70AllEnd3", "OPR 70-01-50-50 end3", "12ah OPR: 70 annual coefficients with three-year endpoint", "Tests high annual flexibility one coefficient below the three-year saturation ceiling.", year = 70L, year_end = 3L),
    opr_row("12ai-OPR71AllEnd3Degree2", "OPR 71-01-50-50 end3 degree2", "12ai OPR: 71 annual coefficients with three-year endpoint and retained linear terms", "Separates the three-year saturation ceiling from the default all-high-order-term endpoint flattening.", year = 71L, year_end = 3L, year_degree = 2L)
  )

  ## Regional, interaction, and seasonal complexity grid.  These use only
  ## values below the 73-year endpoint-constrained capacity.
  component_count_grid <- list(
    opr_row("12aj-OPR69Reg40Int40End2", "OPR 69-01-40-40 end2", "12aj OPR: low regional and interaction complexity with two-year endpoint", "Tests a deliberate regional and season-by-region parameter reduction at the reference endpoint.", region = 40L, region_season = 40L, year_end = 2L),
    opr_row("12ak-OPR69Reg40Int40End3", "OPR 69-01-40-40 end3", "12ak OPR: low regional and interaction complexity with three-year endpoint", "Tests low regional complexity together with the minimal all-component endpoint extension.", region = 40L, region_season = 40L, year_end = 3L),
    opr_row("12al-OPR69Reg45Int45End2", "OPR 69-01-45-45 end2", "12al OPR: intermediate-low regional and interaction complexity with two-year endpoint", "Provides an intermediate parameter-count check between 40-40 and the screening 50-50 setting.", region = 45L, region_season = 45L, year_end = 2L),
    opr_row("12am-OPR69Reg45Int45End3", "OPR 69-01-45-45 end3", "12am OPR: intermediate-low regional and interaction complexity with three-year endpoint", "Separates the intermediate regional parameter count from endpoint pooling.", region = 45L, region_season = 45L, year_end = 3L),
    opr_row("12an-OPR69Reg40Int50End2", "OPR 69-01-40-50 end2", "12an OPR: reduce regional but retain interaction complexity at two-year endpoint", "Identifies whether regional coefficients, rather than interaction coefficients, are the main Hessian burden.", region = 40L, region_season = 50L, year_end = 2L),
    opr_row("12ao-OPR69Reg40Int50End3", "OPR 69-01-40-50 end3", "12ao OPR: reduce regional but retain interaction complexity at three-year endpoint", "Tests the same regional-only reduction under endpoint pooling.", region = 40L, region_season = 50L, year_end = 3L),
    opr_row("12ap-OPR69Reg50Int40End2", "OPR 69-01-50-40 end2", "12ap OPR: retain regional but reduce interaction complexity at two-year endpoint", "Identifies whether the large season-by-region block is the main Hessian burden.", region = 50L, region_season = 40L, year_end = 2L),
    opr_row("12aq-OPR69Reg50Int40End3", "OPR 69-01-50-40 end3", "12aq OPR: retain regional but reduce interaction complexity at three-year endpoint", "Tests the interaction-only reduction under endpoint pooling.", region = 50L, region_season = 40L, year_end = 3L),
    opr_row("12ar-OPR69Reg60Int50End2", "OPR 69-01-60-50 end2", "12ar OPR: increase regional but retain interaction complexity at two-year endpoint", "Separates regional complexity from the interaction block in the high-regional direction.", region = 60L, region_season = 50L, year_end = 2L),
    opr_row("12as-OPR69Reg60Int50End3", "OPR 69-01-60-50 end3", "12as OPR: increase regional but retain interaction complexity at three-year endpoint", "Tests the regional-only increase under endpoint pooling.", region = 60L, region_season = 50L, year_end = 3L),
    opr_row("12at-OPR69Reg50Int60End2", "OPR 69-01-50-60 end2", "12at OPR: retain regional but increase interaction complexity at two-year endpoint", "Separates interaction complexity from the regional block in the high-interaction direction.", region = 50L, region_season = 60L, year_end = 2L),
    opr_row("12au-OPR69Reg50Int60End3", "OPR 69-01-50-60 end3", "12au OPR: retain regional but increase interaction complexity at three-year endpoint", "Tests the interaction-only increase under endpoint pooling.", region = 50L, region_season = 60L, year_end = 3L),
    opr_row("12av-OPR69Season3End2", "OPR 69-03-50-50 end2", "12av OPR: intermediate seasonal complexity with two-year endpoint", "Tests an intermediate seasonal coefficient count between the screening 01 and 05 settings.", season = 3L, year_end = 2L),
    opr_row("12aw-OPR69Season3End3", "OPR 69-03-50-50 end3", "12aw OPR: intermediate seasonal complexity with three-year endpoint", "Separates intermediate seasonal complexity from endpoint pooling.", season = 3L, year_end = 3L),
    opr_row("12ax-OPR69Season7End2", "OPR 69-07-50-50 end2", "12ax OPR: high seasonal complexity with two-year endpoint", "Tests seasonal flexibility beyond the original 05 screening setting while holding regional effects at the rank-1 values.", season = 7L, year_end = 2L)
  )

  ## Broad but structured envelope.  These models span parsimonious OPR
  ## decompositions, a high-complexity 69-69-69-69 envelope, and the valid
  ## endpoint-specific all-effect saturation limits.  Every count is at or
  ## below the 73-year capacity enforced by MFCL neworth.cpp.
  broad_complexity_grid <- list(
    opr_row("12ay-OPR69Reg1Int1End2", "OPR 69-01-01-01 end2", "12ay OPR: 69-01-01-01 with two-year endpoint", "Tests a strongly parsimonious regional and season-by-region OPR decomposition while retaining the rank-1 annual and seasonal counts.", region = 1L, region_season = 1L, year_end = 2L),
    opr_row("12az-OPR69Reg1Int1End3", "OPR 69-01-01-01 end3", "12az OPR: 69-01-01-01 with three-year endpoint", "Tests whether endpoint pooling preserves fit in the most parsimonious regional OPR decomposition.", region = 1L, region_season = 1L, year_end = 3L),
    opr_row("12ba-OPR69Reg10Int10End2", "OPR 69-01-10-10 end2", "12ba OPR: 69-01-10-10 with two-year endpoint", "Tests a low-but-flexible regional and interaction block between 01-01 and 40-40.", region = 10L, region_season = 10L, year_end = 2L),
    opr_row("12bb-OPR69Reg10Int10End3", "OPR 69-01-10-10 end3", "12bb OPR: 69-01-10-10 with three-year endpoint", "Separates low regional/interaction complexity from endpoint pooling.", region = 10L, region_season = 10L, year_end = 3L),
    opr_row("12bc-OPR69Reg25Int25End2", "OPR 69-01-25-25 end2", "12bc OPR: 69-01-25-25 with two-year endpoint", "Tests a mid-low regional and interaction parameter count at the reference endpoint.", region = 25L, region_season = 25L, year_end = 2L),
    opr_row("12bd-OPR69Reg25Int25End3", "OPR 69-01-25-25 end3", "12bd OPR: 69-01-25-25 with three-year endpoint", "Tests the same mid-low regional setting with the minimal shared endpoint extension.", region = 25L, region_season = 25L, year_end = 3L),

    opr_row("12be-OPR69All69End2", "OPR 69-69-69-69 end2", "12be OPR: 69-69-69-69 with two-year endpoint", "Tests a high-complexity OPR envelope while retaining a valid two-year endpoint-constrained basis.", season = 69L, region = 69L, region_season = 69L, year_end = 2L),
    opr_row("12bf-OPR73All73End0", "OPR 73-73-73-73 end0", "12bf OPR: all effects saturated with no multi-year endpoint ties", "Tests the fully saturated 73-year OPR envelope with one-point endpoints. It is intentionally a high-flexibility boundary model, not a preferred production candidate.", year = 73L, season = 73L, region = 73L, region_season = 73L, year_end = 0L, region_end = -1L, season_end = -1L, region_season_end = -1L, region_degree = 0L, season_degree = 0L, region_season_degree = 0L),
    opr_row("12bg-OPR72All72End2", "OPR 72-72-72-72 end2", "12bg OPR: all effects saturated conditional on two-year endpoint", "Tests the all-effect saturation ceiling under a two-year endpoint; 72 is the MFCL-valid maximum coefficient count for each effect.", year = 72L, season = 72L, region = 72L, region_season = 72L, year_end = 2L),
    opr_row("12bh-OPR71All71End3", "OPR 71-71-71-71 end3", "12bh OPR: all effects saturated conditional on three-year endpoint", "Tests the all-effect saturation ceiling under a three-year endpoint.", year = 71L, season = 71L, region = 71L, region_season = 71L, year_end = 3L),
    opr_row("12bi-OPR70All70End4", "OPR 70-70-70-70 end4", "12bi OPR: all effects saturated conditional on four-year endpoint", "Tests the all-effect saturation ceiling under a four-year endpoint.", year = 70L, season = 70L, region = 70L, region_season = 70L, year_end = 4L),
    opr_row("12bj-OPR69All69End5", "OPR 69-69-69-69 end5", "12bj OPR: all effects saturated conditional on five-year endpoint", "Tests the all-effect saturation ceiling under a five-year endpoint, matching 69 coefficients to 69 effective annual points.", season = 69L, region = 69L, region_season = 69L, year_end = 5L),

    opr_row("12bk-OPR69Season10End2", "OPR 69-10-50-50 end2", "12bk OPR: 10 seasonal coefficients with two-year endpoint", "Extends the seasonal-effect axis beyond the 01 and 05 screening values while holding all other rank-1 settings fixed.", season = 10L, year_end = 2L),
    opr_row("12bl-OPR69Season10End3", "OPR 69-10-50-50 end3", "12bl OPR: 10 seasonal coefficients with three-year endpoint", "Tests seasonal complexity 10 together with endpoint pooling.", season = 10L, year_end = 3L),
    opr_row("12bm-OPR69Season25End2", "OPR 69-25-50-50 end2", "12bm OPR: 25 seasonal coefficients with two-year endpoint", "Tests a mid-high seasonal block at the reference endpoint.", season = 25L, year_end = 2L),
    opr_row("12bn-OPR69Season25End3", "OPR 69-25-50-50 end3", "12bn OPR: 25 seasonal coefficients with three-year endpoint", "Separates a mid-high seasonal block from endpoint pooling.", season = 25L, year_end = 3L),
    opr_row("12bo-OPR69Season50End2", "OPR 69-50-50-50 end2", "12bo OPR: 50 seasonal coefficients with two-year endpoint", "Tests high seasonal flexibility while retaining the rank-1 regional and interaction blocks.", season = 50L, year_end = 2L),
    opr_row("12bp-OPR69Season50End3", "OPR 69-50-50-50 end3", "12bp OPR: 50 seasonal coefficients with three-year endpoint", "Tests high seasonal flexibility under endpoint pooling.", season = 50L, year_end = 3L),
    opr_row("12bq-OPR69Season69End2", "OPR 69-69-50-50 end2", "12bq OPR: 69 seasonal coefficients with two-year endpoint", "Tests the near-saturated seasonal-effect extreme while regional and interaction counts stay at the rank-1 values.", season = 69L, year_end = 2L),
    opr_row("12br-OPR69Season69End3", "OPR 69-69-50-50 end3", "12br OPR: 69 seasonal coefficients with three-year endpoint", "Tests the near-saturated seasonal-effect extreme under endpoint pooling.", season = 69L, year_end = 3L),

    opr_row("12bs-OPR69Reg1Int50End2", "OPR 69-01-01-50 end2", "12bs OPR: minimal region block with rank-1 interaction block", "Separates a near-minimal regional temporal basis from the baseline season-by-region interaction basis.", region = 1L, region_season = 50L, year_end = 2L),
    opr_row("12bt-OPR69Reg1Int50End3", "OPR 69-01-01-50 end3", "12bt OPR: minimal region block with rank-1 interaction block and three-year endpoint", "Tests whether endpoint pooling compensates for the minimal regional temporal basis.", region = 1L, region_season = 50L, year_end = 3L),
    opr_row("12bu-OPR69Reg10Int50End2", "OPR 69-01-10-50 end2", "12bu OPR: low region block with rank-1 interaction block", "Locates the regional-complexity threshold while leaving the interaction block unchanged.", region = 10L, region_season = 50L, year_end = 2L),
    opr_row("12bv-OPR69Reg10Int50End3", "OPR 69-01-10-50 end3", "12bv OPR: low region block with rank-1 interaction block and three-year endpoint", "Separates low regional complexity from endpoint pooling.", region = 10L, region_season = 50L, year_end = 3L),
    opr_row("12bw-OPR69Reg25Int50End2", "OPR 69-01-25-50 end2", "12bw OPR: mid-low region block with rank-1 interaction block", "Tests a mid-low regional block while retaining baseline interaction flexibility.", region = 25L, region_season = 50L, year_end = 2L),
    opr_row("12bx-OPR69Reg25Int50End3", "OPR 69-01-25-50 end3", "12bx OPR: mid-low region block with rank-1 interaction block and three-year endpoint", "Tests the same regional threshold under endpoint pooling.", region = 25L, region_season = 50L, year_end = 3L),
    opr_row("12by-OPR69Reg69Int50End2", "OPR 69-01-69-50 end2", "12by OPR: near-saturated region block with rank-1 interaction block", "Tests the high regional-complexity extreme separately from the interaction block.", region = 69L, region_season = 50L, year_end = 2L),
    opr_row("12bz-OPR69Reg69Int50End3", "OPR 69-01-69-50 end3", "12bz OPR: near-saturated region block with rank-1 interaction block and three-year endpoint", "Tests high regional complexity with endpoint pooling.", region = 69L, region_season = 50L, year_end = 3L),
    opr_row("12ca-OPR69Reg50Int1End2", "OPR 69-01-50-01 end2", "12ca OPR: rank-1 region block with minimal interaction block", "Tests whether most interaction temporal flexibility can be removed while retaining the rank-1 regional block.", region = 50L, region_season = 1L, year_end = 2L),
    opr_row("12cb-OPR69Reg50Int1End3", "OPR 69-01-50-01 end3", "12cb OPR: rank-1 region block with minimal interaction block and three-year endpoint", "Tests minimal interaction complexity under endpoint pooling.", region = 50L, region_season = 1L, year_end = 3L),
    opr_row("12cc-OPR69Reg50Int10End2", "OPR 69-01-50-10 end2", "12cc OPR: rank-1 region block with low interaction block", "Locates the interaction-complexity threshold while retaining baseline regional flexibility.", region = 50L, region_season = 10L, year_end = 2L),
    opr_row("12cd-OPR69Reg50Int10End3", "OPR 69-01-50-10 end3", "12cd OPR: rank-1 region block with low interaction block and three-year endpoint", "Tests low interaction complexity under endpoint pooling.", region = 50L, region_season = 10L, year_end = 3L),

    opr_row("12ce-OPR69Season5Reg10Int10End2", "OPR 69-05-10-10 end2", "12ce OPR: seasonal 05 with low regional and interaction blocks", "Tests the screening seasonal alternative in a parsimonious regional decomposition.", season = 5L, region = 10L, region_season = 10L, year_end = 2L),
    opr_row("12cf-OPR69Season5Reg10Int10End3", "OPR 69-05-10-10 end3", "12cf OPR: seasonal 05 with low regional and interaction blocks and three-year endpoint", "Tests the same parsimonious seasonal alternative under endpoint pooling.", season = 5L, region = 10L, region_season = 10L, year_end = 3L),
    opr_row("12cg-OPR69Season5Reg25Int25End2", "OPR 69-05-25-25 end2", "12cg OPR: seasonal 05 with mid-low regional and interaction blocks", "Tests a balanced mid-low complexity alternative to the screening 05-50-50 setting.", season = 5L, region = 25L, region_season = 25L, year_end = 2L),
    opr_row("12ch-OPR69Season5Reg25Int25End3", "OPR 69-05-25-25 end3", "12ch OPR: seasonal 05 with mid-low regional and interaction blocks and three-year endpoint", "Tests the balanced mid-low alternative under endpoint pooling.", season = 5L, region = 25L, region_season = 25L, year_end = 3L),
    opr_row("12ci-OPR69Season5Reg40Int40End2", "OPR 69-05-40-40 end2", "12ci OPR: seasonal 05 with reduced regional and interaction blocks", "Tests an intermediate high-season model with fewer regional and interaction coefficients than the screening 05-50-50 setting.", season = 5L, region = 40L, region_season = 40L, year_end = 2L),
    opr_row("12cj-OPR69Season5Reg40Int40End3", "OPR 69-05-40-40 end3", "12cj OPR: seasonal 05 with reduced regional and interaction blocks and three-year endpoint", "Tests this intermediate high-season model under endpoint pooling.", season = 5L, region = 40L, region_season = 40L, year_end = 3L),
    opr_row("12ck-OPR69Season5Reg69Int69End2", "OPR 69-05-69-69 end2", "12ck OPR: seasonal 05 with near-saturated regional and interaction blocks", "Tests a high regional-complexity seasonal-05 envelope below the two-year capacity ceiling.", season = 5L, region = 69L, region_season = 69L, year_end = 2L),
    opr_row("12cl-OPR69Season5Reg69Int69End3", "OPR 69-05-69-69 end3", "12cl OPR: seasonal 05 with near-saturated regional and interaction blocks and three-year endpoint", "Tests the high regional-complexity seasonal-05 envelope under endpoint pooling.", season = 5L, region = 69L, region_season = 69L, year_end = 3L)
  )

  opr <- do.call(rbind, c(
    endpoint_grid,
    screening_grid,
    annual_count_grid,
    component_count_grid,
    broad_complexity_grid
  ))

  rbind(standard, opr)
}

terminal_sensitivity_control_step_ids <- function() {
  c("11-TimeVaryingCV", "12-OrthogonalPoly")
}

terminal_sensitivity_run_step_ids <- function(include_controls = TRUE) {
  ids <- terminal_sensitivity_model_spec()$step_id
  if (isTRUE(include_controls)) c(terminal_sensitivity_control_step_ids(), ids) else ids
}

terminal_sensitivity_hessian_nsplit <- function() {
  # Scheduler policy agreed for this deliberately broad grid: above 50 models,
  # keep one Hessian job per fitted model rather than multiplying the queue by
  # per-model partitions. The fallback preserves two parts for smaller grids.
  if (length(terminal_sensitivity_run_step_ids()) > 50L) 1L else 2L
}

terminal_sensitivity_job_rows <- function() {
  spec <- terminal_sensitivity_model_spec()
  is_standard <- spec$parameterization == "standard"
  opr_parameter_count <- ifelse(
    is_standard,
    0L,
    spec$year_effect + 3L * spec$season_effect + 4L * spec$region_effect + 12L * spec$region_season_effect
  )
  data.frame(
    step_id = spec$step_id,
    enabled = rep(FALSE, nrow(spec)),
    documentation_visible = rep(FALSE, nrow(spec)),
    major_step = ifelse(is_standard, "11-TerminalRecruitmentSensitivity", "12-OPRTerminalSensitivity"),
    substep = sub("-.*$", "", spec$step_id),
    change_axis = spec$rationale,
    model_label = spec$model_label,
    job_title = paste0("Sensitivity ", spec$step_id),
    job_key = tolower(gsub("[^A-Za-z0-9]+", "-", spec$step_id)),
    run_mode = rep("doitall", nrow(spec)),
    region_count = rep(5L, nrow(spec)),
    # The all-effect saturation boundary cases have substantially larger OPR
    # blocks. They receive the same 12 GB fit allocation as the diagnostic
    # Hessian task; ordinary sensitivity fits retain the proven 8 GB setting.
    kflow_memory = ifelse(opr_parameter_count >= 1200L, "12GB", "8GB"),
    mfcl_program_path = rep("", nrow(spec)),
    input_par = rep("", nrow(spec)),
    frq = rep("bet.frq", nrow(spec)),
    output_par = rep("", nrow(spec)),
    stringsAsFactors = FALSE
  )
}
