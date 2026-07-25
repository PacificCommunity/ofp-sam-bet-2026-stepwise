#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-/home/mfcl/mfclo64}
input_par=${TAG_TAU_SMOKE_PAR:-}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
model_root="$repo_root/steps/S03-CommonTagTau-MIX015/model"
output_root=${TAG_TAU_SMOKE_OUTPUT:-"$repo_root/outputs/common-tag-tau-smoke"}
lower_bounds=${TAG_TAU_SMOKE_LOWER_BOUNDS:-"default 2"}
groupings=${TAG_TAU_SMOKE_GROUPINGS:-"common program-informed"}
recruitment_penalties=${TAG_TAU_SMOKE_RECRUITMENT_PENALTIES:-"0.1 0.2"}

if [ ! -x "$program_path" ]; then
  echo "Native MFCL executable is unavailable: $program_path" >&2
  exit 1
fi
if [ -z "$input_par" ] || [ ! -s "$input_par" ]; then
  echo "Set TAG_TAU_SMOKE_PAR to a compatible fitted 33-fishery parameter file." >&2
  exit 1
fi

mkdir -p "$output_root"
printf 'grouping,regional_recruitment_penalty,age_flag110,requested_lower,effective_lower,start_tau,estimated_tau_count,fixed_m,status\n' \
  > "$output_root/smoke-summary.csv"

for grouping in $groupings; do
  case "$grouping" in
    common) expected_tau_count=1 ;;
    program-informed) expected_tau_count=3 ;;
    *)
      echo "TAG_TAU_SMOKE_GROUPINGS accepts only common and program-informed." >&2
      exit 1
      ;;
  esac

  for recruitment_penalty in $recruitment_penalties; do
  case "$recruitment_penalty" in
    0.1) age_flag_110=0 ;;
    0.2) age_flag_110=2 ;;
    *)
      echo "TAG_TAU_SMOKE_RECRUITMENT_PENALTIES accepts only 0.1 and 0.2." >&2
      exit 1
      ;;
  esac

  for requested_lower in $lower_bounds; do
  if [ "$grouping" = program-informed ] && [ "$requested_lower" != default ]; then
    continue
  fi
  case "$requested_lower" in
    default|1)
      requested_lower=default
      flag306=0
      effective_lower=1.006737947
      start_tau=2
      theta=0
      ;;
    2)
      flag306=200
      effective_lower=2
      start_tau=3
      theta=0.6931471805599453
      ;;
    *)
      echo "TAG_TAU_SMOKE_LOWER_BOUNDS accepts only default and 2." >&2
      exit 1
      ;;
  esac

  run_dir="$output_root/$grouping-recpen-$recruitment_penalty-lower-$requested_lower"
  mkdir -p "$run_dir"
  for file in bet.frq bet.tag bet.age_length bet.reg_scaling mfcl.cfg; do
    cp "$model_root/$file" "$run_dir/$file"
  done

  awk -v theta="$theta" '
    BEGIN { in_fish = 0; fish_row = 0; changed = 0 }
    /^# extra fishery parameters/ { in_fish = 1; print; next }
    in_fish && /^#/ { print; next }
    in_fish && NF == 0 { print; next }
    in_fish {
      fish_row++
      if (fish_row == 4) {
        if (NF != 33) exit 42
        for (i = 1; i <= NF; i++) {
          printf "%s%s", theta, (i == NF ? "\n" : " ")
        }
        changed = 1
        in_fish = 0
        next
      }
    }
    { print }
    END { if (changed != 1) exit 43 }
  ' "$input_par" > "$run_dir/input.par"

  {
    printf '%s\n' \
      '1 111 4' \
      '1 177 0' \
      '1 239 0' \
      '1 249 0' \
      '1 101 0' \
      '1 305 1' \
      "1 306 $flag306" \
      '1 358 0' \
      '2 100 0' \
      "2 110 $age_flag_110" \
      '2 121 0' \
      '2 122 0'
    fishery=1
    while [ "$fishery" -le 33 ]; do
      if [ "$fishery" -le 28 ]; then
        group=1
        if [ "$grouping" = program-informed ]; then
          case "$fishery" in
            1|12|13) group=2 ;;
            25|26|27|28) group=3 ;;
          esac
        fi
        printf -- '-%s 43 1 -%s 44 %s\n' "$fishery" "$fishery" "$group"
      else
        printf -- '-%s 43 0 -%s 44 0\n' "$fishery" "$fishery"
      fi
      fishery=$((fishery + 1))
    done
    printf '%s\n' \
      '1 1 30' \
      '1 50 -1' \
      '1 121 0' \
      '1 246 1'
  } > "$run_dir/controls.txt"

  (
    cd "$run_dir"
    "$program_path" bet.frq input.par output.par -file controls.txt > mfcl.log 2>&1
  )

  actual_tau=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' "$run_dir/indepvar.rpt")
  parest_121=$(awk '/^# The parest_flags/{getline; print $121; exit}' "$run_dir/output.par")
  parest_306=$(awk '/^# The parest_flags/{getline; print $306; exit}' "$run_dir/output.par")
  observed_age_flag_110=$(awk '/^# age flags/{getline; print $110; exit}' "$run_dir/output.par")
  fixed_m=$(awk '
    /^# age_pars/ || /^# age-class related parameters [(]age_pars[)]/ {
      in_age=1
      next
    }
    in_age && /^#/ {next}
    in_age && NF {row++; if (row == 5) {print $1; exit}}
  ' "$run_dir/output.par")
  if [ "$actual_tau" -ne "$expected_tau_count" ] || [ "$parest_121" != 0 ] ||
     [ "$observed_age_flag_110" != "$age_flag_110" ] ||
     [ "$parest_306" != "$flag306" ] ||
     ! awk -v observed="$fixed_m" 'BEGIN {
       expected=-2.54930339768360
       difference=observed-expected
       if (difference < 0) difference=-difference
       exit(difference <= 1e-12 ? 0 : 1)
     }'; then
    echo "Tag-tau smoke test failed for $grouping, recruitment penalty $recruitment_penalty and requested lower $requested_lower." >&2
    exit 2
  fi

  printf '%s,%s,%s,%s,%s,%s,%s,%s,passed\n' \
    "$grouping" "$recruitment_penalty" "$observed_age_flag_110" \
    "$requested_lower" "$effective_lower" "$start_tau" "$actual_tau" "$fixed_m" \
    >> "$output_root/smoke-summary.csv"
  done
done
done

echo "Tag-tau grouping, lower-bound and recruitment-penalty smoke tests passed."
