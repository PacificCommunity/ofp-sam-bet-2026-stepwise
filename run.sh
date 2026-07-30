#!/usr/bin/env bash
set -euo pipefail

model=${MODEL:-K015-tau-estimated}
program_path=${PROGRAM_PATH:-/home/mfcl/mfclo64}
output_root=${OUTPUT_DIR:-outputs}

case "$model" in
  K005-tau-estimated|K005-tau-not-estimated|\
  K010-tau-estimated|K010-tau-not-estimated|\
  K015-tau-estimated|K015-tau-not-estimated|\
  K020-tau-estimated|K020-tau-not-estimated|\
  K025-tau-estimated|K025-tau-not-estimated|\
  K030-tau-estimated|K030-tau-not-estimated) ;;
  *)
    echo "MODEL must combine K005/K010/K015/K020/K025/K030 with tau-estimated or tau-not-estimated." >&2
    exit 2
    ;;
esac

if [[ ! -x "$program_path" ]]; then
  echo "PROGRAM_PATH is not an executable MFCL binary: $program_path" >&2
  exit 3
fi

bash scripts/validate-inputs.sh

source_dir="explorations/$model"
run_dir="$output_root/$model"
if [[ -e "$run_dir" ]]; then
  echo "Refusing to overwrite an existing run directory: $run_dir" >&2
  exit 4
fi

mkdir -p "$run_dir"
cp -a "$source_dir/." "$run_dir/"

echo "Running $model"
echo "MFCL executable: $program_path"
(
  cd "$run_dir"
  export PROGRAM_PATH="$program_path"
  export BET_PHASE10_11_CONVERGENCE=${BET_PHASE10_11_CONVERGENCE:--4}
  export REGIONAL_RECRUITMENT_PENALTY=${REGIONAL_RECRUITMENT_PENALTY:-0.1}
  export TAG_TAU_GROUPING=${TAG_TAU_GROUPING:-common}
  export TAG_TAU_LOWER_BOUND=${TAG_TAU_LOWER_BOUND:-default}
  export ESTIMATE_M_FINAL=${ESTIMATE_M_FINAL:-false}
  export TAG_LIKELIHOOD_WEIGHT=${TAG_LIKELIHOOD_WEIGHT:-0}
  ./doitall.sh 2>&1 | tee mfcl.log
)

case "$model" in
  *-tau-estimated) final_stage=12.par ;;
  *-tau-not-estimated) final_stage=11.par ;;
esac

if [[ ! -s "$run_dir/$final_stage" ]]; then
  echo "MFCL did not create the expected final PAR: $run_dir/$final_stage" >&2
  exit 5
fi

cp "$run_dir/$final_stage" "$run_dir/final.par"
final_sha=$(sha256sum "$run_dir/final.par" | awk '{print $1}')
printf '%s\n' \
  'model,source_dir,final_stage,final_par_sha256,status' \
  "$model,$source_dir,$final_stage,$final_sha,completed" \
  > "$run_dir/run-summary.csv"

echo "Completed: $run_dir/final.par"
echo "SHA256: $final_sha"
