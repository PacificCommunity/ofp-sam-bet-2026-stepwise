# 12b Late-transfer OPR 72-E2, terminal penalty

Its `doitall.sh` first rebuilds the standard Step-11 solution from the initial
inputs, then activates OPR
`72-01-50-50`, applies `E2`, then applies `pf397=100` only in the final
refinement.

This is the principal practical candidate: it retains the two-calendar-year
terminal protection while testing whether an OPR conversion after Step 11
avoids the scale change seen when OPR is introduced early in a fit sequence.
