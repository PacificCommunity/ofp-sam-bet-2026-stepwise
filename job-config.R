stepwise_models <- data.frame(
  step_id = c(
    "K020-tau-not-estimated-sel20c-f10-ndpen-weak",
    "K020-tau-not-estimated-sel20c-f10-ndpen-default"
  ),
  enabled = c(TRUE, TRUE),
  job_key = c(
    "f10-ndpen-weak",
    "f10-ndpen-default"
  ),
  job_title = c(
    "F10 non-decreasing penalty | Weak (10,000)",
    "F10 non-decreasing penalty | MFCL default (1,000,000)"
  ),
  model_label = c(
    "F10 5-node spline | Weak non-decreasing penalty",
    "F10 5-node spline | Default non-decreasing penalty"
  ),
  scientific_parent_id = c("Job 18718", "Job 18718"),
  major_step = c("F10 selectivity robustness", "F10 selectivity robustness"),
  substep = c("Weak penalty", "Default penalty"),
  change_axis = c(
    "Set F10 fish flags 16=1 and 56=10000; retain five estimated spline nodes",
    "Set F10 fish flags 16=1 and 56=1000000; retain five estimated spline nodes"
  ),
  kflow_memory = c("8GB", "8GB"),
  stringsAsFactors = FALSE
)
