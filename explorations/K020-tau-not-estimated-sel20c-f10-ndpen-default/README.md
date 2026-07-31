# K=0.20 — tau not estimated — F10 default non-decreasing penalty

This self-contained robustness candidate is identical to
`K020-tau-not-estimated-sel20c` (Job 18718) except for one F10
`LL.ALL.5` selectivity control:

```text
-10 16 1
-10 56 1000000
```

F10 remains an independently estimated five-node cubic spline. Fishery flag
16 activates the MFCL non-decreasing selectivity penalty, and fishery flag 56
explicitly sets the MFCL source-code default weight of 1,000,000.

This candidate tests the standard strong constraint against the weak-penalty
candidate. All data, tag mixing, negative-binomial tag likelihood, tau
treatment, reporting rates, fixed natural mortality, DM controls and other
selectivity settings are unchanged.
