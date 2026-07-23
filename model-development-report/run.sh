#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/.." && pwd)"
REPORT_OUTPUT_DIR="${REPORT_OUTPUT_DIR:-model-development}"
INPUT_DIR="${INPUT_DIR:-inputs}"
R_LIBRARY="${R_LIBS_USER:-${HERE}/.R-library}"

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${HERE}" "$1" ;;
  esac
}

REPORT_OUTPUT_PATH="$(resolve_path "${REPORT_OUTPUT_DIR}")"
INPUT_PATH="$(resolve_path "${INPUT_DIR}")"

mkdir -p "${REPORT_OUTPUT_PATH}" "${INPUT_PATH}" "${R_LIBRARY}"
export R_LIBS_USER="${R_LIBRARY}"

Rscript - <<'RS'
lib <- Sys.getenv("R_LIBS_USER")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(lib, .libPaths())))

required_ref <- Sys.getenv("MFCLSHINY_GITHUB_REF", "main")
source_dir <- Sys.getenv("MFCLSHINY_SOURCE_DIR", "")
has_api <- requireNamespace("mfclshiny", quietly = TRUE) &&
  all(vapply(
    c("build_model_dag_report", "build_report_figures"),
    exists,
    logical(1),
    envir = asNamespace("mfclshiny"),
    inherits = FALSE
  ))

if (nzchar(source_dir) && dir.exists(source_dir)) {
  if (isNamespaceLoaded("mfclshiny")) unloadNamespace("mfclshiny")
  output <- system2(
    file.path(R.home("bin"), "R"),
    c("CMD", "INSTALL", "-l", lib, normalizePath(source_dir)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) stop(paste(output, collapse = "\n"), call. = FALSE)
  has_api <- TRUE
}

if (!has_api) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes", lib = lib, repos = "https://cloud.r-project.org")
  }
  token <- Sys.getenv("GITHUB_PAT", Sys.getenv("GITHUB_TOKEN", ""))
  if (!nzchar(token)) stop("A GitHub token is required to install mfclshiny.", call. = FALSE)
  remotes::install_github(
    paste0("PacificCommunity/mfclshiny@", required_ref),
    lib = lib,
    auth_token = token,
    upgrade = "never",
    dependencies = NA,
    quiet = TRUE
  )
}

for (api in c("build_model_dag_report", "build_report_figures")) {
  if (!exists(api, envir = asNamespace("mfclshiny"), inherits = FALSE)) {
    stop("Installed mfclshiny does not provide ", api, "().", call. = FALSE)
  }
}
RS

cd "${ROOT}"
OUTPUT_DIR="${REPORT_OUTPUT_PATH}" \
INPUT_DIR="${INPUT_PATH}" \
Rscript R/build_stepwise_report.R

printf 'Stepwise model-development report: %s\n' \
  "${REPORT_OUTPUT_PATH}/bet-2026-stepwise-model-development.html"
