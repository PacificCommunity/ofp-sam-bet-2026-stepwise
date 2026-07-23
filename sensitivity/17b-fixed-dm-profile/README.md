# 17b profile with fixed DM composition weights

## Purpose

This sensitivity profiles average total biomass while holding the fitted
Dirichlet-multinomial (DM) length-composition weights fixed.

The profile starts from the completed final parameter file for step
`17b-DMG8Nmax25` (Kflow Job 14067). The base model is not refitted.

## Fixed and retained settings

- The fitted `fish_pars(22)` and `fish_pars(23)` values are retained for all
  33 fisheries.
- Fishery estimation flags 69 and 89 are set to zero before profiling.
- Fishery grouping flag 68 is retained.
- Length-composition likelihood flag 141 remains 11.
- The DM `Nmax` setting in flag 342 remains 25.
- All other model inputs and fitted parameter values come from the Job 14067
  final parameter file.

This preserves the fitted DM likelihood and its effective composition weights
while preventing those weight parameters from being re-estimated at each
profile point. It is not a conversion to a fixed-divisor multinomial
likelihood.

## Profile design

- Quantity: average total biomass
- Range: 60% to 140% of the fitted value
- Increment: 2.5 percentage points
- Execution: independent downstream and upstream continuation chains
- Convergence threshold: MGC <= 0.001

The two chains are merged after completion. The generated audit files record
the retained DM settings and confirm that only flags 69 and 89 were changed.
