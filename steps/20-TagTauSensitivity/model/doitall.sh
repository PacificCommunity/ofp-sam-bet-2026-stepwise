#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}

if [ -z "$program_path" ]; then
  echo "PROGRAM_PATH is not set. Exiting."
  exit 1
fi

phase11_12_convergence=${BET_PHASE11_12_CONVERGENCE:-${BET_PHASE10_11_CONVERGENCE:--4}}
case "$phase11_12_convergence" in
  -[0-9]|-[0-9][0-9]|[0-9]|[0-9][0-9]) ;;
  *)
    echo "BET_PHASE11_12_CONVERGENCE must be numeric, e.g. -3 for quick runs or -5 for strict runs." >&2
    exit 1
    ;;
esac

tag_tau_scenario=${TAG_TAU_SCENARIO:-common}
case "$tag_tau_scenario" in
  common|pttp-r4-combined-vs-rest|pttp-r4-west-east-vs-rest|g19-vs-rest|g20-vs-rest|longline-vs-other|longline-other-index|rest-pttp-r4-index|longline-other-pttp-r4-index|longline-other-g19-g20-index|jptp-core-vs-rest|jptp-core-pttp-r4-vs-rest|jptp-core-pttp-r4-west-east-vs-rest) ;;
  *)
    echo "Unsupported TAG_TAU_SCENARIO: $tag_tau_scenario" >&2
    exit 1
    ;;
esac

tag_tau_lower_x100=${TAG_TAU_LOWER_X100:-200}
case "$tag_tau_lower_x100" in
  200)
    tag_tau_start_theta=0.6931471805599453
    ;;
  300)
    tag_tau_start_theta=1.0986122886681098
    ;;
  400)
    tag_tau_start_theta=1.3862943611198906
    ;;
  *)
    echo "Unsupported TAG_TAU_LOWER_X100: $tag_tau_lower_x100" >&2
    exit 1
    ;;
esac

tag_tau_group_for_fishery()
{
  fishery=$1
  case "$tag_tau_scenario" in
    common)
      echo 1
      ;;
    pttp-r4-combined-vs-rest)
      if [ "$fishery" -ge 25 ] && [ "$fishery" -le 28 ]; then echo 2; else echo 1; fi
      ;;
    pttp-r4-west-east-vs-rest)
      case "$fishery" in
        25|27) echo 2 ;;
        26|28) echo 3 ;;
        *) echo 1 ;;
      esac
      ;;
    g19-vs-rest)
      case "$fishery" in 25|27) echo 2 ;; *) echo 1 ;; esac
      ;;
    g20-vs-rest)
      case "$fishery" in 26|28) echo 2 ;; *) echo 1 ;; esac
      ;;
    longline-vs-other)
      if [ "$fishery" -le 11 ]; then echo 1; else echo 2; fi
      ;;
    longline-other-index)
      if [ "$fishery" -le 11 ]; then
        echo 1
      elif [ "$fishery" -le 28 ]; then
        echo 2
      else
        echo 3
      fi
      ;;
    rest-pttp-r4-index)
      if [ "$fishery" -le 24 ]; then
        echo 1
      elif [ "$fishery" -le 28 ]; then
        echo 2
      else
        echo 3
      fi
      ;;
    longline-other-pttp-r4-index)
      if [ "$fishery" -le 11 ]; then
        echo 1
      elif [ "$fishery" -le 24 ]; then
        echo 2
      elif [ "$fishery" -le 28 ]; then
        echo 3
      else
        echo 4
      fi
      ;;
    longline-other-g19-g20-index)
      if [ "$fishery" -le 11 ]; then
        echo 1
      elif [ "$fishery" -le 24 ]; then
        echo 2
      else
        case "$fishery" in
          25|27) echo 3 ;;
          26|28) echo 4 ;;
          *) echo 5 ;;
        esac
      fi
      ;;
    jptp-core-vs-rest)
      case "$fishery" in 1|12|13) echo 2 ;; *) echo 1 ;; esac
      ;;
    jptp-core-pttp-r4-vs-rest)
      case "$fishery" in
        1|12|13) echo 2 ;;
        25|26|27|28) echo 3 ;;
        *) echo 1 ;;
      esac
      ;;
    jptp-core-pttp-r4-west-east-vs-rest)
      case "$fishery" in
        1|12|13) echo 2 ;;
        25|27) echo 3 ;;
        26|28) echo 4 ;;
        *) echo 1 ;;
      esac
      ;;
  esac
}

