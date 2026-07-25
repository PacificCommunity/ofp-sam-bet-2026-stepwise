#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-/home/mfcl/mfclo64}
input_root=${KFLOW_INPUT_DIR:-${INPUT_DIR:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
model_root="$repo_root/steps/22-TagTauSensitivity/model"
output_root="$repo_root/outputs/tag-tau-smoke"

if [ ! -x "$program_path" ]; then
  echo "Native MFCL executable is unavailable: $program_path" >&2
  exit 1
fi
if [ -z "$input_root" ] || [ ! -d "$input_root" ]; then
  echo "Kflow input directory is unavailable." >&2
  exit 1
fi

payload=$(find "$input_root" -type f -name model_payload.rds -path '*19a-R1F2F3F29SharedSelectivity*' -print | head -n 1)
if [ -z "$payload" ]; then
  payload=$(find "$input_root" -type f -name model_payload.rds -print | head -n 1)
fi
if [ -z "$payload" ]; then
  echo "Job 15984 model_payload.rds was not found under $input_root." >&2
  exit 1
fi

mkdir -p "$output_root"
Rscript --vanilla "$repo_root/scripts/extract_payload_artifact.R" \
  "$payload" par "$output_root/job15984-final.par"
cp "$model_root/bet.frq" "$output_root/bet.frq"
cp "$model_root/tag_tau_scenarios.sh" "$output_root/tag_tau_scenarios.sh"

(
  cd "$output_root"
  . ./tag_tau_scenarios.sh

  input_sha=$(sha256sum job15984-final.par | awk '{print $1}')
  printf 'scenario,source_job,source_step,input_par_sha256,lower_tau,start_tau\n' > smoke-summary.csv

  for scenario in g01-common g05-jptp-r4-west-east g10-fishery; do
    expected=$(tag_tau_expected_groups "$scenario")
    scenario_dir="$output_root/$scenario"
    mkdir -p "$scenario_dir"
    cp bet.frq "$scenario_dir/bet.frq"

    awk -v theta="0.6931471805599453" '
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
    ' job15984-final.par > "$scenario_dir/input-tau.par"

    controls=$(tag_tau_write_controls "$scenario")
    {
      printf '%s\n' \
        '1 111 4' \
        '1 177 0' \
        '1 239 0' \
        '1 249 0' \
        '1 101 0' \
        '1 305 1' \
        '1 306 200' \
        '1 358 0' \
        '2 100 0' \
        '2 121 0' \
        '2 122 0'
      printf '%s\n' "$controls"
      printf '%s\n' \
        '1 1 30' \
        '1 50 -1' \
        '1 121 0' \
        '1 246 1'
    } > "$scenario_dir/smoke-controls.txt"

    (
      cd "$scenario_dir"
      "$program_path" bet.frq input-tau.par output.par -file smoke-controls.txt \
        > mfcl.log 2>&1
    )

    if [ ! -s "$scenario_dir/output.par" ] || [ ! -s "$scenario_dir/indepvar.rpt" ]; then
      echo "$scenario did not produce output.par and indepvar.rpt." >&2
      exit 1
    fi

    actual=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' "$scenario_dir/indepvar.rpt")
    if [ "$actual" -ne "$expected" ]; then
      echo "$scenario estimated $actual tau parameters; expected $expected." >&2
      grep -E 'fish_pars[(]4[)]|tag|tau' "$scenario_dir/indepvar.rpt" || true
      exit 1
    fi

    awk '
      /^# fish flags/ {in_fish=1; next}
      in_fish && /^#/ {exit}
      in_fish && NF {
        fishery++
        print fishery, $43, $44
        if (fishery == 33) exit
      }
    ' "$scenario_dir/output.par" > "$scenario_dir/output-tau-map.txt"
    if [ "$(wc -l < "$scenario_dir/output-tau-map.txt")" -ne 33 ]; then
      echo "$scenario output did not contain all 33 fishery tau controls." >&2
      exit 1
    fi
    while read -r fishery active group; do
      expected_group=$(tag_tau_group_for_fishery "$scenario" "$fishery")
      if tag_tau_fishery_is_active "$fishery"; then
        expected_active=1
      else
        expected_active=0
      fi
      if [ "$active" != "$expected_active" ] || [ "$group" != "$expected_group" ]; then
        echo "$scenario output changed the tau map for F$fishery: $active/$group; expected $expected_active/$expected_group." >&2
        exit 1
      fi
    done < "$scenario_dir/output-tau-map.txt"

    parest_111=$(awk '/^# The parest_flags/{getline; print $111; exit}' "$scenario_dir/output.par")
    parest_121=$(awk '/^# The parest_flags/{getline; print $121; exit}' "$scenario_dir/output.par")
    parest_177=$(awk '/^# The parest_flags/{getline; print $177; exit}' "$scenario_dir/output.par")
    parest_305=$(awk '/^# The parest_flags/{getline; print $305; exit}' "$scenario_dir/output.par")
    parest_306=$(awk '/^# The parest_flags/{getline; print $306; exit}' "$scenario_dir/output.par")
    parest_358=$(awk '/^# The parest_flags/{getline; print $358; exit}' "$scenario_dir/output.par")
    if [ "$parest_111" != 4 ] || [ "$parest_121" != 0 ] ||
       [ "$parest_177" != 0 ] || [ "$parest_305" != 1 ] ||
       [ "$parest_306" != 200 ] || [ "$parest_358" != 0 ]; then
      echo "$scenario did not retain the required parest controls." >&2
      exit 1
    fi

    printf 'scenario,expected_tau,estimated_tau,parest111,parest121,parest177,parest305,parest306,parest358,status\n' \
      > "$scenario_dir/audit.csv"
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,passed\n' \
      "$scenario" "$expected" "$actual" "$parest_111" "$parest_121" \
      "$parest_177" "$parest_305" "$parest_306" "$parest_358" \
      >> "$scenario_dir/audit.csv"
    printf '%s,15984,19a-R1F2F3F29SharedSelectivity,%s,2,3\n' "$scenario" "$input_sha" \
      >> smoke-summary.csv
  done
)

echo "All representative Job 15984 tag-tau smoke tests passed."
