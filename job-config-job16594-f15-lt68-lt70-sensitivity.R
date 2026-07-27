## Job 16594 F15 length-frequency QC sensitivity.
##
## The Job 16594 Nmax=25 reference and the separately submitted unfiltered
## Nmax=15 control are not rerun. These four rows cross two data-QC variants
## with Nmax 25 and 15, while retaining every other Job 16594 input/control.

f15_variants <- data.frame(
  token = c("LT68", "LT70"),
  mode = c("lt68", "lt70"),
  short_label = c(
    "F15 remove lengths <68 cm",
    "F15 remove lengths <70 cm"
  ),
  change_axis = c(
    "Set F15 length-bin counts below 68 cm to zero; retain the reduced sample total.",
    "Set F15 length-bin counts below 70 cm to zero; retain the reduced sample total."
  ),
  stringsAsFactors = FALSE
)

make_f15_row <- function(variant_index, nmax, plot_order) {
  variant <- f15_variants[variant_index, , drop = FALSE]
  step_id <- sprintf("F15-%s-NMAX%d", variant$token, nmax)
  label <- sprintf(
    "%02d. Job16594 F15 QC | %s | DM Nmax=%d",
    plot_order,
    variant$short_label,
    nmax
  )
  parent <- if (identical(as.integer(nmax), 25L)) {
    "Job 16594 (unfiltered F15, Nmax=25)"
  } else {
    "Job 17222 (unfiltered F15, Nmax=15 control)"
  }
  data.frame(
    step_id = step_id,
    STEP_SELECT = step_id,
    enabled = TRUE,
    major_step = "F15LengthQCSensitivity",
    substep = paste0(variant$token, "-NMAX", nmax),
    scientific_parent = parent,
    change_axis = variant$change_axis,
    control_notes = paste0(
      "Exact Job 16594 S03 inputs. F15_QC_MODE=", variant$mode,
      "; DM_NMAX=", nmax,
      ". F15 catch and effort, all non-F15 FRQ records, SC22-IP10 K=0.15 ",
      "mixing, tag_flags(:,2)=1, one estimated common/native tau, fixed M, ",
      "regional recruitment penalty 0.1, tag likelihood 100%, selectivity, ",
      "growth, and all other controls remain unchanged. Removed LF counts are ",
      "not renormalised. No complete quarter or complete fishery LF is removed."
    ),
    model_label = label,
    job_title = paste0(label, " | F15 LF data-QC sensitivity"),
    job_key = sprintf("job16594-f15-%s-nmax%d", tolower(variant$token), nmax),
    plot_order = as.integer(plot_order),
    f15_qc_mode = variant$mode,
    dm_nmax = as.character(nmax),
    tau_mode = "estimated-common",
    tag_tau_grouping = "common",
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

rows <- list()
plot_order <- 0L
for (nmax in c(25L, 15L)) {
  for (variant_index in seq_len(nrow(f15_variants))) {
    plot_order <- plot_order + 1L
    rows[[plot_order]] <- make_f15_row(variant_index, nmax, plot_order)
  }
}
stepwise_models <- do.call(rbind, rows)

stepwise_run <- list(
  default_step_select = "F15-LT68-NMAX25",
  model_rows = nrow(stepwise_models),
  flow_group = "bet-2026-job16594-f15-lt68-lt70-dm15-25-20260727",
  trigger_next = FALSE
)