tag_tau_group_controls=
fishery=1
while [ "$fishery" -le 33 ]; do
  tag_tau_group=$(tag_tau_group_for_fishery "$fishery")
  tag_tau_group_controls="${tag_tau_group_controls}
  -${fishery} 43 1 -${fishery} 44 ${tag_tau_group}"
  fishery=$((fishery + 1))
done

echo "TAG tau scenario: $tag_tau_scenario"
echo "TAG tau lower bound: $(printf '%s.%02d' "$((tag_tau_lower_x100 / 100))" "$((tag_tau_lower_x100 % 100))")"
echo "TAG tau starting value: $(printf '%s.%02d' "$((tag_tau_lower_x100 / 100 + 1))" "$((tag_tau_lower_x100 % 100))")"
echo "PHASE 11/12 convergence criterion: $phase11_12_convergence"
if [ "${TAG_TAU_VALIDATE_ONLY:-false}" = "true" ]; then
  fishery=1
  while [ "$fishery" -le 33 ]; do
    printf '%s,%s\n' "$fishery" "$(tag_tau_group_for_fishery "$fishery")"
    fishery=$((fishery + 1))
  done
  exit 0
fi

# -----------------------------------
#  PHASE 0 - create initial par file
# -----------------------------------

$program_path bet.frq bet.ini 00.par -makepar

# -----------------------
#  PHASE 1 - initial par
# -----------------------

$program_path bet.frq 00.par 01.par -file - <<PHASE1
# Use default quasi-Newton minimizer
  1 351 0
  1 192 0
# Allow all growth parameters to be fixed during control phase
  1 32 7
# Richards growth settings
  1 226 0
  1 227 0
# Catch conditioned flags
# General activation
  1 373 1  # activate CC with Baranov equation
  1 393 0  # estimate kludged_equilib_coffs and implicit_fm_level_regression_pars
  2 92 2   # specify catch-conditioned option with Baranov equation
# Catch equation bounds
  2 116 70   # value for Zmax_fish in catch equations
  2 189 80   # fraction of Zmax_fish above which penalty is calculated
  1 382 300  # weight for Zmax_fish penalty - set to 300 to avoid triggering Zmax_flag=1
# Deactivate any catch errors flags
  -999 1 0
  -999 4 0
  -999 10 0
  -999 15 0
  -999 13 0
# Survey fisheries defined
# fish flag 92 = round(region sigma * 100), fish flag 94 = allow unequal sigma,
# fish flag 66 = 1: use normalized time-varying relative-variance multipliers from the frequency data.
# 2026 index-fishery sigma settings.
  -29 94 1 -29 92 35 -29 66 1  # Preliminary CPUE R1 MLE sigma=0.354; fixed executed error scale=0.35 (flag 92=35)
  -30 94 1 -30 92 24 -30 66 1  # Preliminary CPUE R2 MLE sigma=0.237; fixed executed error scale=0.24 (flag 92=24)
  -31 94 1 -31 92 21 -31 66 1  # Preliminary CPUE R3 MLE sigma=0.212; fixed executed error scale=0.21 (flag 92=21)
  -32 94 1 -32 92 24 -32 66 1  # Preliminary CPUE R4 MLE sigma=0.239; fixed executed error scale=0.24 (flag 92=24)
  -33 94 1 -33 92 23 -33 66 1  # Preliminary CPUE R5 MLE sigma=0.225; fixed executed error scale=0.23 (flag 92=23)
# Grouping flags for survey CPUE
   -1 99 1
   -2 99 2
   -3 99 3
   -4 99 4
   -5 99 5
   -6 99 6
   -7 99 7
   -8 99 8
   -9 99 9
  -10 99 10
  -11 99 11
  -12 99 12
  -13 99 13
  -14 99 14
  -15 99 15
  -16 99 16
  -17 99 17
  -18 99 18
  -19 99 19
  -20 99 20
  -21 99 21
  -22 99 22
  -23 99 23
  -24 99 24
  -25 99 25
  -26 99 26
  -27 99 27
  -28 99 28
  -29 99 29  # Index R1; shared initial stationary-catchability/likelihood group
  -30 99 29  # Index R2; shared initial stationary-catchability/likelihood group
  -31 99 29  # Index R3; shared initial stationary-catchability/likelihood group
  -32 99 29  # Index R4; shared initial stationary-catchability/likelihood group
  -33 99 29  # Index R5; shared initial stationary-catchability/likelihood group
