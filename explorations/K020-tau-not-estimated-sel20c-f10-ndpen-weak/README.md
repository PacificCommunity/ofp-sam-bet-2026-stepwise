# K=0.20 — tau not estimated — F10 weak non-decreasing penalty

This self-contained robustness candidate is identical to
`K020-tau-not-estimated-sel20c` (Job 18718) except for one F10
`LL.ALL.5` selectivity control:

```text
-10 16 1
-10 56 10000
```

F10 remains an independently estimated five-node cubic spline. Fishery flag
16 activates the MFCL non-decreasing selectivity penalty, and fishery flag 56
sets its weight to 10,000, which is 1% of the MFCL source-code default of
1,000,000.

The weak candidate is intended to leave the near-asymptotic Job 18718 base
curve effectively unchanged while discouraging the much stronger F10
old-age decline found in the low-depletion jitter solution. All data, tag
mixing, negative-binomial tag likelihood, tau treatment, reporting rates,
fixed natural mortality, DM controls and other selectivity settings are
unchanged.
