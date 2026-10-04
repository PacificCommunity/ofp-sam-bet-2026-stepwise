args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Provide one saved model payload.", call. = FALSE)
payload <- readRDS(args[[1L]])
artifact <- payload$artifacts$files$rep
if (!is.list(artifact) || !identical(artifact$storage, "raw-file") ||
    !identical(artifact$compression, "gzip") || !is.raw(artifact$bytes) ||
    length(artifact$size) != 1L || !is.finite(artifact$size) || artifact$size <= 0) {
  stop("The saved native REP is incomplete.", call. = FALSE)
}
decoded <- memDecompress(artifact$bytes, type = "gzip")
if (length(decoded) != artifact$size) stop("Saved REP size differs.", call. = FALSE)
text <- rawToChar(decoded)
if (!identical(charToRaw(text), decoded)) stop("Saved REP is not lossless text.", call. = FALSE)
cat(text, sep = "")