# Recruitment and initial population settings
  1 149 100        # recruitment deviation penalty
  1 400 6          # final six recruitment deviates set to zero
# Fixed terminal recruitments are arithmetic mean of remaining period (not default geometric mean)
  1 398 1
  2 177 1          # use old totpop scaling method
  2 32 1           # and estimate totpop parameter
  2 93 4           # set no. of recruitments per year to 4
  2 57 4           # set no. of recruitments per year to 4
  2 94 1 2 128 100  # initial Z = 1.0*M, i.e. initial F = 0
# Likelihood component settings
  1 111 4     # set likelihood function for tags to negative binomial
  1 141 11  # length-frequency likelihood: Dirichlet-multinomial without random effects
  1 139 3     # set likelihood function for WF data to normal
  -999 49 20  # divide LF sample sizes by 20
  -999 50 20  # divide WF sample sizes by 20
# Additional LF/WF sample-size reductions retained from the inherited setup.
# Index fisheries 29-33 are included; extraction labels need the 03 fishery map.
   -1 49 40   -1 50 40
   -2 49 40   -2 50 40
   -4 49 40   -4 50 40
   -6 49 40   -6 50 40
   -7 49 40   -7 50 40
   -8 49 40   -8 50 40
  -10 49 40  -10 50 40
  -29 49 40  -29 50 40
  -30 49 40  -30 50 40
  -31 49 40  -31 50 40
  -32 49 40  -32 50 40
  -33 49 40  -33 50 40
# Tag dynamics settings
  1 33 99    # maximum tag reporting rate for all fisheries is 0.99
  2 96 30    # pool tags after 30 quarters at liberty
# Mixing periods are read from bet.ini tag flags for this step.
  2 198 1    # activate release group reporting rates
  -999 43 0  # estimate tag variance if = 1
  -999 44 0  # group all tags for variance estimation if = 1
# Grouping of fisheries for tag return data, mapped from BET_PHrev_FNL.xlsx.
# New labels with region 4 in the workbook are treated as region 5 here.
   -1 32 1   # LL.WEST.1, old1
   -2 32 2   # LL.EAST.1, old2
   -3 32 3   # LL.US.1, old3
   -4 32 4   # LL.ALL.2, old7
   -5 32 5   # LL.OS.2, old6
   -6 32 6   # LL.ARCH.3, old8
   -7 32 7   # LL.WEST.3, old4
   -8 32 8   # LL.EAST.3, old9
   -9 32 9   # LL.OS.3, old5
  -10 32 10  # LL.ALL.5, old11 + old12 + old29
  -11 32 11  # LL.AU.5, old10 + old27
  -12 32 12  # PS.JP.1, old19
  -13 32 13  # PL.JP.1, old20
  -14 32 14  # HL.ID.2, part of old18
  -15 32 14  # HL.PH.2, part of old18
  -16 32 15  # PL.ALL.2, old28
  -17 32 14  # PS.ID.2, split old24
  -18 32 14  # PS.PH.2, split old24
  -19 32 16  # PS.ASS.2, old30
  -20 32 16  # PS.UNA.2, old31
  -21 32 14  # DOM.ID.2, old23
  -22 32 14  # DOM.PH.2, old17
  -23 32 17  # DOM.VN.2, old32
  -24 32 18  # PL.ALL.WEST.3, old21 + old22
  -25 32 19  # PS.ASS.WEST.3, old13 + old25
  -26 32 20  # PS.ASS.EAST.3, old15
  -27 32 19  # PS.UNA.WEST.3, old14 + old26
  -28 32 20  # PS.UNA.EAST.3, old16
  -29 32 21  # Index R1
  -30 32 21  # Index R2
  -31 32 21  # Index R3
  -32 32 21  # Index R4
  -33 32 21  # Index R5
# Selectivity settings
  -999 3 37  # all selectivities equal for age class 37 and older
  -999 26 2  # evaluate age-based selectivity against scaled mean length-at-age
  -999 57 3  # cubic-spline selectivity
  -999 61 5  # five cubic-spline coefficients by default
