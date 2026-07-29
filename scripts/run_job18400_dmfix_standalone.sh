#!/usr/bin/env bash
set -euo pipefail

root="$(pwd)"
output_root="${OUTPUT_DIR:-outputs}"
case "${output_root}" in
  /*) output_base="${output_root}" ;;
  *) output_base="${root}/${output_root}" ;;
esac
work_root="${DMFIX_WORK_DIR:-${root}/work/job18400-dmfix}"
model_id="F14-Y5-REC01"
model_output="${output_base}/models/${model_id}"
log_output="${output_base}/logs/${model_id}"
program_path="${PROGRAM_PATH:-/home/mfcl/mfclo64}"
expected_source_sha256="${EXPECTED_SOURCE_PAR_SHA256:-23f8f45e43369fb5df4b797846f975221dc155113518327498906c424e35b86b}"

fail() {
  echo "[job18400-dmfix] $*" >&2
  exit 61
}

find_input_archive() {
  if [[ -n "${JOB18400_ARCHIVE:-}" ]]; then
    [[ -s "${JOB18400_ARCHIVE}" ]] || fail "JOB18400_ARCHIVE does not exist: ${JOB18400_ARCHIVE}"
    printf '%s\n' "${JOB18400_ARCHIVE}"
    return 0
  fi

  local search_dir archive
  for search_dir in \
    "${root}/../input_archives" \
    "${root}/input_archives" \
    "/kflow/input_archives" \
    "/kflow/inputs"
  do
    [[ -d "${search_dir}" ]] || continue
    while IFS= read -r archive; do
      if tar -tzf "${archive}" 2>/dev/null |
          grep 'outputs/models/F14-Y5-REC01/model_payload[.]rds$' >/dev/null; then
        printf '%s\n' "${archive}"
        return 0
      fi
    done < <(find "${search_dir}" -maxdepth 2 -type f -name '*.tar.gz' -print | sort)
  done
  fail "Could not locate the attached Job 18400 output archive."
}

[[ -x "${program_path}" ]] || fail "MFCL executable is unavailable: ${program_path}"
command -v Rscript >/dev/null 2>&1 || fail "Rscript is required to restore the compact final PAR."

archive="$(find_input_archive)"
echo "[job18400-dmfix] Using attached archive: ${archive}"

rm -rf "${work_root}"
mkdir -p "${work_root}/input" "${work_root}/model" "${model_output}" "${log_output}"
tar -xzf "${archive}" -C "${work_root}/input"

payload="$(find "${work_root}/input" -type f \
  -path '*/outputs/models/F14-Y5-REC01/model_payload.rds' -print -quit)"
[[ -n "${payload}" && -s "${payload}" ]] ||
  fail "The attached Job 18400 archive has no F14-Y5-REC01 model payload."
input_dir="$(dirname "${payload}")/mfcl-inputs"
[[ -d "${input_dir}" && -s "${input_dir}/bet.frq" ]] ||
  fail "The attached Job 18400 archive has no complete MFCL input bundle."

cp -a "${input_dir}/." "${work_root}/model/"
Rscript --vanilla "${root}/scripts/restore_payload_par_base.R" \
  "${payload}" "${work_root}/model/previous-job.par"

source_sha256="$(sha256sum "${work_root}/model/previous-job.par" | awk '{print $1}')"
[[ "${source_sha256}" == "${expected_source_sha256}" ]] ||
  fail "Restored PAR checksum ${source_sha256} is not the verified Job 18400 checksum."

cp "${root}/steps/S03-CommonTagTau-MIX015/model/continue-job18400-dmfix.sh" \
  "${work_root}/model/"
chmod +x "${work_root}/model/continue-job18400-dmfix.sh"

echo "[job18400-dmfix] Starting MFCL now; the following output is the live MFCL log."
set +e
(
  cd "${work_root}/model"
  PROGRAM_PATH="${program_path}" \
  EXPECTED_SOURCE_PAR_SHA256="${expected_source_sha256}" \
  BET_PHASE10_11_CONVERGENCE="${BET_PHASE10_11_CONVERGENCE:--4}" \
  JOB_PAR_MAX_EVALUATIONS="${JOB_PAR_MAX_EVALUATIONS:-10000}" \
    bash ./continue-job18400-dmfix.sh
) 2>&1 | tee "${log_output}/mfcl.log"
mfcl_status=${PIPESTATUS[0]}
set -e
[[ "${mfcl_status}" -eq 0 ]] ||
  fail "MFCL DM-fixed continuation failed with exit status ${mfcl_status}."

for required in final.par indepvar.rpt job18400-dmfix-audit.csv; do
  [[ -s "${work_root}/model/${required}" ]] ||
    fail "Expected MFCL output is missing: ${required}"
done

cp -a "${work_root}/model/." "${model_output}/"
mkdir -p "${model_output}/mfcl-inputs"
cp -a "${input_dir}/." "${model_output}/mfcl-inputs/"

printf '%s\n' \
  'model_id,model_label,model_dir,source_job,fit_mode,dm_fixed,dm_parameter_count_fixed,m_fixed,mgc' \
  "${model_id},Job 18400 | DM concentration fixed,models/${model_id},18400,final-PAR continuation,true,8,true,1e-4" \
  > "${output_base}/model-index.csv"
printf '%s\n' \
  'step_id,model_label,source_job,change_axis' \
  "${model_id},Job 18400 | DM concentration fixed,18400,Fix the eight grouped fish_pars(22) DM concentration intercepts and re-optimise all remaining parameters" \
  > "${output_base}/selected-steps.csv"
cp "${work_root}/model/job18400-dmfix-audit.csv" \
  "${output_base}/job18400-dmfix-audit.csv"

echo "[job18400-dmfix] Fit and audit completed successfully."
