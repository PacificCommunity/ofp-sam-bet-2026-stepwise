# -------------------------------------------------------
#  PHASE 10 - estimate tag-recapture overdispersion tau
# -------------------------------------------------------

tag_tau_lower_bound=${TAG_TAU_LOWER_BOUND:-default}
case "$tag_tau_lower_bound" in
  default|1)
    # A flag-306 value of 100 is invalid because MFCL evaluates log(1 - 1).
    # The native default transformed bound is therefore used: theta >= -5,
    # which gives the effective tau lower bound 1 + exp(-5) = 1.006737947.
    tag_tau_lower_bound=default
    tag_tau_flag306=0
    tag_tau_start=2
    tag_tau_start_theta=0
    tag_tau_effective_lower=1.006737947
    ;;
  2)
    tag_tau_flag306=200
    tag_tau_start=3
    tag_tau_start_theta=0.6931471805599453
    tag_tau_effective_lower=2
    ;;
  *)
    echo "TAG_TAU_LOWER_BOUND must be default or 2." >&2
    exit 40
    ;;
esac

estimate_m_final=${ESTIMATE_M_FINAL:-false}
case "$estimate_m_final" in
  false|FALSE|0|no|NO)
    estimate_m_final=false
    mortality_phase11_flag=0
    ;;
  true|TRUE|1|yes|YES)
    estimate_m_final=true
    mortality_phase11_flag=1
    ;;
  *)
    echo "ESTIMATE_M_FINAL must be true or false." >&2
    exit 41
    ;;
esac

tag_likelihood_weight=${TAG_LIKELIHOOD_WEIGHT:-0}
case "$tag_likelihood_weight" in
  0|full|FULL)
    tag_likelihood_weight=0
    tag_likelihood_multiplier=1.00
    ;;
  500)
    tag_likelihood_multiplier=0.50
    ;;
  *)
    echo "TAG_LIKELIHOOD_WEIGHT must be 0, full, or 500." >&2
    exit 55
    ;;
esac

tag_tau_grouping=${TAG_TAU_GROUPING:-common}
case "$tag_tau_grouping" in
  off)
    # Retain the inherited negative-binomial tag likelihood and fish_pars(4)
    # values, but do not estimate any tag-overdispersion parameter.
    expected_tau_count=0
    tag_tau_grouping_label=not-estimated
    tag_tau_parest305=0
    tag_tau_lower_bound=not-applicable
    tag_tau_effective_lower=not-applicable
    tag_tau_start=not-estimated
    tag_tau_start_theta=0
    tag_tau_flag306=0
    ;;
  common)
    expected_tau_count=1
    tag_tau_grouping_label=common-F1-F28
    tag_tau_parest305=1
    ;;
  program-informed)
    # MFCL tau is indexed by recapture fishery, not release programme.
    # These three strata are therefore programme-informed proxies:
    # F1/F12/F13 contain 93.4% of post-mixing JPTP recaptures, F25-F28
    # contain 93.1% of post-mixing recaptures from PTTP Region 4 releases,
    # and all other active recapture fisheries form the reference stratum.
    expected_tau_count=3
    tag_tau_grouping_label=program-informed-recapture-strata
    tag_tau_parest305=1
    ;;
  *)
    echo "TAG_TAU_GROUPING must be off, common, or program-informed." >&2
    exit 42
    ;;
esac

tag_tau_group_for_fishery()
{
  fishery=$1
  if [ "$fishery" -gt 28 ]; then
    echo 0
    return
  fi
  case "$tag_tau_grouping" in
    off)
      echo 0
      ;;
    common)
      echo 1
      ;;
    program-informed)
      case "$fishery" in
        1|12|13) echo 2 ;;
        25|26|27|28) echo 3 ;;
        *) echo 1 ;;
      esac
      ;;
  esac
}

tag_tau_group_controls=$(
  fishery=1
  while [ "$fishery" -le 33 ]; do
    if [ "$tag_tau_grouping" = off ]; then
      printf '  -%s 43 0 -%s 44 0\n' "$fishery" "$fishery"
    elif [ "$fishery" -le 28 ]; then
      group=$(tag_tau_group_for_fishery "$fishery")
      printf '  -%s 43 1 -%s 44 %s\n' "$fishery" "$fishery" "$group"
    else
      printf '  -%s 43 0 -%s 44 0\n' "$fishery" "$fishery"
    fi
    fishery=$((fishery + 1))
  done
)

