# OPR Screening Summary

Source: John Hampton's `OPR.pptx`, provided for the BET/YFT 2026 assessment work.

The screening applied OPR settings to final converged fits and compared models
with AIC. The BET screening used the 4R model, not this final 5-region stepwise
path, but the best-ranked BET OPR setting is carried forward here as the current
stepwise OPR choice.

## BET Result Used

| model | -LN(L) | npar | AIC | rank |
| --- | ---: | ---: | ---: | ---: |
| DEVS | -888926.12 | 1595 | -1774662 | 6 |
| 69-01-50-50 | -888837.19 | 873 | -1775928 | 1 |
| 69-05-50-50 | -888841.01 | 885 | -1775912 | 2 |
| 69-01-60-60 | -888944.57 | 993 | -1775903 | 3 |

## Applied In Stepwise

`10-OPR` applies the BET rank-1 `69-01-50-50` setting in PHASE 3:

- `1 155 69` and `1 221 69`: year effect.
- `1 217 1`: season effect.
- `1 216 50`: region effect.
- `1 218 50`: region-season interaction effect.
- `1 202 2`, `1 210 0`, `1 212 0`, and `1 214 0`: terminal constraints from the example `do-OPR` file.

