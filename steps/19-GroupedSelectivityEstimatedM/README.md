# 19 Grouped selectivity with estimated Lorenzen M

This sensitivity reruns the complete native-MFCL `doitall.sh` sequence using
the grouped-selectivity configuration in Step 18 and estimates the Lorenzen
natural-mortality intercept from Phase 10.

## Natural-mortality configuration

| Setting | Implementation |
| --- | --- |
| Starting value | `age_pars(5,1) = -2.5` in `bet.ini` |
| Length slope | Retained at `age_pars(5,2) = -1` |
| Phases 0-9 | Intercept fixed (`flag 121 = 0`) |
| Phases 10-11 | Intercept estimated (`flag 121 = 1`) |

## Selectivity configuration

F29-F32 share selectivity with F2, F4, F7 and F8 respectively; F33 remains
independent. F1, F3, F5 and F33 use four spline nodes, F15 retains five, and
F25/F26 retain seven. Regional-index flag-99 catchability groups remain
independent.

## Held constant

All other Step 18 and Job 14363 controls and inputs are unchanged, including
the all-relaxed fishery-specific selectivity-form controls, G8
Dirichlet-multinomial weighting with Nmax 25, CPUE error settings, tag controls,
recruitment settings, and data files.

## Execution

The Kflow sensitivity executes `model/doitall.sh` from Phase 0 through Phase 11
with `/home/mfcl/mfclo64`. It does not use `mfclrtmb` and does not continue from
an earlier final parameter file.
