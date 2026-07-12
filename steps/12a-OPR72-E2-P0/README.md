# 12a Late-transfer OPR 72-E2, no terminal penalty

Its `doitall.sh` first rebuilds the standard Step-11 solution from the initial
inputs, then activates OPR
`72-01-50-50`, and uses a two-calendar-year endpoint constraint (`E2`).
`pf397=0` keeps the terminal-recruitment penalty off.

This is the direct test of whether the current practical OPR representation
changes scale before a terminal penalty is applied. `transfer.par` records the
native standard-to-OPR conversion checkpoint; `final.par` is the refit.
