#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}
frq=${FRQ:-bet.frq}
input_par=previous-job.par
fixed_start_par=job18518-rrg29-fixed-start.par
source_indepvar=source-indepvar.rpt
bridge_par=parest359-stage-a.par
final_par=final.par
bridge_control_file=job18518-rrg29fix-parest359-stage-a-control.txt
final_control_file=job18518-rrg29fix-parest359-stage-b-control.txt
audit_file=job18518-rrg29fix-parest359-audit.csv
reporting_fix_script=fix_tag_reporting_group.py
bridge_convergence_exponent=${PAREST359_BRIDGE_CONVERGENCE:--5}
final_convergence_exponent=${BET_PHASE10_11_CONVERGENCE:--4}
bridge_evaluations=${PAREST359_BRIDGE_MAX_EVALUATIONS:-10000}
final_evaluations=${JOB_PAR_MAX_EVALUATIONS:-10000}
penalty_flag=${SELECTIVITY_LOWER_BOUND_PENALTY:-1000}
expected_source_par_sha256=${EXPECTED_SOURCE_PAR_SHA256:-}

fail()
{
  echo "$*" >&2
  exit 61
}

[ -n "$program_path" ] && [ -x "$program_path" ] ||
  fail "PROGRAM_PATH does not name an executable MFCL binary."
[ -s "$frq" ] && [ -s "$input_par" ] && [ -s "$source_indepvar" ] &&
[ -s "$reporting_fix_script" ] ||
  fail "The continuation needs $frq, Job 18518 $input_par, $source_indepvar, and $reporting_fix_script."
[ "$bridge_convergence_exponent" = -5 ] ||
  fail "PAREST359_BRIDGE_CONVERGENCE must be -5."
[ "$final_convergence_exponent" = -4 ] ||
  fail "BET_PHASE10_11_CONVERGENCE must be -4."
[ "$penalty_flag" = 1000 ] ||
  fail "SELECTIVITY_LOWER_BOUND_PENALTY must be 1000 for this sensitivity."
case "$bridge_evaluations:$final_evaluations" in
  *[!0-9:]*|:*|*:) fail "Both evaluation limits must be positive integers." ;;
esac
[ "$bridge_evaluations" -gt 0 ] || fail "Bridge evaluations must be positive."
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

read_indepvar_value()
{
  awk -v parameter="$1" '$2 == parameter {print $3; exit}' "$2"
}

source_sha256=$(sha256_file "$input_par")
[ "$source_sha256" = "$expected_source_par_sha256" ] ||
  fail "Attached PAR is not the checksum-verified Job 18518 final PAR."

