#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

fail()
{
  echo "Validation failed: $*" >&2
  exit 1
}

[[ -s profile.env ]] || fail "missing profile.env"
python3 - <<'PY' || fail "invalid dependent profile configuration"
from pathlib import Path

values = {}
for raw in Path("profile.env").read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    key, value = line.split("=", 1)
    values[key] = value.strip().strip('"')

grid = [float(value) for value in values["PROFILE_VALUES"].split()]
expected = [60 + 2.5 * index for index in range(33)]
assert grid == expected
assert values["KFLOW_DOCKER_IMAGE"] == (
    "ghcr.io/pacificcommunity/tuna-flow:v2.5@"
    "sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360"
)
assert values["PROGRAM_PATH"] == "/home/mfcl/mfclo64"
assert values["MODEL_SOURCE_REF"] == "632bb945d350343b76ec6fba2f95c49a224cb2bb"
packages = values["KFLOW_REPO_RUNTIME_PACKAGES"]
assert "FLR4MFCL=PacificCommunity/ofp-sam-flr4mfcl@3faaf84a4867175bfea50d89e4d518c085e84739" in packages
assert "mfclkit=PacificCommunity/ofp-sam-mfclkit@25103916446d0395286afae28b5404bf361670fc" in packages
assert "mfclshiny=PacificCommunity/mfclshiny@1fc0bb6bf4cf5349da6f6def54cc56c5a60e182a" in packages
assert values["PROFILE_PRESET"] == "robust_fast"
assert values["PROFILE_PARALLEL_MODE"] == "chains"
assert values["PROFILE_EXECUTION_MODE"] == "continuation"
for key in (
    "PROFILE_RETRY_JAGGED",
    "PROFILE_UNIT_RETRY_JAGGED",
    "PROFILE_REVERSE_ONCE",
    "PROFILE_UNIT_REVERSE_ONCE",
    "PROFILE_POST_MERGE_REPAIR",
):
    assert values[key] == "false"
for key in (
    "PROFILE_JAGGED_REPAIR_PASSES",
    "PROFILE_UNIT_JAGGED_REPAIR_PASSES",
    "PROFILE_MAX_JAGGED_REPAIRS",
    "PROFILE_UNIT_MAX_JAGGED_REPAIRS",
):
    assert values[key] == "0"
PY

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
selectivity_suffixes=("" "-sel20c")
source_suffixes=(0.05 0.1 0.15 0.2 0.25 0.3)

expected_m=-2.54930339768360e+00
expected_k015_sha=670940e4815f7f10f734f5de289bbe033657169ffa764a6297d0adc693ce221f
expected_frq_sha=9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3
expected_age_length_sha=426859b825bd815aa69c8d97c9dd93097027ed1eb6b9e444d88b69562097a00c
expected_tag_sha=b140e66eb52f2b7e022ef2c562134f8bc9baf3dede18ce95283a001acd2b013f
expected_scaling_sha=5f047ddb4053d1f6df9ace18e85e440b11553de246d024ce8138b427f5f9f7e3
expected_estimated_script_sha=39d66e31bc3e7ac6eeb4e0d5bfcc6d32caf75f28d10a67955bd93d6501a490c4
expected_not_estimated_script_sha=1e9b1f785a7eead494e450cd54bd55cef4ce5de31b1e09d5c399fa66e3170070
expected_estimated_sel20c_script_sha=3dfcf4d64acaa500ff7316cb9393453606bcdbff2a563b433915d6d01285eaee
expected_not_estimated_sel20c_script_sha=4a6a76faa6049b1c7a6b149e967c2e9d7653c2db3443c5cdcac9d7d1c2f8d659

for selectivity_suffix in "${selectivity_suffixes[@]}"; do
  for tau_mode in "${tau_modes[@]}"; do
    for scenario in "${scenarios[@]}"; do
      model="${scenario}-tau-${tau_mode}${selectivity_suffix}"
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
done

