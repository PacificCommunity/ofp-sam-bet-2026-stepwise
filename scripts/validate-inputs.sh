#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

fail()
{
  echo "Validation failed: $*" >&2
  exit 1
}

read_m()
{
  awk '
    /^# age_pars/ {
      in_age=1
      next
    }
    in_age && /^#/ {next}
    in_age && NF {
      row++
      if (row == 5) {
        print $1
        exit
      }
    }
  ' "$1"
}

canonical_rr()
{
  awk '
    (NR >= 107 && NR <= 205) ||
    (NR >= 207 && NR <= 305) ||
    (NR >= 307 && NR <= 405) ||
    (NR >= 407 && NR <= 505) ||
    (NR >= 507 && NR <= 605) {
      for (i = 1; i <= NF; i++) {
        printf "%.15g%s", $i + 0, (i == NF ? ORS : OFS)
      }
    }
  ' "$1"
}

required=(
  bet.age_length
  bet.frq
  bet.ini
  bet.reg_scaling
  bet.tag
  cpue_mle_sigma_audit.csv
  doitall.sh
  fishery_map.R
  mfcl.cfg
  tag_rep_map.R
  MANIFEST.sha256
  README.md
)
tau_modes=(estimated not-estimated)
scenarios=(K005 K010 K015 K020 K025 K030)
source_suffixes=(0.05 0.1 0.15 0.2 0.25 0.3)

expected_m=-2.54930339768360e+00
expected_k015_sha=670940e4815f7f10f734f5de289bbe033657169ffa764a6297d0adc693ce221f
expected_frq_sha=9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3
expected_age_length_sha=426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c
expected_tag_sha=b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f
expected_scaling_sha=5f047ddb4053d1f6df9ace18e85e440b11553de246d024ce8138b427f5f9f7e3
expected_estimated_script_sha=39d66e31bc3e7ac6eeb4e0d5bfcc6d32caf75f28d10a67955bd93d6501a490c4
expected_not_estimated_script_sha=1e9b1f785a7eead494e450cd54bd55cef4ce5de31b1e09d5c399fa66e3170070