# Selectivity groups for the Region 1 sharing sensitivity.
# F2 LL.EAST.1, F3 LL.US.1, and F29 Index R1 share one selectivity.
# The Job 15363 F30/F4 (R2), F31/F7 (R3), and F32/F8 (R4) matches are
# retained, and F33 (R5) remains independent. Group identifiers are renumbered
# to the contiguous range 1:28 after merging the former F3 group into group 2.
# Catchability groups are controlled separately by flag 99.
  -1 24 1  # F1 staged-run-1 selectivity group
  -2 24 2  # F2 staged-run-1 selectivity group
  -3 24 2  # F3 shares the F2/F29 Region 1 selectivity
  -4 24 3  # F4 independent selectivity
  -5 24 4  # F5 independent selectivity
  -6 24 5  # F6 independent selectivity
  -7 24 6  # F7 independent selectivity
  -8 24 7  # F8 independent selectivity
  -9 24 8  # F9 independent selectivity
  -10 24 9  # F10 independent selectivity
  -11 24 10  # F11 independent selectivity
  -12 24 11  # F12 independent selectivity
  -13 24 12  # F13 independent selectivity
  -14 24 13  # F14 independent selectivity
  -15 24 14  # F15 independent selectivity
  -16 24 15  # F16 independent selectivity
  -17 24 16  # F17 independent selectivity
  -18 24 17  # F18 independent selectivity
  -19 24 18  # F19 independent selectivity
  -20 24 19  # F20 independent selectivity
  -21 24 20  # F21 independent selectivity
  -22 24 21  # F22 independent selectivity
  -23 24 22  # F23 independent selectivity
  -24 24 23  # F24 independent selectivity
  -25 24 24  # F25 independent selectivity
  -26 24 25  # F26 independent selectivity
  -27 24 26  # F27 independent selectivity
  -28 24 27  # F28 independent selectivity
  -29 24 2   # Index R1 shares selectivity with F2 LL.EAST.1
  -30 24 3   # Index R2 shares selectivity with F4 LL.ALL.2
  -31 24 6   # Index R3 shares selectivity with F7 LL.WEST.3
  -32 24 7   # Index R4 shares selectivity with F8 LL.EAST.3
  -33 24 28  # Index R5 retains the final independent selectivity group
# Non-decreasing selectivity for the old6-derived longline fishery.
# Selected old-derived longline fisheries set to zero for first two age classes.
  -2 75 2  # F2 youngest age classes fixed at zero selectivity
  -4 75 2  # F4 youngest age classes fixed at zero selectivity
  -5 75 2  # F5 youngest age classes fixed at zero selectivity
  -7 75 2  # F7 youngest age classes fixed at zero selectivity
  -8 75 2  # F8 youngest age classes fixed at zero selectivity
  -9 75 2  # F9 youngest age classes fixed at zero selectivity
  -10 75 2  # F10 youngest age classes fixed at zero selectivity
# Old18 split into HL.ID.2 and HL.PH.2.
  -15 75 5  # F15 youngest age classes fixed at zero selectivity
# Age-based spline constraints mapped from old fishery recipes.
  -19 16 0 -19 3 25  # F19 terminal spline age and start age for the older-age dome penalty
  -25 16 0 -25 3 25  # F25 terminal spline age and start age for the older-age dome penalty
  -26 16 0 -26 3 25  # F26 terminal spline age and start age for the older-age dome penalty
  -27 16 0 -27 3 30  # F27 terminal spline age and start age for the older-age dome penalty
  -17 16 0 -17 3 25  # F17 terminal spline age and start age for the older-age dome penalty
  -18 16 0 -18 3 25  # F18 terminal spline age and start age for the older-age dome penalty
  -12 16 0 -12 3 25  # F12 terminal spline age and start age for the older-age dome penalty
  -13 16 0 -13 3 30  # F13 terminal spline age and start age for the older-age dome penalty
# Upper-age selectivity constraints mapped from old fishery recipes.
  -22 16 0 -22 3 7  # F22 terminal spline age and start age for the older-age dome penalty
  -24 16 0 -24 3 25  # F24 terminal spline age and start age for the older-age dome penalty
  -21 16 0 -21 3 10  # F21 terminal spline age and start age for the older-age dome penalty
  -16 16 0 -16 3 25  # F16 terminal spline age and start age for the older-age dome penalty
  -23 16 0 -23 3 6  # F23 terminal spline age and start age for the older-age dome penalty
