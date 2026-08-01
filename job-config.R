stepwise_models <- data.frame(
  step_id = c(
    "K020-tau-not-estimated-sel20c-f10-ndpen-weak",
    "K020-tau-not-estimated-sel20c-f10-ndpen-default",
    "K020-tau-not-estimated-sel20c-f10-logistic",
    "K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node",
    "K020-tau-not-estimated-sel20c-f10-logistic-f33-logistic",
    "K020-tau-not-estimated-sel20c-f10-logistic-f33-ndpen-strong",
    "K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node-f33-logistic",
    "K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node-f33-ndpen-strong",
    "K020-tau-not-estimated-sel20c-f10-ndpen-weak-seed23-base"
  ),
  enabled = rep(TRUE, 9),
  job_key = c(
    "f10-ndpen-weak",
    "f10-ndpen-default",
    "f10-logistic",
    "f10-logistic-r1ll-4node",
    "f10-logistic-f33-logistic",
    "f10-logistic-f33-ndpen-strong",
    "f10-logistic-r1ll-4node-f33-logistic",
    "f10-logistic-r1ll-4node-f33-ndpen-strong",
    "f10-ndpen-weak-seed23-base"
  ),
  job_title = c(
    "F10 non-decreasing penalty | Weak (10,000)",
    "F10 non-decreasing penalty | MFCL default (1,000,000)",
    "F10 asymptotic logistic selectivity",
    "F10 logistic | Region-1 LL four-node splines",
    "F10 logistic | F33 logistic | F1-F3 five-node",
    "F10 logistic | F33 non-decreasing 1e8 | F1-F3 five-node",
    "F10 logistic | F33 logistic | F1-F3 four-node",
    "F10 logistic | F33 non-decreasing 1e8 | F1-F3 four-node",
    "F10 weak non-decreasing | Job 19325 best-objective seed 23 base"
  ),
  model_label = c(
    "F10 5-node spline | Weak non-decreasing penalty",
    "F10 5-node spline | Default non-decreasing penalty",
    "F10 2-parameter asymptotic logistic selectivity",
    "F10 logistic | F1-F3 independently estimated four-node splines",
    "F10 logistic | F33 logistic | F1-F3 five-node splines",
    "F10 logistic | F33 five-node spline with non-decreasing weight 1e8 | F1-F3 five-node",
    "F10 logistic | F33 logistic | F1-F3 four-node splines",
    "F10 logistic | F33 five-node spline with non-decreasing weight 1e8 | F1-F3 four-node",
    "F10 five-node spline | Weak non-decreasing penalty | deterministic Job 19325 seed-23 base"
  ),
  scientific_parent_id = c(rep("Job 18718", 2), rep("Job 19326", 6), "Job 19325"),
  major_step = c(
    rep("F10 selectivity robustness", 2),
    rep("F10, Region-1 LL, and Index R5 selectivity robustness", 6),
    "Best-objective jitter solution promoted to reproducible base"
  ),
  substep = c(
    "Weak penalty",
    "Default penalty",
    "F10 logistic base",
    "F1-F3 four-node control",
    "F33 logistic; F1-F3 five-node",
    "F33 non-decreasing; F1-F3 five-node",
    "F33 logistic; F1-F3 four-node",
    "F33 non-decreasing; F1-F3 four-node",
    "Job 19325 seed 23 base"
  ),
  change_axis = c(
    "Set F10 fish flags 16=1 and 56=10000; retain five estimated spline nodes",
    "Set F10 fish flags 16=1 and 56=1000000; retain five estimated spline nodes",
    "Set F10 fish flag 57=1; estimate the two asymptotic logistic parameters",
    "Retain F10 flag 57=1 and set fish flag 61=4 for F1-F3 only",
    "Retain F10 logistic and F1-F3 five-node splines; set F33 flag 57=1 after Phase-5 group separation",
    "Retain F10 logistic and F1-F3 five-node splines; set F33 flags 16=1 and 56=100000000 after Phase-5 group separation",
    "Retain F10 logistic and F1-F3 flag 61=4; set F33 flag 57=1 after Phase-5 group separation",
    "Retain F10 logistic and F1-F3 flag 61=4; set F33 flags 16=1 and 56=100000000 after Phase-5 group separation",
    "Retain the Job 19325 weak F10 model and reproduce its best converged seed-23 CV=0.1 Phase-1/2/5 initialization path"
  ),
  kflow_memory = rep("8GB", 9),
  stringsAsFactors = FALSE
)
