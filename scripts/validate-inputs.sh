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
expected_estimated_script_sha=9a5922133fd749ff162972590897f47796e0423c18dc71d0e332828f37e92ccf
expected_not_estimated_script_sha=5e4094a328e4530b355a6a0c9ce971287a5b057e395d9c5cc70d327fee33520a

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

echo "Validated 12 self-contained exploration folders."
echo "K015 matches Job 18386; all M, reporting-rate, tag-flag, and v2.5 scaling checks passed."