# Turn on weighted spline for calculating maturity at age
  2 188 2
# Set Lorenzen M
  2 109 3  # select Lorenzen curve
  1 121 0    # estimate no natural-mortality age_pars(5) coefficients; fix Lorenzen intercept and length slope at incoming .par values
# Filter out comps with input samples less than 50
  1 311 1  # enable tail-compressed observed and predicted length-frequency arrays
  1 301 1   # set tail compression for WF data
  1 313 0   # proportions in compressed tails for LF data
  1 303 0   # proportions in compressed tails for WF data
  1 312 50  # set minimum obs sample size for LF data
  1 302 50  # set minimum obs sample size for WF data
# MFCL 2.2.2.0 growth variance fix
  1 34 0    # set to 1 34 1 for backwards compatibility
  -15 16 0  # F15 older-age dome penalty from the flag-3 age onward
  -15 3 25  # F15 terminal spline age and start age for the older-age dome penalty
  -25 61 7  # F25 seven estimated cubic-spline nodes
  -25 75 0  # F25 no youngest age classes forced to near-zero selectivity
  -26 61 7  # F26 seven estimated cubic-spline nodes
  -26 75 0  # F26 no youngest age classes forced to near-zero selectivity
  -1 61 4   # F1 four cubic-spline nodes retained from Job 15363
  -2 61 4   # F2/F3/F29 shared Region 1 selectivity uses four nodes
  -3 61 4   # F2/F3/F29 shared Region 1 selectivity uses four nodes
  -5 61 4   # F5 four cubic-spline nodes retained from Job 15363
  -29 61 4  # F2/F3/F29 shared Region 1 selectivity uses four nodes
  -33 61 4  # Index R5 four cubic-spline nodes; selectivity remains independent
  -1 75 2  # F1 youngest age classes fixed at zero selectivity
  -3 75 2  # F3 youngest age classes fixed at zero selectivity
  -6 75 2  # F6 youngest age classes fixed at zero selectivity
  -11 75 2  # F11 youngest age classes fixed at zero selectivity
  -12 75 2  # F12 youngest age classes fixed at zero selectivity
  -13 75 1  # F13 youngest age classes fixed at zero selectivity
  -29 75 2  # Index R1 youngest age classes fixed at zero selectivity
  -30 75 2  # Index R2 youngest age classes fixed at zero selectivity
  -31 75 2  # Index R3 youngest age classes fixed at zero selectivity
  -32 75 2  # Index R4 youngest age classes fixed at zero selectivity
  -33 75 2  # Index R5 youngest age classes fixed at zero selectivity
  1 320 5  # use tail-compressed DM when the first-to-last-positive observed span contains at least five bins
  1 342 25  # DM effective-sample-size upper asymptote Nmax=25
  -1 68 1  # G8PSSET DM group for F1
  -2 68 1  # G8PSSET DM group for F2
  -3 68 1  # G8PSSET DM group for F3
  -4 68 1  # G8PSSET DM group for F4
  -5 68 2  # G8PSSET DM group for F5
  -6 68 1  # G8PSSET DM group for F6
  -7 68 1  # G8PSSET DM group for F7
  -8 68 1  # G8PSSET DM group for F8
  -9 68 2  # G8PSSET DM group for F9
  -10 68 1  # G8PSSET DM group for F10
  -11 68 1  # G8PSSET DM group for F11
  -12 68 3  # G8PSSET DM group for F12
  -13 68 7  # G8PSSET DM group for F13
  -14 68 6  # G8PSSET DM group for F14
  -15 68 6  # G8PSSET DM group for F15
  -16 68 7  # G8PSSET DM group for F16
  -17 68 3  # G8PSSET DM group for F17
  -18 68 3  # G8PSSET DM group for F18
  -19 68 4  # G8PSSET DM group for F19
  -20 68 5  # G8PSSET DM group for F20
  -21 68 7  # G8PSSET DM group for F21
  -22 68 7  # G8PSSET DM group for F22
  -23 68 7  # G8PSSET DM group for F23
  -24 68 7  # G8PSSET DM group for F24
  -25 68 4  # G8PSSET DM group for F25
  -26 68 4  # G8PSSET DM group for F26
  -27 68 5  # G8PSSET DM group for F27
  -28 68 5  # G8PSSET DM group for F28
  -29 68 8  # G8PSSET DM group for F29
  -30 68 8  # G8PSSET DM group for F30
  -31 68 8  # G8PSSET DM group for F31
  -32 68 8  # G8PSSET DM group for F32
  -33 68 8  # G8PSSET DM group for F33
  -999 69 1  # estimate group-specific DM scalar exponent
  -999 89 0  # stage relative sample-size exponent fixed at zero
