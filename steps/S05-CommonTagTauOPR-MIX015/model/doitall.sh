#!/bin/sh
set -eu

program_path=${PROGRAM_PATH:-}

if [ -z "$program_path" ]; then
  echo "PROGRAM_PATH is not set. Exiting."
  exit 1
fi

phase10_11_convergence=${BET_PHASE10_11_CONVERGENCE:--4}
case "$phase10_11_convergence" in
  -[0-9]|-[0-9][0-9]|[0-9]|[0-9][0-9]) ;;
  *)
    echo "BET_PHASE10_11_CONVERGENCE must be numeric, e.g. -3 for quick runs or -5 for strict runs." >&2
    exit 1
    ;;
esac
echo "PHASE 10/11 convergence criterion: $phase10_11_convergence"

regional_recruitment_penalty=${REGIONAL_RECRUITMENT_PENALTY:-0.1}
case "$regional_recruitment_penalty" in
  0.1)
    regional_recruitment_penalty_flag=0
    ;;
  0.2)
    # MFCL stores ten times this coefficient in age flag 110.
    regional_recruitment_penalty_flag=2
    ;;
  *)
    echo "REGIONAL_RECRUITMENT_PENALTY must be 0.1 or 0.2." >&2
    exit 39
    ;;
esac
echo "Regional recruitment-distribution penalty: $regional_recruitment_penalty (age flag 110=$regional_recruitment_penalty_flag)"

dm_nmax=${DM_NMAX:-25}
case "$dm_nmax" in
  25)
    dm_nmax_flag=25
    dm_nmax_effective=25
    ;;
  default|1000)
    # A zero flag invokes the MFCL no-random-effects DM default Nmax=1000.
    dm_nmax_flag=0
    dm_nmax_effective=1000
    ;;
  *)
    echo "DM_NMAX must be 25, default, or 1000." >&2
    exit 38
    ;;
esac
echo "DM effective-sample-size upper bound: $dm_nmax_effective (parest flag 342=$dm_nmax_flag)"


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
  -29 94 1 -29 92 35 -29 66 1  # Residual-based CPUE R1 maximum-likelihood observation-error estimate=0.354; fixed executed error scale=0.35 (flag 92=35)
  -30 94 1 -30 92 24 -30 66 1  # Residual-based CPUE R2 maximum-likelihood observation-error estimate=0.237; fixed executed error scale=0.24 (flag 92=24)
  -31 94 1 -31 92 21 -31 66 1  # Residual-based CPUE R3 maximum-likelihood observation-error estimate=0.212; fixed executed error scale=0.21 (flag 92=21)
  -32 94 1 -32 92 24 -32 66 1  # Residual-based CPUE R4 maximum-likelihood observation-error estimate=0.239; fixed executed error scale=0.24 (flag 92=24)
  -33 94 1 -33 92 23 -33 66 1  # Residual-based CPUE R5 maximum-likelihood observation-error estimate=0.225; fixed executed error scale=0.23 (flag 92=23)
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
  2 110 $regional_recruitment_penalty_flag  # regional recruitment-distribution penalty coefficient
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
# Index fisheries 29-33 are included; extraction labels use the five-region fishery map.
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
# Grouping of fisheries with common selectivity, mapped from BET_PHrev_FNL.xlsx.
# Staged run 1 uses 29 contiguous groups: F1-F28 use groups 1-28; F29-F33 initially share group 29.
  -1 24 1  # F1 selectivity-stability group
  -2 24 2  # F2 selectivity-stability group (shared Region 1 longline extraction curve (F2/F3))
  -3 24 2  # F3 selectivity-stability group (shared Region 1 longline extraction curve (F2/F3))
  -4 24 3  # F4 selectivity-stability group
  -5 24 4  # F5 selectivity-stability group
  -6 24 5  # F6 selectivity-stability group
  -7 24 6  # F7 selectivity-stability group (shared Region 3-West longline extraction curve (F7/F9))
  -8 24 7  # F8 selectivity-stability group
  -9 24 6  # F9 selectivity-stability group (shared Region 3-West longline extraction curve (F7/F9))
  -10 24 8  # F10 selectivity-stability group
  -11 24 9  # F11 selectivity-stability group
  -12 24 10  # F12 selectivity-stability group
  -13 24 11  # F13 selectivity-stability group
  -14 24 12  # F14 selectivity-stability group
  -15 24 13  # F15 selectivity-stability group
  -16 24 14  # F16 selectivity-stability group
  -17 24 15  # F17 selectivity-stability group
  -18 24 16  # F18 selectivity-stability group
  -19 24 17  # F19 selectivity-stability group
  -20 24 18  # F20 selectivity-stability group
  -21 24 19  # F21 selectivity-stability group
  -22 24 20  # F22 selectivity-stability group
  -23 24 21  # F23 selectivity-stability group
  -24 24 22  # F24 selectivity-stability group
  -25 24 23  # F25 selectivity-stability group
  -26 24 24  # F26 selectivity-stability group
  -27 24 25  # F27 selectivity-stability group
  -28 24 26  # F28 selectivity-stability group
  -29 24 27  # F29 selectivity-stability group
  -30 24 28  # F30 selectivity-stability group
  -31 24 29  # F31 selectivity-stability group
  -32 24 30  # F32 selectivity-stability group
  -33 24 31  # F33 selectivity-stability group
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
  -19 16 0 -19 3 25  # F19 selected revised fishery-specific specification: selectivity-form penalty off
  -25 16 0 -25 3 25  # F25 selected revised fishery-specific specification: selectivity-form penalty off
  -26 16 0 -26 3 25  # F26 selected revised fishery-specific specification: selectivity-form penalty off
  -27 16 0 -27 3 30  # F27 selected revised fishery-specific specification: selectivity-form penalty off
  -17 16 0 -17 3 25  # F17 selected revised fishery-specific specification: selectivity-form penalty off
  -18 16 0 -18 3 25  # F18 selected revised fishery-specific specification: selectivity-form penalty off
  -12 16 0 -12 3 25  # F12 selected revised fishery-specific specification: selectivity-form penalty off
  -13 16 0 -13 3 30  # F13 selected revised fishery-specific specification: selectivity-form penalty off
