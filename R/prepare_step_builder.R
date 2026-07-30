## Constructor for self-contained BET 2026 step folders.

make_step <- function(step_id, frq_source, ini_source, tag_source, age_source,
                      frq_chop_year = NA_integer_, frq_transform = NULL,
                      size_data_qc = FALSE,
                      size_data_qc_source_sha256 = "",
                      frq_tag_groups = NA_integer_, index_cpue_source = "",
                      mix_from_ini = TRUE,
                      retain_reporting_rates_during_mixing = TRUE,
                      tag_reporting_source = "",
                      reporting_rate_variant = "none",
                      tag_mixing_source = "",
                      tag_flag_column2 = 0L,
                      age_effective_sample_size = NA_real_,
                      tag_reporting_cell_repairs = list(),
                      reporting_rate_group_prior_repairs = list(),
                      reg_scaling_source = "",
                      regional_scaling_weight = NA_integer_,
                      doitall_edits = list(),
                      cpue_sigma_calibration = NULL,
                      francis_divisors = numeric(),
                      francis_source = "",
                      francis_source_note = "",
                      title, summary, bullets, input_notes, control_notes,
                      input_changes = NULL, run_notes = character(),
                      outstanding = character(),
                      status = "Ready for Kflow smoke runs; full MFCL fit not run here.") {
  step_dir <- file.path(root, "steps", step_id)
  model_dir <- file.path(step_dir, "model")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)
  remove_model_par_files(model_dir)
  # Optional audit sidecars must be regenerated only by steps that introduce
  # them. Removing them first prevents a renamed/reordered campaign from
  # inheriting stale evidence from an earlier occupant of the folder.
  unlink(
    file.path(model_dir, c(
      "cpue_mle_sigma_audit.csv", "francis_weights.csv",
      "f15-lf-qc-audit.csv", "f15-lf-qc-summary.csv",
      "dom-lf-qc-audit.csv", "dom-lf-qc-summary.csv"
    )),
    force = TRUE
  )

  frq_out <- file.path(model_dir, "bet.frq")
  if (identical(frq_transform, "effort_creep")) {
    if (!is.na(frq_chop_year)) {
      stop("Effort creep is only supported for the complete FRQ", call. = FALSE)
    }
    write_frq_with_effort_creep(frq_source, frq_out)
    frq_note <- "generated from the authoritative FRQ by changing only positive effort for F29-F33"
  } else if (is.na(frq_chop_year)) {
    copy_one(frq_source, frq_out)
    frq_note <- "copied without year chopping"
  } else {
    chop_frq(frq_source, frq_out, max_year = frq_chop_year)
    frq_note <- paste0("chopped to year <= ", frq_chop_year)
  }
  if (nzchar(index_cpue_source)) {
    replaced <- replace_frq_index_cpue_records(
      frq_out, index_cpue_source,
      max_year = frq_chop_year,
      index_fisheries = 29:33
    )
    frq_note <- paste0(frq_note, "; replaced ", replaced, " F29-F33 CPUE records")
  }
  size_qc <- NULL
  if (isTRUE(size_data_qc)) {
    size_qc <- apply_bet_size_data_qc(
      model_dir,
      expected_source_sha256 = size_data_qc_source_sha256
    )
    frq_note <- paste0(
      frq_note,
      "; F15 <70 cm bins zeroed and F21-F23 >90 cm midpoint bins removed",
      " without renormalisation"
    )
  }
  normalized <- normalize_frq_absent_lf_records(frq_out)
  if (normalized) frq_note <- paste0(frq_note, "; normalized ", normalized, " absent-LF records")
  ensure_frq_fishery_region_locations(frq_out)
  if (!is.na(frq_tag_groups)) set_frq_tag_group_count(frq_out, frq_tag_groups)
  frq_counts <- frq_header_counts(readLines(frq_out, warn = FALSE), frq_out)

  ini_out <- file.path(model_dir, "bet.ini")
  tag_out <- file.path(model_dir, "bet.tag")
  copy_one(ini_source, ini_out)
  copy_one(tag_source, tag_out)
  ini_notes <- c(repair_tag_reporting_matrices(
    ini_out,
    tag_out,
    reference_ini = if (exists("regfish_ini_source")) regfish_ini_source else "",
    reference_tag = if (exists("regfish_tag_source")) regfish_tag_source else ""
  ))
  if (nzchar(tag_reporting_source)) {
    ini_notes <- c(ini_notes, copy_tag_reporting_matrices(ini_out, tag_reporting_source))
  }
  if (length(tag_reporting_cell_repairs)) {
    for (repair in tag_reporting_cell_repairs) {
      ini_notes <- c(ini_notes, repair_positive_tag_recapture_reporting_rates(
        ini_out, tag_out,
        target_fishery = repair$target_fishery,
        source_fishery = repair$source_fishery
      ))
    }
  }
  apply_fixm_m(ini_out)
  ini_notes <- c(
    ini_notes,
    paste(
      "Fixed Lorenzen natural-mortality intercept applied from",
      get0("fixm_age_par_source", ifnotfound = "locked diagnostic")
    ),
    set_total_population_scalar(
      ini_out,
      get0("five_region_total_population_scalar", ifnotfound = 17L)
    )
  )
  lw <- get0("bias_corrected_length_weight_parameters", ifnotfound = character())
  if (length(lw)) ini_notes <- c(ini_notes, set_length_weight_parameters(ini_out, lw))
  ini_notes <- c(
    ini_notes,
    ensure_ini_tag_flags(
      ini_out,
      frq_counts$n_tag_groups,
      tag_path = tag_out,
      terminal_year = frq_chop_year,
      retain_reporting_rates_during_mixing = retain_reporting_rates_during_mixing
    ),
    ensure_ini_tag_shed_rates(ini_out, frq_counts$n_tag_groups)
  )
  if (identical(reporting_rate_variant, "rrpttp26")) {
    ini_notes <- c(
      ini_notes,
      apply_rrpttp26_reporting_rates(ini_out, tag_path = tag_out)
    )
  } else if (!reporting_rate_variant %in% c("none", "peatman")) {
    stop("Unknown reporting-rate variant: ", reporting_rate_variant, call. = FALSE)
  }
  if (nzchar(tag_mixing_source)) {
    ini_notes <- c(ini_notes, copy_ini_tag_flag_column(ini_out, tag_mixing_source, 1L))
  }
  if (!is.na(tag_flag_column2)) {
    ini_notes <- c(ini_notes, set_ini_tag_flag_column(ini_out, 2L, tag_flag_column2))
  }
  ini_notes <- c(ini_notes, repair_tag_reporting_grouped_initial_values(ini_out))
  if (length(reporting_rate_group_prior_repairs)) {
    for (repair in reporting_rate_group_prior_repairs) {
      ini_notes <- c(ini_notes, standardize_positive_tag_reporting_group_prior(
        ini_out,
        group_id = repair$group_id,
        expected_mean = repair$expected_mean,
        expected_penalty = repair$expected_penalty
      ))
    }
  }
  validate_positive_tag_recapture_reporting_rates(ini_out, tag_out)
  validate_tag_reporting_grouped_initial_values(ini_out)

  age_out <- file.path(model_dir, "bet.age_length")
  copy_one(age_source, age_out)
  age_note <- "exact source variant retained"
  if (!is.na(age_effective_sample_size)) {
    age_note <- set_age_length_effective_sample_size(age_out, age_effective_sample_size)
  }

  has_reg_scaling <- nzchar(reg_scaling_source)
  reg_info <- NULL
  if (has_reg_scaling) {
    reg_info <- write_regional_scaling_inputs(
      source_path = reg_scaling_source,
      active_path = file.path(model_dir, "bet.reg_scaling"),
      full_path = file.path(model_dir, "bet.reg_scaling.full"),
      start_period = reg_scaling_active_start_period,
      end_period = reg_scaling_active_end_period
    )
  }

  template_step <- get0("stepwise_5_region_template_step_id", ifnotfound = "05-NewStructure")
  template_model <- file.path(root, "steps", template_step, "model")
  copy_one(file.path(template_model, "mfcl.cfg"), file.path(model_dir, "mfcl.cfg"))
  fishery_map_out <- file.path(model_dir, "fishery_map.R")
  copy_one(file.path(template_model, "fishery_map.R"), fishery_map_out)
  if (isTRUE(doitall_edits$parsimonious_selectivity)) {
    apply_parsimonious_selectivity_map(fishery_map_out)
  }
  write_generated_tag_rep_map(model_dir)

  sigma_flags <- integer()
  if (!is.null(cpue_sigma_calibration)) {
    sigma_flags <- cpue_sigma_calibration$flag92
    write_cpue_mle_sigma_audit(model_dir, cpue_sigma_calibration)
  }
  write_doitall(
    file.path(template_model, "doitall.sh"),
    file.path(model_dir, "doitall.sh"),
    mix_from_ini = mix_from_ini,
    regional_cpue = isTRUE(doitall_edits$regional_cpue),
    regional_scaling_weight = regional_scaling_weight,
    regional_scaling_periods = if (has_reg_scaling) reg_info$total_periods else 292L,
    regional_scaling_start_period = reg_scaling_active_start_period,
    regional_scaling_end_period = reg_scaling_active_end_period,
    parsimonious_selectivity = isTRUE(
      doitall_edits$parsimonious_selectivity
    ),
    ph_id_young5_selectivity = isTRUE(
      doitall_edits$ph_id_young5_selectivity
    ),
    tail_compression_1pct = isTRUE(doitall_edits$tail_compression_1pct),
    time_varying_cv = isTRUE(doitall_edits$time_varying_cv),
    effort_creep = identical(frq_transform, "effort_creep"),
    dom_divisor200 = isTRUE(doitall_edits$dom_divisor200),
    cpue_sigma_flag92 = sigma_flags,
    cpue_mle_sigma = if (!is.null(cpue_sigma_calibration)) {
      cpue_sigma_calibration$cpue_mle_sigma
    } else {
      numeric()
    },
    francis_divisors = francis_divisors,
    dm_grouping = get0("dm_grouping", doitall_edits, ifnotfound = ""),
    dm_nmax = get0("dm_nmax", doitall_edits, ifnotfound = NA_integer_),
    dm_fixed_concentration = get0(
      "dm_fixed_concentration", doitall_edits, ifnotfound = NA_real_
    )
  )
  if (length(francis_divisors)) {
    if (!nzchar(francis_source)) {
      stop("Francis divisors require their bundled audit CSV source", call. = FALSE)
    }
    copy_one(francis_source, file.path(model_dir, "francis_weights.csv"))
  }
  entries <- list(
    list(role = "frq", file = "bet.frq", source = frq_source, note = frq_note),
    list(role = "ini", file = "bet.ini", source = ini_source,
         note = paste(ini_notes[nzchar(ini_notes)], collapse = "; ")),
    list(role = "tag", file = "bet.tag", source = tag_source,
         note = "exact selected tag input; never replaced by an earlier step"),
    list(role = "age_length", file = "bet.age_length", source = age_source, note = age_note),
    list(role = "doitall", file = "doitall.sh",
         source = file.path("steps", template_step, "model", "doitall.sh"),
      note = "generated from the five-region template with only declared cumulative controls")
  )
  if (!is.null(size_qc)) {
    entries <- c(entries, list(
      list(
        role = "f15_size_qc", file = "f15-lf-qc-summary.csv",
        source = frq_source,
        note = paste0(
          "F15 bins below 70 cm set to zero; source SHA ",
          size_qc$source_sha256
        )
      ),
      list(
        role = "domestic_size_qc", file = "dom-lf-qc-summary.csv",
        source = frq_source,
        note = paste0(
          "F21-F23 intervals with midpoint above 90 cm removed; output SHA ",
          size_qc$output_sha256
        )
      )
    ))
  }
  if (nzchar(tag_reporting_source)) {
    entries <- c(entries, list(list(
      role = "ini_reporting_rates", file = "bet.ini", source = tag_reporting_source,
      note = paste0(reporting_rate_variant, " reporting-rate matrices only")
    )))
  }
  if (identical(reporting_rate_variant, "rrpttp26")) {
    entries <- c(entries, list(list(
      role = "rrpttp26_reporting_audit", file = "bet.ini",
      source = get0("rrpttp26_reporting_source", ifnotfound = ""),
      note = "complete audited 33-fishery RRPTTP26 matrix specification"
    )))
  }
  if (nzchar(tag_mixing_source)) {
    entries <- c(entries, list(list(
      role = "ini_tag_mixing", file = "bet.ini", source = tag_mixing_source,
      note = "only tag_flags(:,1) copied; tag_flags(:,2) and all other INI fields retained"
    )))
  }
  if (has_reg_scaling) {
    entries <- c(entries, list(
      list(role = "reg_scaling", file = "bet.reg_scaling", source = reg_scaling_source,
           note = paste0("active periods ", reg_scaling_active_start_period, "-", reg_scaling_active_end_period)),
      list(role = "reg_scaling_full", file = "bet.reg_scaling.full", source = reg_scaling_source,
           note = "complete source matrix retained as a calculation/audit artifact")
    ))
  }
  if (!is.null(cpue_sigma_calibration)) {
    entries <- c(entries, list(list(
      role = "cpue_mle_sigma", file = "cpue_mle_sigma_audit.csv",
      source = if (!is.null(cpue_sigma_calibration$source_file)) {
        cpue_sigma_calibration$source_file
      } else {
        file.path("R", "prepare_bet_2026_step_inputs.R")
      },
      note = cpue_sigma_calibration$basis
    )))
  }
  if (length(francis_divisors)) {
    entries <- c(entries, list(list(
      role = "francis_weights",
      file = "francis_weights.csv",
      source = francis_source,
      note = paste(
        francis_source_note,
        "All 33 positive recommended_divisor values are validated and applied to fish flag 49."
      )
    )))
  }
  write_manifest(step_dir, entries)
  write_readme(
    step_dir = step_dir,
    title = title,
    summary = summary,
    bullets = bullets,
    inputs = c(input_notes, "input_manifest.csv" = "machine-readable source and generated-edit provenance"),
    controls = c(
      control_notes,
      "The folder is generated independently from source inputs; its scientific parent is not a runtime dependency.",
      "No OPR or length-bin selectivity controls are generated.",
      "INI and TAG inputs are never rolled back to an earlier selected row."
    ),
    outstanding = outstanding,
    status = status,
    run_notes = run_notes,
    input_changes = input_changes,
    source_revisions = input_repo_revision_table()
  )
  invisible(step_dir)
}
