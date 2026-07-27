#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}
frq=${FRQ:-bet.frq}
input_par=previous-job.par
final_par=final.par
control_file=job-par-control.txt
audit_file=job-par-continuation-audit.csv
convergence_exponent=${BET_PHASE10_11_CONVERGENCE:--5}
regional_recruitment_penalty=${REGIONAL_RECRUITMENT_PENALTY:-0.1}
max_evaluations=${JOB_PAR_MAX_EVALUATIONS:-10000}
expected_source_par_sha256=${EXPECTED_SOURCE_PAR_SHA256:-}

if [ -z "$program_path" ] || [ ! -x "$program_path" ]; then
  echo "PROGRAM_PATH does not name an executable MFCL binary." >&2
  exit 60
fi
if [ ! -s "$frq" ] || [ ! -s "$input_par" ]; then
  echo "The continuation needs $frq and the attached Job 17227 $input_par." >&2
  exit 61
fi
case "$convergence_exponent" in
  -[0-9]|-[0-9][0-9]) ;;
  *)
    echo "BET_PHASE10_11_CONVERGENCE must be a negative integer exponent." >&2
    exit 62
    ;;
esac
case "$regional_recruitment_penalty" in
  0.1)
    regional_recruitment_penalty_flag=0
    ;;
  0.2)
    # MFCL uses the default 0.1 when age flag 110 is zero. For positive
    # values, the source implements penalty = age_flags(110) / 10.
    regional_recruitment_penalty_flag=2
    ;;
  *)
    echo "REGIONAL_RECRUITMENT_PENALTY must be 0.1 or 0.2." >&2
    exit 63
    ;;
esac
case "$max_evaluations" in
  *[!0-9]*|"")
    echo "JOB_PAR_MAX_EVALUATIONS must be a positive integer." >&2
    exit 64
    ;;
esac
if [ "$max_evaluations" -le 0 ]; then
  echo "JOB_PAR_MAX_EVALUATIONS must be greater than zero." >&2
  exit 64
fi
if [ -z "$expected_source_par_sha256" ]; then
  echo "EXPECTED_SOURCE_PAR_SHA256 is required for the Job 17227 continuation." >&2
  exit 65
fi

sha256_file()
{
  sha256sum "$1" | awk '{print $1}'
}

read_par_flag()
{
  awk -v header="$1" -v index="$2" '
    $0 == header {
      getline
      print $index
      exit
    }
  ' "$3"
}

read_footer_value()
{
  awk -v header="$1" '
    $0 == header {
      getline
      print $1
      exit
    }
  ' "$2"
}

source_par_sha256=$(sha256_file "$input_par")
if [ "$source_par_sha256" != "$expected_source_par_sha256" ]; then
  echo "Attached PAR checksum does not match the verified Job 17227 final PAR." >&2
  echo "expected=$expected_source_par_sha256 observed=$source_par_sha256" >&2
  exit 66
fi

source_age_flag_110=$(read_par_flag "# age flags" 110 "$input_par")
source_parest_flag_50=$(read_par_flag "# The parest_flags" 50 "$input_par")
if [ "$source_age_flag_110" != 0 ]; then
  echo "Job 17227 source PAR age flag 110 is $source_age_flag_110; expected 0 (default penalty 0.1)." >&2
  exit 67
fi
if [ "$source_parest_flag_50" != -4 ]; then
  echo "Job 17227 source PAR parest flag 50 is $source_parest_flag_50; expected -4." >&2
  exit 68
fi

{
  printf '%s\n' \
    "  1 1 $max_evaluations  # maximum function evaluations for final-PAR continuation" \
    "  1 50 $convergence_exponent  # MGC threshold = 10^exponent" \
    "  2 110 $regional_recruitment_penalty_flag  # default 0.1 when 0; positive values are divided by 10" \
    "  1 121 0  # retain fixed natural mortality from Job 17227" \
    "  1 246 1  # write indepvar.rpt" \
    "  1 189 1  # write fit reports" \
    "  1 190 1  # write plot report" \
    "  1 188 1  # write standard report output" \
    "  1 187 1  # write tag report output" \
    "  1 186 0"
} > "$control_file"

