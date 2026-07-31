# F1-F3 four-node plus F33 strong non-decreasing sensitivity

This model combines the existing Job 19600 Region-1 longline treatment with
a strong one-sided F33 spline penalty:

- F10 remains asymptotic logistic;
- F1-F3 remain separate selectivity groups and use four independently
  estimated cubic-spline nodes; and
- F33 retains its five-node cubic spline, with fishery flags 16=1 and
  56=100,000,000 applied after the regional indices separate in Phase 5.

The Job 19326 F33 curve is already non-decreasing, so the added penalty is
zero at that curve. The strong weight is used instead of MFCL's 1,000,000
default because the default adds only about 28.5 objective units to the
archived seed-2 F33 decline, versus that fit's roughly 922-unit objective
advantage over Job 19326.

All data, K=0.20 mixing, original non-estimated tau treatment,
negative-binomial tags, reporting rates, fixed M, DM controls, and other
selectivity settings are unchanged.
