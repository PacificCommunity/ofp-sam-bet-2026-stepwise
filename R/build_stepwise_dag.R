# Build the BET 2026 stepwise model-development diagram from job-config.R.
#
# The rendering engine is generic and lives in mfclshiny. This adapter only
# maps the assessment-specific configuration columns to that public API.

build_stepwise_dag <- function(
    config_path = "job-config.R",
    output_dir = Sys.getenv("OUTPUT_DIR", "outputs"),
    basename = "bet-2026-stepwise-dag") {
  if (!requireNamespace("mfclshiny", quietly = TRUE)) {
    stop("The mfclshiny package is required to build the stepwise diagram.")
  }

  config_path <- normalizePath(config_path, mustWork = TRUE)
  config <- new.env(parent = baseenv())
  sys.source(config_path, envir = config)

  if (!exists("stepwise_models", envir = config, inherits = FALSE)) {
    stop("job-config.R does not define stepwise_models.")
  }

  nodes <- get("stepwise_models", envir = config, inherits = FALSE)
  required <- c(
    "step_id", "scientific_parent_id", "model_label",
    "carry_status", "selected", "major_step"
  )
  missing <- setdiff(required, names(nodes))
  if (length(missing)) {
    stop("stepwise_models is missing: ", paste(missing, collapse = ", "))
  }

  selected_count <- sum(as.logical(nodes$selected), na.rm = TRUE)
  alternative_count <- nrow(nodes) - selected_count
  subtitle <- sprintf(
    "%d configurations across %d development stages",
    nrow(nodes),
    length(unique(nodes$major_step))
  )
  caption <- paste0(
    "Stepwise model-development pathway for the BET 2026 stock assessment. ",
    "Solid teal arrows trace the selected pathway; dashed grey branches show ",
    "alternative configurations that were evaluated but not carried forward. ",
    selected_count, " configurations were retained and ", alternative_count,
    " were comparison branches."
  )

  mfclshiny::build_model_dag_report(
    nodes = nodes,
    id_col = "step_id",
    parent_col = "scientific_parent_id",
    label_col = "model_label",
    status_col = "carry_status",
    selected_col = "selected",
    external_labels = c(
      "external-2023-diagnostic-archive" = "2023 diagnostic model"
    ),
    output_dir = output_dir,
    basename = basename,
    title = "BET 2026 model-development pathway",
    subtitle = subtitle,
    caption = caption,
    max_levels_per_row = 7L
  )
}

if (sys.nframe() == 0L) {
  build_stepwise_dag()
}
