#!/usr/bin/env bash
# Complete, independently reproducible sensitivity fit.
#
# First rebuild the common standard Step-11 path from the model inputs, then
# apply this model's terminal-treatment or OPR scenario from the resulting
# `11.par`.  Keeping both stages in the model-local doitall avoids silently
# using a checked-in or unrelated PAR file.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

# A Kflow run receives a clean work directory, but local reruns may retain
# generated numeric PARs.  Remove only generated fit checkpoints so that this
# script always starts from the model inputs and never reuses a stale solution.
shopt -s nullglob
rm -f -- [0-9]*.par final.par transfer.par

# Export the small scenario file so standard terminal controls are active from
# Phase 1 as well as in their final refinement. OPR rows leave these variables
# unset and therefore use the common Step-11 Fix6 baseline before conversion.
set -a
# shellcheck source=/dev/null
source ./scenario.env
set +a

./standard-doitall.sh
STEPWISE_START_PAR="11.par" exec ./late-transfer.sh
