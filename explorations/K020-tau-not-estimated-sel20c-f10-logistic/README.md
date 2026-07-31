# F10 asymptotic logistic candidate

This model is identical to Job 18718
`K020-tau-not-estimated-sel20c` except that F10 `LL.ALL.5` uses the
MFCL asymptotic logistic selectivity form:

- fishery flag 57 = 1 for F10;
- the two logistic parameters in `fish_pars(9:10)` remain estimated; and
- no non-decreasing spline penalty is needed because the form is inherently
  asymptotic and non-decreasing.

All data, K=0.20 mixing, original non-estimated tau treatment,
negative-binomial tags, reporting rates, fixed M, DM controls, and other
selectivity settings are unchanged.