PHASE1

# ---------
#  PHASE 2
# ---------

$program_path bet.frq 01.par 02.par -file - <<PHASE2
  1 1 100  # set max. number of function evaluations per phase to 100
  1 50 0   # set convergence criterion to 1
  2 113 0  # scaling init pop - turned off
  1 190 1  # write plot-xxx.par.rep
  -999 89 1  # estimate group-specific DM relative sample-size exponent (CEST)
PHASE2

# ---------
#  PHASE 3
# ---------

$program_path bet.frq 02.par 03.par -file - <<PHASE3
  2 70 1   # activate time series of reg recruitment parameters
  2 71 1   # estimate temporal changes in recruitment distribution
  2 178 1  # constrain regional recruitments
  1 1 200
PHASE3

# ---------
#  PHASE 4
# ---------

$program_path bet.frq 03.par 04.par -file - <<PHASE4
  2 68 1   # estimate movement coefficients
  2 69 1
  2 27 -1  # penalty wt 0.1 computed against prior
PHASE4

# ---------
#  PHASE 5
# ---------

$program_path bet.frq 04.par 05.par -file - <<PHASE5
  -100000 1 1  # estimate
  -100000 2 1  # time-invariant
  -100000 3 1  # distribution
  -100000 4 1  # of
  -100000 5 1  # recruitment
# STAGED MFCL RUN 5: introduce REGW regional scaling and separate regional CPUE groups.
# These controls persist in subsequent runs through the carried parameter file.
  1 77 100  # REGW regional-scaling penalty weight
  1 78 1  # use mean regional-scaling target
  1 79 240  # start bound: 240 periods back from model end, mapping to source period 53
  1 80 220  # end bound: 220 periods back from model end, mapping to source period 72
  1 81 1  # enable the multivariate-normal regional-scaling penalty
  -29 99 29  # Index R1; separate stationary-catchability/likelihood group from staged run 5
  -30 99 30  # Index R2; separate stationary-catchability/likelihood group from staged run 5
  -31 99 31  # Index R3; separate stationary-catchability/likelihood group from staged run 5
  -32 99 32  # Index R4; separate stationary-catchability/likelihood group from staged run 5
  -33 99 33  # Index R5; separate stationary-catchability/likelihood group from staged run 5
  -29 94 0  # Index R1; separate flag-99 group now supplies its own flag-92 error scale
  -30 94 0  # Index R2; separate flag-99 group now supplies its own flag-92 error scale
  -31 94 0  # Index R3; separate flag-99 group now supplies its own flag-92 error scale
  -32 94 0  # Index R4; separate flag-99 group now supplies its own flag-92 error scale
  -33 94 0  # Index R5; separate flag-99 group now supplies its own flag-92 error scale
# STAGED MFCL RUN 5: explicitly retain the complete contiguous selectivity map
# after assigning each regional index an independent flag-99
# catchability/likelihood group above.
  -1 24 1
  -2 24 2
  -3 24 2
  -4 24 3
  -5 24 4
  -6 24 5
  -7 24 6
  -8 24 7
  -9 24 8
  -10 24 9
  -11 24 10
  -12 24 11
  -13 24 12
  -14 24 13
  -15 24 14
  -16 24 15
  -17 24 16
  -18 24 17
  -19 24 18
  -20 24 19
  -21 24 20
  -22 24 21
  -23 24 22
  -24 24 23
  -25 24 24
  -26 24 25
  -27 24 26
  -28 24 27
  -29 24 2   # Index R1 retains the shared F2/F3 selectivity
  -30 24 3   # Index R2 retains the F4 selectivity
  -31 24 6   # Index R3 retains the F7 selectivity
  -32 24 7   # Index R4 retains the F8 selectivity
  -33 24 28  # Index R5 retains an independent selectivity
PHASE5

# ---------
#  PHASE 6
# ---------