for tau_mode in "${tau_modes[@]}"; do
  for scenario in "${scenarios[@]}"; do
    model="${scenario}-tau-${tau_mode}"
    dir="explorations/$model"
    [[ -d "$dir" ]] || fail "missing directory $dir"
    for file in "${required[@]}"; do
      [[ -s "$dir/$file" ]] || fail "missing or empty $dir/$file"
    done
    (cd "$dir" && sha256sum -c MANIFEST.sha256 >/dev/null) ||
      fail "manifest mismatch in $dir"
    sh -n "$dir/doitall.sh" || fail "shell syntax error in $dir/doitall.sh"
    if grep -q 'DM_NMAX' "$dir/doitall.sh"; then
      fail "DM Nmax is still configurable in $dir/doitall.sh"
    fi
    grep -Eq '^dm_nmax=25$' "$dir/doitall.sh" ||
      fail "DM Nmax is not fixed at 25 in $dir/doitall.sh"
    grep -Eq '^dm_concentration=7$' "$dir/doitall.sh" ||
      fail "DM concentration is not fixed at 7 in $dir/doitall.sh"
    grep -Eq '^[[:space:]]+1[[:space:]]+141[[:space:]]+11' "$dir/doitall.sh" ||
      fail "DM-noRE parest 141=11 is missing in $dir/doitall.sh"
    grep -Eq '^[[:space:]]+1[[:space:]]+320[[:space:]]+5' "$dir/doitall.sh" ||
      fail "DM tail support parest 320=5 is missing in $dir/doitall.sh"
    grep -Eq '^[[:space:]]+1[[:space:]]+342[[:space:]]+25' "$dir/doitall.sh" ||
      fail "DM Nmax parest 342=25 is missing in $dir/doitall.sh"
    grep -Eq '^[[:space:]]+-999[[:space:]]+69[[:space:]]+0' "$dir/doitall.sh" ||
      fail "fish_pars(22) is not fixed with flag 69=0 in $dir/doitall.sh"
    grep -Eq '^[[:space:]]+-999[[:space:]]+89[[:space:]]+1' "$dir/doitall.sh" ||
      fail "fish_pars(23) is not estimated with flag 89=1 in $dir/doitall.sh"
    grep -Fq '$program_path bet.frq 00.dm-fixed.par 01.par' "$dir/doitall.sh" ||
      fail "Phase 1 does not consume the explicit row-22-fixed PAR in $dir/doitall.sh"
    grep -Eq 'dm22_active.*(-ne|!=).*0' "$dir/doitall.sh" ||
      fail "final audit does not require zero active fish_pars(22) in $dir/doitall.sh"
    grep -Eq 'dm23_active.*(-ne|!=).*8' "$dir/doitall.sh" ||
      fail "final audit does not require eight active fish_pars(23) in $dir/doitall.sh"

    [[ $(read_m "$dir/bet.ini") == "$expected_m" ]] ||
      fail "wrong fixed M in $dir/bet.ini"
    awk 'NR >= 6 && NR <= 103 {
      if (NF != 10 || $2 != 1) bad++
      rows++
    } END {exit(rows == 98 && bad == 0 ? 0 : 1)}' "$dir/bet.ini" ||
      fail "tag flags are not 98x10 with column 2 equal to one in $dir/bet.ini"
    awk 'NF != 5 {bad++} END {exit(NR == 20 && bad == 0 ? 0 : 1)}' \
      "$dir/bet.reg_scaling" ||
      fail "regional scaling is not headerless 20x5 in $dir"

    [[ $(sha256sum "$dir/bet.frq" | awk '{print $1}') == "$expected_frq_sha" ]] ||
      fail "FRQ drift in $dir"
    [[ $(sha256sum "$dir/bet.age_length" | awk '{print $1}') == "$expected_age_length_sha" ]] ||
      fail "age-length drift in $dir"
    [[ $(sha256sum "$dir/bet.tag" | awk '{print $1}') == "$expected_tag_sha" ]] ||
      fail "tag-file drift in $dir"
    [[ $(sha256sum "$dir/bet.reg_scaling" | awk '{print $1}') == "$expected_scaling_sha" ]] ||
      fail "regional-scaling drift in $dir"
  done
done

for index in "${!scenarios[@]}"; do
  scenario=${scenarios[$index]}
  source_ini="provenance/SC22-IP10-regionMean/bet.2026.mix-${source_suffixes[$index]}.ini"
  estimated_ini="explorations/${scenario}-tau-estimated/bet.ini"
  not_estimated_ini="explorations/${scenario}-tau-not-estimated/bet.ini"

  cmp -s "$estimated_ini" "$not_estimated_ini" ||
    fail "tau modes do not share the exact same INI for $scenario"
  diff -q \
    <(sed -n '6,103p' "$source_ini" | tr -d '\r') \
    <(sed -n '6,103p' "$estimated_ini" | tr -d '\r') >/dev/null ||
    fail "tag-mixing vector does not match the source for $scenario"
  diff -q <(canonical_rr "$source_ini") <(canonical_rr "$estimated_ini") >/dev/null ||
    fail "reporting-rate controls differ numerically from the source for $scenario"
done

cmp -s \
  explorations/K015-tau-estimated/bet.ini \
  provenance/job-18386/bet.ini ||
  fail "K015 INI is not byte-identical to the actual Job 18386 INI"
[[ $(sha256sum explorations/K015-tau-estimated/bet.ini | awk '{print $1}') == "$expected_k015_sha" ]] ||
  fail "K015 INI checksum drift"

