#!/usr/bin/env Rscript

# Remove machine-specific source paths from public report payload metadata.
# Embedded model artifacts and fitted quantities are not modified.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
model_dir <- file.path(root, "data", "stepwise", "models")
payloads <- list.files(
  model_dir,
  pattern = "^model_payload[.]rds$",
  recursive = TRUE,
  full.names = TRUE
)

sanitize_value <- function(value) {
  if (is.character(value)) {
    absolute <- !is.na(value) & grepl("^(/|[A-Za-z]:[/\\\\])", value)
    value[absolute] <- basename(value[absolute])
    return(value)
  }
  if (is.list(value)) {
    return(lapply(value, sanitize_value))
  }
  value
}

for (file in payloads) {
  payload <- readRDS(file)
  payload <- sanitize_value(payload)
  payload$folder <- basename(dirname(file))
  saveRDS(payload, file, version = 3, compress = "gzip")
}

message("Sanitized machine-specific metadata in ", length(payloads), " payloads.")
