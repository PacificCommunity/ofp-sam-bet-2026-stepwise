# F33 strong non-decreasing spline sensitivity

This model is identical to fitted Job 19326 except that F33 `Index R5`
receives a strong one-sided non-decreasing penalty after the regional-index
selectivity groups are separated in Phase 5.

- F10 remains asymptotic logistic, exactly as in Job 19326;
- F1-F3 retain their independently estimated five-node cubic splines;
- F33 retains its independently estimated five-node cubic spline;
- F33 fishery flag 16 is set to 1; and
- F33 fishery flag 56 is set to 100,000,000.

The Job 19326 F33 curve is already non-decreasing, so this penalty is zero at
the fitted base curve. The weight is approximately three times the minimum
required for the archived seed-2 F33 decline penalty to exceed that fit's
roughly 922-objective-unit advantage over Job 19326. Seed 2 and seed 20 are
therefore explicit post-fit stress tests rather than assumed successes.

All data, K=0.20 mixing, original non-estimated tau treatment,
negative-binomial tags, reporting rates, fixed M, DM controls, and other
selectivity settings are unchanged.