# Upper-age selectivity constraints mapped from old fishery recipes.
  -22 16 0 -22 3 7  # F22 selected revised fishery-specific specification: selectivity-form penalty off
  -24 16 0 -24 3 25  # F24 selected revised fishery-specific specification: selectivity-form penalty off
  -21 16 0 -21 3 10  # F21 selected revised fishery-specific specification: selectivity-form penalty off
  -16 16 0 -16 3 25  # F16 selected revised fishery-specific specification: selectivity-form penalty off
  -23 16 0 -23 3 6  # F23 selected revised fishery-specific specification: selectivity-form penalty off
# Turn on weighted spline for calculating maturity at age
  2 188 2
# Set Lorenzen M
  2 109 3  # select Lorenzen curve
  1 121 0    # estimate no natural-mortality age_pars(5) coefficients; fix Lorenzen intercept and length slope at incoming .par values
# Filter out comps with input samples less than 50
  1 311 1  # enable tail-compressed observed and predicted length-frequency arrays
  1 301 1   # set tail compression for WF data
  1 313 0  # not read by the DM likelihood; reset to avoid percentage-tail preprocessing, while flag 320 controls DM support
  1 303 0   # proportions in compressed tails for WF data
  1 312 50  # set minimum obs sample size for LF data
  1 302 50  # set minimum obs sample size for WF data
