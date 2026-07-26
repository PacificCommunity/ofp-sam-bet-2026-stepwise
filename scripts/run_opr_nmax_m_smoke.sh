#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-/home/mfcl/mfclo64}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
model_root="$repo_root/steps/S05-CommonTagTauOPR-MIX015/model"
output_root=${TAG_TAU_OPR_SMOKE_OUTPUT:-"$repo_root/outputs/tag-tau-opr-smoke"}
smoke_evaluations=${TAG_TAU_OPR_SMOKE_EVALUATIONS:-3}
smoke_grouping=${TAG_TAU_OPR_SMOKE_GROUPING:-program-informed}

if [ ! -x "$program_path" ]; then
  echo "Native MFCL executable is unavailable: $program_path" >&2
  exit 1
fi
case "$smoke_evaluations" in
  *[!0-9]*|"") echo "TAG_TAU_OPR_SMOKE_EVALUATIONS must be a positive integer." >&2; exit 1 ;;
esac
[ "$smoke_evaluations" -gt 0 ] || exit 1
case "$smoke_grouping" in
  off) expected_tau_count=0 ;;
  common) expected_tau_count=1 ;;
  program-informed) expected_tau_count=3 ;;
  *) echo "TAG_TAU_OPR_SMOKE_GROUPING must be off, common, or program-informed." >&2; exit 1 ;;
esac

mkdir -p "$output_root"
for file in bet.frq bet.ini bet.tag bet.age_length bet.reg_scaling mfcl.cfg doitall.sh; do
  cp "$model_root/$file" "$output_root/$file"
done

# Preserve the generated phase order and scientific controls. Only shorten the
# optimizer calls so this test checks control activation rather than fit.
perl -0pi -e \
  's/^(\s*1\s+1\s+)\d+(\s*(?:#.*)?)$/${1}'"$smoke_evaluations"'${2}/mg' \
  "$output_root/doitall.sh"
chmod +x "$output_root/doitall.sh"

(
  cd "$output_root"
  PROGRAM_PATH="$program_path" \
  BET_PHASE10_11_CONVERGENCE=-1 \
  TAG_TAU_GROUPING="$smoke_grouping" \
  TAG_TAU_LOWER_BOUND=default \
  REGIONAL_RECRUITMENT_PENALTY=0.2 \
  DM_NMAX=default \
  ESTIMATE_M_FINAL=true \
  TAG_LIKELIHOOD_WEIGHT=500 \
    sh doitall.sh > mfcl.log 2>&1
)

final_par="$output_root/12.par"
indepvar="$output_root/indepvar.rpt"
parest()
{
  awk -v column="$1" '/^# The parest_flags/{getline; print $column; exit}' "$final_par"
}
ageflag()
{
  awk -v column="$1" '/^# age flags/{getline; print $column; exit}' "$final_par"
}

[ "$(parest 121)" = 1 ]
[ "$(parest 177)" = 500 ]
[ "$(parest 155)" = 72 ]
[ "$(parest 216)" = 50 ]
[ "$(parest 217)" = 1 ]
[ "$(parest 218)" = 50 ]
[ "$(parest 342)" = 0 ]
[ "$(ageflag 30)" = 1 ]
[ "$(ageflag 70)" = 0 ]
[ "$(ageflag 71)" = 0 ]
[ "$(ageflag 110)" = 2 ]
[ "$(ageflag 178)" = 0 ]
[ "$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' "$indepvar")" = "$expected_tau_count" ]
[ "$(awk '$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}' "$indepvar")" = 1 ]

printf '%s\n' \
  "Sequential generated doitall: passed" \
  "OPR 72-01-50-50 with end2 from Phase 3: passed" \
  "regional recruitment coefficient 0.2 (age flag 110=2): passed" \
  "MFCL default DM Nmax (parest flag 342=0): passed" \
  "tag-recapture likelihood multiplier 0.50 (parest flag 177=500): passed" \
  "requested tau-estimation mode from Phase 10 ($smoke_grouping; $expected_tau_count parameter(s)): passed" \
  "late Lorenzen M estimation from Phase 11: passed"
