args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Usage: build-model-payload.R MODEL_OUTPUT_DIRECTORY", call. = FALSE)
}

model_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
if (!requireNamespace("mfclkit", quietly = TRUE)) {
  stop("The pinned mfclkit package is unavailable.", call. = FALSE)
}
if (!requireNamespace("mfclshiny", quietly = TRUE)) {
  stop("The pinned mfclshiny package is unavailable.", call. = FALSE)
}

mfclshiny::build_model_payload(
  folder = model_dir,
  recursive = FALSE,
  overwrite = TRUE,
  object_cache = Sys.getenv("MFCLSHINY_PAYLOAD_OBJECT_CACHE", "all"),
  artifacts = Sys.getenv("MFCLSHINY_PAYLOAD_ARTIFACTS", "core")
)

payload <- file.path(model_dir, "model_payload.rds")
manifest <- file.path(model_dir, "model_payload_manifest.json")
if (!file.exists(payload) || file.info(payload)$size <= 0L || !file.exists(manifest)) {
  stop("mfclshiny did not create a complete model payload.", call. = FALSE)
}

package_record <- function(package) {
  description <- utils::packageDescription(package)
  value <- function(field) {
    if (!(field %in% names(description))) return("")
    as.character(description[[field]][[1L]])
  }
  data.frame(
    package = package,
    version = as.character(utils::packageVersion(package)),
    remote_sha = value("RemoteSha"),
    stringsAsFactors = FALSE
  )
}
utils::write.csv(
  do.call(rbind, lapply(c("mfclkit", "mfclshiny"), package_record)),
  file.path(model_dir, "runtime-package-versions.csv"),
  row.names = FALSE,
  quote = TRUE
)

message("[final-exploration] Wrote ", payload)