robust_parent=explorations/K020-tau-not-estimated-sel20c
robust_models=(
  K020-tau-not-estimated-sel20c-f10-ndpen-weak
  K020-tau-not-estimated-sel20c-f10-ndpen-default
)
robust_weights=(10000 1000000)
logistic_model=K020-tau-not-estimated-sel20c-f10-logistic
logistic_r1_four_node_model=K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node
robust_unchanged_files=(
  bet.age_length
  bet.frq
  bet.ini
  bet.reg_scaling
  bet.tag
  cpue_mle_sigma_audit.csv
  fishery_map.R
  mfcl.cfg
  tag_rep_map.R
)

for index in "${!robust_models[@]}"; do
  model=${robust_models[$index]}
  weight=${robust_weights[$index]}
  dir="explorations/$model"
  [[ -d "$dir" ]] || fail "missing robust-candidate directory $dir"
  for file in "${required[@]}"; do
    [[ -s "$dir/$file" ]] || fail "missing or empty $dir/$file"
  done
  (cd "$dir" && sha256sum -c MANIFEST.sha256 >/dev/null) ||
    fail "manifest mismatch in $dir"
  sh -n "$dir/doitall.sh" || fail "shell syntax error in $dir/doitall.sh"
  for file in "${robust_unchanged_files[@]}"; do
    cmp -s "$robust_parent/$file" "$dir/$file" ||
      fail "$model changed frozen parent input $file"
  done
  cmp -s \
    <(sed -E \
      -e '/^[[:space:]]+-10[[:space:]]+16[[:space:]]+1([[:space:]]|$)/d' \
      -e '/^[[:space:]]+-10[[:space:]]+56[[:space:]]+[0-9]+([[:space:]]|$)/d' \
      "$dir/doitall.sh") \
    "$robust_parent/doitall.sh" ||
    fail "$model changes controls beyond the two declared F10 penalty flags"
  [[ $(grep -Ec '^[[:space:]]+-10[[:space:]]+16[[:space:]]+1([[:space:]]|$)' \
    "$dir/doitall.sh") -eq 1 ]] ||
    fail "$model does not set F10 flag 16 exactly once"
  [[ $(grep -Ec "^[[:space:]]+-10[[:space:]]+56[[:space:]]+$weight([[:space:]]|$)" \
    "$dir/doitall.sh") -eq 1 ]] ||
    fail "$model does not set F10 flag 56 to $weight exactly once"
  grep -Eq '^[[:space:]]+-999[[:space:]]+57[[:space:]]+3([[:space:]]|$)' \
    "$dir/doitall.sh" ||
    fail "$model no longer uses cubic-spline selectivity"
  grep -Eq '^[[:space:]]+-999[[:space:]]+61[[:space:]]+5([[:space:]]|$)' \
    "$dir/doitall.sh" ||
    fail "$model no longer estimates five default spline nodes"
done

logistic_dir="explorations/$logistic_model"
[[ -d "$logistic_dir" ]] ||
  fail "missing robust-candidate directory $logistic_dir"
for file in "${required[@]}"; do
  [[ -s "$logistic_dir/$file" ]] ||
    fail "missing or empty $logistic_dir/$file"
done
(cd "$logistic_dir" && sha256sum -c MANIFEST.sha256 >/dev/null) ||
  fail "manifest mismatch in $logistic_dir"
sh -n "$logistic_dir/doitall.sh" ||
  fail "shell syntax error in $logistic_dir/doitall.sh"
for file in "${robust_unchanged_files[@]}"; do
  cmp -s "$robust_parent/$file" "$logistic_dir/$file" ||
    fail "$logistic_model changed frozen parent input $file"
done
cmp -s \
  <(sed -E \
    -e '/^[[:space:]]+-10[[:space:]]+57[[:space:]]+1([[:space:]]|$)/d' \
    "$logistic_dir/doitall.sh") \
  "$robust_parent/doitall.sh" ||
  fail "$logistic_model changes controls beyond the declared F10 logistic form"
