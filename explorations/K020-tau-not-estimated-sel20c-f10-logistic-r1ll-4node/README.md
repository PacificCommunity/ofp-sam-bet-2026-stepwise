# F10 logistic with four-node Region-1 longline splines

This model is identical to Job 18718
`K020-tau-not-estimated-sel20c` except for two declared selectivity changes:

- fishery flag 57 = 1 for F10;
- the two logistic parameters in `fish_pars(9:10)` remain estimated; and
- fishery flag 61 = 4 for F1 `LL.WEST.1`, F2 `LL.EAST.1`, and F3 `LL.US.1`.

The Region-1 fisheries retain independently estimated cubic splines. Reducing
them from five to four coefficients tests whether their principal selectivity
patterns can be retained without the weakly identified terminal degree of
freedom. F10 needs no non-decreasing spline penalty because its logistic form
is inherently asymptotic and non-decreasing.

All data, K=0.20 mixing, original non-estimated tau treatment,
negative-binomial tags, reporting rates, fixed M, DM controls, and other
selectivity settings are unchanged.
