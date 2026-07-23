#!/usr/bin/env bash
set -euo pipefail

real_program="${MFCL_REAL_PROGRAM_PATH:-/home/mfcl/mfclo64}"
neval="${MFCL_STRICT_NEVAL:-20000}"
convergence="${MFCL_STRICT_CONVERGENCE:--5}"
minimizer="${MFCL_STRICT_MINIMIZER:-1}"
memory_steps="${MFCL_STRICT_MEMORY_STEPS:-400}"
angle_bound="${MFCL_STRICT_ANGLE_BOUND:-0}"

if [[ ! -x "$real_program" ]]; then
  echo "MFCL executable is not available: $real_program" >&2
  exit 1
fi

for value in "$neval" "$convergence" "$minimizer" "$memory_steps" "$angle_bound"; do
  if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
    echo "Strict-refit switch values must be integers; received: $value" >&2
    exit 1
  fi
done

"$real_program" "$@" -file - <<EOF
  1 1 $neval
  1 50 $convergence
  1 351 $minimizer
  1 192 $memory_steps
  1 352 $angle_bound
  1 246 1
EOF