[[ $(grep -Ec '^[[:space:]]+-10[[:space:]]+57[[:space:]]+1([[:space:]]|$)' \
  "$logistic_dir/doitall.sh") -eq 1 ]] ||
  fail "$logistic_model does not set F10 flag 57=1 exactly once"
if grep -Eq '^[[:space:]]+-10[[:space:]]+(16|56)[[:space:]]+' \
  "$logistic_dir/doitall.sh"; then
  fail "$logistic_model incorrectly combines the logistic form with a spline penalty"
fi

logistic_r1_four_node_dir="explorations/$logistic_r1_four_node_model"
[[ -d "$logistic_r1_four_node_dir" ]] ||
  fail "missing robust-candidate directory $logistic_r1_four_node_dir"
for file in "${required[@]}"; do
  [[ -s "$logistic_r1_four_node_dir/$file" ]] ||
    fail "missing or empty $logistic_r1_four_node_dir/$file"
done
(cd "$logistic_r1_four_node_dir" && sha256sum -c MANIFEST.sha256 >/dev/null) ||
  fail "manifest mismatch in $logistic_r1_four_node_dir"
sh -n "$logistic_r1_four_node_dir/doitall.sh" ||
  fail "shell syntax error in $logistic_r1_four_node_dir/doitall.sh"
for file in "${robust_unchanged_files[@]}"; do
  cmp -s "$robust_parent/$file" "$logistic_r1_four_node_dir/$file" ||
    fail "$logistic_r1_four_node_model changed frozen parent input $file"
done
cmp -s \
  <(sed -E \
    -e '/^[[:space:]]+-(1|2|3)[[:space:]]+61[[:space:]]+4([[:space:]]|$)/d' \
    -e '/^[[:space:]]+-10[[:space:]]+57[[:space:]]+1([[:space:]]|$)/d' \
    "$logistic_r1_four_node_dir/doitall.sh") \
  "$robust_parent/doitall.sh" ||
  fail "$logistic_r1_four_node_model changes controls beyond F10 logistic and F1-F3 node counts"
for fishery in 1 2 3; do
  [[ $(grep -Ec "^[[:space:]]+-$fishery[[:space:]]+61[[:space:]]+4([[:space:]]|$)" \
    "$logistic_r1_four_node_dir/doitall.sh") -eq 1 ]] ||
    fail "$logistic_r1_four_node_model does not set F$fishery flag 61=4 exactly once"
done
[[ $(grep -Ec '^[[:space:]]+-10[[:space:]]+57[[:space:]]+1([[:space:]]|$)' \
  "$logistic_r1_four_node_dir/doitall.sh") -eq 1 ]] ||
  fail "$logistic_r1_four_node_model does not set F10 flag 57=1 exactly once"
if grep -Eq '^[[:space:]]+-(1|2|3|10)[[:space:]]+(16|56)[[:space:]]+' \
  "$logistic_r1_four_node_dir/doitall.sh"; then
  fail "$logistic_r1_four_node_model incorrectly adds a directional spline penalty"
fi

f33_models=(
  K020-tau-not-estimated-sel20c-f10-logistic-f33-logistic
  K020-tau-not-estimated-sel20c-f10-logistic-f33-ndpen-strong
  K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node-f33-logistic
  K020-tau-not-estimated-sel20c-f10-logistic-r1ll-4node-f33-ndpen-strong
)
f33_parents=(
  "$logistic_model"
  "$logistic_model"
  "$logistic_r1_four_node_model"
  "$logistic_r1_four_node_model"
)
f33_treatments=(logistic ndpen logistic ndpen)

