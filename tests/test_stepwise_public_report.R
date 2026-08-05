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
  nrow(hessian) == 1L,
  identical(hessian$step_id, "22-Diagnostic"),
  identical(hessian$pdh, "Yes"),
  hessian$nonpositive_eigenvalues == 0L,
  hessian$eigenvalues_checked == 1997L,
  hessian$smallest_eigenvalue > 0
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
  recent <- stepwise_official_recent_quantities(series, map)
  diagnostic <- recent[recent$Configuration == "22-Diagnostic", , drop = FALSE]
  stopifnot(
    abs(diagnostic[["SB recent / SB F=0"]] - 0.1731393) < 5e-7,
    abs(diagnostic[["SB recent / SB MSY"]] - 1.025495) < 5e-7,
    abs(diagnostic[["F recent / F MSY"]] - 1.143641) < 5e-7
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
  "AKIA", "ghp_"
)
for (file in text_outputs) {
  text <- readLines(file, warn = FALSE, encoding = "UTF-8")
  stopifnot(!any(vapply(
    private_patterns, function(pattern) any(grepl(pattern, text, fixed = TRUE)),
    logical(1)
  )))
}
