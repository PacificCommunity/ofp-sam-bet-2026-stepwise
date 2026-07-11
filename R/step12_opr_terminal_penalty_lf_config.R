## Curated Step 11/12 sensitivity design for terminal recruitment, length-fit
## controls, composition weights, and recent tagging assumptions.
##
## The grid is deliberately staged rather than Cartesian. The primary OPR
## counts are 73, 72, and 71; the older OPR69 setting appears only once as the
## supplied numerical benchmark. All generated fits use a matched 1,000-
## evaluation final phase and are independent Kflow jobs.

opr_terminal_penalty_lf_generator_marker <- function() {
  ".opr-terminal-penalty-lf-generated"
}

opr_terminal_penalty_lf_generated_step_name <- function(path) {
  grepl("^(11|12)p[0-9]{3}-[A-Za-z0-9][A-Za-z0-9-]*$", basename(path))
}

opr_terminal_penalty_lf_generated_step_dir <- function(path) {
  if (!dir.exists(path) || !opr_terminal_penalty_lf_generated_step_name(path)) return(FALSE)

  marker <- file.path(path, opr_terminal_penalty_lf_generator_marker())
  if (file.exists(marker)) {
    value <- readLines(marker, warn = FALSE, n = 1L)
    return(length(value) == 1L && identical(value, "opr-terminal-penalty-lf-generator-v1"))
  }

  ## Compatibility for folders produced before the marker was introduced.
  ## Both generator-specific lines are required, so an arbitrary manually
  ## maintained 11p/12p folder is never classified from its name alone.
  patch <- file.path(path, "patch.R")
  if (!file.exists(patch)) return(FALSE)
  lines <- readLines(patch, warn = FALSE)
  identical(lines[seq_len(min(3L, length(lines)))], c(
    "## Generated thin patch: the parent model is staged before this file runs.",
    "source(file.path(root, \"R\", \"apply_opr_terminal_penalty_lf_patch.R\"), local = TRUE)",
    "apply_opr_terminal_penalty_lf_patch(model_dir, step_id, root = root)"
  ))
}

opr_terminal_penalty_lf_cleanup_generated_steps <- function(steps_dir) {
  if (!dir.exists(steps_dir)) return(character())
  candidates <- list.dirs(steps_dir, full.names = TRUE, recursive = FALSE)
  generated <- candidates[vapply(candidates, opr_terminal_penalty_lf_generated_step_dir, logical(1L))]
  if (length(generated)) {
    status <- vapply(generated, unlink, integer(1L), recursive = TRUE, force = TRUE)
    failed <- generated[status != 0L]
    if (length(failed)) {
      stop(
        "Could not remove generated step folder(s): ",
        paste(basename(failed), collapse = ", "),
        call. = FALSE
      )
    }
  }
  basename(generated)
}