for index in "${!f33_models[@]}"; do
  model=${f33_models[$index]}
  parent=${f33_parents[$index]}
  treatment=${f33_treatments[$index]}
  dir="explorations/$model"
  parent_dir="explorations/$parent"
  [[ -d "$dir" ]] || fail "missing F33 sensitivity directory $dir"
  for file in "${required[@]}"; do
    [[ -s "$dir/$file" ]] || fail "missing or empty $dir/$file"
  done
  (cd "$dir" && sha256sum -c MANIFEST.sha256 >/dev/null) ||
    fail "manifest mismatch in $dir"
  sh -n "$dir/doitall.sh" || fail "shell syntax error in $dir/doitall.sh"

  for file in "${robust_unchanged_files[@]}"; do
    cmp -s "$parent_dir/$file" "$dir/$file" ||
      fail "$model changed frozen parent input $file"
  done
  [[ $(grep -Ec '^[[:space:]]+-10[[:space:]]+57[[:space:]]+1([[:space:]]|$)' \
    "$dir/doitall.sh") -eq 1 ]] ||
    fail "$model does not retain F10 flag 57=1 exactly once"
  grep -Eq '^[[:space:]]+-999[[:space:]]+61[[:space:]]+5([[:space:]]|$)' \
    "$dir/doitall.sh" || fail "$model does not retain the default five-node spline setting"

  group_line=$(grep -nE '^[[:space:]]+-33[[:space:]]+24[[:space:]]+33([[:space:]]|$)' \
    "$dir/doitall.sh" | cut -d: -f1)
  phase5_end=$(awk -v start="$group_line" 'NR > start && /^PHASE5$/ {print NR; exit}' \
    "$dir/doitall.sh")
  [[ -n "$group_line" && -n "$phase5_end" ]] ||
    fail "$model does not contain the Phase-5 F33 group-separation boundary"

  if [[ "$treatment" == logistic ]]; then
    [[ $(grep -Ec '^[[:space:]]+-33[[:space:]]+57[[:space:]]+1([[:space:]]|$)' \
      "$dir/doitall.sh") -eq 1 ]] || fail "$model does not set F33 flag 57=1 exactly once"
    if grep -Eq '^[[:space:]]+-33[[:space:]]+(16|56)[[:space:]]+' "$dir/doitall.sh"; then
      fail "$model incorrectly combines F33 logistic with a non-decreasing spline penalty"
    fi
    treatment_line=$(grep -nE '^[[:space:]]+-33[[:space:]]+57[[:space:]]+1([[:space:]]|$)' \
      "$dir/doitall.sh" | cut -d: -f1)
    cmp -s \
      <(sed -E \
        -e '/^# F33 sensitivity: after the regional indices are independent, replace only$/d' \
        -e "/^# Index R5's five-node spline with MFCL's two-parameter asymptotic logistic[.]$/d" \
        -e '/^[[:space:]]+-33[[:space:]]+57[[:space:]]+1([[:space:]]|$)/d' \
        "$dir/doitall.sh") \
      "$parent_dir/doitall.sh" ||
      fail "$model changes controls beyond its declared F33 logistic treatment"
  else
    [[ $(grep -Ec '^[[:space:]]+-33[[:space:]]+16[[:space:]]+1([[:space:]]|$)' \
      "$dir/doitall.sh") -eq 1 ]] || fail "$model does not set F33 flag 16=1 exactly once"
    [[ $(grep -Ec '^[[:space:]]+-33[[:space:]]+56[[:space:]]+100000000([[:space:]]|$)' \
      "$dir/doitall.sh") -eq 1 ]] || fail "$model does not set F33 flag 56=100000000 exactly once"
    if grep -Eq '^[[:space:]]+-33[[:space:]]+57[[:space:]]+[12]([[:space:]]|$)' \
      "$dir/doitall.sh"; then
      fail "$model incorrectly combines the F33 spline penalty with a functional form"
    fi
    treatment_line=$(grep -nE '^[[:space:]]+-33[[:space:]]+16[[:space:]]+1([[:space:]]|$)' \
      "$dir/doitall.sh" | cut -d: -f1)
    cmp -s \
      <(sed -E \
        -e '/^# F33 sensitivity: retain the fitted five-node spline but strongly penalize$/d' \
        -e '/^# any decline after Index R5 becomes its own selectivity group[.]$/d' \
        -e '/^[[:space:]]+-33[[:space:]]+16[[:space:]]+1([[:space:]]|$)/d' \
        -e '/^[[:space:]]+-33[[:space:]]+56[[:space:]]+100000000([[:space:]]|$)/d' \
        "$dir/doitall.sh") \
      "$parent_dir/doitall.sh" ||
      fail "$model changes controls beyond its declared F33 non-decreasing treatment"
  fi
  (( treatment_line > group_line && treatment_line < phase5_end )) ||
    fail "$model applies the F33 treatment before Phase-5 group separation"

  if [[ "$model" == *-r1ll-4node-* ]]; then
    for fishery in 1 2 3; do
      [[ $(grep -Ec "^[[:space:]]+-$fishery[[:space:]]+61[[:space:]]+4([[:space:]]|$)" \
        "$dir/doitall.sh") -eq 1 ]] || fail "$model does not retain F$fishery flag 61=4"
    done
  elif grep -Eq '^[[:space:]]+-(1|2|3)[[:space:]]+61[[:space:]]+4([[:space:]]|$)' \
    "$dir/doitall.sh"; then
    fail "$model unexpectedly changes F1-F3 from five to four nodes"
  fi
