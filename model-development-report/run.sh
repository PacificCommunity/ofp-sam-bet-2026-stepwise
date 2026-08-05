#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/.." && pwd)"
REPORT_OUTPUT_DIR="${REPORT_OUTPUT_DIR:-model-development}"
INPUT_DIR="${INPUT_DIR:-../data/stepwise}"
R_LIBRARY="${R_LIBS_USER:-${HERE}/.R-library}"

resolve_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "${HERE}" "$1" ;;
  esac
}

REPORT_OUTPUT_PATH="$(resolve_path "${REPORT_OUTPUT_DIR}")"
INPUT_PATH="$(resolve_path "${INPUT_DIR}")"

case "${REPORT_OUTPUT_PATH}" in
  "${ROOT}/"*) ;;
  *)
    printf 'Refusing to replace report output outside the repository: %s\n' "${REPORT_OUTPUT_PATH}" >&2
    exit 64
    ;;
esac
if [ "${REPORT_OUTPUT_PATH}" = "${ROOT}" ]; then
  printf 'Refusing to use the repository root as report output.\n' >&2
  exit 64
fi
rm -rf -- "${REPORT_OUTPUT_PATH}"
mkdir -p "${REPORT_OUTPUT_PATH}" "${INPUT_PATH}" "${R_LIBRARY}"
export R_LIBS_USER="${R_LIBRARY}"

CACHE_VIEWER="${INPUT_PATH}/report-cache/outputs/overview/interactive-model-viewer.html"
CACHE_SERIES="${INPUT_PATH}/report-cache/outputs/mfclshiny-report-depletion-data.csv"

if [ ! -s "${CACHE_VIEWER}" ] || [ ! -s "${CACHE_SERIES}" ]; then
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
else
  printf 'Using checksum-locked public report cache; no private package install is required.\n'
fi

cd "${ROOT}"
OUTPUT_DIR="${REPORT_OUTPUT_PATH}" \
INPUT_DIR="${INPUT_PATH}" \
Rscript R/build_stepwise_report.R

printf 'Stepwise model-development report: %s\n' \
  "${REPORT_OUTPUT_PATH}/bet-2026-stepwise-model-development.html"
printf 'Stepwise interactive viewer: %s\n' \
  "${REPORT_OUTPUT_PATH}/interactive-model-viewer.html"