echo "TAG tau grouping: $tag_tau_grouping_label ($expected_tau_count estimated parameter(s))"
echo "TAG tau requested lower bound: $tag_tau_lower_bound"
echo "TAG tau effective lower bound: $tag_tau_effective_lower"
echo "TAG tau starting value: $tag_tau_start"
echo "TAG-recapture likelihood multiplier: $tag_likelihood_multiplier (parest flag 177=$tag_likelihood_weight)"
echo "Lorenzen M estimation in Phases 11-12: $estimate_m_final"

# Set only fishery-parameter row 4 in the Phase 10 input. Phases 0-9 retain
# the complete selected selectivity-form and recruitment-penalty sequence.
if [ "$tag_tau_grouping" = off ]; then
  cp 09.par 09.tau.par
else
  awk -v theta="$tag_tau_start_theta" '
  BEGIN { in_fish = 0; fish_row = 0; changed = 0 }
  /^# extra fishery parameters/ { in_fish = 1; print; next }
  in_fish && /^#/ { print; next }
  in_fish && NF == 0 { print; next }
  in_fish {
    fish_row++
    if (fish_row == 4) {
      if (NF != 33) {
        print "Expected 33 fishery parameters in row 4; found " NF > "/dev/stderr"
        exit 42
      }
      for (i = 1; i <= NF; i++) {
        printf "%s%s", theta, (i == NF ? "\n" : " ")
      }
      changed = 1
      in_fish = 0
      next
    }
  }
  { print }
  END {
    if (changed != 1) {
      print "Could not set fishery-parameter row 4 in 09.par" > "/dev/stderr"
      exit 43
    }
  }
' 09.par > 09.tau.par
fi

$program_path bet.frq 09.tau.par 10.par -file - <<PHASE10
  1 111 4    # negative-binomial tag-recapture likelihood
  1 177 $tag_likelihood_weight  # selected tag-recapture likelihood multiplier
  1 239 0    # serial tag-return implementation supporting direct tau
  1 249 0    # standard tag-return likelihood
  1 101 0    # standard tag-return calculation
  1 305 $tag_tau_parest305  # selected negative-binomial tau treatment
  1 306 $tag_tau_flag306  # selected direct-tau lower-bound control
  1 358 0    # retain the default upper-bound rule
  2 100 0    # standard tag-return calculation
  2 121 0    # do not use tag survival-analysis likelihood
  2 122 0    # keep tag-recapture data active
$tag_tau_group_controls
  1 1 3000   # stabilize the newly opened common tau parameter
  1 50 -3
  1 121 0    # keep the INI Lorenzen natural-mortality value fixed
PHASE10

# ----------
#  PHASE 11
# ----------

$program_path bet.frq 10.par 11.par -file - <<PHASE11
  1 1 10000
  1 50 $phase10_11_convergence
  1 121 $mortality_phase11_flag  # estimate M only in the final two phases when requested
PHASE11

# ----------
#  PHASE 12
# ----------

$program_path bet.frq 11.par 12.par -file - <<PHASE12
  1 1 5000
  1 50 $phase10_11_convergence
  1 121 $mortality_phase11_flag  # retain the requested final-phase M treatment
  1 246 1   # write indepvar.rpt
PHASE12

final_par=12.par

# Fail unless MFCL retained exactly the requested tau configuration.
actual_tau=$(awk '$2 ~ /^fish_pars[(]4[)]/ {n++} END {print n+0}' indepvar.rpt)
if [ "$actual_tau" -ne "$expected_tau_count" ]; then
  echo "Final fit estimated $actual_tau tau parameters; expected $expected_tau_count." >&2
  exit 44
fi

awk '
  /^# fish flags/ {in_fish=1; next}
  in_fish && /^#/ {exit}
  in_fish && NF {
    fishery++
    print fishery, $43, $44
    if (fishery == 33) exit
  }
' "$final_par" > tag-tau-map-final.txt
if [ "$(wc -l < tag-tau-map-final.txt)" -ne 33 ]; then
  echo "Final parameter file did not contain all 33 fishery tau controls." >&2
  exit 45
fi
while read -r fishery active group; do
  if [ "$tag_tau_grouping" = off ]; then
    expected_active=0
    expected_group=0
  elif [ "$fishery" -le 28 ]; then
    expected_active=1
    expected_group=$(tag_tau_group_for_fishery "$fishery")
  else
    expected_active=0
    expected_group=0
  fi
  if [ "$active" != "$expected_active" ] || [ "$group" != "$expected_group" ]; then
    echo "Final tau map differs at F$fishery: $active/$group; expected $expected_active/$expected_group." >&2
    exit 46
  fi
done < tag-tau-map-final.txt