done

seed23_model=K020-tau-not-estimated-sel20c-f10-ndpen-weak-seed23-base
seed23_dir="explorations/$seed23_model"
[[ -d "$seed23_dir" ]] || fail "missing seed-23 base directory $seed23_dir"
for file in "${required[@]}"; do
  [[ -s "$seed23_dir/$file" ]] || fail "missing or empty $seed23_dir/$file"
done
(cd "$seed23_dir" && sha256sum -c MANIFEST.sha256 >/dev/null) ||
  fail "manifest mismatch in $seed23_dir"
sh -n "$seed23_dir/doitall.sh" ||
  fail "shell syntax error in $seed23_dir/doitall.sh"
for file in "${robust_unchanged_files[@]}"; do
  cmp -s "explorations/K020-tau-not-estimated-sel20c-f10-ndpen-weak/$file" \
    "$seed23_dir/$file" ||
    fail "$seed23_model changed frozen Job 19325 input $file"
done
grep -Fqx 'seed23_seed=23' "$seed23_dir/doitall.sh" ||
  fail "$seed23_model does not lock seed 23"
grep -Fqx 'seed23_cv=0.1' "$seed23_dir/doitall.sh" ||
  fail "$seed23_model does not lock jitter CV 0.1"
grep -Fq 'mfk_phase1_baseline.par' "$seed23_dir/doitall.sh" ||
  fail "$seed23_model lacks the ordinary-jitter no-double-application guard"
grep -Fq '104729 + as.double(phase) * 1009 + 17' "$seed23_dir/doitall.sh" ||
  fail "$seed23_model does not retain the archived deferred-seed formula"
grep -Fq 'fish_pars23 \' "$seed23_dir/doitall.sh" ||
  fail "$seed23_model lacks the Phase-2 DM initialization hook"
grep -Fq 'selectivity_coff \' "$seed23_dir/doitall.sh" ||
  fail "$seed23_model lacks the Phase-5 index-selectivity initialization hook"
Rscript -e '
  path <- commandArgs(TRUE)[[1L]]
  lines <- readLines(path, warn = FALSE)
  first <- which(lines == "args <- commandArgs(trailingOnly = TRUE)")
  last <- which(lines == "SEED23_R")
  stopifnot(length(first) == 1L, length(last) == 1L, last > first)
  parse(text = lines[first:(last - 1L)])
' "$seed23_dir/doitall.sh" >/dev/null ||
  fail "$seed23_model embedded R initializer has a syntax error"
grep -Fq 'cp "$program_path" "$run_dir/mfclo64"' run.sh ||
  fail "run.sh does not bundle the exact MFCL executable for $seed23_model"

exploration_count=$(find explorations -mindepth 1 -maxdepth 1 -type d | wc -l)
[[ "$exploration_count" -eq 33 ]] ||
  fail "expected exactly 33 exploration directories; found $exploration_count"

python3 scripts/create-sel20c-variants.py --check >/dev/null ||
  fail "committed sel20c variants differ from Job 15062 plus the F14 constraint"

