# F33 asymptotic logistic sensitivity

This model is identical to fitted Job 19326 except that F33 `Index R5`
switches from its five-node cubic spline to the MFCL two-parameter
asymptotic logistic selectivity form after the regional-index selectivity
groups are separated in Phase 5.

- F10 remains asymptotic logistic, exactly as in Job 19326;
- F1-F3 retain their independently estimated five-node cubic splines;
- F33 fishery flag 57 changes from 3 to 1 in Phase 5; and
- F33 `fish_pars(9:10)` remain estimated.

All data, K=0.20 mixing, original non-estimated tau treatment,
negative-binomial tags, reporting rates, fixed M, DM controls, and other
selectivity settings are unchanged.
