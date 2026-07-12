# OPR Screening Summary

Source: the BET OPR screening slides and OPR `doitall` example prepared for
the BET/YFT 2026 assessment work.

The screening applied OPR settings to final converged fits and compared models
with AIC. The BET screening used the 4R model, not this final 5-region stepwise
path. The table is historical context; the current reviewed PDH lineage uses a
72-degree year effect.

## BET Result Used

| model | -LN(L) | npar | AIC | rank |
| --- | ---: | ---: | ---: | ---: |
| DEVS | -888926.12 | 1595 | -1774662 | 6 |
| 69-01-50-50 | -888837.19 | 873 | -1775928 | 1 |
| 69-05-50-50 | -888841.01 | 885 | -1775912 | 2 |
| 69-01-60-60 | -888944.57 | 993 | -1775903 | 3 |

## Applied In Stepwise

`12-OrthogonalPoly` applies the reviewed PDH `72-01-50-50` setting in PHASE 3:

- `1 155 72`: year effect.
- `1 217 1`: season effect.
- `1 216 50`: region effect.
- `1 218 50`: region-season interaction effect.
- `1 202 2`: OPR end window for the year effect; the last 2 real years use the lower-degree/constant-end basis.
- `1 210 0`, `1 212 0`, and `1 214 0`: region, season, and region-season end-window controls. In current MFCL, `0` means inherit `parest_flag(202)`, so these also use the last-2-real-year end window. Use `-1` to turn an end window off.
- `1 149 0`, `1 398 0`, `1 400 0`, `2 177 0`, `2 32 0`, and `2 113 0`: OPR transfer controls from the screening `doitall` example.
- `2 30 1`: kept on because current MFCL requires this flag for the OPR polynomial coefficients to activate.
- `2 70 0`, `2 71 0`, `2 178 0`, and `-100000 1:5 0`: regional recruitment-deviation/distribution controls turned off at the OPR phase. The 4-region screening example turns off regions 1-4; this 5-region step turns off regions 1-5.
- `1 1 500`: PHASE 3 function-evaluation setting from the screening `doitall` example.

`parest_flag(221)=72` is retained for reference-PAR compatibility, but the
current MFCL source does not use it as the active year-degree control. That
control is `parest_flag(155)`.