awk '
  ($4 == 14 || $4 == 15) && NF == 103 {
    rows[$4]++
    for (i = 8; i <= 102; i++) {
      length_cm = 10 + (i - 8) * 2
      if ($i > 0 && (!($4 in minimum) || length_cm < minimum[$4])) {
        minimum[$4] = length_cm
      }
      if ($i > 0 && length_cm < 70) {
        below_70[$4] += $i
      }
    }
  }
  END {
    exit(rows[14] == 50 && rows[15] == 135 &&
         minimum[14] == 72 && minimum[15] == 70 &&
         below_70[14] == 0 && below_70[15] == 0 ? 0 : 1)
  }
' explorations/K015-tau-estimated/bet.frq ||
  fail "F14/F15 retained length-frequency support check failed"

for index in "${!scenarios[@]}"; do
  scenario=${scenarios[$index]}
  source_ini="provenance/SC22-IP10-regionMean/bet.2026.mix-${source_suffixes[$index]}.ini"
  estimated_ini="explorations/${scenario}-tau-estimated/bet.ini"
  not_estimated_ini="explorations/${scenario}-tau-not-estimated/bet.ini"
  estimated_sel20c_ini="explorations/${scenario}-tau-estimated-sel20c/bet.ini"
  not_estimated_sel20c_ini="explorations/${scenario}-tau-not-estimated-sel20c/bet.ini"

  cmp -s "$estimated_ini" "$not_estimated_ini" ||
    fail "tau modes do not share the exact same INI for $scenario"
  cmp -s "$estimated_ini" "$estimated_sel20c_ini" ||
    fail "estimated-tau selectivity treatments do not share the exact same INI for $scenario"
  cmp -s "$estimated_ini" "$not_estimated_sel20c_ini" ||
    fail "tau and selectivity treatments do not share the exact same INI for $scenario"
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
  estimated_sel20c_script="explorations/${scenario}-tau-estimated-sel20c/doitall.sh"
  not_estimated_sel20c_script="explorations/${scenario}-tau-not-estimated-sel20c/doitall.sh"
  [[ $(sha256sum "$estimated_script" | awk '{print $1}') == "$expected_estimated_script_sha" ]] ||
    fail "estimated-tau script drift in $scenario"
  [[ $(sha256sum "$not_estimated_script" | awk '{print $1}') == "$expected_not_estimated_script_sha" ]] ||
    fail "tau-not-estimated script drift in $scenario"
  [[ $(sha256sum "$estimated_sel20c_script" | awk '{print $1}') == "$expected_estimated_sel20c_script_sha" ]] ||
    fail "estimated-tau 20c-selectivity script drift in $scenario"
  [[ $(sha256sum "$not_estimated_sel20c_script" | awk '{print $1}') == "$expected_not_estimated_sel20c_script_sha" ]] ||
    fail "tau-not-estimated 20c-selectivity script drift in $scenario"
  grep -Eq '^[[:space:]]+-14[[:space:]]+75[[:space:]]+5' "$estimated_sel20c_script" ||
    fail "F14 youngest-five-age constraint is missing in $scenario estimated sel20c"
  grep -Eq '^[[:space:]]+-15[[:space:]]+75[[:space:]]+5' "$estimated_sel20c_script" ||
    fail "F15 youngest-five-age constraint is missing in $scenario estimated sel20c"
  grep -Eq '^[[:space:]]+-14[[:space:]]+75[[:space:]]+5' "$not_estimated_sel20c_script" ||
    fail "F14 youngest-five-age constraint is missing in $scenario tau-not-estimated sel20c"
  grep -Eq '^[[:space:]]+-15[[:space:]]+75[[:space:]]+5' "$not_estimated_sel20c_script" ||
    fail "F15 youngest-five-age constraint is missing in $scenario tau-not-estimated sel20c"
done

grep -Eq '^[[:space:]]+1[[:space:]]+111[[:space:]]+4' \
  explorations/K015-tau-not-estimated/doitall.sh ||
  fail "tau-not-estimated mode does not retain negative-binomial flag 111=4"
