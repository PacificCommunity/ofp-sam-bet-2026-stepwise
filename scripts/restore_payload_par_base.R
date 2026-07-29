args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: restore_payload_par_base.R MODEL_PAYLOAD OUTPUT_PAR", call. = FALSE)
}

`%||%` <- function(x, y) {
  if (is.null(x) || !length(x) || is.na(x[[1L]]) || !nzchar(as.character(x[[1L]]))) y else x
}

payload_file <- normalizePath(args[[1L]], mustWork = TRUE)
output_file <- args[[2L]]
payload <- readRDS(payload_file)
artifact <- tryCatch(payload$artifacts$files$par, error = function(e) NULL)
if (is.null(artifact) || !is.raw(artifact$bytes)) {
  stop("The payload does not contain an embedded raw PAR artifact.", call. = FALSE)
}

bytes <- artifact$bytes
compression <- as.character(artifact$compression %||% "none")
if (!identical(compression, "none")) {
  bytes <- memDecompress(bytes, type = compression)
}
expected_size <- suppressWarnings(as.numeric(artifact$size))
if (is.finite(expected_size) && length(bytes) != expected_size) {
  stop(
    "Restored PAR byte count differs from its payload manifest: ",
    length(bytes), " versus ", expected_size, ".",
    call. = FALSE
  )
}

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
writeBin(bytes, output_file)
cat(normalizePath(output_file, mustWork = TRUE), "\n")
