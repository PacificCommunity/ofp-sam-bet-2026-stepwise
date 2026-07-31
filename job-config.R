stepwise_models <- data.frame(
  step_id = c(
    "K020-tau-not-estimated-sel20c-f10-ndpen-weak",
    "K020-tau-not-estimated-sel20c-f10-ndpen-default",
    "K020-tau-not-estimated-sel20c-f10-logistic",
    "K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node"
  ),
  enabled = c(TRUE, TRUE, TRUE, TRUE),
  job_key = c(
    "f10-ndpen-weak",
    "f10-ndpen-default",
    "f10-logistic",
    "f10-logistic-r1ll-4node"
  ),
  job_title = c(
    "F10 non-decreasing penalty | Weak (10,000)",
    "F10 non-decreasing penalty | MFCL default (1,000,000)",
    "F10 asymptotic logistic selectivity",
    "F10 logistic | Region-1 LL four-node splines"
  ),
  model_label = c(
    "F10 5-node spline | Weak non-decreasing penalty",
    "F10 5-node spline | Default non-decreasing penalty",
    "F10 2-parameter asymptotic logistic selectivity",
    "F10 logistic | F1-F3 independently estimated four-node splines"
  ),
  scientific_parent_id = rep("Job 18718", 4),
  major_step = rep("F10 and Region-1 LL selectivity robustness", 4),
  substep = c("Weak penalty", "Default penalty", "Logistic form", "Logistic plus R1 four-node"),
  change_axis = c(
    "Set F10 fish flags 16=1 and 56=10000; retain five estimated spline nodes",
    "Set F10 fish flags 16=1 and 56=1000000; retain five estimated spline nodes",
    "Set F10 fish flag 57=1; estimate the two asymptotic logistic parameters",
    "Retain F10 flag 57=1 and set fish flag 61=4 for F1-F3 only"
  ),
  kflow_memory = rep("8GB", 4),
  stringsAsFactors = FALSE
)
