#!/usr/bin/env bash
set -euo pipefail

model=${MODEL:-${STEP_SELECT:-K020-tau-not-estimated-sel20c-f10-ndpen-weak}}
program_path=${PROGRAM_PATH:-/home/mfcl/mfclo64}
output_root=${OUTPUT_DIR:-outputs}

truthy()
{
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON|always|ALWAYS) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ ! "$model" =~ ^K(005|010|015|020|025|030)-tau-(estimated|not-estimated)(-sel20c)?$ ]] &&
   [[ ! "$model" =~ ^K020-tau-not-estimated-sel20c-f10-(ndpen-(weak|default)|logistic(-r1ll-4node)?(-f33-(logistic|ndpen-strong))?)$ ]]; then
  echo "MODEL is not a supported final-exploration or F10 penalty candidate." >&2
  exit 2
fi

if [[ ! -x "$program_path" ]]; then
  echo "PROGRAM_PATH is not an executable MFCL binary: $program_path" >&2
  exit 3
fi

bash scripts/validate-inputs.sh

if truthy "${BUILD_MODEL_PAYLOAD:-false}"; then
  runtime_library=${R_LIBS_USER:-${KFLOW_RUNTIME_LIBRARY:-"$PWD/.R-library"}}
  if ! mkdir -p "$runtime_library" 2>/dev/null || [[ ! -w "$runtime_library" ]]; then
    runtime_library="$PWD/.R-library"
    mkdir -p "$runtime_library"
  fi
  export R_LIBS_USER="$runtime_library"
  export KFLOW_RUNTIME_LIBRARY="$runtime_library"
  Rscript scripts/prepare-runtime-packages.R
fi

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
  *-tau-estimated|*-tau-estimated-sel20c) final_stage=12.par ;;
  *-tau-not-estimated*) final_stage=11.par ;;
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

if truthy "${BUILD_MODEL_PAYLOAD:-false}"; then
  Rscript scripts/build-model-payload.R "$run_dir"
  tar -C "$R_LIBS_USER" -czf "$run_dir/runtime-package-library.tar.gz" \
    mfclkit mfclshiny
fi

echo "Completed: $run_dir/final.par"
echo "SHA256: $final_sha"
