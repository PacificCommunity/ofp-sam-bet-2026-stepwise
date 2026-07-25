#!/bin/sh

# Native MFCL tag-dispersion groupings.
#
# Tau is indexed by recapture fishery, not by tag-release programme. The JPTP
# and PTTP Region 4 labels below therefore identify recapture-fishery proxies:
# F1/F12/F13 contain 141 of 151 post-mixing JPTP recaptures, and F25-F28
# contain 2,239 of 2,405 post-mixing recaptures from PTTP Region 4 releases
# under the SC22-IP10 K=0.15 mixing periods.

tag_tau_scenario_is_supported()
{
  case "$1" in
    g01-common|\
    g02-jptp-proxy|\
    g03-pttp-r4-proxy|\
    g04-jptp-r4|\
    g05-jptp-r4-west-east|\
    g06-jptp-gear-r4-west-east|\
    g07-jptp-fishery-r4-west-east|\
    g08-focus-fisheries|\
    g09-operational|\
    g10-fishery)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

tag_tau_expected_groups()
{
  case "$1" in
    g01-common) echo 1 ;;
    g02-jptp-proxy|g03-pttp-r4-proxy) echo 2 ;;
    g04-jptp-r4) echo 3 ;;
    g05-jptp-r4-west-east) echo 4 ;;
    g06-jptp-gear-r4-west-east) echo 5 ;;
    g07-jptp-fishery-r4-west-east) echo 6 ;;
    g08-focus-fisheries) echo 8 ;;
    g09-operational) echo 15 ;;
    g10-fishery) echo 19 ;;
    *) return 1 ;;
  esac
}

tag_tau_fishery_is_active()
{
  fishery=$1
  [ "$fishery" -ge 1 ] && [ "$fishery" -le 28 ]
}

tag_tau_group_for_fishery()
{
  scenario=$1
  fishery=$2

  if ! tag_tau_fishery_is_active "$fishery"; then
    echo 0
    return
  fi

  case "$scenario" in
    g01-common)
      echo 1
      ;;
    g02-jptp-proxy)
      case "$fishery" in 1|12|13) echo 2 ;; *) echo 1 ;; esac
      ;;
    g03-pttp-r4-proxy)
      case "$fishery" in 25|26|27|28) echo 2 ;; *) echo 1 ;; esac
      ;;
    g04-jptp-r4)
      case "$fishery" in
        1|12|13) echo 2 ;;
        25|26|27|28) echo 3 ;;
        *) echo 1 ;;
      esac
      ;;
    g05-jptp-r4-west-east)
      case "$fishery" in
        1|12|13) echo 2 ;;
        25|27) echo 3 ;;
        26|28) echo 4 ;;
        *) echo 1 ;;
      esac
      ;;
    g06-jptp-gear-r4-west-east)
      case "$fishery" in
        1) echo 2 ;;
        12|13) echo 3 ;;
        25|27) echo 4 ;;
        26|28) echo 5 ;;
        *) echo 1 ;;
      esac
      ;;
    g07-jptp-fishery-r4-west-east)
      case "$fishery" in
        1) echo 2 ;;
        12) echo 3 ;;
        13) echo 4 ;;
        25|27) echo 5 ;;
        26|28) echo 6 ;;
        *) echo 1 ;;
      esac
      ;;
    g08-focus-fisheries)
      case "$fishery" in
        1) echo 2 ;;
        12) echo 3 ;;
        13) echo 4 ;;
        25) echo 5 ;;
        26) echo 6 ;;
        27) echo 7 ;;
        28) echo 8 ;;
        *) echo 1 ;;
      esac
      ;;
    g09-operational)
      case "$fishery" in
        1) echo 1 ;;
        2|3) echo 2 ;;
        4) echo 3 ;;
        5) echo 4 ;;
        6) echo 5 ;;
        7) echo 6 ;;
        8) echo 7 ;;
        9) echo 8 ;;
        10|11) echo 9 ;;
        12) echo 10 ;;
        13|16|24) echo 11 ;;
        14|15|17|18|21|22|23) echo 12 ;;
        19|20) echo 13 ;;
        25|27) echo 14 ;;
        26|28) echo 15 ;;
      esac
      ;;
    g10-fishery)
      case "$fishery" in
        1) echo 1 ;;
        2|3) echo 2 ;;
        4) echo 3 ;;
        5) echo 4 ;;
        6) echo 5 ;;
        7) echo 6 ;;
        8) echo 7 ;;
        9) echo 8 ;;
        10|11) echo 9 ;;
        12) echo 10 ;;
        13|16|24) echo 11 ;;
        14|15) echo 12 ;;
        17|18|19|20) echo 13 ;;
        21) echo 14 ;;
        22|23) echo 15 ;;
        25) echo 16 ;;
        26) echo 17 ;;
        27) echo 18 ;;
        28) echo 19 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

tag_tau_write_controls()
{
  scenario=$1
  fishery=1
  while [ "$fishery" -le 33 ]; do
    group=$(tag_tau_group_for_fishery "$scenario" "$fishery")
    if tag_tau_fishery_is_active "$fishery"; then
      printf '  -%s 43 1 -%s 44 %s\n' "$fishery" "$fishery" "$group"
    else
      printf '  -%s 43 0 -%s 44 0\n' "$fishery" "$fishery"
    fi
    fishery=$((fishery + 1))
  done
}

tag_tau_validate_mapping()
{
  scenario=$1
  expected=$(tag_tau_expected_groups "$scenario") || return 1
  groups=
  fishery=1
  while [ "$fishery" -le 28 ]; do
    group=$(tag_tau_group_for_fishery "$scenario" "$fishery") || return 1
    [ "$group" -ge 1 ] || return 1
    groups="${groups}
${group}"
    fishery=$((fishery + 1))
  done
  actual=$(printf '%s\n' "$groups" | awk 'NF {seen[$1]=1} END {print length(seen)}')
  [ "$actual" -eq "$expected" ]
}
