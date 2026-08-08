source("R/build_stepwise_dag.R")
source("R/build_stepwise_key_quantities.R")

config <- new.env(parent = baseenv())
sys.source("job-config.R", envir = config)
models <- config$stepwise_models
stopifnot(
  nrow(models) == 23L,
  identical(models$step_id[c(14L, 15L)], c("14a-REG075", "14b-SUB075")),
  identical(tail(models$step_id, 4L), c(
    "19-DMG8Nmax25", "20-Tau2Fixed", "21-F33WeakPenalty", "22-Diagnostic"
  )),
  !any(grepl("19b|seed.?23", models$step_id, ignore.case = TRUE))
)

hessian <- read.csv(
  "data/stepwise/hessian-audit.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(hessian) == 23L,
  identical(hessian$step_id, models$step_id),
  all(hessian$pdh %in% c("Yes", "No", "Pending")),
  !any(hessian$pdh == "Pending"),
  identical(hessian$pdh[hessian$step_id == "22-Diagnostic"], "Yes"),
  hessian$nonpositive_eigenvalues[hessian$step_id == "22-Diagnostic"] == 0L,
  hessian$total_eigenvalues[hessian$step_id == "22-Diagnostic"] == 1997L,
  hessian$smallest_eigenvalue[hessian$step_id == "22-Diagnostic"] > 0
)

preview <- tempfile("stepwise-pathway-")
dag <- build_stepwise_dag(output_dir = preview, models = models)
stopifnot(
  nrow(dag$nodes) == 23L,
  nrow(dag$edges) == 22L,
  length(unique(dag$nodes$x)) == 1L,
  length(unique(c(dag$edges$x, dag$edges$xend))) == 1L,
  all(dag$edges$x == dag$edges$xend)
)

result_dir <- "results/stepwise-report/results"
series_file <- file.path(result_dir, "mfclshiny-report-depletion-data.csv")
if (file.exists(series_file)) {
  series <- read.csv(series_file, stringsAsFactors = FALSE, check.names = FALSE)
  source_index <- read.csv("data/stepwise/source-index.csv", stringsAsFactors = FALSE, check.names = FALSE)
  map <- stepwise_model_map(source_index, series)
  recent <- stepwise_cached_recent_quantities(
    file.path(result_dir, "tables", "stepwise-recent-key-quantities.csv"), map
  )
  if (is.null(recent)) recent <- stepwise_official_recent_quantities(series, map)
  stopifnot(isTRUE(stepwise_validate_recent_periods(recent)))
  expected_periods <- data.frame(
    `SB recent period` = vapply(
      recent[["Terminal year"]],
      function(year) stepwise_period_label(seq.int(year - 3L, year)),
      character(1)
    ),
    `SB F=0 period` = vapply(
      recent[["Terminal year"]],
      function(year) stepwise_period_label(seq.int(year - 9L, year)),
      character(1)
    ),
    `F recent period` = vapply(
      recent[["Terminal year"]],
      function(year) stepwise_period_label(seq.int(year - 4L, year - 1L)),
      character(1)
    ),
    check.names = FALSE
  )
  stopifnot(identical(
    recent[names(expected_periods)],
    expected_periods
  ))
  invalid_recent <- recent
  invalid_recent[["SB F=0 period"]][[1L]] <- "1900\u20131909"
  invalid_rejected <- tryCatch(
    {
      stepwise_validate_recent_periods(invalid_recent)
      FALSE
    },
    error = function(error) grepl(
      as.character(invalid_recent$Configuration[[1L]]),
      conditionMessage(error),
      fixed = TRUE
    )
  )
  stopifnot(isTRUE(invalid_rejected))
  diagnostic <- recent[recent$Configuration == "22-Diagnostic", , drop = FALSE]
  stopifnot(
    abs(diagnostic[["SB recent / SB F=0"]] - 0.1739457) < 5e-7,
    abs(diagnostic[["SB recent / SB MSY"]] - 1.025495) < 5e-7,
    abs(diagnostic[["F recent / F MSY"]] - 1.143641) < 5e-7
  )
}

report_html <- "results/stepwise-report/bet-2026-stepwise-model-development.html"
if (file.exists(report_html)) {
  html <- paste(readLines(report_html, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  stopifnot(
    grepl('src="data:text/html;charset=utf-8;base64,', html, fixed = TRUE),
    grepl("pacificcommunity.github.io/ofp-sam-bet-2026-stepwise/interactive-model-viewer.html", html, fixed = TRUE),
    grepl("KS D-statistic cutoff of 0.20", html, fixed = TRUE),
    grepl("maximum-likelihood estimates", html, fixed = TRUE),
    grepl("Copy table for Word", html, fixed = TRUE),
    grepl("Copy LaTeX", html, fixed = TRUE)
  )
}

likelihood_file <- "results/stepwise-report/stepwise-objective-components.csv"
if (file.exists(likelihood_file)) {
  likelihood <- read.csv(likelihood_file, stringsAsFactors = FALSE, check.names = FALSE)
  diagnostic <- likelihood[likelihood$Model == "22-Diagnostic", , drop = FALSE]
  stopifnot(
    nrow(likelihood) == 23L,
    nrow(diagnostic) == 1L,
    abs(diagnostic$Tag - 7379.619593) < 5e-7,
    abs(diagnostic[["Length frequency"]] - 80583.589246) < 5e-7,
    abs(diagnostic$Penalty - 210.347675) < 5e-7,
    any(abs(likelihood$Tag) > 0),
    any(abs(likelihood[["Length frequency"]]) > 0)
  )
}

text_outputs <- list.files(
  "results/stepwise-report",
  pattern = "[.](html|csv|json|txt|tex|bib|qmd)$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
private_patterns <- c(
  "/home/", "/var/lib/condor", "KflowOutput", "suvofp", "corp.spc",
  "Kflow Hessian merge Job", "AKIA", "ghp_"
)
for (file in text_outputs) {
  text <- readLines(file, warn = FALSE, encoding = "UTF-8")
  if (grepl("[.]html$", file, ignore.case = TRUE)) {
    # Embedded figures and the self-contained viewer are base64 data URIs.
    # Strip their encoded bytes before checking readable report metadata;
    # arbitrary base64 substrings can otherwise resemble path fragments.
    text <- gsub("data:[^\"']+", "", text, perl = TRUE)
    text <- text[!grepl(
      "^[[:space:]]*[A-Za-z0-9+/=]{40,}[[:space:]]*$",
      text,
      perl = TRUE
    )]
  }
  stopifnot(!any(vapply(
    private_patterns, function(pattern) any(grepl(pattern, text, fixed = TRUE)),
    logical(1)
  )))
}
