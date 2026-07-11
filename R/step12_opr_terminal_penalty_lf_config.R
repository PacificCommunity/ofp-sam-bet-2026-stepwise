## Focused Step 11/12 sensitivity design for terminal recruitment, length-fit
## controls, and recent tagging assumptions.
##
## The design is deliberately staged rather than a full Cartesian product.
## Core models identify the terminal-penalty and selectivity effects. Targeted
## tag models then ask which observation/process assumption carries the recent
## abundance signal. The two unchanged parent steps are included as controls.

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
    if (length(failed)) stop("Could not remove generated step folder(s): ", paste(basename(failed), collapse = ", "), call. = FALSE)
  }
  basename(generated)
}

opr_terminal_penalty_lf_model_spec <- function() {
  rows <- list()
  opr_index <- 0L
  std_index <- 0L

  template <- list(
    step_id = "",
    parent_step = "12-OrthogonalPoly",
    parameterization = "opr",
    family = "",
    anchor = "",
    model_label = "",
    job_title = "",
    rationale = "",
    terminal_years = 2L,
    terminal_penalty_weight = 0,
    terminal_penalty_flag = 0L,
    fish_profile = "baseline",
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

  fish_labels <- c(
    baseline = "current fishery controls",
    review_exact = "five-fishery LF controls exactly as proposed",
    group_consistent = "LF controls propagated within shared selectivity groups",
    large_fish_group = "large-fish tail controls for fisheries 20/27/28",
    young_age = "zero young-age selectivity for fisheries 12 and 26",
    f17_group = "earlier upper-age control for fisheries 17 and 18"
  )

  ## A. Matched 1,000-evaluation terminal-penalty refinements. Weight zero is
  ## retained as the matched optimisation control. The actual MFCL weight is
  ## parest_flag(397)/10, hence 25/50/100/200 map to 250/500/1000/2000.
  for (terminal_years in c(1L, 2L)) {
    for (weight in c(0, 25, 50, 100, 200)) {
      for (fish_profile in c("baseline", "group_consistent")) {
        anchor <- sprintf(
          "E%d-W%03d-%s",
          terminal_years,
          as.integer(weight),
          switch(fish_profile, baseline = "FBase", review_exact = "FExact", group_consistent = "FGroup")
        )
        add_row(list(
          family = "terminal-penalty-by-selectivity",
          anchor = anchor,
          model_label = sprintf("OPR69 end%d weight %g; %s", terminal_years, weight, fish_labels[[fish_profile]]),
          rationale = sprintf(
            paste0(
              "Tests an OPR69 terminal window of %d calendar year(s) (%d quarters) with terminal-recruitment penalty weight %g. ",
              "The selectivity treatment is %s. Every model receives the same final 1,000-evaluation phase, including weight-zero controls."
            ),
            terminal_years, 4L * terminal_years, weight, fish_labels[[fish_profile]]
          ),
          terminal_years = terminal_years,
          terminal_penalty_weight = weight,
          fish_profile = fish_profile
        ))
      }
    }
  }

  ## Retain the exact five-fishery proposal at the central weight only. F20
  ## and F17 share selectivity groups in the current model, so multiplying the
  ## intentionally group-inconsistent diagnostic across every weight would not
  ## add useful evidence.
  for (terminal_years in c(1L, 2L)) {
    add_row(list(
      family = "terminal-penalty-by-selectivity",
      anchor = sprintf("E%d-W100-FExact", terminal_years),
      model_label = sprintf("OPR69 end%d weight 100; %s", terminal_years, fish_labels[["review_exact"]]),
      rationale = sprintf(
        "Tests the exact five-fishery LF-control proposal at a %d-year terminal window and penalty weight 100; group-consistent cases remain the primary structural comparison.",
        terminal_years
      ),
      terminal_years = terminal_years,
      terminal_penalty_weight = 100,
      fish_profile = "review_exact"
    ))
  }

  ## B. Isolate the three biological/selectivity hypotheses at the central
  ## penalty weight, rather than interpreting only the combined change.
  for (terminal_years in c(1L, 2L)) {
    for (fish_profile in c("large_fish_group", "young_age", "f17_group")) {
      anchor <- sprintf(
        "E%d-W100-%s",
        terminal_years,
        switch(fish_profile, large_fish_group = "FTail", young_age = "FYoung", f17_group = "F17")
      )
      add_row(list(
        family = "isolated-selectivity-effect",
        anchor = anchor,
        model_label = sprintf("OPR69 end%d weight 100; %s", terminal_years, fish_labels[[fish_profile]]),
        rationale = paste(
          "Isolates one length-frequency/selectivity hypothesis at terminal penalty weight 100.",
          fish_labels[[fish_profile]]
        ),
        terminal_years = terminal_years,
        terminal_penalty_weight = 100,
        fish_profile = fish_profile
      ))
    }
  }

  ## Four contexts carry the targeted tag diagnostics. They distinguish a
  ## boundary-only fit, a penalised fit, the reviewed selectivity treatment,
  ## and the longer terminal window without multiplying every tag option by
  ## the complete structural grid.
  tag_contexts <- list(
    list(code = "C1", terminal_years = 1L, weight = 0, fish = "baseline"),
    list(code = "C2", terminal_years = 1L, weight = 100, fish = "baseline"),
    list(code = "C3", terminal_years = 1L, weight = 100, fish = "group_consistent"),
    list(code = "C4", terminal_years = 2L, weight = 100, fish = "group_consistent")
  )

  add_tag_context <- function(context, suffix, label, rationale, ...) {
    add_row(utils::modifyList(list(
      family = "tagging-diagnostic",
      anchor = paste(context$code, suffix, sep = "-"),
      model_label = sprintf(
        "OPR69 end%d weight %g %s; %s",
        context$terminal_years, context$weight,
        if (identical(context$fish, "baseline")) "base LF" else "group-consistent LF",
        label
      ),
      rationale = rationale,
      terminal_years = context$terminal_years,
      terminal_penalty_weight = context$weight,
      fish_profile = context$fish
    ), list(...)))
  }

  for (context in tag_contexts) {
    ## Dose response: 0 means MFCL's default full tag weight; the non-zero
    ## flag is divided by 1,000 in ongoing-dev newl2.cpp.
    for (flag in c(300L, 100L, 30L, 1L)) {
      add_tag_context(
        context,
        sprintf("TagWt%04d", flag),
        sprintf("tag likelihood weight %.3f", flag / 1000),
        sprintf(
          paste0(
            "Scales only the tag likelihood to %.3f with parest_flag(177)=%d. ",
            "Reporting-rate priors remain active, so this is a dose-response diagnostic rather than a literal no-tag model."
          ),
          flag / 1000, flag
        ),
        tag_weight_flag = flag
      )
    }

    add_tag_context(
      context, "TagCond", "recaptures-conditioned tags",
      paste0(
        "Uses parest_flag(249)=1 so tag data primarily inform relative spatial/fishery recapture patterns rather than absolute recapture magnitude and temporal mortality. ",
        "This is a different observation model, not an automatic preferred case."
      ),
      tag_likelihood = "recaptures_conditioned"
    )
    add_tag_context(
      context, "TagDrop2021", "2021 releases removed",
      paste0(
        "Removes the two 2021 release groups as a deletion diagnostic and synchronises TAG, FRQ, all MFCL 1007 tag sections, and reporting maps. ",
        "Objective values are not directly comparable because the data differ."
      ),
      remove_2021_tags = TRUE,
      tag_deletion = "both"
    )
    add_tag_context(
      context, "TagDisp", "estimated pooled tag overdispersion",
      paste0(
        "Uses parest_flag(305)=1 and fish_flags(43/44)=1 to estimate one shared direct-tau negative-binomial dispersion parameter with source-supported bounds. ",
        "Because parest_flag(305) also changes the negative-binomial parameterisation from the legacy fish-parameter form, this is a compound observation-model diagnostic rather than a stand-alone final-model candidate."
      ),
      estimate_tag_dispersion = TRUE
    )
    add_tag_context(
      context, "TagRR2021", "separate 2021 campaign reporting rate",
      paste0(
        "Adds one reporting-rate parameter for the dominant 2021 campaign/fishery cells while retaining their existing target and prior precision. ",
        "This separates campaign-specific reporting from past releases without deleting observations."
      ),
      rr_2021_scope = "campaign",
      rr_2021_target = 0.52015,
      rr_2021_penalty = 485.2
    )
    add_tag_context(
      context, "TagRR2021Wide", "separate 2021 reporting rate with wider prior",
      paste0(
        "Adds the same single 2021 campaign reporting-rate parameter and reduces its prior penalty ten-fold, widening the prior SD from about 0.032 to about 0.10. ",
        "This tests prior conflict while avoiding a high-dimensional release-by-fishery expansion."
      ),
      rr_2021_scope = "campaign",
      rr_2021_target = 0.52015,
      rr_2021_penalty = 48.52
    )
    add_tag_context(
      context, "TagMixRR2021", "2021 mixing-period reporting correction",
      paste0(
        "Sets tag_flags(18/60,2)=1 so uncertain reporting-rate corrections are excluded during their pre-mixing periods, as recommended by the manual and ongoing-dev validation."
      ),
      tag_rr_mixing_mode = "2021"
    )
    add_tag_context(
      context, "TagMixRRAll", "all-release mixing-period reporting correction",
      paste0(
        "Sets tag_flags(:,2)=1 for every release, restoring the source/manual-recommended treatment of reporting rates during pre-mixing periods."
      ),
      tag_rr_mixing_mode = "all"
    )
  }

  ## Leave-one-release diagnostics at the two base-LF contexts distinguish the
  ## negligible small cohort from the dominant region-4 cohort before the
  ## combined 2021 deletion is interpreted.
  for (context in tag_contexts[1:2]) {
    add_tag_context(
      context, "TagDrop18", "small 2021 release removed",
      "Removes only release group 18 to separate its effect from the dominant 2021 cohort; all MFCL tag structures are synchronised and rebuilt.",
      remove_2021_tags = TRUE,
      tag_deletion = "group18"
    )
    add_tag_context(
      context, "TagDrop60", "dominant 2021 release removed",
      "Removes only release group 60 as the direct cohort-attribution diagnostic; all MFCL tag structures are synchronised and rebuilt.",
      remove_2021_tags = TRUE,
      tag_deletion = "group60"
    )
    add_tag_context(
      context, "TagMixRR60", "dominant-release mixing reporting correction",
      "Sets only tag_flags(60,2)=1, isolating the release-quarter reporting-rate depletion treatment for the dominant 2021 cohort.",
      tag_rr_mixing_mode = "group60"
    )
  }

  ## Reporting-rate prior response surface for the dominant group-60 release
  ## at the two central one-year contexts. The target remains the independently
  ## derived PTTP value; only prior precision is relaxed. The campaign-level
  ## cases above are the cleaner structural candidate because both releases
  ## share a programme and release month. The unpenalised endpoint diagnoses
  ## identifiability and is not a production recommendation.
  for (context in tag_contexts[2:3]) {
    for (penalty in c(485.2, 121.3, 48.52, 12.13, 0)) {
      suffix <- sprintf("%04d", as.integer(round(penalty * 10)))
      prior_sd <- if (penalty > 0) sqrt(1 / (2 * penalty)) else Inf
      add_tag_context(
        context,
        paste0("TagRR60P", suffix),
        sprintf(
          "dominant-release reporting-rate prior penalty %g%s",
          penalty,
          if (is.finite(prior_sd)) sprintf(" (SD %.3f)", prior_sd) else " (unpenalised)"
        ),
        paste0(
          "Keeps the externally derived reporting-rate target at 0.52015 and estimates one parameter for release group 60 pooled across fisheries 25-28. ",
          sprintf("The Gaussian prior penalty is %g%s. ", penalty, if (is.finite(prior_sd)) sprintf(" (SD %.3f)", prior_sd) else ""),
          if (penalty > 0) {
            "This is a prior-precision sensitivity; the campaign-level grouping remains the cleaner final-model candidate, and selection cannot be based on recruitment shape alone."
          } else {
            "The zero-penalty endpoint is an identifiability stress test with high reporting-rate/recruitment confounding risk, not a final-model candidate."
          }
        ),
        rr_2021_scope = "group60",
        rr_2021_target = 0.52015,
        rr_2021_penalty = penalty
      )
    }
  }

  ## The 2021 mixing periods were region-level imputations rather than
  ## release-specific KS estimates. Bracket the dominant group-60 value at the
  ## two boundary/penalty contexts while applying the source/manual-recommended
  ## pre-mixing reporting-rate treatment. Together with TagMixRR60 at the
  ## inherited one-quarter value, these form a coherent Q1-Q4 comparison.
  for (context in tag_contexts[1:2]) {
    for (periods in 2:4) {
      add_tag_context(
        context,
        sprintf("TagMixRR60Q%d", periods),
        sprintf("2021 dominant release mixing %d quarters with reporting correction", periods),
        sprintf(
          paste0(
            "Sets tag_flags(60,2)=1 and changes the dominant 2021 release group's imputed mixing period from 1 to %d quarters. ",
            "Together with the one-quarter TagMixRR60 case, this tests pre-mixing imputation uncertainty without suppressing late recaptures."
          ),
          periods
        ),
        tag_rr_mixing_mode = "group60",
        tag_2021_mixing_period = as.integer(periods)
      )
    }
  }

  ## Observation-family and independently informed tag-loss screens are kept
  ## to the two base-LF contexts so their structural meaning remains clear.
  for (context in tag_contexts[1:2]) {
    add_tag_context(
      context, "TagGamma", "binned-gamma tags",
      paste0(
        "Uses the binned-gamma likelihood with a one-recapture censor and one estimated dispersion parameter to represent excess zero/small cells. ",
        "Likelihood values cannot be compared directly with negative-binomial cases."
      ),
      tag_likelihood = "binned_gamma",
      estimate_tag_dispersion = TRUE
    )
    add_tag_context(
      context, "TagGammaRob", "robust binned-gamma tags",
      paste0(
        "Uses robustified binned gamma with a one-recapture censor and 0.05 mixture fraction. It is an outlier sensitivity, not a device for tuning away an inconvenient cohort."
      ),
      tag_likelihood = "robust_binned_gamma",
      estimate_tag_dispersion = TRUE
    )
    add_tag_context(
      context, "TagLoss", "assumed long-term tag loss",
      paste0(
        "Applies a fixed continuous tag-loss rate of 0.021 per quarter to all releases (0.084/year divided across four model periods), based on an external bigeye double-tagging estimate. ",
        "This transfer is diagnostic and should not replace a Pacific-specific estimate."
      ),
      tag_loss_mode = "all",
      tag_loss_rate = 0.021
    )
  }

  ## D. Keep the corrected trend-penalty axis separate from the terminal
  ## penalty. Flag -1 is off, 0 is the MFCL default weight 0.01, and 1 is 0.1.
  for (terminal_years in c(1L, 2L)) {
    for (trend_flag in c(-1L, 1L)) {
      add_row(list(
        family = "trend-penalty",
        anchor = sprintf("E%d-W100-FGroup-Trend%s", terminal_years, if (trend_flag < 0L) "Off" else "010"),
        model_label = sprintf("OPR69 end%d weight 100; grouped LF; trend flag %d", terminal_years, trend_flag),
        rationale = sprintf(
          "Separates the OPR trend penalty from the terminal-mean penalty: parest_flag(153)=%d (%s).",
          trend_flag,
          if (trend_flag < 0L) "off" else "weight 0.1"
        ),
        terminal_years = terminal_years,
        terminal_penalty_weight = 100,
        fish_profile = "group_consistent",
        trend_flag = trend_flag
      ))
    }
  }

  ## E. Final-candidate reporting-rate screens. The manual strongly discourages
  ## the inherited tag_flags(:,2)=0 pre-mixing treatment. Combine the central,
  ## externally informed campaign prior with tag_flags(:,2)=1 in the two
  ## central one-year contexts so the reporting-rate candidate is not selected
  ## from two separate, untested main effects.
  for (context in tag_contexts[2:3]) {
    add_tag_context(
      context,
      "TagRR2021MixAll",
      "central 2021 campaign reporting rate with recommended mixing treatment",
      paste0(
        "Combines the central 2021 campaign reporting-rate parameter (target 0.52015, penalty 485.2) with tag_flags(:,2)=1 for every release. ",
        "This interaction is the reporting-rate final-candidate screen; acceptance still requires stable fits, gradients, population scale, and a positive-definite Hessian under stricter convergence."
      ),
      rr_2021_scope = "campaign",
      rr_2021_target = 0.52015,
      rr_2021_penalty = 485.2,
      tag_rr_mixing_mode = "all"
    )
  }

  ## F. Ordinary recruitment-deviation controls from Step 11. These determine
  ## whether the recent tag signal exists without OPR and whether terminal
  ## fixing merely displaces it.
  standard_cases <- list(
    list(code = "Free", quarters = 0L, mean = FALSE, rationale = "estimates every terminal recruitment deviation"),
    list(code = "FreeDrop2021", quarters = 0L, mean = FALSE, drop = TRUE, rationale = "estimates every terminal deviation after removing the two 2021 releases"),
    list(code = "FreeTagWt0100", quarters = 0L, mean = FALSE, tag_weight = 100L, rationale = "estimates every terminal deviation with tag likelihood weight 0.1"),
    list(code = "FreeTagCond", quarters = 0L, mean = FALSE, tag_like = "recaptures_conditioned", rationale = "estimates every terminal deviation with recaptures-conditioned tags"),
    list(code = "Fix4", quarters = 4L, mean = TRUE, rationale = "fixes the last four quarterly deviations to the historical arithmetic-mean treatment"),
    list(code = "Fix4Drop2021", quarters = 4L, mean = TRUE, drop = TRUE, rationale = "combines a four-quarter terminal block with the 2021-release deletion diagnostic"),
    list(code = "Fix8", quarters = 8L, mean = TRUE, rationale = "fixes the last eight quarterly deviations to the historical arithmetic-mean treatment"),
    list(code = "Fix8TagWt0100", quarters = 8L, mean = TRUE, tag_weight = 100L, rationale = "combines an eight-quarter terminal block with tag likelihood weight 0.1")
  )
  for (case in standard_cases) {
    add_row(list(
      parent_step = "11-TimeVaryingCV",
      parameterization = "standard",
      family = "standard-recruitment-control",
      anchor = case$code,
      model_label = paste("Standard recruitment:", case$rationale),
      rationale = paste0(
        "Uses ordinary quarter-specific recruitment deviations and ", case$rationale,
        ". This is a structural control for the OPR terminal response."
      ),
      standard_terminal_quarters = case$quarters,
      standard_arithmetic_mean = case$mean,
      tag_weight_flag = case$tag_weight %||% 0L,
      tag_likelihood = case$tag_like %||% "negative_binomial",
      remove_2021_tags = isTRUE(case$drop),
      tag_deletion = if (isTRUE(case$drop)) "both" else "none",
      expected_final_par = "11.par"
    ))
  }

  spec <- do.call(rbind, rows)
  rownames(spec) <- NULL
  if (anyDuplicated(spec$step_id) || anyDuplicated(spec$anchor)) {
    stop("Sensitivity design contains duplicate step IDs or anchors.", call. = FALSE)
  }
  if (any(spec$terminal_penalty_flag != round(10 * spec$terminal_penalty_weight))) {
    stop("Terminal penalty flags do not match weight * 10.", call. = FALSE)
  }
  if (any(spec$parameterization == "opr" & !spec$terminal_years %in% c(1L, 2L))) {
    stop("OPR terminal windows must be one or two calendar years.", call. = FALSE)
  }
  if (any(spec$rr_2021_scope != "shared" & (
    !is.finite(spec$rr_2021_target) | spec$rr_2021_target <= 0 | spec$rr_2021_target >= 1 |
      !is.finite(spec$rr_2021_penalty) | spec$rr_2021_penalty < 0
  ))) {
    stop("Every separated reporting-rate case needs a probability target and non-negative prior penalty.", call. = FALSE)
  }
  if (any(!spec$rr_2021_scope %in% c("shared", "campaign", "group60"))) {
    stop("Unknown 2021 reporting-rate scope.", call. = FALSE)
  }
  expected_generated <- 114L
  if (nrow(spec) != expected_generated) {
    stop("Sensitivity design count changed: expected ", expected_generated, ", got ", nrow(spec), ".", call. = FALSE)
  }
  spec
}

opr_terminal_penalty_lf_control_step_ids <- function() {
  c("11-TimeVaryingCV", "12-OrthogonalPoly")
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