for scenario in "${scenarios[@]}"; do
  estimated_script="explorations/${scenario}-tau-estimated/doitall.sh"
  not_estimated_script="explorations/${scenario}-tau-not-estimated/doitall.sh"
  [[ $(sha256sum "$estimated_script" | awk '{print $1}') == "$expected_estimated_script_sha" ]] ||
    fail "estimated-tau script drift in $scenario"
  [[ $(sha256sum "$not_estimated_script" | awk '{print $1}') == "$expected_not_estimated_script_sha" ]] ||
    fail "tau-not-estimated script drift in $scenario"
done

grep -Eq '^[[:space:]]+1[[:space:]]+111[[:space:]]+4' \
  explorations/K015-tau-not-estimated/doitall.sh ||
  fail "tau-not-estimated mode does not retain negative-binomial flag 111=4"
if grep -Eq '^[[:space:]]+1[[:space:]]+111[[:space:]]+2' \
  explorations/K015-tau-not-estimated/doitall.sh; then
  fail "tau-not-estimated mode incorrectly switches to Poisson flag 111=2"
fi

[[ $(sha256sum provenance/job-18518/continue-job18400-dmfix.sh | awk '{print $1}') == \
  52627192cab7fa3886e8cf74d60cb0ec6ef87c956e1ff6cc1b094f718cd2e350 ]] ||
  fail "Job 18518 continuation-script provenance drift"
[[ $(sha256sum provenance/job-18518/job18400-dmfix-audit.csv | awk '{print $1}') == \
  28318dca237682a20fc40209bfac94e3f5e619e042823b174582206656403412 ]] ||
  fail "Job 18518 completed-run audit provenance drift"

expected_image='ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360'
expected_mfclkit=25103916446d0395286afae28b5404bf361670fc
expected_mfclshiny=1fc0bb6bf4cf5349da6f6def54cc56c5a60e182a
grep -Fqx "docker_image: $expected_image" kflow.yaml ||
  fail "Kflow tuna-flow v2.5 image pin changed"
[[ $(grep -Fc "$expected_mfclkit" kflow.yaml) -ge 3 ]] ||
  fail "Kflow mfclkit package pin is incomplete"
[[ $(grep -Fc "$expected_mfclshiny" kflow.yaml) -ge 3 ]] ||
  fail "Kflow mfclshiny package pin is incomplete"
grep -Fqx '    - MFCLKIT_GITHUB_REF' kflow.yaml ||
  fail "Kflow mfclkit version override is not exposed"
grep -Fqx '    - MFCLSHINY_GITHUB_REF' kflow.yaml ||
  fail "Kflow mfclshiny version override is not exposed"
grep -Fqx '        ref_env: MFCLKIT_GITHUB_REF' kflow.yaml ||
  fail "MFCL Shiny local app does not resolve the configured mfclkit ref"
grep -Fqx '        ref_env: MFCLSHINY_GITHUB_REF' kflow.yaml ||
  fail "MFCL Shiny local app does not resolve the configured mfclshiny ref"
grep -Fqx '  BUILD_MODEL_PAYLOAD: "true"' kflow.yaml ||
  fail "Kflow payload construction is not enabled"
grep -Fqx '    runner: local-docker-ssh' kflow.yaml ||
  fail "Kflow MFCL Shiny local app is missing"
grep -Fq 'Rscript scripts/prepare-runtime-packages.R' run.sh ||
  fail "run.sh does not prepare the pinned R packages"
grep -Fq 'Rscript scripts/build-model-payload.R "$run_dir"' run.sh ||
  fail "run.sh does not build the MFCL Shiny payload"
Rscript -e 'parse(file = "scripts/prepare-runtime-packages.R"); parse(file = "scripts/build-model-payload.R")' \
  >/dev/null ||
  fail "R helper syntax check failed"

echo "Validated 12 self-contained exploration folders."
echo "K015 matches Job 18386; Job 18518 DM, M, reporting-rate, tag-flag, and v2.5 scaling checks passed."
echo "Pinned tuna-flow v2.5, mfclkit, mfclshiny, payload, and local-app checks passed."
