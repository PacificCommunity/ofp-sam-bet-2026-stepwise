`%||%` <- function(x, y) {
  if (is.null(x) || !length(x)) return(y)
  first <- x[[1L]]
  if (length(first) == 1L && is.atomic(first) && is.na(first)) y else x
}
stepwise_html_escape <- function(x) {
  x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}
source("R/stepwise_report_inputs.R")

viewer_file <- tempfile(fileext = ".html")
viewer_payload <- list(
  models = list(key = list("01-base", "02-final"), label = list("Base", "Final")),
  metrics = list(
    list(
      key = "model_summary", kind = "table",
      records = list(
        Model = list("Base", "22-Diagnostic"),
        `Model fit time` = list("1 min", "2 min"),
        `Fit seconds` = list(60, 120),
        `Memory request` = list("8GB", "8GB"),
        `Max gradient` = list(1e-4, 9e-5),
        `Objective value` = list(10, 9),
        `Active parameters` = list(100, 101),
        `Hessian PDH` = list("Not evaluated", "Not evaluated"),
        `Non-positive eigenvalues` = list("", ""),
        `Smallest eigenvalue` = list("", "")
      ),
      columns = as.list(c(
        "Model", "Model fit time", "Fit seconds", "Memory request", "Max gradient",
        "Objective value", "Active parameters", "Hessian PDH",
        "Non-positive eigenvalues", "Smallest eigenvalue"
      ))
    ),
    list(
      key = "objective_components", kind = "table",
      records = list(Model = list("Base", "Final"), Penalty = list(2, 1))
    )
  )
)
writeLines(
  c(
    "<html><body>",
    '<script type="application/json" id="viewer-data">',
    jsonlite::toJSON(viewer_payload, auto_unbox = TRUE),
    "</script></body></html>"
  ),
  viewer_file
)

parsed <- stepwise_extract_viewer_data(viewer_file)
summary <- stepwise_metric_table(parsed, "model_summary")
stopifnot(nrow(summary) == 2L)
stopifnot(identical(as.character(summary$Model), c("Base", "22-Diagnostic")))

hessian_file <- tempfile(fileext = ".csv")
write.csv(data.frame(
  step_id = "22-Diagnostic", pdh = "Yes", total_eigenvalues = 1997L,
  nonpositive_eigenvalues = 0L, smallest_eigenvalue = 2.55194e-7,
  source = "Native MFCL Hessian eigen analysis"
), hessian_file, row.names = FALSE)
stopifnot(stepwise_simplify_viewer(viewer_file, hessian_file))
simplified <- stepwise_extract_viewer_data(viewer_file)
simplified_summary <- stepwise_metric_table(simplified, "model_summary")
stopifnot(
  identical(names(simplified_summary), c(
    "Model", "Max gradient", "Objective value", "Active parameters", "Hessian PDH",
    "Non-positive eigenvalues", "Smallest eigenvalue"
  )),
  identical(as.character(simplified_summary$`Hessian PDH`), c("Not evaluated", "Yes")),
  identical(as.character(simplified_summary$`Non-positive eigenvalues`[[1L]]), ""),
  as.numeric(simplified_summary$`Non-positive eigenvalues`[[2L]]) == 0
)

index <- stepwise_source_index_from_viewer(simplified)
stopifnot(nrow(index) == 2L)
stopifnot(identical(index$step_id, c("01-base", "02-final")))

html <- stepwise_dynamic_table_html(summary, "test-table")
stopifnot(grepl("test-table", html, fixed = TRUE))
stopifnot(grepl("22-Diagnostic", html, fixed = TRUE))