parest_111=$(awk '/^# The parest_flags/{getline; print $111; exit}' "$final_par")
parest_121=$(awk '/^# The parest_flags/{getline; print $121; exit}' "$final_par")
parest_177=$(awk '/^# The parest_flags/{getline; print $177; exit}' "$final_par")
parest_239=$(awk '/^# The parest_flags/{getline; print $239; exit}' "$final_par")
parest_249=$(awk '/^# The parest_flags/{getline; print $249; exit}' "$final_par")
parest_305=$(awk '/^# The parest_flags/{getline; print $305; exit}' "$final_par")
parest_306=$(awk '/^# The parest_flags/{getline; print $306; exit}' "$final_par")
parest_342=$(awk '/^# The parest_flags/{getline; print $342; exit}' "$final_par")
parest_358=$(awk '/^# The parest_flags/{getline; print $358; exit}' "$final_par")
if [ "$parest_111" != 4 ] ||
   [ "$parest_177" != "$tag_likelihood_weight" ] || [ "$parest_239" != 0 ] ||
   [ "$parest_249" != 0 ] || [ "$parest_305" != "$tag_tau_parest305" ] ||
   [ "$parest_306" != "$tag_tau_flag306" ] ||
   [ "$parest_342" != "$dm_nmax_flag" ] || [ "$parest_358" != 0 ]; then
  echo "Final parameter file did not retain the required direct-tau or tag-weight controls." >&2
  exit 47
fi
if { [ "$estimate_m_final" = false ] && [ "$parest_121" != 0 ]; } ||
   { [ "$estimate_m_final" = true ] && [ "$parest_121" != 1 ]; }; then
  echo "Final parest flag 121 is inconsistent with ESTIMATE_M_FINAL=$estimate_m_final." >&2
  exit 48
fi

age_flag_110=$(awk '/^# age flags/{getline; print $110; exit}' "$final_par")
if [ "$age_flag_110" != "$regional_recruitment_penalty_flag" ]; then
  echo "Final age flag 110 is $age_flag_110; expected $regional_recruitment_penalty_flag." >&2
  exit 49
fi

phase10_m=$(awk '
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
' 10.par)
if ! awk -v observed="$phase10_m" 'BEGIN {
  expected = -2.54930339768360
  difference = observed - expected
  if (difference < 0) difference = -difference
  exit(difference <= 1e-12 ? 0 : 1)
}'; then
  echo "Lorenzen natural mortality changed before the optional Phase 11 opening: $phase10_m" >&2
  exit 50
fi

final_m=$(awk '
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
' "$final_par")
if [ -z "$final_m" ]; then
  echo "Could not read the final Lorenzen natural-mortality value." >&2
  exit 51
fi
if [ "$estimate_m_final" = true ]; then
  estimated_m_count=$(awk '$2 ~ /^age_pars[(]5[)]/ {n++} END {print n+0}' indepvar.rpt)
  if [ "$estimated_m_count" -ne 1 ]; then
    echo "Final phase estimated $estimated_m_count Lorenzen M parameters; expected one." >&2
    exit 52
  fi
else
  estimated_m_count=0
  if ! awk -v observed="$final_m" 'BEGIN {
    expected = -2.54930339768360
    difference = observed - expected
    if (difference < 0) difference = -difference
    exit(difference <= 1e-12 ? 0 : 1)
  }'; then
    echo "Fixed-M fit changed the Lorenzen natural-mortality value: $final_m" >&2
    exit 53
  fi
fi

printf 'grouping,regional_recruitment_penalty,age_flag110,dm_nmax_request,dm_nmax_effective,parest342,requested_tau_lower,effective_tau_lower,tau_start,estimated_tau_count,estimate_m_phases11_12,estimated_m_count,phase10_m,final_m,parest111,parest121,parest177,parest239,parest249,parest305,parest306,parest358,status\n' \
  > tag-tau-audit.csv
printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,passed\n' \
  "$tag_tau_grouping_label" \
  "$regional_recruitment_penalty" "$age_flag_110" \
  "$dm_nmax" "$dm_nmax_effective" "$parest_342" \
  "$tag_tau_lower_bound" "$tag_tau_effective_lower" "$tag_tau_start" \
  "$actual_tau" "$estimate_m_final" "$estimated_m_count" "$phase10_m" "$final_m" \
  "$parest_111" "$parest_121" "$parest_177" \
  "$parest_239" "$parest_249" "$parest_305" "$parest_306" "$parest_358" \
  >> tag-tau-audit.csv
if ! awk -F, 'NR == 1 {columns = NF} NR > 1 && NF != columns {exit 1}' \
  tag-tau-audit.csv; then
  echo "Tag-tau audit CSV has inconsistent column counts." >&2
  exit 54
fi
