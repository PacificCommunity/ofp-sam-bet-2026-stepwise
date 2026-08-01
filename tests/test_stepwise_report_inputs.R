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
      records = list(Model = list("Base", "Final"), Objective = list(10, 9))
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
stopifnot(nrow(summary) == 2L, ncol(summary) == 2L)
stopifnot(identical(as.character(summary$Model), c("Base", "Final")))

index <- stepwise_source_index_from_viewer(parsed)
stopifnot(nrow(index) == 2L)
stopifnot(identical(index$step_id, c("01-base", "02-final")))

html <- stepwise_dynamic_table_html(summary, "test-table")
stopifnot(grepl("test-table", html, fixed = TRUE))
stopifnot(grepl("Final", html, fixed = TRUE))