opr_terminal_penalty_lf_model_spec <- function() {
  rows <- list()
  opr_index <- 0L
  std_index <- 0L

  ## The reviewed LF treatment is propagated across shared-selectivity groups
  ## throughout the curated grid, as required by the MFCL flag-24 grouping
  ## rule. Baseline and exact-five-fishery-only rows are explicit comparators.
  template <- list(
    step_id = "",
    parent_step = "12-OrthogonalPoly",
    parameterization = "opr",
    family = "",
    anchor = "",
    model_label = "",
    job_title = "",
    rationale = "",
    opr_year_coefficients = 73L,
    opr_legacy_year_override = 0L,
    opr_season_coefficients = 1L,
    opr_region_coefficients = 50L,
    opr_interaction_coefficients = 50L,
    terminal_years = 1L,
    component_terminal_years = 0L,
    terminal_penalty_weight = 0,
    terminal_penalty_flag = 0L,
    fish_profile = "group_consistent",
    length_comp_divisor = 0L,
    tag_weight_flag = 0L,
    tag_likelihood = "negative_binomial",
    estimate_tag_dispersion = FALSE,
    remove_2021_tags = FALSE,
    tag_deletion = "none",
    rr_2021_scope = "shared",
    rr_2021_target = NA_real_,
    rr_2021_penalty = NA_real_,
    tag_loss_mode = "none",
    tag_loss_rate = 0,
    tag_rr_mixing_mode = "inherited",
    tag_2021_mixing_period = NA_integer_,
    trend_flag = 0L,
    standard_terminal_quarters = NA_integer_,
    standard_arithmetic_mean = NA,
    benchmark_protocol = FALSE,
    benchmark_label = "curated-matched-1000-evaluation",
    final_candidate = FALSE,
    expected_final_par = "12.par"
  )

  add_row <- function(values) {
    row <- utils::modifyList(template, values)
    if (!nzchar(row$step_id)) {
      if (identical(row$parameterization, "opr")) {
        opr_index <<- opr_index + 1L
        row$step_id <- sprintf("12p%03d-%s", opr_index, row$anchor)
      } else {
        std_index <<- std_index + 1L
        row$step_id <- sprintf("11p%03d-%s", std_index, row$anchor)
      }
    }
    if (!nzchar(row$model_label)) row$model_label <- row$anchor
    if (!nzchar(row$job_title)) row$job_title <- paste("Sensitivity", row$anchor)
    row$terminal_penalty_flag <- as.integer(round(10 * row$terminal_penalty_weight))
    rows[[length(rows) + 1L]] <<- as.data.frame(
      row,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    invisible(NULL)
  }

  opr_label <- function(year, endpoint, weight, fish = "group_consistent") {
    fish_text <- switch(
      fish,
      review_exact = "exact five-fishery-only LF controls",
      baseline = "current LF controls",
      group_consistent = "reviewed group-consistent LF controls",
      large_fish_group = "isolated large-fish-tail controls",
      young_age = "isolated young-age controls",
      f17_group = "isolated F17/F18 upper-age controls",
      fish
    )
    sprintf("OPR%d-01-50-50 E%d weight %g; %s", year, endpoint, weight, fish_text)
  }

  ## A. One-year endpoint: annual OPR count by terminal-penalty strength.
  ## OPR73 is the maximum supported count for an endpoint of at least one
  ## calendar year; 72 and 71 retain one and two degrees of smoothing.
  for (year in c(73L, 72L, 71L)) {
    for (weight in c(0, 25, 50, 100, 200)) {
      add_row(list(
        family = "annual-count-penalty",
        anchor = sprintf("Y%d-E1-W%03d-FGroup", year, as.integer(weight)),
        model_label = opr_label(year, 1L, weight),
        rationale = sprintf(
          paste0(
            "Tests %d annual OPR coefficients with a one-calendar-year endpoint and terminal-recruitment penalty weight %g. ",
            "The reviewed controls are held constant across shared selectivity groups, and every case receives the same 1,000-evaluation phase; weight zero is the matched optimisation control."
          ),
          year, weight
        ),
        opr_year_coefficients = year,
        terminal_years = 1L,
        component_terminal_years = 0L,
        terminal_penalty_weight = weight
      ))
    }
  }

  ## B. Longer endpoints reduce the maximum supported annual OPR count. The
  ## valid maxima are 72 for E2 and 71 for E3, so invalid saturated cases are
  ## intentionally absent.
  for (endpoint in c(2L, 3L)) {
    years <- if (endpoint == 2L) c(72L, 71L) else 71L
    for (year in years) {
      for (weight in c(0, 100, 200)) {
        add_row(list(
          family = "longer-terminal-window",
          anchor = sprintf("Y%d-E%d-W%03d-FGroup", year, endpoint, as.integer(weight)),
          model_label = opr_label(year, endpoint, weight),
          rationale = sprintf(
            paste0(
              "Tests %d annual OPR coefficients with a %d-calendar-year endpoint and penalty weight %g. ",
              "This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter."
            ),
            year, endpoint, weight
          ),
          opr_year_coefficients = year,
          terminal_years = endpoint,
          component_terminal_years = 0L,
          terminal_penalty_weight = weight
        ))
      }
    }
  }

  ## C. Endpoint-free controls retain the same near-saturated annual counts
  ## while disabling multi-year component pooling. The terminal penalty must
  ## remain off because parest_flag(202)=0.
  for (year in c(73L, 72L, 71L)) {
    add_row(list(
      family = "endpoint-free-control",
      anchor = sprintf("Y%d-E0-W000-FGroup", year),
      model_label = opr_label(year, 0L, 0),
      rationale = sprintf(
        paste0(
          "Uses %d annual OPR coefficients with no annual terminal endpoint and component endpoint flags set to -1. ",
          "This is the direct no-endpoint control; the terminal-recruitment penalty is necessarily off."
        ),
        year
      ),
      opr_year_coefficients = year,
      terminal_years = 0L,
      component_terminal_years = -1L,
      terminal_penalty_weight = 0
    ))
  }

  ## D. Length/selectivity comparisons at the central E1/W100 setting. The
  ## source-consistent reviewed treatment is already present in family A for
  ## each count. Baseline and exact-five-fishery-only rows bracket it; three
  ## OPR73 rows isolate the biological source of any likelihood gain.
  for (year in c(73L, 72L, 71L)) {
    for (fish in c("baseline", "review_exact")) {
      add_row(list(
        family = "length-selectivity",
        anchor = sprintf(
          "Y%d-E1-W100-%s",
          year,
          if (fish == "baseline") "FBase" else "FExact"
        ),
        model_label = opr_label(year, 1L, 100, fish),
        rationale = if (fish == "baseline") {
          sprintf("Restores the current Step 12 LF controls at OPR%d/E1/W100 to measure the net effect of the reviewed group-consistent changes.", year)
        } else {
          sprintf("Applies only the exact five listed fishery changes at OPR%d/E1/W100. This deliberately omits F27/F18 propagation and is a flag-grouping diagnostic, not the source-consistent default.", year)
        },
        opr_year_coefficients = year,
        terminal_years = 1L,
        component_terminal_years = 0L,
        terminal_penalty_weight = 100,
        fish_profile = fish
      ))
    }
  }
  for (fish in c("large_fish_group", "young_age", "f17_group")) {
    code <- switch(fish, large_fish_group = "FTail", young_age = "FYoung", f17_group = "F17")
    add_row(list(
      family = "length-selectivity",
      anchor = paste("Y73-E1-W100", code, sep = "-"),
      model_label = opr_label(73L, 1L, 100, fish),
      rationale = switch(
        fish,
        large_fish_group = "Isolates the large-fish tail controls for fisheries sharing the F20/F27 selectivity group and fishery 28.",
        young_age = "Isolates zero young-age selectivity where fisheries 12 and 26 have no observed catch in the affected age classes.",
        f17_group = "Isolates the earlier upper-age control for fisheries 17 and 18, which share a selectivity group."
      ),
      opr_year_coefficients = 73L,
      terminal_years = 1L,
      component_terminal_years = 0L,
      terminal_penalty_weight = 100,
      fish_profile = fish
    ))
  }

  ## E. Uniform length-composition downweights at each annual OPR count. A
  ## divisor of 40 is the moderate Step-15-style case; 80 is the strong case
  ## and gives every LF record half the effective sample size of uniform 40. Only
  ## fish flag(49) changes; weight-composition flag(50) remains untouched.
  for (year in c(73L, 72L, 71L)) {
    for (divisor in c(40L, 80L)) {
      add_row(list(
        family = "length-composition-weight",
        anchor = sprintf("Y%d-E1-W100-FGroup-LenDiv%02d", year, divisor),
        model_label = sprintf("OPR%d-01-50-50 E1 weight 100; uniform length divisor %d", year, divisor),
        rationale = sprintf(
          paste0(
            "Sets fish flag(49) to a uniform length-composition divisor of %d for every fishery at OPR%d/E1/W100. ",
            "%s Weight-composition flag(50) remains unchanged."
          ),
          divisor,
          year,
          if (divisor == 40L) {
            "This is the moderate Step-15-style downweight."
          } else {
            "This strong case gives every LF record half the effective sample size of the uniform-40 case."
          }
        ),
        opr_year_coefficients = year,
        terminal_years = 1L,
        component_terminal_years = 0L,
        terminal_penalty_weight = 100,
        length_comp_divisor = divisor
      ))
    }
  }

  ## F. The trend axis is evaluated only at the fully saturated central case.
  ## Flag -1 disables it; flag +1 gives weight 0.1. The inherited default
  ## remains represented by the matching family-A row.
  for (trend in c(-1L, 1L)) {
    add_row(list(
      family = "trend-penalty",
      anchor = sprintf("Y73-E1-W100-FGroup-Trend%s", if (trend < 0L) "Off" else "010"),
      model_label = sprintf("OPR73-01-50-50 E1 weight 100; trend flag %d", trend),
      rationale = sprintf(
        "Separates the OPR trend penalty from the terminal-mean penalty with parest_flag(153)=%d (%s).",
        trend,
        if (trend < 0L) "off" else "weight 0.1"
      ),
      opr_year_coefficients = 73L,
      terminal_years = 1L,
      component_terminal_years = 0L,
      terminal_penalty_weight = 100,
      trend_flag = trend
    ))
  }

  ## G. Targeted tag diagnostics. U73 is the matched unpenalised context;
  ## P73/P72/P71 use the reviewed group-consistent LF treatment at E1/W100. No option is
  ## crossed with the full OPR grid.
  tag_context <- function(code, year, weight) {
    list(code = code, year = as.integer(year), weight = weight)
  }
  U73 <- tag_context("U73", 73L, 0)
  P73 <- tag_context("P73", 73L, 100)
  P72 <- tag_context("P72", 72L, 100)
  P71 <- tag_context("P71", 71L, 100)

  add_tag <- function(context, suffix, label, rationale, ..., final_candidate = FALSE) {
    extras <- list(...)
    base <- list(
      family = "tagging-diagnostic",
      anchor = paste(context$code, suffix, sep = "-"),
      model_label = sprintf(
        "OPR%d-01-50-50 E1 weight %g; %s",
        context$year, context$weight, label
      ),
      rationale = rationale,
      opr_year_coefficients = context$year,
      terminal_years = 1L,
      component_terminal_years = 0L,
      terminal_penalty_weight = context$weight,
      fish_profile = "group_consistent",
      final_candidate = final_candidate
    )
    add_row(utils::modifyList(base, extras))
  }

  for (flag in c(300L, 100L, 30L)) {
    add_tag(
      P73,
      sprintf("TagWt%04d", flag),
      sprintf("tag likelihood weight %.2f", flag / 1000),
      sprintf(
        paste0(
          "Scales only the tag likelihood to %.2f with parest_flag(177)=%d while retaining reporting-rate priors. ",
          "The three-point response tests whether the recent recruitment signal changes continuously with tag influence."
        ),
        flag / 1000, flag
      ),
      tag_weight_flag = flag
    )
  }

  add_tag(
    P73, "TagCond", "recaptures-conditioned tags",
    paste0(
      "Uses parest_flag(249)=1 so tag information is conditioned on total recaptures and primarily informs their relative distribution. ",
      "It is an alternative observation model, not an automatic preferred case."
    ),
    tag_likelihood = "recaptures_conditioned"
  )
  add_tag(
    P73, "TagDisp", "estimated pooled tag overdispersion",
    paste0(
      "Estimates one pooled direct-tau negative-binomial dispersion parameter. Because this also changes the dispersion parameterisation, ",
      "it is retained as a structural diagnostic rather than a final-candidate shortcut."
    ),
    estimate_tag_dispersion = TRUE
  )

  for (context in list(U73, P73)) {
    add_tag(
      context, "TagDrop60", "dominant 2021 release removed",
      paste0(
        "Removes only release group 60 and synchronises TAG, FRQ, MFCL 1007 tag sections, and reporting maps. ",
        "This is a cohort-attribution diagnostic; objectives are not directly comparable because the data differ."
      ),
      remove_2021_tags = TRUE,
      tag_deletion = "group60"
    )
    add_tag(
      context, "TagMixAll", "all-release mixing reporting correction",
      "Sets tag_flags(:,2)=1 for every release so reporting-rate corrections are excluded during pre-mixing periods, following the source/manual treatment.",
      tag_rr_mixing_mode = "all"
    )
  }

  add_tag(
    P73, "TagDrop2021", "both 2021 releases removed",
    paste0(
      "Removes release groups 18 and 60 together and synchronises TAG, FRQ, every MFCL 1007 tag section, and reporting maps. ",
      "This reproduces the full 2021-release deletion as an attribution upper bound; it is not a default data treatment."
    ),
    remove_2021_tags = TRUE,
    tag_deletion = "both"
  )

  add_tag(
    P73, "RRCampaign", "separate 2021 campaign reporting rate",
    paste0(
      "Adds one reporting-rate parameter for the two 2021 campaign releases across fisheries 25-28, retaining target 0.52015 and penalty 485.2. ",
      "This tests campaign-specific reporting without deleting observations."
    ),
    rr_2021_scope = "campaign",
    rr_2021_target = 0.52015,
    rr_2021_penalty = 485.2
  )

  add_tag(
    P73, "RRCampaignMixAll", "central 2021 campaign reporting rate plus mixing correction",
    paste0(
      "Combines the externally informed 2021 campaign reporting-rate parameter (target 0.52015, penalty 485.2) with tag_flags(:,2)=1. ",
      "It is shortlisted only if likelihood components, population scale, gradients, and Hessian diagnostics remain stable at stricter convergence."
    ),
    rr_2021_scope = "campaign",
    rr_2021_target = 0.52015,
    rr_2021_penalty = 485.2,
    tag_rr_mixing_mode = "all",
    final_candidate = TRUE
  )
  add_tag(
    P73, "RRCampaignWideMixAll", "wider 2021 campaign prior plus mixing correction",
    paste0(
      "Combines all-release pre-mixing correction with the same 0.52015 campaign target but relaxes the reporting-rate penalty to 48.52 (prior SD about 0.10). ",
      "This is a prior-conflict diagnostic, not a preferred fit selected by recruitment shape."
    ),
    rr_2021_scope = "campaign",
    rr_2021_target = 0.52015,
    rr_2021_penalty = 48.52,
    tag_rr_mixing_mode = "all"
  )
  add_tag(
    P73, "RR60MixAll", "dominant-release reporting rate plus mixing correction",
    paste0(
      "Estimates a separate reporting rate only for release group 60 at target 0.52015 and penalty 485.2 while applying tag_flags(:,2)=1 to every release. ",
      "Comparison with the campaign grouping diagnoses reporting-rate/recruitment confounding."
    ),
    rr_2021_scope = "group60",
    rr_2021_target = 0.52015,
    rr_2021_penalty = 485.2,
    tag_rr_mixing_mode = "all"
  )

  for (period in c(2L, 4L)) {
    add_tag(
      P73,
      sprintf("TagMix60Q%d", period),
      sprintf("dominant-release mixing period %d quarters", period),
      sprintf(
        paste0(
          "Sets tag_flags(60,2)=1 and the dominant 2021 release mixing period to %d quarters. ",
          "This brackets plausible pre-mixing duration without suppressing later recaptures."
        ),
        period
      ),
      tag_rr_mixing_mode = "group60",
      tag_2021_mixing_period = period
    )
  }

  add_tag(
    P73, "TagGammaRob", "robust binned-gamma tags",
    paste0(
      "Uses robust binned gamma with a one-recapture censor and 0.05 mixture fraction. ",
      "This is a targeted outlier sensitivity and its objective is not directly comparable with negative-binomial cases."
    ),
    tag_likelihood = "robust_binned_gamma",
    estimate_tag_dispersion = TRUE
  )

  for (context in list(P72, P71)) {
    add_tag(
      context, "RRCampaignMixAll", "central 2021 campaign reporting rate plus mixing correction",
      paste0(
        "Combines the central campaign reporting-rate prior and all-release pre-mixing correction at this annual OPR count. ",
        "This is a shortlisted structural comparison across 73, 72, and 71 annual coefficients."
      ),
      rr_2021_scope = "campaign",
      rr_2021_target = 0.52015,
      rr_2021_penalty = 485.2,
      tag_rr_mixing_mode = "all",
      final_candidate = TRUE
    )
    add_tag(
      context, "TagDrop60", "dominant 2021 release removed",
      "Removes only release group 60 at this annual OPR count to check whether cohort attribution is stable across 73, 72, and 71 coefficients.",
      remove_2021_tags = TRUE,
      tag_deletion = "group60"
    )
  }

  ## H. Ordinary recruitment-deviation controls from Step 11. They determine
  ## whether the same recent tag pressure exists before OPR and whether a fixed
  ## terminal block merely displaces it.
  standard_cases <- list(
    list(code = "Free", quarters = 0L, mean = FALSE, deletion = "none", tag_weight = 0L,
      text = "estimates every terminal recruitment deviation with the parent tag likelihood and data"),
    list(code = "Fix4", quarters = 4L, mean = TRUE, deletion = "none", tag_weight = 0L,
      text = "fixes the last four quarterly deviations to the historical arithmetic-mean treatment"),
    list(code = "Fix8", quarters = 8L, mean = TRUE, deletion = "none", tag_weight = 0L,
      text = "fixes the last eight quarterly deviations to the historical arithmetic-mean treatment"),
    list(code = "FreeDrop60", quarters = 0L, mean = FALSE, deletion = "group60", tag_weight = 0L,
      text = "estimates every terminal deviation after removing dominant 2021 release group 60"),
    list(code = "FreeTagWt0100", quarters = 0L, mean = FALSE, deletion = "none", tag_weight = 100L,
      text = "estimates every terminal deviation with tag likelihood weight 0.1")
  )
  for (case in standard_cases) {
    dropping <- case$deletion != "none"
    add_row(list(
      parent_step = "11-TimeVaryingCV",
      parameterization = "standard",
      family = "standard-recruitment-control",
      anchor = case$code,
      model_label = paste("Standard recruitment:", case$text),
      rationale = paste0(
        "Uses ordinary quarter-specific recruitment deviations and ", case$text,
        ". The reviewed controls are propagated across shared selectivity groups so this is a source-consistent structural control for the OPR response."
      ),
      opr_year_coefficients = NA_integer_,
      opr_season_coefficients = NA_integer_,
      opr_region_coefficients = NA_integer_,
      opr_interaction_coefficients = NA_integer_,
      terminal_years = NA_integer_,
      component_terminal_years = NA_integer_,
      terminal_penalty_weight = 0,
      fish_profile = "group_consistent",
      standard_terminal_quarters = case$quarters,
      standard_arithmetic_mean = case$mean,
      tag_weight_flag = case$tag_weight,
      remove_2021_tags = dropping,
      tag_deletion = case$deletion,
      expected_final_par = "11.par"
    ))
  }

  ## I. Compatibility pair for a supplied OPR71/end3 setup that also sets
  ## parest_flag(221)=71. Public ongoing-dev treats flag 221 as obsolete, so a
  ## matched flag-zero row determines whether the assessment executable has
  ## restored executable-specific behaviour. Both retain original Step 12 LF
  ## controls and no terminal penalty to avoid confounding this check.
  for (legacy_override in c(0L, 71L)) {
    add_row(list(
      family = "supplied-opr221-check",
      anchor = sprintf("Y71-E3-W000-FBase-P221-%02d", legacy_override),
      model_label = sprintf(
        "OPR71-01-50-50 E3 weight 0; current LF controls; parest flag 221=%d",
        legacy_override
      ),
      rationale = if (legacy_override == 0L) {
        paste0(
          "Matched compatibility control for the supplied OPR71/end3 setup, with parest_flag(221)=0. ",
          "Public ongoing-dev treats flag 221 as obsolete; compare only with the paired flag-71 row."
        )
      } else {
        paste0(
          "Reproduces the supplied OPR settings 155=71, 221=71, 216=50, 217=1, and 202=3 while retaining the parent interaction count 218=50. ",
          "A difference from the paired flag-zero row would identify assessment-executable behaviour not present in public ongoing-dev."
        )
      },
      opr_year_coefficients = 71L,
      opr_legacy_year_override = legacy_override,
      terminal_years = 3L,
      component_terminal_years = 0L,
      terminal_penalty_weight = 0,
      fish_profile = "baseline",
      final_candidate = FALSE
    ))
  }

  ## J. One supplied benchmark reproduces OPR69-01-50-50, a two-year
  ## endpoint, weight 100, current LF settings, and the 1,000-evaluation
  ## protocol. It is retained for numerical comparison and cannot be promoted
  ## into the 71/72/73 final-candidate set.
  add_row(list(
    family = "supplied-benchmark",
    anchor = "Benchmark-OPR69-E2-W100-FBase",
    model_label = "Supplied benchmark: OPR69-01-50-50 E2 weight 100; current LF controls",
    rationale = paste0(
      "Reproduces the supplied OPR69-01-50-50, two-calendar-year endpoint, terminal-penalty weight 100, and 1,000-evaluation protocol from a newly fitted branch-local 11.par. ",
      "It is a numerical benchmark only; the curated candidate grid uses 73, 72, and 71 annual coefficients."
    ),
    opr_year_coefficients = 69L,
    terminal_years = 2L,
    component_terminal_years = 0L,
    terminal_penalty_weight = 100,
    fish_profile = "baseline",
    benchmark_protocol = TRUE,
    benchmark_label = "supplied-opr69-e2-w100-1000-evaluation",
    final_candidate = FALSE
  ))

  spec <- do.call(rbind, rows)
  rownames(spec) <- NULL

  if (anyDuplicated(spec$step_id) || anyDuplicated(spec$anchor)) {
    stop("Sensitivity design contains duplicate step IDs or anchors.", call. = FALSE)
  }
  if (any(spec$terminal_penalty_flag != round(10 * spec$terminal_penalty_weight))) {
    stop("Terminal penalty flags do not match weight * 10.", call. = FALSE)
  }
  if (any(!spec$opr_legacy_year_override %in% c(0L, 71L))) {
    stop("Legacy annual OPR override flag 221 must be zero or 71 in the supplied compatibility pair.", call. = FALSE)
  }
  if (any(!spec$length_comp_divisor %in% c(0L, 40L, 80L))) {
    stop("Length-composition divisor must preserve inherited values (0) or set a uniform 40/80 divisor.", call. = FALSE)
  }

  opr <- spec$parameterization == "opr"
  if (any(!spec$opr_year_coefficients[opr] %in% c(69L, 71L, 72L, 73L))) {
    stop("OPR annual coefficient count must be 71/72/73, except for the single OPR69 benchmark.", call. = FALSE)
  }
  if (any(spec$opr_season_coefficients[opr] != 1L) ||
      any(spec$opr_region_coefficients[opr] != 50L) ||
      any(spec$opr_interaction_coefficients[opr] != 50L)) {
    stop("Every OPR case must use the 01-50-50 seasonal, regional, and interaction counts.", call. = FALSE)
  }
  if (any(!spec$terminal_years[opr] %in% 0:3)) {
    stop("OPR terminal endpoints must be zero to three calendar years.", call. = FALSE)
  }
  max_year_count <- 74L - pmax(1L, spec$terminal_years[opr])
  if (any(spec$opr_year_coefficients[opr] > max_year_count)) {
    stop("An OPR annual coefficient count exceeds 74 - max(1, terminal endpoint).", call. = FALSE)
  }
  endpoint_free <- opr & spec$terminal_years == 0L
  if (any(spec$component_terminal_years[endpoint_free] != -1L) ||
      any(spec$terminal_penalty_weight[endpoint_free] != 0)) {
    stop("Endpoint-free OPR rows require component endpoint -1 and penalty weight zero.", call. = FALSE)
  }
  endpoint_active <- opr & spec$terminal_years > 0L
  if (any(spec$component_terminal_years[endpoint_active] != 0L)) {
    stop("Active OPR endpoints must use component value zero to inherit the annual endpoint.", call. = FALSE)
  }
  if (any(opr & spec$terminal_penalty_weight > 0 & spec$terminal_years <= 0L)) {
    stop("A positive terminal-recruitment penalty requires an active annual endpoint.", call. = FALSE)
  }

  benchmark_rows <- which(spec$benchmark_protocol)
  if (length(benchmark_rows) != 1L) {
    stop("Exactly one supplied benchmark is required.", call. = FALSE)
  }
  benchmark <- spec[benchmark_rows, , drop = FALSE]
  if (benchmark$family != "supplied-benchmark" ||
      benchmark$opr_year_coefficients != 69L || benchmark$terminal_years != 2L ||
      benchmark$terminal_penalty_weight != 100 || benchmark$fish_profile != "baseline" ||
      benchmark$final_candidate) {
    stop("The supplied benchmark must be the baseline OPR69/E2/W100 case and excluded from final candidates.", call. = FALSE)
  }
  if (any(spec$opr_year_coefficients[opr & !spec$benchmark_protocol] == 69L)) {
    stop("OPR69 is allowed only in the supplied benchmark.", call. = FALSE)
  }

  opr221_pair <- spec$family == "supplied-opr221-check"
  if (sum(opr221_pair) != 2L ||
      !setequal(spec$opr_legacy_year_override[opr221_pair], c(0L, 71L)) ||
      any(spec$opr_year_coefficients[opr221_pair] != 71L) ||
      any(spec$terminal_years[opr221_pair] != 3L) ||
      any(spec$terminal_penalty_weight[opr221_pair] != 0) ||
      any(spec$fish_profile[opr221_pair] != "baseline")) {
    stop("The supplied OPR221 compatibility check must be a matched OPR71/E3/W0 baseline-LF pair with flag 221 values 0 and 71.", call. = FALSE)
  }
  if (any(spec$opr_legacy_year_override[!opr221_pair] != 0L)) {
    stop("A nonzero flag 221 is allowed only in the supplied compatibility pair.", call. = FALSE)
  }

  grouped_default_families <- c(
    "annual-count-penalty", "longer-terminal-window", "endpoint-free-control",
    "length-composition-weight", "trend-penalty", "tagging-diagnostic",
    "standard-recruitment-control"
  )
  grouped_default <- spec$family %in% grouped_default_families
  if (any(spec$fish_profile[grouped_default] != "group_consistent")) {
    stop("Core, endpoint, composition, trend, tag, and standard rows must use the source-consistent reviewed LF controls.", call. = FALSE)
  }
  exact_grouping_diagnostics <- spec$family == "length-selectivity" & spec$fish_profile == "review_exact"
  if (sum(exact_grouping_diagnostics) != 3L ||
      !setequal(spec$opr_year_coefficients[exact_grouping_diagnostics], c(71L, 72L, 73L)) ||
      any(spec$terminal_penalty_weight[exact_grouping_diagnostics] != 100)) {
    stop("The exact-five-fishery-only grouping diagnostic must occur once at OPR71/72/73 E1/W100.", call. = FALSE)
  }

  pure_standard_free <- spec$parameterization == "standard" &
    spec$standard_terminal_quarters == 0L & spec$tag_deletion == "none" &
    spec$tag_weight_flag == 0L
  if (sum(pure_standard_free) != 1L) {
    stop("Exactly one unconfounded free-terminal standard-recruitment control is required.", call. = FALSE)
  }
  full_2021_deletion <- spec$tag_deletion == "both"
  if (sum(full_2021_deletion) != 1L ||
      spec$opr_year_coefficients[full_2021_deletion] != 73L ||
      spec$terminal_penalty_weight[full_2021_deletion] != 100) {
    stop("Exactly one full-2021-release deletion is required at OPR73/E1/W100.", call. = FALSE)
  }

  separated_rr <- spec$rr_2021_scope != "shared"
  invalid_rr <- separated_rr & (
    !is.finite(spec$rr_2021_target) | spec$rr_2021_target <= 0 | spec$rr_2021_target >= 1 |
      !is.finite(spec$rr_2021_penalty) | spec$rr_2021_penalty < 0
  )
  if (any(invalid_rr)) {
    stop("Every separated reporting-rate case needs a probability target and non-negative prior penalty.", call. = FALSE)
  }
  if (any(!spec$rr_2021_scope %in% c("shared", "campaign", "group60"))) {
    stop("Unknown 2021 reporting-rate scope.", call. = FALSE)
  }

  candidate <- spec[spec$final_candidate, , drop = FALSE]
  if (nrow(candidate) != 3L ||
      !setequal(candidate$opr_year_coefficients, c(71L, 72L, 73L)) ||
      any(candidate$terminal_years != 1L) ||
      any(candidate$terminal_penalty_weight != 100) ||
      any(candidate$fish_profile != "group_consistent") ||
      any(candidate$rr_2021_scope != "campaign") ||
      any(candidate$rr_2021_penalty != 485.2) ||
      any(candidate$tag_rr_mixing_mode != "all") ||
      any(candidate$benchmark_protocol)) {
    stop("Final candidates must be the three group-consistent reviewed-LF E1/W100 campaign-RR-plus-mixing cases for OPR71/72/73.", call. = FALSE)
  }

  expected_family_counts <- c(
    `annual-count-penalty` = 15L,
    `longer-terminal-window` = 9L,
    `endpoint-free-control` = 3L,
    `length-selectivity` = 9L,
    `length-composition-weight` = 6L,
    `trend-penalty` = 2L,
    `tagging-diagnostic` = 21L,
    `standard-recruitment-control` = 5L,
    `supplied-opr221-check` = 2L,
    `supplied-benchmark` = 1L
  )
  actual_family_counts <- table(spec$family)
  if (!setequal(names(actual_family_counts), names(expected_family_counts)) ||
      any(actual_family_counts[names(expected_family_counts)] != expected_family_counts)) {
    stop(
      "Sensitivity family counts changed: expected ",
      paste(names(expected_family_counts), expected_family_counts, sep = "=", collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  expected_generated <- 73L
  if (nrow(spec) != expected_generated) {
    stop("Sensitivity design count changed: expected ", expected_generated, ", got ", nrow(spec), ".", call. = FALSE)
  }
  spec
}

opr_terminal_penalty_lf_control_step_ids <- function() {
  "11-TimeVaryingCV"
}

opr_terminal_penalty_lf_run_step_ids <- function(include_controls = TRUE) {
  generated <- opr_terminal_penalty_lf_model_spec()$step_id
  if (isTRUE(include_controls)) c(opr_terminal_penalty_lf_control_step_ids(), generated) else generated
}

opr_terminal_penalty_lf_hessian_nsplit <- function() {
  if (length(opr_terminal_penalty_lf_run_step_ids()) > 50L) 1L else 2L
}

opr_terminal_penalty_lf_job_rows <- function() {
  spec <- opr_terminal_penalty_lf_model_spec()
  data.frame(
    step_id = spec$step_id,
    enabled = rep(FALSE, nrow(spec)),
    documentation_visible = rep(FALSE, nrow(spec)),
    major_step = ifelse(spec$parameterization == "opr", "12-OPRTerminalPenaltyLFTag", "11-StandardTerminalTag"),
    substep = sub("-.*$", "", spec$step_id),
    change_axis = spec$rationale,
    model_label = spec$model_label,
    job_title = spec$job_title,
    job_key = tolower(gsub("[^A-Za-z0-9]+", "-", spec$step_id)),
    run_mode = rep("doitall", nrow(spec)),
    region_count = rep(5L, nrow(spec)),
    kflow_memory = ifelse(spec$tag_likelihood == "recaptures_conditioned", "10GB", "8GB"),
    mfcl_program_path = rep("", nrow(spec)),
    input_par = rep("", nrow(spec)),
    frq = rep("bet.frq", nrow(spec)),
    output_par = rep("", nrow(spec)),
    source_dir = file.path("steps", spec$parent_step, "model"),
    expected_final_par = spec$expected_final_par,
    stringsAsFactors = FALSE
  )
}
