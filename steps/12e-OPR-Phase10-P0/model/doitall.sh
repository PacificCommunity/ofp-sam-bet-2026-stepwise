#!/usr/bin/env bash
# Full independently reproducible OPR phase-placement run.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

# A Kflow run starts clean; this makes local reruns equally deterministic.
shopt -s nullglob
rm -f -- [0-9]*.par final.par transfer.par

set -a
# shellcheck source=/dev/null
source ./scenario.env
set +a

exec ./phase-opr-doitall.sh