echo "Continuing verified Job 17227 final PAR."
echo "  source PAR SHA256: $source_par_sha256"
echo "  convergence exponent: $convergence_exponent"
echo "  regional recruitment penalty: $regional_recruitment_penalty (age flag 110=$regional_recruitment_penalty_flag)"
echo "  maximum evaluations: $max_evaluations"

"$program_path" "$frq" "$input_par" "$final_par" -file "$control_file"

if [ ! -s "$final_par" ]; then
  echo "MFCL did not create $final_par." >&2
  exit 69
fi

output_age_flag_110=$(read_par_flag "# age flags" 110 "$final_par")
output_parest_flag_50=$(read_par_flag "# The parest_flags" 50 "$final_par")
if [ "$output_age_flag_110" != "$regional_recruitment_penalty_flag" ]; then
  echo "Final age flag 110 is $output_age_flag_110; expected $regional_recruitment_penalty_flag." >&2
  exit 70
fi
if [ "$output_parest_flag_50" != "$convergence_exponent" ]; then
  echo "Final parest flag 50 is $output_parest_flag_50; expected $convergence_exponent." >&2
  exit 71
fi

for flag in 111 121 177 239 249 305 306 342 358; do
  source_value=$(read_par_flag "# The parest_flags" "$flag" "$input_par")
  output_value=$(read_par_flag "# The parest_flags" "$flag" "$final_par")
  if [ "$source_value" != "$output_value" ]; then
    echo "Continuation changed parest flag $flag: $source_value -> $output_value." >&2
    exit 72
  fi
done

if [ ! -s indepvar.rpt ]; then
  echo "Continuation did not write indepvar.rpt." >&2
  exit 73
fi
estimated_tau_count=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' indepvar.rpt)
if [ "$estimated_tau_count" -ne 1 ]; then
  echo "Continuation estimated $estimated_tau_count common tau parameters; expected one." >&2
  exit 74
fi

source_objective=$(read_footer_value "# Objective function value" "$input_par")
source_max_gradient=$(read_footer_value "# Maximum magnitude gradient" "$input_par")
output_objective=$(read_footer_value "# Objective function value" "$final_par")
output_max_gradient=$(read_footer_value "# Maximum magnitude gradient" "$final_par")
if [ -z "$output_objective" ] || [ -z "$output_max_gradient" ]; then
  echo "Could not read the final objective function or maximum gradient." >&2
  exit 75
fi
if ! awk -v gradient="$output_max_gradient" -v exponent="$convergence_exponent" '
  BEGIN {
    if (gradient < 0) gradient = -gradient
    threshold = 10 ^ exponent
    exit(gradient <= threshold ? 0 : 1)
  }
'; then
  echo "Final maximum gradient $output_max_gradient did not reach 10^$convergence_exponent." >&2
  exit 76
fi

output_par_sha256=$(sha256_file "$final_par")
{
  printf '%s\n' \
    "source_job,source_par_sha256,output_par_sha256,source_objective,output_objective,source_max_gradient,output_max_gradient,source_parest50,output_parest50,regional_recruitment_penalty,source_age_flag110,output_age_flag110,max_evaluations,estimated_tau_count,status"
  printf '%s\n' \
    "17227,$source_par_sha256,$output_par_sha256,$source_objective,$output_objective,$source_max_gradient,$output_max_gradient,$source_parest_flag_50,$output_parest_flag_50,$regional_recruitment_penalty,$source_age_flag_110,$output_age_flag_110,$max_evaluations,$estimated_tau_count,passed"
} > "$audit_file"

echo "Job 17227 final-PAR continuation audit passed."
