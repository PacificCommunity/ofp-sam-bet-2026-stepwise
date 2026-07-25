#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: extract_payload_artifact.R PAYLOAD ROLE OUTPUT", call. = FALSE)
}

payload_path <- args[[1L]]
role <- args[[2L]]
output_path <- args[[3L]]
payload <- readRDS(payload_path)
artifact <- payload$artifacts$files[[role]]
if (is.null(artifact) || !identical(artifact$storage, "raw-file")) {
  stop("Payload does not contain a raw-file artifact for role: ", role, call. = FALSE)
}

bytes <- artifact$bytes
if (!is.raw(bytes)) {
  stop("Artifact bytes are not stored as a raw vector: ", role, call. = FALSE)
}
if (identical(artifact$compression, "gzip")) {
  bytes <- memDecompress(bytes, type = "gzip")
} else if (!artifact$compression %in% c("", "none", NULL)) {
  stop("Unsupported artifact compression: ", artifact$compression, call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
writeBin(bytes, output_path)
if (!file.exists(output_path) || file.info(output_path)$size <= 0) {
  stop("Failed to extract artifact: ", role, call. = FALSE)
}
