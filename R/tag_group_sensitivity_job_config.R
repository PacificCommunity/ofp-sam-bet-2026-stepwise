## Four-cell terminal-2022 G59/G60 tag-cohort campaign.

config_path <- file.path(getwd(), "job-config.R")
if (!file.exists(config_path)) {
  stop("Run this configuration from the repository root.", call. = FALSE)
}

full_config <- new.env(parent = baseenv())
sys.source(config_path, envir = full_config)

tag_step_ids <- c(
  "20-Terminal2022TagReference",
  "20a-Terminal2022TagG60Excluded",
  "20b-Terminal2022TagG59Excluded",
  "20c-Terminal2022TagG59G60Excluded"
)
row_index <- match(tag_step_ids, full_config$stepwise_models$step_id)
if (anyNA(row_index)) {
  stop("One or more terminal-2022 tag sensitivity rows are missing.", call. = FALSE)
}

stepwise_models <- full_config$stepwise_models[row_index, , drop = FALSE]
rownames(stepwise_models) <- NULL
