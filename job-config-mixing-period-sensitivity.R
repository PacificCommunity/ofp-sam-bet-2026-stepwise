## Job 16594 tag-mixing sensitivity grid.
##
## Every row uses the exact S03 model inputs used by Job 16594. At staging
## time, the row's patch changes only tag_flags(:,1:2) in bet.ini.

mixing_levels <- data.frame(
  mixing_key = c(
    "K005", "K010", "K015", "K020", "K025",
    "K030", "K035", "K040", "K045", "ALL2"
  ),
  mixing_label = c(
    "SC22 K=0.05", "SC22 K=0.10", "SC22 K=0.15",
    "SC22 K=0.20", "SC22 K=0.25", "SC22 K=0.30",
    "SC22 K=0.35", "SC22 K=0.40", "SC22 K=0.45",
    "Mix=2 all releases"
  ),
  stringsAsFactors = FALSE
)

mixing_row <- function(mixing_key, mixing_label, tag_flag2, plot_order) {
  step_id <- paste0("MIX-", mixing_key, "-TAGF2-", tag_flag2)
  rr_label <- if (identical(as.integer(tag_flag2), 1L)) {
    "RR post-mix only (tag2=1)"
  } else {
    "RR all periods (tag2=0)"
  }
  label <- sprintf("%02d. %s | %s", plot_order, mixing_label, rr_label)
  rr_key <- if (identical(as.integer(tag_flag2), 1L)) "rr-post" else "rr-all"
  data.frame(
    step_id = step_id,
    STEP_SELECT = step_id,
    enabled = TRUE,
    major_step = "MixingSensitivity",
    substep = mixing_key,
    scientific_parent = "Job 16594",
    change_axis = "tag_flags(:,1:2) only",
    control_notes = paste0(
      "Exact Job 16594 S03 inputs; tag_flags(:,1)=", mixing_label,
      "; tag_flags(:,2)=", tag_flag2,
      "; tag_flags(:,3:10), M, length-weight, RR and all other controls unchanged."
    ),
    model_label = label,
    job_title = paste0(label, " | Mixing sensitivity | base 16594"),
    job_key = tolower(sprintf("mix-%02d-%s-%s", plot_order, mixing_key, rr_key)),
    plot_order = as.integer(plot_order),
    plot_group = mixing_key,
    rr_mode = if (identical(as.integer(tag_flag2), 1L)) "post-mix-only" else "all-periods",
    run_mode = "doitall",
    source_dir = "steps/S03-CommonTagTau-MIX015/model",
    mixing_key = mixing_key,
    tag_flags_it2 = as.character(tag_flag2),
    region_count = 5L,
    kflow_cpus = 2L,
    kflow_memory = "8GB",
    kflow_disk = "8GB",
    mfcl_program_path = "/home/mfcl/mfclo64",
    input_par = "",
    frq = "bet.frq",
    output_par = "",
    stringsAsFactors = FALSE
  )
}

stepwise_models <- do.call(
  rbind,
  lapply(seq_len(nrow(mixing_levels)), function(index) {
    level <- mixing_levels[index, , drop = FALSE]
    rbind(
      mixing_row(level$mixing_key, level$mixing_label, 1L, 2L * index - 1L),
      mixing_row(level$mixing_key, level$mixing_label, 0L, 2L * index)
    )
  })
)

stepwise_run <- list(
  default_step_select = "MIX-K015-TAGF2-1",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-sc22-ip10-mixing-tagflag-grid-20260727",
  trigger_next = FALSE
)
