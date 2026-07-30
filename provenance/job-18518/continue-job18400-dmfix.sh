#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}
frq=${FRQ:-bet.frq}
input_par=previous-job.par
final_par=final.par
control_file=fix-job18400-dm-control.txt
audit_file=job18400-dmfix-audit.csv
final_convergence_exponent=${BET_PHASE10_11_CONVERGENCE:--4}
final_evaluations=${JOB_PAR_MAX_EVALUATIONS:-10000}
expected_source_par_sha256=${EXPECTED_SOURCE_PAR_SHA256:-}

fail()
{
  echo "$*" >&2
  exit 61
}

[ -n "$program_path" ] && [ -x "$program_path" ] ||
  fail "PROGRAM_PATH does not name an executable MFCL binary."
[ -s "$frq" ] && [ -s "$input_par" ] ||
  fail "The DM-fixed continuation needs $frq and Job 18400 $input_par."
[ "$final_convergence_exponent" = -4 ] ||
  fail "BET_PHASE10_11_CONVERGENCE must be -4."
case "$final_evaluations" in
  *[!0-9]*|"") fail "JOB_PAR_MAX_EVALUATIONS must be a positive integer." ;;
esac
[ "$final_evaluations" -gt 0 ] || fail "Maximum evaluations must be positive."
[ -n "$expected_source_par_sha256" ] ||
  fail "EXPECTED_SOURCE_PAR_SHA256 is required."

sha256_file()
{
  sha256sum "$1" | awk '{print $1}'
}

read_par_flag()
{
  awk -v header="$1" -v field_no="$2" '
    $0 == header {getline; print $field_no; exit}
  ' "$3"
}

read_fish_flag()
{
  awk -v fishery="$1" -v field_no="$2" '
    /^# fish flags/ {in_fish=1; next}
    in_fish && /^#/ {exit}
    in_fish && NF {
      row++
      if (row == fishery) {print $field_no; exit}
    }
  ' "$3"
}

read_age_pars5()
{
  awk '
    /^# age_pars/ || /^# age-class related parameters [(]age_pars[)]/ {
      in_age=1
      next
    }
    in_age && /^#/ {next}
    in_age && NF {
      row++
      if (row == 5) {print $1; exit}
    }
  ' "$1"
}

read_footer_value()
{
  awk -v marker="$1" '
    index($0, marker) == 1 {getline; print $1; exit}
  ' "$2"
}

source_sha256=$(sha256_file "$input_par")
[ "$source_sha256" = "$expected_source_par_sha256" ] ||
  fail "Attached PAR is not the checksum-verified Job 18400 final PAR."

