# 12c Late-transfer OPR 73-E1, no terminal penalty

After rebuilding Step 11 from the initial inputs, its `doitall.sh` uses fully
flexible annual OPR (`73-01-50-50`) with `E1` and no terminal
penalty. `73-E1` is the valid fully saturated annual comparison; `73-E2` is
not valid for the 73-year model period.

It measures the contribution of the two-year endpoint basis constraint without
also changing terminal recruitment through `pf397`.