# MFCL 2.2.2.0 growth variance fix
  1 34 0    # set to 1 34 1 for backwards compatibility
  -15 16 0  # F15 selected revised fishery-specific specification: selectivity-form penalty off
  -15 3 25  # F15 terminal spline age and start age for the older-age dome penalty
  -25 61 7  # F25 seven estimated cubic-spline nodes
  -25 75 0  # F25 no youngest age classes forced to near-zero selectivity
  -26 61 7  # F26 seven estimated cubic-spline nodes
  -26 75 0  # F26 no youngest age classes forced to near-zero selectivity
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
  -1 61 4  # F1 retained Job 15989 four-node selectivity
  -2 61 4  # F2 retained Job 15989 four-node selectivity
  -3 61 4  # F3 retained Job 15989 four-node selectivity
  -5 61 4  # F5 retained Job 15989 four-node selectivity
  -29 61 4  # F29 retained Job 15989 four-node selectivity
  -33 57 1  # F33 independent asymptotic logistic selectivity
  1 320 5  # use tail-compressed DM when the first-to-last-positive observed span contains at least five bins
  1 342 $dm_nmax_flag  # selected DM effective-sample-size upper bound
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
# BET 2026 OPR settings: 72-01-50-50 with a two-real-year end window.
  1 149 0   # turn off recruitment-deviation penalty for OPR
  1 398 0   # turn off arithmetic-mean terminal fixed-recruitment option for OPR
  1 400 0   # clear fixed terminal recruitment-deviate block for OPR
  2 177 0   # turn off old total-pop scaling for OPR
  2 32 0    # turn off overall population scaling parameter for OPR
  2 113 0   # keep scaling init pop off during OPR transfer
  1 155 72  # orthogonal polynomial recruitment - year effect
  1 217 1   # orthogonal polynomial recruitment - season effect
  1 216 50  # orthogonal polynomial recruitment - region effect
  1 218 50  # orthogonal polynomial recruitment - region-season interaction effect
  1 202 2   # OPR end window: last 2 real years use lower-degree/constant-end basis
  1 210 0   # OPR region end window: 0 inherits parest_flag(202)
  1 212 0   # OPR season end window: 0 inherits parest_flag(202)
  1 214 0   # OPR region-season end window: 0 inherits parest_flag(202)
  2 30 1    # keep age_flag(30) on so current MFCL activates OPR coefficients
  2 70 0    # turn off mean+deviate regional recruitment time series
  2 71 0    # turn off regional recruitment distribution deviations
  2 178 0   # turn off regional recruitment sum-product constraint
  -100000 1 0  # turn off time-invariant recruitment distribution, region 1
  -100000 2 0  # turn off time-invariant recruitment distribution, region 2
  -100000 3 0  # turn off time-invariant recruitment distribution, region 3
  -100000 4 0  # turn off time-invariant recruitment distribution, region 4
  -100000 5 0  # turn off time-invariant recruitment distribution, region 5
  1 1 500  # function evaluations for the BET 2026 OPR transfer
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
  -100000 1 0 # estimate
  -100000 2 0 # time-invariant
  -100000 3 0 # distribution
  -100000 4 0 # of
  -100000 5 0 # recruitment
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
# STAGED MFCL RUN 5: separate the five regional-index selectivity-sharing groups.
  -29 24 27  # F29 selectivity-stability group
  -30 24 28  # F30 selectivity-stability group
  -31 24 29  # F31 selectivity-stability group
  -32 24 30  # F32 selectivity-stability group
  -33 24 31  # F33 selectivity-stability group
  -1 24 1  # F1 selectivity-stability group
  -2 24 2  # F2 selectivity-stability group (shared Region 1 longline extraction curve (F2/F3))
  -3 24 2  # F3 selectivity-stability group (shared Region 1 longline extraction curve (F2/F3))
  -4 24 3  # F4 selectivity-stability group
  -5 24 4  # F5 selectivity-stability group
  -6 24 5  # F6 selectivity-stability group
  -7 24 6  # F7 selectivity-stability group (shared Region 3-West longline extraction curve (F7/F9))
  -8 24 7  # F8 selectivity-stability group
  -9 24 6  # F9 selectivity-stability group (shared Region 3-West longline extraction curve (F7/F9))
  -10 24 8  # F10 selectivity-stability group
  -11 24 9  # F11 selectivity-stability group
  -12 24 10  # F12 selectivity-stability group
  -13 24 11  # F13 selectivity-stability group
  -14 24 12  # F14 selectivity-stability group
  -15 24 13  # F15 selectivity-stability group
  -16 24 14  # F16 selectivity-stability group
  -17 24 15  # F17 selectivity-stability group
  -18 24 16  # F18 selectivity-stability group
  -19 24 17  # F19 selectivity-stability group
  -20 24 18  # F20 selectivity-stability group
  -21 24 19  # F21 selectivity-stability group
  -22 24 20  # F22 selectivity-stability group
  -23 24 21  # F23 selectivity-stability group
  -24 24 22  # F24 selectivity-stability group
  -25 24 23  # F25 selectivity-stability group
  -26 24 24  # F26 selectivity-stability group
  -27 24 25  # F27 selectivity-stability group
  -28 24 26  # F28 selectivity-stability group
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

# ----------
#  PHASE 10
# ----------

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
