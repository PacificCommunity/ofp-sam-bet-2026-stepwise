#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT_DIR="${OUTPUT_DIR:-outputs}"
INPUT_DIR="${INPUT_DIR:-inputs}"
WORK_DIR="${ROOT}/work"
INPUT_REPO="${SOURCE_REPO:-PacificCommunity/ofp-sam-bet2026-inputs}"
INPUT_REF="${SOURCE_REF:-main}"
PROGRAM_PATH="${PROGRAM_PATH:-/home/mfcl/mfclo64}"

mkdir -p "${OUT_DIR}" "${WORK_DIR}" "${INPUT_DIR}"
rm -rf "${WORK_DIR}/inputs"

echo "BET stepwise task"
echo "Input repo: ${INPUT_REPO}@${INPUT_REF}"
echo "MFCL program: ${PROGRAM_PATH}"

git clone --depth 1 --branch "${INPUT_REF}" "https://github.com/${INPUT_REPO}.git" "${WORK_DIR}/inputs"

Rscript R/run_stepwise.R

