#!/usr/bin/env bash
# Run the post-Step-11 part of a complete recruitment sensitivity doitall.
#
# The model-local `doitall.sh` first rebuilds Step 11 from the initial inputs,
# then calls this script with its newly created `11.par`.  `STEPWISE_START_PAR`
# remains an explicit override for controlled local experiments, but a normal
# sensitivity run never depends on a checked-in or externally staged PAR.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scenario_file="${script_dir}/scenario.env"
if [[ ! -f "$scenario_file" ]]; then
  echo "Missing scenario.env beside $(basename "$0")." >&2
  exit 2
fi

# shellcheck source=/dev/null
source "$scenario_file"

program_path="${PROGRAM_PATH:-/home/mfcl/mfclo64}"
start_par="${STEPWISE_START_PAR:-11.par}"
transfer_evaluations="${BET_LATE_TRANSFER_EVALUATIONS:-1}"
opr_final_evaluations="${BET_LATE_OPR_FINAL_EVALUATIONS:-20000}"
standard_final_evaluations="${BET_LATE_STANDARD_FINAL_EVALUATIONS:-20000}"
convergence="${BET_LATE_TRANSFER_CONVERGENCE:-${BET_PHASE10_11_CONVERGENCE:--4}}"

for variable in transfer_evaluations opr_final_evaluations standard_final_evaluations; do
  value="${!variable}"
  case "$value" in
    ''|*[!0-9]*) echo "$variable must be a positive integer, got: $value" >&2; exit 2 ;;
  esac
  if [[ "$value" -le 0 ]]; then
    echo "$variable must be a positive integer, got: $value" >&2
    exit 2
  fi
done

if [[ ! -f "$start_par" ]]; then
  echo "Late-transfer start PAR not found: $start_par" >&2
  echo "Run the model-local doitall.sh first, or set STEPWISE_START_PAR to a compatible fitted Step-11 PAR." >&2
  exit 2
fi
if [[ ! -f bet.frq ]]; then
  echo "Expected bet.frq beside the scenario script." >&2
  exit 2
fi

case "${SCENARIO_KIND:-}" in
  standard)
    : "${STANDARD_P398:?scenario.env must set STANDARD_P398}"
    : "${STANDARD_P400:?scenario.env must set STANDARD_P400}"
    echo "Late-transfer standard control: ${SCENARIO_ID:-unknown}; start=${start_par}; p398=${STANDARD_P398}; p400=${STANDARD_P400}"
    "$program_path" bet.frq "$start_par" final.par -file - <<EOF
  1 398 ${STANDARD_P398}
  1 400 ${STANDARD_P400}
  1 1 ${standard_final_evaluations}
  1 50 ${convergence}
  1 246 1
EOF
    ;;

  opr)
    : "${OPR_YEAR:?scenario.env must set OPR_YEAR}"
    : "${OPR_SEASON:?scenario.env must set OPR_SEASON}"
    : "${OPR_REGION:?scenario.env must set OPR_REGION}"
    : "${OPR_SEASON_REGION:?scenario.env must set OPR_SEASON_REGION}"
    : "${OPR_END_YEARS:?scenario.env must set OPR_END_YEARS}"
    : "${OPR_YEAR_END_DEGREE:?scenario.env must set OPR_YEAR_END_DEGREE}"
    : "${OPR_REGION_END_YEARS:?scenario.env must set OPR_REGION_END_YEARS}"
    : "${OPR_REGION_END_DEGREE:?scenario.env must set OPR_REGION_END_DEGREE}"
    : "${OPR_SEASON_END_YEARS:?scenario.env must set OPR_SEASON_END_YEARS}"
    : "${OPR_SEASON_END_DEGREE:?scenario.env must set OPR_SEASON_END_DEGREE}"
    : "${OPR_INTERACTION_END_YEARS:?scenario.env must set OPR_INTERACTION_END_YEARS}"
    : "${OPR_INTERACTION_END_DEGREE:?scenario.env must set OPR_INTERACTION_END_DEGREE}"
    : "${TERMINAL_PENALTY:?scenario.env must set TERMINAL_PENALTY}"
    opr_compatibility_year="${OPR_COMPATIBILITY_YEAR:-${OPR_YEAR}}"

    # The first command deliberately has one evaluation only. MFCL detects the
    # standard -> OPR transition here and performs its native pre-minimisation
    # coefficient conversion before that evaluation. The resulting transfer.par
    # is retained in raw outputs for diagnosing conversion versus refit movement.
    echo "Late-transfer OPR conversion: ${SCENARIO_ID:-unknown}; start=${start_par}; settings=${OPR_YEAR}-${OPR_SEASON}-${OPR_REGION}-${OPR_SEASON_REGION}; end=${OPR_END_YEARS}; penalty=${TERMINAL_PENALTY}"
    "$program_path" bet.frq "$start_par" transfer.par -file - <<EOF
  1 149 0
  1 398 0
  1 400 0
  2 177 0
  2 32 0
  2 113 0
  1 155 ${OPR_YEAR}
  1 221 ${opr_compatibility_year}
  1 217 ${OPR_SEASON}
  1 216 ${OPR_REGION}
  1 218 ${OPR_SEASON_REGION}
  1 202 ${OPR_END_YEARS}
  1 203 ${OPR_YEAR_END_DEGREE}
  1 210 ${OPR_REGION_END_YEARS}
  1 211 ${OPR_REGION_END_DEGREE}
  1 212 ${OPR_SEASON_END_YEARS}
  1 213 ${OPR_SEASON_END_DEGREE}
  1 214 ${OPR_INTERACTION_END_YEARS}
  1 215 ${OPR_INTERACTION_END_DEGREE}
  1 397 0
  2 30 1
  2 70 0
  2 71 0
  2 178 0
  -100000 1 0
  -100000 2 0
  -100000 3 0
  -100000 4 0
  -100000 5 0
  1 1 ${transfer_evaluations}
  1 50 0
  1 246 1
EOF

    "$program_path" bet.frq transfer.par final.par -file - <<EOF
  1 155 ${OPR_YEAR}
  1 221 ${opr_compatibility_year}
  1 217 ${OPR_SEASON}
  1 216 ${OPR_REGION}
  1 218 ${OPR_SEASON_REGION}
  1 202 ${OPR_END_YEARS}
  1 203 ${OPR_YEAR_END_DEGREE}
  1 210 ${OPR_REGION_END_YEARS}
  1 211 ${OPR_REGION_END_DEGREE}
  1 212 ${OPR_SEASON_END_YEARS}
  1 213 ${OPR_SEASON_END_DEGREE}
  1 214 ${OPR_INTERACTION_END_YEARS}
  1 215 ${OPR_INTERACTION_END_DEGREE}
  1 397 ${TERMINAL_PENALTY}
  1 1 ${opr_final_evaluations}
  1 50 ${convergence}
  1 246 1
EOF
    ;;

  *)
    echo "Unsupported SCENARIO_KIND=${SCENARIO_KIND:-<empty>}; use standard or opr." >&2
    exit 2
    ;;
esac
