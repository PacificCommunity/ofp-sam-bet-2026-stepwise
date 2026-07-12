# 12e Late-transfer OPR 72-E2, spatial endpoint ties released

After rebuilding Step 11 from the initial inputs, its `doitall.sh` uses
`72-01-50-50` with annual `E2` and `pf397=100`, but releases the terminal
endpoint tie for region, season, and region-season components
(`pf210=pf212=pf214=-1`).

It tests whether the spatial endpoint constraints, rather than the annual
terminal treatment itself, cause a change in absolute population scale.
