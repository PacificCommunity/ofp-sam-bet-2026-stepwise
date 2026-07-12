#!/usr/bin/env bash
# Static validation for the late-transfer OPR sensitivity branch.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
reference_step="11-Reference-Fix6"

mapfile -t selected_steps < <(
  cd "$root"
  Rscript -e 'source("job-config.R"); cat(stepwise_models$step_id[stepwise_models$enabled], sep = "\n")'
)

if [[ "${#selected_steps[@]}" -ne 10 ]]; then
  echo "Expected exactly 10 enabled late-transfer models; found ${#selected_steps[@]}." >&2
  exit 1
fi

for step in "${selected_steps[@]}"; do
  model_dir="$root/steps/$step/model"
  [[ -d "$model_dir" ]] || { echo "Missing model directory: $model_dir" >&2; exit 1; }
  [[ -f "$model_dir/bet.frq" ]] || { echo "Missing bet.frq: $model_dir" >&2; exit 1; }
done

for step in "${selected_steps[@]:1}"; do
  model_dir="$root/steps/$step/model"
  doitall="$model_dir/doitall.sh"
  standard_doitall="$model_dir/standard-doitall.sh"
  script="$model_dir/late-transfer.sh"
  scenario="$model_dir/scenario.env"
  [[ -x "$doitall" ]] || { echo "Missing executable doitall.sh: $doitall" >&2; exit 1; }
  [[ -x "$standard_doitall" ]] || { echo "Missing executable standard-doitall.sh: $standard_doitall" >&2; exit 1; }
  [[ -x "$script" ]] || { echo "Missing executable late-transfer.sh: $script" >&2; exit 1; }
  [[ -f "$scenario" ]] || { echo "Missing scenario.env: $scenario" >&2; exit 1; }
  grep -q 'standard-doitall.sh' "$doitall" || {
    echo "$step doitall.sh does not rebuild the standard Step-11 path." >&2
    exit 1
  }
  grep -q 'STEPWISE_START_PAR="11.par"' "$doitall" || {
    echo "$step doitall.sh does not pass its freshly fitted 11.par to the scenario." >&2
    exit 1
  }
  cmp -s "$model_dir/bet.frq" "$root/steps/$reference_step/model/bet.frq" || {
    echo "FRQ input differs from the standard reference for $step." >&2
    exit 1
  }
  for file in bet.ini bet.tag bet.age_length bet.reg_scaling; do
    [[ -f "$model_dir/$file" ]] || { echo "Missing $file for $step." >&2; exit 1; }
    cmp -s "$model_dir/$file" "$root/steps/$reference_step/model/$file" || {
      echo "$file differs from the standard reference for $step." >&2
      exit 1
    }
  done
  bash -n "$doitall"
  sh -n "$standard_doitall"
  bash -n "$script"
  # shellcheck source=/dev/null
  source "$scenario"
  if [[ "${SCENARIO_KIND:-}" == "opr" ]]; then
    [[ "${OPR_COMPATIBILITY_YEAR:-}" == "0" ]] || {
      echo "$step must leave legacy pf221 at zero." >&2
      exit 1
    }
    if [[ "${OPR_YEAR:-}" == "73" && "${OPR_END_YEARS:-}" != "1" ]]; then
      echo "$step has invalid 73-year OPR with endpoint E${OPR_END_YEARS:-?}; use E1." >&2
      exit 1
    fi
    if [[ "${TERMINAL_PENALTY:-0}" -gt 0 && "${OPR_END_YEARS:-0}" -le 0 ]]; then
      echo "$step has a terminal penalty without a positive terminal window." >&2
      exit 1
    fi
  fi
done

Rscript -e 'source("job-config.R"); stopifnot(all(stepwise_models$run_mode == "doitall"), all(stepwise_models$run_script == "doitall.sh"))'
cmp -s "$root/steps/11-Reference-Fix6/model/bet.frq" "$root/steps/11a-Standard-Free/model/bet.frq" || {
  echo "The standard terminal control must retain the reference Step-11 FRQ input." >&2
  exit 1
}

echo "late-transfer OPR static validation passed for ${#selected_steps[@]} models"
