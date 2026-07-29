#!/usr/bin/env bash
set -euo pipefail

root="$(pwd)"
output_root="${OUTPUT_DIR:-outputs}"
case "${output_root}" in
  /*) output_base="${output_root}" ;;
  *) output_base="${root}/${output_root}" ;;
esac
work_root="${RRG29_PAREST359_WORK_DIR:-${root}/work/job18518-rrg29fix-parest359}"
model_id="F14-Y5-REC01"
model_output="${output_base}/models/${model_id}"
log_output="${output_base}/logs/${model_id}"
program_path="${PROGRAM_PATH:-/home/mfcl/mfclo64}"
expected_source_sha256="${EXPECTED_SOURCE_PAR_SHA256:-2077bf1c29ab432063e87e438cd529f97c259e5d2ba3d4ff0d693aa987292dd0}"

fail() {
  echo "[job18518-rrg29fix-parest359] $*" >&2
  exit 61
}

find_input_archive() {
  if [[ -n "${JOB18518_ARCHIVE:-}" ]]; then
    [[ -s "${JOB18518_ARCHIVE}" ]] ||
      fail "JOB18518_ARCHIVE does not exist: ${JOB18518_ARCHIVE}"
    printf '%s\n' "${JOB18518_ARCHIVE}"
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
          grep 'outputs/models/F14-Y5-REC01/final[.]par$' >/dev/null; then
        printf '%s\n' "${archive}"
        return 0
      fi
    done < <(find "${search_dir}" -maxdepth 2 -type f -name '*.tar.gz' -print | sort)
  done
  fail "Could not locate the attached Job 18518 output archive."
}

[[ -x "${program_path}" ]] || fail "MFCL executable is unavailable: ${program_path}"

archive="$(find_input_archive)"
echo "[job18518-rrg29fix-parest359] Using attached archive: ${archive}"

rm -rf "${work_root}"
mkdir -p "${work_root}/input" "${work_root}/model" "${model_output}" "${log_output}"
tar -xzf "${archive}" -C "${work_root}/input"

source_par="$(find "${work_root}/input" -type f \
  -path '*/outputs/models/F14-Y5-REC01/final.par' -print -quit)"
[[ -n "${source_par}" && -s "${source_par}" ]] ||
  fail "The attached Job 18518 archive has no F14-Y5-REC01 final PAR."
source_model="$(dirname "${source_par}")"
input_dir="${source_model}/mfcl-inputs"
[[ -d "${input_dir}" && -s "${input_dir}/bet.frq" ]] ||
  fail "The attached Job 18518 archive has no complete MFCL input bundle."
[[ -s "${source_model}/indepvar.rpt" ]] ||
  fail "The attached Job 18518 archive has no source indepvar.rpt."

cp -a "${input_dir}/." "${work_root}/model/"
cp "${source_par}" "${work_root}/model/previous-job.par"
cp "${source_model}/indepvar.rpt" "${work_root}/model/source-indepvar.rpt"

source_sha256="$(sha256sum "${work_root}/model/previous-job.par" | awk '{print $1}')"
[[ "${source_sha256}" == "${expected_source_sha256}" ]] ||
  fail "Source PAR checksum ${source_sha256} is not the verified Job 18518 checksum."

cp "${root}/steps/S03-CommonTagTau-MIX015/model/continue-job18518-rrg29fix-parest359.sh" \
  "${work_root}/model/"
cp "${root}/scripts/fix_tag_reporting_group.py" "${work_root}/model/"
chmod +x \
  "${work_root}/model/continue-job18518-rrg29fix-parest359.sh" \
  "${work_root}/model/fix_tag_reporting_group.py"

echo "[job18518-rrg29fix-parest359] Starting MFCL now; the following output is the live MFCL log."
set +e
(
  cd "${work_root}/model"
  PROGRAM_PATH="${program_path}" \
  EXPECTED_SOURCE_PAR_SHA256="${expected_source_sha256}" \
  EXPECTED_SOURCE_M_INTERCEPT="${EXPECTED_SOURCE_M_INTERCEPT:--2.44602044920584}" \
  FIXED_M_INTERCEPT="${FIXED_M_INTERCEPT:--2.5493033976836}" \
  SELECTIVITY_LOWER_BOUND_PENALTY="${SELECTIVITY_LOWER_BOUND_PENALTY:-1000}" \
  PAREST359_BRIDGE_CONVERGENCE="${PAREST359_BRIDGE_CONVERGENCE:--5}" \
  PAREST359_BRIDGE_MAX_EVALUATIONS="${PAREST359_BRIDGE_MAX_EVALUATIONS:-10000}" \
  BET_PHASE10_11_CONVERGENCE="${BET_PHASE10_11_CONVERGENCE:--4}" \
  JOB_PAR_MAX_EVALUATIONS="${JOB_PAR_MAX_EVALUATIONS:-10000}" \
    bash ./continue-job18518-rrg29fix-parest359.sh
) 2>&1 | tee "${log_output}/mfcl.log" >&2
mfcl_status=${PIPESTATUS[0]}
set -e
[[ "${mfcl_status}" -eq 0 ]] ||
  fail "MFCL reporting-rate/selectivity-penalty continuation failed with exit status ${mfcl_status}."

for required in final.par indepvar.rpt job18518-rrg29fix-parest359-audit.csv; do
  [[ -s "${work_root}/model/${required}" ]] ||
    fail "Expected MFCL output is missing: ${required}"
done

cp -a "${work_root}/model/." "${model_output}/"
mkdir -p "${model_output}/mfcl-inputs"
cp -a "${input_dir}/." "${model_output}/mfcl-inputs/"

printf '%s\n' \
  'model_id,model_label,model_dir,source_job,fit_mode,parest359,dm_fixed,m_fixed,m_intercept,bridge_mgc,final_mgc' \
  "${model_id},Job 18518 | M=-2.5493033976836 | RR group 29 fixed zero + spline penalty,models/${model_id},18518,final-PAR continuation,1000,true,true,-2.5493033976836,1e-5,1e-4" \
  > "${output_base}/model-index.csv"
printf '%s\n' \
  'step_id,model_label,source_job,change_axis' \
  "${model_id},Job 18518 | M=-2.5493033976836 | RR29=0 + parest359=1000,18518,Change only the fixed M intercept from -2.44602044920584 to the Job 17805 value -2.5493033976836 relative to Job 18584" \
  > "${output_base}/selected-steps.csv"
cp "${work_root}/model/job18518-rrg29fix-parest359-audit.csv" \
  "${output_base}/job18518-rrg29fix-parest359-audit.csv"

echo "[job18518-rrg29fix-parest359] Fit and audit completed successfully."
