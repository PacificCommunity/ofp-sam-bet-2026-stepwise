## Job 16594 DM Nmax sensitivity grid.
##
## Every row stages the exact S03 model inputs used by Job 16594 and changes
## only the runtime value supplied to MFCL parest flag 342. The reference
## Job 16594 value Nmax=25 is intentionally not rerun.

nmax_values <- c(10L, 15L, 40L, 50L)

nmax_row <- function(nmax, plot_order) {
  step_id <- sprintf("JOB16594-NMAX%d", nmax)
  label <- sprintf(
    "%02d. Job 16594 | DM G8 Nmax=%d | common tau",
    plot_order,
    nmax
  )
  data.frame(
    step_id = step_id,
    STEP_SELECT = step_id,
    enabled = TRUE,
    major_step = "DMNmaxSensitivity",
    substep = paste0("NMAX", nmax),
    scientific_parent = "Job 16594",
    change_axis = paste0(
      "DM effective-sample-size upper asymptote only: Nmax 25 -> ",
      nmax
    ),
    control_notes = paste0(
      "Exact Job 16594 S03 inputs and full doitall sequence; change only ",
      "DM_NMAX so MFCL parest flag 342=", nmax,
      ". SC22-IP10 K=0.15 mixing, tag_flags(:,2)=1, one common/native tau, ",
      "fixed M, G8 grouping, Nmax-independent inputs and all other controls ",
      "remain unchanged."
    ),
    model_label = label,
    job_title = paste0(label, " | Nmax sensitivity"),
    job_key = sprintf("job16594-nmax-%d", nmax),
    plot_order = as.integer(plot_order),
    tau_mode = "estimated-common",
    tag_tau_grouping = "common",
    dm_nmax = as.character(nmax),
    run_mode = "doitall",
    source_dir = "steps/S03-CommonTagTau-MIX015/model",
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
  lapply(seq_along(nmax_values), function(index) {
    nmax_row(nmax_values[[index]], index)
  })
)

stepwise_run <- list(
  default_step_select = "JOB16594-NMAX10",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job16594-dm-nmax10-15-40-50-20260727",
  trigger_next = FALSE
)