if grep -Eq '^[[:space:]]+1[[:space:]]+111[[:space:]]+2' \
  explorations/K015-tau-not-estimated/doitall.sh; then
  fail "tau-not-estimated mode incorrectly switches to Poisson flag 111=2"
fi
grep -Eq '^[[:space:]]+1[[:space:]]+111[[:space:]]+4' \
  explorations/K015-tau-not-estimated-sel20c/doitall.sh ||
  fail "20c-selectivity tau-not-estimated mode does not retain negative-binomial flag 111=4"

[[ $(sha256sum provenance/job-18518/continue-job18400-dmfix.sh | awk '{print $1}') == \
  52627192cab7fa3886e8cf74d60cb0ec6ef87c956e1ff6cc1b094f718cd2e350 ]] ||
  fail "Job 18518 continuation-script provenance drift"
[[ $(sha256sum provenance/job-18518/job18400-dmfix-audit.csv | awk '{print $1}') == \
  28318dca237682a20fc40209bfac94e3f5e619e042823b174582206656403412 ]] ||
  fail "Job 18518 completed-run audit provenance drift"
[[ $(sha256sum provenance/job-15062/doitall.sh | awk '{print $1}') == \
  11fc97e3d3798df7ca766229bcb7187cc6c78753d772afaf28e312eab5e2d15e ]] ||
  fail "Job 15062 archived doitall.sh provenance drift"

expected_image='ghcr.io/pacificcommunity/tuna-flow:v2.5@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360'
expected_mfclkit=34c56de25afecdd13e9f8e94f2e421e37d9c2f9b
expected_mfclshiny=ff0dfcc0534c743713601dbadca5d9d56c0a4025
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
grep -Fqx '  BUILD_MODEL_PAYLOAD: "true"' kflow.yaml ||
  fail "Kflow payload construction is not enabled"
grep -Fqx '    runner: local-docker-ssh' kflow.yaml ||
  fail "Kflow MFCL Shiny local app is missing"
grep -Fq 'Rscript scripts/prepare-runtime-packages.R' run.sh ||
  fail "run.sh does not prepare the pinned R packages"
grep -Fq 'Rscript scripts/build-model-payload.R "$run_dir"' run.sh ||
  fail "run.sh does not build the MFCL Shiny payload"
grep -Fq '"$run_dir/runtime-package-library.tar.gz"' run.sh ||
  fail "run.sh does not archive the selected R package versions"
grep -Fq 'runtime-package-library.tar.gz' kflow.yaml ||
  fail "MFCL Shiny local app does not load the job-specific R package library"
Rscript -e 'parse(file = "scripts/prepare-runtime-packages.R"); parse(file = "scripts/build-model-payload.R")' \
  >/dev/null ||
  fail "R helper syntax check failed"

Rscript -e 'source("job-config.R"); stopifnot(nrow(stepwise_models) == 9L)' ||
  fail "job-config.R does not define the nine-row campaign"

echo "Validated 33 self-contained exploration folders."
echo "The 12 sel20c variants reproduce Job 15062 Phase 1/5 selectivity controls with the deliberate F14 constraint."
echo "The two F10 candidates differ from Job 18718 only by flags 16 and 56."
echo "The F10 logistic candidate differs from Job 18718 only by flag 57=1."
echo "The Region-1 candidate adds only F1-F3 flag 61=4 to the F10 logistic treatment."
echo "The four F33 candidates form the validated F1-F3 five/four-node by F33 logistic/non-decreasing 2x2 sensitivity."
echo "The Job 19325 seed-23 base has a syntax-checked standalone Phase-1/2/5 initializer and ordinary-jitter guard."
echo "F14/F15 retained length-frequency support and youngest-five-age constraints passed."
echo "K015 matches Job 18386; Job 18518 DM, M, reporting-rate, tag-flag, and v2.5 scaling checks passed."
echo "Pinned tuna-flow v2.5, mfclkit, mfclshiny, payload, and local-app checks passed."
