# 13bk-LBS-LLIDXvsoft-N6

Runtime sensitivity patch for `LBS LL+IDX very soft mono N6`.

- Change: 6-node non-decreasing longline/index selectivity with very soft penalty
- Notes: Tests whether a more flexible spline needs only light monotone-tail guidance.
- Source model: `steps/13-LengthBasedSel/model`
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
| `-1 56 10000` |
| `-2 56 10000` |
| `-3 56 10000` |
| `-4 56 10000` |
| `-5 56 10000` |
| `-6 56 10000` |
| `-7 56 10000` |
| `-8 56 10000` |
| `-9 56 10000` |
| `-10 56 10000` |
| `-11 56 10000` |
| `-29 56 10000` |
| `-30 56 10000` |
| `-31 56 10000` |
| `-32 56 10000` |
| `-33 56 10000` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
