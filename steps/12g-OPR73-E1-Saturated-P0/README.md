# 12g Late-transfer saturated OPR benchmark

After rebuilding Step 11 from the initial inputs, its `doitall.sh` uses
`73-73-73-73`, `E1`, and no terminal penalty. This is a representation
benchmark, not a preferred final model: it asks whether an almost unrestricted
OPR surface can retain the standard solution when it is initialized from that
solution.

If this model still shifts scale substantially, the difference is more likely
to arise during joint likelihood optimisation than from low OPR rank alone.
