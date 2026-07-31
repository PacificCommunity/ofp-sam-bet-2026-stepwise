# F1-F3 four-node plus F33 logistic sensitivity

This model combines the existing Job 19600 Region-1 longline treatment with
an F33 functional-form sensitivity:

- F10 remains asymptotic logistic;
- F1-F3 remain separate selectivity groups and use four independently
  estimated cubic-spline nodes; and
- F33 switches from its five-node cubic spline to the MFCL two-parameter
  asymptotic logistic after the regional indices separate in Phase 5.

F33 fishery flag 16 remains zero because the MFCL manual specifies that the
non-decreasing spline penalty should not be combined with functional forms.

All data, K=0.20 mixing, original non-estimated tau treatment,
negative-binomial tags, reporting rates, fixed M, DM controls, and other
selectivity settings are unchanged.
