#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
data_dir <- file.path(root, "data", "stepwise")
source_index <- utils::read.csv(
  file.path(data_dir, "source-index.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
provenance <- utils::read.csv(
  file.path(data_dir, "payload-provenance.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
hessian_audit <- utils::read.csv(
  file.path(data_dir, "hessian-audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(
  nrow(source_index) == 23L,
  nrow(provenance) == 23L,
  !anyDuplicated(source_index$step_id),
  !anyDuplicated(source_index$job_number),
  identical(source_index$step_id, provenance$step_id),
  identical(as.integer(source_index$job_number), as.integer(provenance$model_job_number)),
  !any(grepl("19b|seed.?23", source_index$step_id, ignore.case = TRUE))
)
diagnostic_hessian <- hessian_audit[
  hessian_audit$step_id == "22-Diagnostic",
  ,
  drop = FALSE
]
stopifnot(
  nrow(hessian_audit) == 23L,
  identical(hessian_audit$step_id, source_index$step_id),
  all(hessian_audit$pdh %in% c("Yes", "No", "Pending")),
  sum(hessian_audit$pdh == "Pending") <= 5L,
  nrow(diagnostic_hessian) == 1L,
  diagnostic_hessian$pdh == "Yes",
  diagnostic_hessian$total_eigenvalues == 1997L,
  diagnostic_hessian$nonpositive_eigenvalues == 0L,
  abs(diagnostic_hessian$smallest_eigenvalue - 2.55194e-7) < 1e-14
)

payload_paths <- file.path(data_dir, "models", source_index$step_id, "model_payload.rds")
if (!all(file.exists(payload_paths))) {
  stop("Missing model payloads: ", paste(source_index$step_id[!file.exists(payload_paths)], collapse = ", "))
}

collect_character <- function(value) {
  if (is.character(value)) return(value)
  if (is.list(value)) return(unlist(lapply(value, collect_character), use.names = FALSE))
  character()
}

audits <- lapply(seq_along(payload_paths), function(i) {
  payload <- readRDS(payload_paths[[i]])
  required <- c("version", "object_cache_mode", "artifact_mode", "obj_fun", "max_grad")
  missing <- setdiff(required, names(payload))
  if (length(missing)) {
    stop(source_index$step_id[[i]], " payload is missing: ", paste(missing, collapse = ", "))
  }
  objective <- suppressWarnings(as.numeric(payload$obj_fun[[1L]]))
  maximum_gradient <- suppressWarnings(as.numeric(payload$max_grad[[1L]]))
  if (!is.finite(objective) || !is.finite(maximum_gradient)) {
    stop(source_index$step_id[[i]], " payload has non-finite fit diagnostics")
  }
  metadata <- collect_character(payload)
  private <- metadata[grepl(
    "(/home/|/var/lib/condor|KflowOutput|suvofp|corp[.]spc|AKIA|ghp_)",
    metadata,
    ignore.case = TRUE
  )]
  if (length(private)) {
    stop(source_index$step_id[[i]], " payload contains machine-specific or private metadata")
  }
  data.frame(
    step_id = source_index$step_id[[i]],
    job_number = source_index$job_number[[i]],
    objective = objective,
    maximum_gradient = maximum_gradient,
    object_cache_mode = as.character(payload$object_cache_mode[[1L]]),
    artifact_mode = as.character(payload$artifact_mode[[1L]]),
    bytes = file.info(payload_paths[[i]])$size,
    stringsAsFactors = FALSE
  )
})
audit <- do.call(rbind, audits)

cache_root <- file.path(data_dir, "report-cache", "outputs")
cache_viewer <- file.path(cache_root, "overview", "interactive-model-viewer.html")
cache_series <- file.path(cache_root, "mfclshiny-report-depletion-data.csv")
cache_recent <- file.path(cache_root, "tables", "stepwise-recent-key-quantities.csv")
cache_files <- c(cache_viewer, cache_series, cache_recent)
if (!all(file.exists(cache_files))) {
  stop("The checksum-locked public report cache is incomplete.")
}
private_patterns <- c(
  "/home/", "/var/lib/condor", "KflowOutput", "suvofp", "corp.spc",
  "AKIA", "ghp_"
)
for (file in cache_files) {
  text <- readLines(file, warn = FALSE, encoding = "UTF-8")
  leaked <- private_patterns[vapply(
    private_patterns, function(pattern) any(grepl(pattern, text, fixed = TRUE)),
    logical(1)
  )]
  if (length(leaked)) {
    stop(basename(file), " contains private or machine-specific metadata: ",
         paste(leaked, collapse = ", "))
  }
}
cache_data <- utils::read.csv(cache_series, stringsAsFactors = FALSE, check.names = FALSE)
if (!"source_file" %in% names(cache_data) ||
    any(!grepl("^data/stepwise/models/[^/]+/model_payload[.]rds$", cache_data$source_file))) {
  stop("The public report cache must use repository-relative source_file values.")
}

source(file.path(root, "R", "build_stepwise_key_quantities.R"))
recent_quantities <- utils::read.csv(
  cache_recent, stringsAsFactors = FALSE, check.names = FALSE, encoding = "UTF-8"
)
if (nrow(recent_quantities) != nrow(source_index) ||
    !identical(as.character(recent_quantities$Configuration), as.character(source_index$step_id))) {
  stop("The cached recent-quantity table does not contain the complete ordered pathway.")
}
stepwise_validate_recent_periods(recent_quantities)
diagnostic_recent <- recent_quantities[
  recent_quantities$Configuration == "22-Diagnostic", , drop = FALSE
]
diagnostic_values <- suppressWarnings(as.numeric(diagnostic_recent[1L, c(
  "SB recent / SB F=0", "SB recent / SB MSY", "F recent / F MSY"
)]))
if (nrow(diagnostic_recent) != 1L || any(!is.finite(diagnostic_values)) ||
    any(abs(diagnostic_values - c(0.1739457, 1.025495, 1.143641)) > 5e-7)) {
  stop("The cached Step 22 official stock-status audit failed.")
}

dir.create(file.path(root, "results"), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(audit, file.path(root, "results", "payload-validation.csv"), row.names = FALSE)
message("Validated 23 repository payloads for the 22-step pathway.")