source_npars=$(read_footer_value "# The number of parameters" "$input_par")
source_obj=$(read_footer_value "# Objective function value" "$input_par")
source_grad=$(read_footer_value "# Maximum magnitude gradient value" "$input_par")
source_m=$(read_age_pars5 "$input_par")
[ "$(read_par_flag "# The parest_flags" 50 "$input_par")" = -4 ] &&
[ "$(read_par_flag "# The parest_flags" 121 "$input_par")" = 0 ] &&
[ "$(read_par_flag "# The parest_flags" 141 "$input_par")" = 11 ] &&
[ "$(read_par_flag "# The parest_flags" 342 "$input_par")" = 25 ] &&
[ "$(read_par_flag "# The parest_flags" 359 "$input_par")" = 0 ] &&
[ "$(read_par_flag "# The parest_flags" 387 "$input_par")" = 0 ] &&
[ "$source_npars" -eq 1981 ] ||
  fail "Job 18518 source controls or parameter count are unexpected."

fishery=1
while [ "$fishery" -le 33 ]; do
  [ "$(read_fish_flag "$fishery" 69 "$input_par")" = 0 ] ||
    fail "Job 18518 fish flag 69 is not fixed for fishery $fishery."
  [ "$(read_fish_flag "$fishery" 89 "$input_par")" = 1 ] ||
    fail "Job 18518 fish flag 89 is not active for fishery $fishery."
  fishery=$((fishery + 1))
done

source_sel14=$(read_indepvar_value \
  "bs_selcoff_gp:14(14,1,1,5)" "$source_indepvar")
source_sel22=$(read_indepvar_value \
  "bs_selcoff_gp:22(22,1,1,5)" "$source_indepvar")
[ -n "$source_sel14" ] && [ -n "$source_sel22" ] ||
  fail "Could not read the two source terminal spline coefficients."
source_rr29=$(read_indepvar_value "tag_fish_rep(29)" "$source_indepvar")
[ -n "$source_rr29" ] ||
  fail "Job 18518 source indepvar.rpt has no active tag_fish_rep(29)."

python3 "$reporting_fix_script" apply "$input_par" "$fixed_start_par"
[ -s "$fixed_start_par" ] ||
  fail "The reporting-rate fix did not create $fixed_start_par."

{
  printf '%s\n' \
    "  1 1 $bridge_evaluations  # bridge evaluations with spline lower-bound penalty" \
    "  1 50 $bridge_convergence_exponent  # bridge MGC target so the optimizer moves" \
    "  1 359 $penalty_flag  # soft quadratic penalty below spline coefficient -15" \
    "  1 246 1  # write indepvar.rpt" \
    "  1 189 0" \
    "  1 190 0" \
    "  1 188 0" \
    "  1 187 0" \
    "  1 186 0"
} > "$bridge_control_file"

echo "Continuing Job 18518 with two targeted stability changes."
echo "  source PAR SHA256: $source_sha256"
echo "  tag reporting-rate group 29: $source_rr29 estimated -> 0 fixed"
echo "  group 29 prior penalty: disabled because MFCL applies it independently of the active flag"
echo "  parest flag 359: 0 -> 1000 (0.1 soft penalty below spline coefficient -15)"
echo "  DM fish_pars(22) remain fixed; M remains fixed at $source_m"
echo "  Stage A: MGC 1e-5 bridge; maximum evaluations $bridge_evaluations"
"$program_path" "$frq" "$fixed_start_par" "$bridge_par" -file "$bridge_control_file"
[ -s "$bridge_par" ] || fail "MFCL did not create $bridge_par."
python3 "$reporting_fix_script" check "$bridge_par"

bridge_obj=$(read_footer_value "# Objective function value" "$bridge_par")
bridge_grad=$(read_footer_value "# Maximum magnitude gradient value" "$bridge_par")
[ "$(read_par_flag "# The parest_flags" 359 "$bridge_par")" = 1000 ] ||
  fail "Bridge parest flag 359 is not 1000."
awk -v gradient="$bridge_grad" 'BEGIN {
  if (gradient < 0) gradient = -gradient
  exit(gradient <= 1e-5 ? 0 : 1)
}' || fail "Bridge maximum gradient $bridge_grad did not reach 1e-5."

{
  printf '%s\n' \
    "  1 1 $final_evaluations  # final evaluations after the tighter bridge" \
    "  1 50 $final_convergence_exponent  # restore final MGC target" \
    "  1 359 $penalty_flag  # retain spline lower-bound penalty" \
    "  1 246 1  # write indepvar.rpt" \
    "  1 189 1  # write fit reports" \
    "  1 190 1  # write plot report" \
    "  1 188 1  # write standard report output" \
    "  1 187 1  # write tag report output" \
    "  1 186 0"
} > "$final_control_file"

echo "  Stage A output: objective=$bridge_obj MGC=$bridge_grad"
echo "  Stage B: retain the fitted solution and restore final MGC 1e-4"
"$program_path" "$frq" "$bridge_par" "$final_par" -file "$final_control_file"
[ -s "$final_par" ] || fail "MFCL did not create $final_par."
[ -s indepvar.rpt ] || fail "MFCL did not write indepvar.rpt."

[ "$(read_par_flag "# The parest_flags" 359 "$final_par")" = 1000 ] ||
  fail "Output parest flag 359 is not 1000."
python3 "$reporting_fix_script" check "$final_par"
for flag in 50 121 141 320 342 387; do
  source_value=$(read_par_flag "# The parest_flags" "$flag" "$input_par")
  output_value=$(read_par_flag "# The parest_flags" "$flag" "$final_par")
  [ "$source_value" = "$output_value" ] ||
    fail "Continuation changed parest flag $flag."
done

fishery=1
while [ "$fishery" -le 33 ]; do
  [ "$(read_fish_flag "$fishery" 69 "$final_par")" = 0 ] ||
    fail "Output fish flag 69 changed for fishery $fishery."
  [ "$(read_fish_flag "$fishery" 89 "$final_par")" = 1 ] ||
    fail "Output fish flag 89 changed for fishery $fishery."
  fishery=$((fishery + 1))
done

[ "$(read_age_pars5 "$final_par")" = "$source_m" ] ||
  fail "The fixed natural-mortality intercept changed."

dm22_count=$(awk '$2 ~ /^fish_pars[(]22[)]/ {n++} END {print n+0}' indepvar.rpt)
dm23_count=$(awk '$2 ~ /^fish_pars[(]23[)]/ {n++} END {print n+0}' indepvar.rpt)
m_count=$(awk '$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}' indepvar.rpt)
tau_count=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' indepvar.rpt)
rr29_count=$(awk '$2 == "tag_fish_rep(29)" {n++} END {print n+0}' indepvar.rpt)
rr_total_count=$(awk '$2 ~ /^tag_fish_rep[(]/ {n++} END {print n+0}' indepvar.rpt)
[ "$dm22_count" -eq 0 ] && [ "$dm23_count" -eq 8 ] &&
[ "$m_count" -eq 0 ] && [ "$tau_count" -eq 1 ] &&
[ "$rr29_count" -eq 0 ] && [ "$rr_total_count" -eq 11 ] ||
  fail "Unexpected active DM, M, tag-tau, or reporting-rate parameter counts."

output_npars=$(read_footer_value "# The number of parameters" "$final_par")
output_obj=$(read_footer_value "# Objective function value" "$final_par")
output_grad=$(read_footer_value "# Maximum magnitude gradient value" "$final_par")
[ "$output_npars" -eq 1980 ] ||
  fail "Expected 1980 active parameters after fixing reporting-rate group 29; found $output_npars."
awk -v gradient="$output_grad" 'BEGIN {
  if (gradient < 0) gradient = -gradient
  exit(gradient <= 1e-4 ? 0 : 1)
}' || fail "Final maximum gradient $output_grad did not reach 1e-4."

output_sel14=$(read_indepvar_value \
  "bs_selcoff_gp:14(14,1,1,5)" indepvar.rpt)
output_sel22=$(read_indepvar_value \
  "bs_selcoff_gp:22(22,1,1,5)" indepvar.rpt)
[ -n "$output_sel14" ] && [ -n "$output_sel22" ] ||
  fail "Could not read the two output terminal spline coefficients."
remaining_lower_bounds=$(awk \
  '$2 == "bs_selcoff_gp:14(14,1,1,5)" ||
   $2 == "bs_selcoff_gp:22(22,1,1,5)" {
     if ($3 <= $4 + 0.00001) n++
   }
   END {print n+0}' indepvar.rpt)

output_sha256=$(sha256_file "$final_par")
{
  printf '%s\n' \
    "source_job,source_par_sha256,output_par_sha256,source_objective,bridge_objective,output_objective,source_max_gradient,bridge_max_gradient,output_max_gradient,source_npars,output_npars,source_parest359,output_parest359,source_reporting_group29,output_reporting_group29,reporting_group29_active,reporting_group29_prior_active,source_sel14_terminal,output_sel14_terminal,source_sel22_terminal,output_sel22_terminal,remaining_terminal_lower_bounds,dm22_active,dm23_active,m_active,tau_active,status"
  printf '%s\n' \
    "18518,$source_sha256,$output_sha256,$source_obj,$bridge_obj,$output_obj,$source_grad,$bridge_grad,$output_grad,$source_npars,$output_npars,0,1000,$source_rr29,0,0,0,$source_sel14,$output_sel14,$source_sel22,$output_sel22,$remaining_lower_bounds,$dm22_count,$dm23_count,$m_count,$tau_count,passed"
} > "$audit_file"

echo "Job 18518 reporting-rate/selectivity-penalty continuation audit passed."
echo "  reporting-rate group 29: $source_rr29 estimated -> 0 fixed"
echo "  active reporting-rate parameters: 12 -> $rr_total_count"
echo "  terminal spline group 14: $source_sel14 -> $output_sel14"
echo "  terminal spline group 22: $source_sel22 -> $output_sel22"
echo "  terminal coefficients still at the numerical lower bound: $remaining_lower_bounds"
