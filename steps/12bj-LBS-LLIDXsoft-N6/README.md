# 12bj-LBS-LLIDXsoft-N6

Runtime sensitivity patch for `LBS LL+IDX soft mono N6`.

- Change: 6-node non-decreasing longline/index selectivity with softer penalty
- Notes: Crosses the flexible N6 spline with the adult/index monotone penalty-strength axis.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |
| `-1 16 1` |
| `-2 16 1` |
| `-3 16 1` |
| `-4 16 1` |
| `-5 16 1` |
| `-6 16 1` |
| `-7 16 1` |
| `-8 16 1` |
| `-9 16 1` |
| `-10 16 1` |
| `-11 16 1` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |
| `-1 56 100000` |
| `-2 56 100000` |
| `-3 56 100000` |
| `-4 56 100000` |
| `-5 56 100000` |
| `-6 56 100000` |
| `-7 56 100000` |
| `-8 56 100000` |
| `-9 56 100000` |
| `-10 56 100000` |
| `-11 56 100000` |
| `-29 56 100000` |
| `-30 56 100000` |
| `-31 56 100000` |
| `-32 56 100000` |
| `-33 56 100000` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