$program_path bet.frq 05.par 06.par -file - <<PHASE6
  1 240 1  # fit to age-length data
  1 14 1   # estimate von Bertalanffy K
  1 12 1   # estimate mean length of age 1
  1 13 1   # estimate length of age n
  1 1 300  # function evaluations
PHASE6

# ---------
#  PHASE 7
# ---------

$program_path bet.frq 06.par 07.par -file - <<PHASE7
  1 15 1   # estimate overall SD of length-at-age
  1 16 1   # estimate length dependent SD
  1 173 0  # activate independent mean lengths for first 0 age classes
  1 182 0  # penalty weight
  1 184 0  # estimate parameters
  1 1 500  # function evaluations
PHASE7

# ---------
#  PHASE 8
# ---------

$program_path bet.frq 07.par 08.par -file - <<PHASE8
  2 145 1    # use SRR parameters - low penalty for deviation
  2 146 1    # estimate SRR parameters
  2 182 1    # make SRR annual rather than quarterly
  2 161 1    # lognormal bias correction
  2 163 0    # use steepness parameterization of B&H SRR
  1 149 0    # penalty for recruitment devs
  2 147 1    # time period between spawning and recruitment
  2 148 20   # period for MSY calc - last 20 quarters
  2 155 4    # but not including last year
  2 199 212  # start period for SRR estimation/yield is start 1965?
  2 200 6    # end period for SRR estimation is mid 2017
  -999 55 1  # do impact analysis
  2 171 1    # include SRR-based equilibrium recruitment to compute unfished biomass
  1 186 1    # write fishmort and plotq0.rep
  1 187 1    # write temporary_tag_report
  1 188 1    # write ests.rep
  1 189 1    # write .fit files
  1 1 500    # function evaluations
  1 50 -2    # convergence criteria
  2 116 100  # increase F bound for NR to 1.0
PHASE8

# ---------
#  PHASE 9
# ---------

$program_path bet.frq 08.par 09.par -file - <<PHASE9
  2 145 -1   # use SRR parameters - low penalty for deviation
  1 1 500    # function evaluations
  1 50 -2    # convergence criteria
  2 116 300  # increase F bound for NR to 3.0
PHASE9

# Set fishery-parameter row 4 only in the Phase 10 input par. This leaves
# Phases 0-9 identical to Job 15984 and starts direct tau one unit above its
# selected lower bound (tau = 3, 4, or 5).
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

# ---------------------------------------------------
#  PHASE 10 - estimate tag-recapture overdispersion
# ---------------------------------------------------

$program_path bet.frq 09.tau.par 10.par -file - <<PHASE10
  1 111 4    # negative-binomial tag-recapture likelihood
  1 177 0    # no fixed tag-likelihood multiplier (250/500 sensitivities are not used)
  1 239 0    # use the serial tag-return implementation, which supports direct tau
  1 249 0    # use the standard tag-return likelihood
  1 101 0    # retain the standard tag-return calculation
  1 305 1    # parameterize fish_pars(4) directly as tau = 1 + exp(theta)
  1 306 $tag_tau_lower_x100  # lower tau bound in hundredths; upper tau bound is 50 times the lower bound
  1 358 0    # do not override the default upper bound
  2 100 0    # retain the standard tag-return calculation
  2 121 0    # do not use tag survival-analysis likelihood
  2 122 0    # keep tag-recapture data active
$tag_tau_group_controls
  1 1 3000   # function evaluations for the newly opened tau parameter(s)
  1 50 -3    # stabilize tau before the strict joint optimization
  1 121 0    # keep Lorenzen natural mortality fixed
PHASE10

# ----------
#  PHASE 11
# ----------

$program_path bet.frq 10.par 11.par -file - <<PHASE11
  1 1 10000  # function evaluations
  1 50 $phase11_12_convergence  # convergence criterion; default -4 (MGC target 1e-4)
  1 121 0    # estimate no natural-mortality age_pars(5) coefficients; fix Lorenzen intercept and length slope at incoming .par values
PHASE11

# ----------
#  PHASE 12
# ----------

$program_path bet.frq 11.par 12.par -file - <<PHASE12
  1 1 5000
  1 50 $phase11_12_convergence  # convergence criterion; default -4 (MGC target 1e-4)
  1 121 0    # keep Lorenzen natural mortality fixed
  1 246 1   # indepvar.rpt
PHASE12
