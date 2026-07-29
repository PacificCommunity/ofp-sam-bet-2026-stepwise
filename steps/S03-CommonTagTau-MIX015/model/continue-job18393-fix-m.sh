#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}
frq=${FRQ:-bet.frq}
input_par=previous-job.par
final_par=final.par
control_file=fix-job18393-m-control.txt
audit_file=job18393-fix-m-audit.csv
final_convergence_exponent=${BET_PHASE10_11_CONVERGENCE:--4}
final_evaluations=${JOB_PAR_MAX_EVALUATIONS:-10000}
expected_source_par_sha256=${EXPECTED_SOURCE_PAR_SHA256:-}
fix_m_final=${FIX_M_FINAL:-false}
fixed_m_intercept=${FIXED_M_INTERCEPT:--2.44602044920584}

if [ -z "$program_path" ] || [ ! -x "$program_path" ]; then
  echo "PROGRAM_PATH does not name an executable MFCL binary." >&2
  exit 60
fi
if [ ! -s "$frq" ] || [ ! -s "$input_par" ]; then
  echo "The fixed-M sensitivity needs $frq and the attached Job 18393 $input_par." >&2
  exit 61
fi
if [ "$fix_m_final" != true ]; then
  echo "FIX_M_FINAL must be true for this Job 18393 sensitivity." >&2
  exit 62
fi
if [ "$final_convergence_exponent" != -4 ]; then
  echo "BET_PHASE10_11_CONVERGENCE must be -4 for this sensitivity." >&2
  exit 63
fi
case "$final_evaluations" in
  *[!0-9]*|"") echo "JOB_PAR_MAX_EVALUATIONS must be a positive integer." >&2; exit 64 ;;
esac
if [ "$final_evaluations" -le 0 ]; then
  echo "JOB_PAR_MAX_EVALUATIONS must be greater than zero." >&2
  exit 64
fi
if [ -z "$expected_source_par_sha256" ]; then
  echo "EXPECTED_SOURCE_PAR_SHA256 is required for the Job 18393 continuation." >&2
  exit 65
fi

sha256_file()
{
  sha256sum "$1" | awk '{print $1}'
}

read_par_flag()
{
  awk -v header="$1" -v field_no="$2" '
    $0 == header {
      getline
      print $field_no
      exit
    }
  ' "$3"
}

read_fish_flag()
{
  awk -v fishery="$1" -v field_no="$2" '
    /^# fish flags/ {in_fish=1; next}
    in_fish && /^#/ {exit}
    in_fish && NF {
      row++
      if (row == fishery) {
        print $field_no
        exit
      }
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
      if (row == 5) {
        print $1
        exit
      }
    }
  ' "$1"
}

read_footer_value()
{
  awk -v marker="$1" '
    index($0, marker) == 1 {
      getline
      print $1
      exit
    }
  ' "$2"
}

same_number()
{
  awk -v observed="$1" -v expected="$2" 'BEGIN {
    difference = observed - expected
    if (difference < 0) difference = -difference
    scale = expected
    if (scale < 0) scale = -scale
    if (scale < 1) scale = 1
    exit(difference <= 1e-12 * scale ? 0 : 1)
  }'
}

source_par_sha256=$(sha256_file "$input_par")
if [ "$source_par_sha256" != "$expected_source_par_sha256" ]; then
  echo "Attached PAR checksum does not match the verified Job 18393 final PAR." >&2
  echo "expected=$expected_source_par_sha256 observed=$source_par_sha256" >&2
  exit 66
fi

source_parest50=$(read_par_flag "# The parest_flags" 50 "$input_par")
source_parest121=$(read_par_flag "# The parest_flags" 121 "$input_par")
source_parest387=$(read_par_flag "# The parest_flags" 387 "$input_par")
source_age27=$(read_par_flag "# age flags" 27 "$input_par")
source_age110=$(read_par_flag "# age flags" 110 "$input_par")
source_f14_flag75=$(read_fish_flag 14 75 "$input_par")
source_f15_flag75=$(read_fish_flag 15 75 "$input_par")
source_m=$(read_age_pars5 "$input_par")
source_npars=$(read_footer_value "# The number of parameters" "$input_par")
if [ "$source_parest50" != -4 ] || [ "$source_parest121" != 1 ] ||
   [ "$source_parest387" != 0 ] || [ "$source_npars" -ne 1990 ]; then
  echo "Job 18393 must start at parest flags 50=-4, 121=1, 387=0 and 1990 parameters." >&2
  exit 67
fi
if [ "$source_age27" != -1 ] || [ "$source_age110" != 0 ]; then
  echo "Job 18393 must retain movement prior 0.1 and recruitment penalty 0.1." >&2
  exit 68
fi
if [ "$source_f14_flag75" != 5 ] || [ "$source_f15_flag75" != 5 ]; then
  echo "Job 18393 F14/F15 youngest-five-age controls are not present." >&2
  exit 69
fi
if ! same_number "$source_m" "$fixed_m_intercept"; then
  echo "Job 18393 fitted M intercept is unexpected: $source_m versus $fixed_m_intercept." >&2
  exit 70
fi