source_npars=$(read_footer_value "# The number of parameters" "$input_par")
source_obj=$(read_footer_value "# Objective function value" "$input_par")
source_grad=$(read_footer_value "# Maximum magnitude gradient value" "$input_par")
source_m=$(read_age_pars5 "$input_par")
[ "$(read_par_flag "# The parest_flags" 50 "$input_par")" = -4 ] &&
[ "$(read_par_flag "# The parest_flags" 121 "$input_par")" = 0 ] &&
[ "$(read_par_flag "# The parest_flags" 141 "$input_par")" = 11 ] &&
[ "$(read_par_flag "# The parest_flags" 342 "$input_par")" = 25 ] &&
[ "$(read_par_flag "# The parest_flags" 387 "$input_par")" = 0 ] &&
[ "$source_npars" -eq 1989 ] ||
  fail "Job 18400 source controls or parameter count are unexpected."

group_file=job18400-dm-groups.txt
: > "$group_file"
fishery=1
while [ "$fishery" -le 33 ]; do
  flag68=$(read_fish_flag "$fishery" 68 "$input_par")
  flag69=$(read_fish_flag "$fishery" 69 "$input_par")
  flag89=$(read_fish_flag "$fishery" 89 "$input_par")
  [ "$flag69" = 1 ] && [ "$flag89" = 1 ] ||
    fail "Job 18400 fishery $fishery does not estimate both DM parameters."
  printf '%s\n' "$flag68" >> "$group_file"
  fishery=$((fishery + 1))
done
group_count=$(sort -nu "$group_file" | wc -l | awk '{print $1}')
[ "$group_count" -eq 8 ] ||
  fail "Expected eight Job 18400 DM groups; found $group_count."

{
  printf '%s\n' \
    "  1 1 $final_evaluations  # maximum evaluations after fixing DM concentration" \
    "  1 50 $final_convergence_exponent  # final MGC target" \
    "  -999 69 0  # fix grouped fish_pars(22) at Job 18400 values" \
    "  1 246 1  # write indepvar.rpt" \
    "  1 189 1  # write fit reports" \
    "  1 190 1  # write plot report" \
    "  1 188 1  # write standard report output" \
    "  1 187 1  # write tag report output" \
    "  1 186 0"
} > "$control_file"

echo "Continuing Job 18400 with eight grouped fish_pars(22) values fixed."
echo "  source PAR SHA256: $source_sha256"
echo "  fish flag 69: 1 -> 0; fish flag 89 remains 1"
echo "  DM-noRE; Nmax=25; fixed M=$source_m"
echo "  MGC 1e-4; maximum evaluations $final_evaluations"
"$program_path" "$frq" "$input_par" "$final_par" -file "$control_file"
[ -s "$final_par" ] || fail "MFCL did not create $final_par."

for flag in 50 121 141 320 342 387; do
  source_value=$(read_par_flag "# The parest_flags" "$flag" "$input_par")
  output_value=$(read_par_flag "# The parest_flags" "$flag" "$final_par")
  [ "$source_value" = "$output_value" ] ||
    fail "DM-fixed continuation changed parest flag $flag."
done

fishery=1
while [ "$fishery" -le 33 ]; do
  [ "$(read_fish_flag "$fishery" 69 "$final_par")" = 0 ] ||
    fail "Output fish flag 69 is not zero for fishery $fishery."
  [ "$(read_fish_flag "$fishery" 89 "$final_par")" = 1 ] ||
    fail "Output fish flag 89 changed for fishery $fishery."
  output_group=$(read_fish_flag "$fishery" 68 "$final_par")
  source_group=$(read_fish_flag "$fishery" 68 "$input_par")
  [ "$output_group" = "$source_group" ] ||
    fail "Output DM group changed for fishery $fishery."
  fishery=$((fishery + 1))
done

[ "$(read_age_pars5 "$final_par")" = "$source_m" ] ||
  fail "The fixed natural-mortality intercept changed."
[ -s indepvar.rpt ] || fail "DM-fixed fit did not write indepvar.rpt."

dm22_count=$(awk '$2 ~ /^fish_pars[(]22[)]/ {n++} END {print n+0}' indepvar.rpt)
dm23_count=$(awk '$2 ~ /^fish_pars[(]23[)]/ {n++} END {print n+0}' indepvar.rpt)
m_count=$(awk '$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}' indepvar.rpt)
tau_count=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' indepvar.rpt)
[ "$dm22_count" -eq 0 ] && [ "$dm23_count" -eq 8 ] &&
[ "$m_count" -eq 0 ] && [ "$tau_count" -eq 1 ] ||
  fail "Unexpected active DM, M, or tag-tau parameter counts."

output_npars=$(read_footer_value "# The number of parameters" "$final_par")
output_obj=$(read_footer_value "# Objective function value" "$final_par")
output_grad=$(read_footer_value "# Maximum magnitude gradient value" "$final_par")
[ "$output_npars" -eq 1981 ] ||
  fail "Expected 1989 -> 1981 active parameters; found $output_npars."
awk -v gradient="$output_grad" 'BEGIN {
  if (gradient < 0) gradient = -gradient
  exit(gradient <= 1e-4 ? 0 : 1)
}' || fail "Final maximum gradient $output_grad did not reach 1e-4."

output_sha256=$(sha256_file "$final_par")
{
  printf '%s\n' \
    "source_job,source_par_sha256,output_par_sha256,source_objective,output_objective,source_max_gradient,output_max_gradient,source_npars,output_npars,dm_groups,source_flag69,output_flag69,output_flag89,dm22_active,dm23_active,m_active,tau_active,status"
  printf '%s\n' \
    "18400,$source_sha256,$output_sha256,$source_obj,$output_obj,$source_grad,$output_grad,$source_npars,$output_npars,$group_count,1,0,1,$dm22_count,$dm23_count,$m_count,$tau_count,passed"
} > "$audit_file"

echo "Job 18400 DM-fixed continuation audit passed."
