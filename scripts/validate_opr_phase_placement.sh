#!/usr/bin/env bash
# Static validation for PDH-rebuild OPR phase-placement sensitivity.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
reference_step="11-Standard-Fix6"
source_step="11-TimeVaryingCV"

mapfile -t selected_steps < <(
  cd "$root"
  Rscript -e 'source("job-config.R"); cat(stepwise_models$step_id[stepwise_models$enabled], sep = "\n")'
)
[[ "${#selected_steps[@]}" -eq 7 ]] || {
  echo "Expected seven enabled models; found ${#selected_steps[@]}." >&2
  exit 1
}

Rscript -e 'source("job-config.R"); stopifnot(all(stepwise_models$run_mode == "doitall"), all(stepwise_models$run_script == "doitall.sh"))'

for step in "${selected_steps[@]}"; do
  model_dir="$root/steps/$step/model"
  [[ -d "$model_dir" && -f "$model_dir/bet.frq" ]] || {
    echo "Missing model inputs for $step." >&2
    exit 1
  }
  [[ -x "$model_dir/doitall.sh" ]] || {
    echo "Missing executable doitall.sh for $step." >&2
    exit 1
  }
  if compgen -G "$model_dir/*.par" > /dev/null; then
    echo "$step must not contain a saved PAR input; every scenario starts at bet.ini." >&2
    exit 1
  fi
done

grep -Fq 'rm -f -- [0-9]*.par final.par transfer.par' \
  "$root/steps/$reference_step/model/doitall.sh" || {
  echo "Standard reference doitall must clear stale generated PAR files." >&2
  exit 1
}

for file in bet.frq bet.ini bet.tag bet.age_length bet.reg_scaling fishery_map.R tag_rep_map.R; do
  cmp -s "$root/steps/$reference_step/model/$file" "$root/steps/$source_step/model/$file" || {
    echo "Reference $file does not match PDH-rebuild Step 11." >&2
    exit 1
  }
done

for step in "${selected_steps[@]:1}"; do
  model_dir="$root/steps/$step/model"
  for file in bet.frq bet.ini bet.tag bet.age_length bet.reg_scaling fishery_map.R tag_rep_map.R; do
    cmp -s "$model_dir/$file" "$root/steps/$reference_step/model/$file" || {
      echo "$step differs from PDH-rebuild Step 11 for $file." >&2
      exit 1
    }
  done
  [[ -x "$model_dir/doitall.sh" && -x "$model_dir/phase-opr-doitall.sh" ]] || {
    echo "$step is missing an executable full doitall." >&2
    exit 1
  }
  bash -n "$model_dir/doitall.sh"
  sh -n "$model_dir/phase-opr-doitall.sh"
  # shellcheck source=/dev/null
  source "$model_dir/scenario.env"
  [[ "${OPR_COMPATIBILITY_YEAR:-}" == "0" ]] || {
    echo "$step must set pf221 compatibility state to zero." >&2
    exit 1
  }
  case "${OPR_SWITCH_PHASE:-}" in 3|8|10) ;; *)
    echo "$step has unsupported OPR switch phase ${OPR_SWITCH_PHASE:-<empty>}." >&2
    exit 1 ;;
  esac
done

echo "OPR phase-placement static validation passed for ${#selected_steps[@]} models"