{
  printf '%s\n' \
    "  1 1 $final_evaluations  # maximum evaluations after fixing M" \
    "  1 50 $final_convergence_exponent  # final MGC target" \
    "  1 121 0  # fix age_pars(5) at the Job 18393 fitted value" \
    "  1 387 0  # retain current default independent-variable scaling" \
    "  1 246 1  # write indepvar.rpt" \
    "  1 189 1  # write fit reports" \
    "  1 190 1  # write plot report" \
    "  1 188 1  # write standard report output" \
    "  1 187 1  # write tag report output" \
    "  1 186 0"
} > "$control_file"

echo "Fixing the Job 18393 fitted Lorenzen M intercept and re-optimising."
echo "  source PAR SHA256: $source_par_sha256"
echo "  fixed M intercept: $source_m"
echo "  parest 121: 1 -> 0; parest 387 remains 0"
echo "  MGC 1e-4; maximum evaluations $final_evaluations"
"$program_path" "$frq" "$input_par" "$final_par" -file "$control_file"
if [ ! -s "$final_par" ]; then
  echo "MFCL did not create $final_par." >&2
  exit 71
fi

output_parest50=$(read_par_flag "# The parest_flags" 50 "$final_par")
output_parest121=$(read_par_flag "# The parest_flags" 121 "$final_par")
output_parest387=$(read_par_flag "# The parest_flags" 387 "$final_par")
if [ "$output_parest50" != -4 ] || [ "$output_parest121" != 0 ] ||
   [ "$output_parest387" != 0 ]; then
  echo "Final PAR did not retain parest flags 50=-4, 121=0 and 387=0." >&2
  exit 72
fi
for flag in 111 177 239 249 305 306 342 358; do
  source_value=$(read_par_flag "# The parest_flags" "$flag" "$input_par")
  output_value=$(read_par_flag "# The parest_flags" "$flag" "$final_par")
  if [ "$source_value" != "$output_value" ]; then
    echo "Fixed-M continuation changed parest flag $flag: $source_value -> $output_value." >&2
    exit 73
  fi
done
if [ "$(read_par_flag "# age flags" 27 "$final_par")" != "$source_age27" ] ||
   [ "$(read_par_flag "# age flags" 110 "$final_par")" != "$source_age110" ] ||
   [ "$(read_fish_flag 14 75 "$final_par")" != "$source_f14_flag75" ] ||
   [ "$(read_fish_flag 15 75 "$final_par")" != "$source_f15_flag75" ]; then
  echo "Fixed-M continuation changed rec, movement, or young-age controls." >&2
  exit 74
fi

final_m=$(read_age_pars5 "$final_par")
if ! same_number "$final_m" "$source_m"; then
  echo "M changed after it was fixed: $source_m -> $final_m." >&2
  exit 75
fi
if [ ! -s indepvar.rpt ]; then
  echo "Fixed-M continuation did not write indepvar.rpt." >&2
  exit 76
fi
estimated_m_count=$(awk '$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}' indepvar.rpt)
estimated_tau_count=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' indepvar.rpt)
if [ "$estimated_m_count" -ne 0 ] || [ "$estimated_tau_count" -ne 1 ]; then
  echo "Expected zero estimated M intercepts and one common tag tau; found $estimated_m_count and $estimated_tau_count." >&2
  exit 77
fi

source_objective=$(read_footer_value "# Objective function value" "$input_par")
source_max_gradient=$(read_footer_value "# Maximum magnitude gradient value" "$input_par")
output_objective=$(read_footer_value "# Objective function value" "$final_par")
output_max_gradient=$(read_footer_value "# Maximum magnitude gradient value" "$final_par")
output_npars=$(read_footer_value "# The number of parameters" "$final_par")
if [ -z "$output_objective" ] || [ -z "$output_max_gradient" ] ||
   [ -z "$final_m" ] || [ "$output_npars" -ne 1989 ]; then
  echo "Could not verify objective, gradient, fixed M, or the expected 1990 -> 1989 parameter count." >&2
  exit 78
fi
if ! awk -v gradient="$output_max_gradient" 'BEGIN {
  if (gradient < 0) gradient = -gradient
  exit(gradient <= 1e-4 ? 0 : 1)
}'; then
  echo "Final maximum gradient $output_max_gradient did not reach 1e-4." >&2
  exit 79
fi

output_par_sha256=$(sha256_file "$final_par")
{
  printf '%s\n' \
    "source_job,source_par_sha256,output_par_sha256,source_objective,output_objective,source_max_gradient,output_max_gradient,source_npars,output_npars,source_m,final_m,source_parest121,output_parest121,source_parest387,output_parest387,estimated_m_count,estimated_tau_count,final_evaluations,status"
  printf '%s\n' \
    "18393,$source_par_sha256,$output_par_sha256,$source_objective,$output_objective,$source_max_gradient,$output_max_gradient,$source_npars,$output_npars,$source_m,$final_m,$source_parest121,$output_parest121,$source_parest387,$output_parest387,$estimated_m_count,$estimated_tau_count,$final_evaluations,passed"
} > "$audit_file"

echo "Job 18393 final-PAR fixed-M audit passed."
