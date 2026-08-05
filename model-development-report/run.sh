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
  printf 'The checksum-locked public report cache is incomplete:\n' >&2
  printf '  %s\n  %s\n' "${CACHE_VIEWER}" "${CACHE_SERIES}" >&2
  exit 66
fi
printf 'Using checksum-locked public report cache; no private package install is required.\n'

cd "${ROOT}"
OUTPUT_DIR="${REPORT_OUTPUT_PATH}" \
INPUT_DIR="${INPUT_PATH}" \
Rscript R/build_stepwise_report.R

printf 'Stepwise model-development report: %s\n' \
  "${REPORT_OUTPUT_PATH}/bet-2026-stepwise-model-development.html"
printf 'Stepwise interactive viewer: %s\n' \
  "${REPORT_OUTPUT_PATH}/interactive-model-viewer.html"
