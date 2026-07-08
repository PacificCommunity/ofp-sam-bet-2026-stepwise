# 13ay-LBS-LLIDXmidsoft-N4

Runtime sensitivity patch for `LBS LL+IDX mid-soft mono N4`.

- Change: 4-node non-decreasing longline/index selectivity with intermediate penalty
- Notes: Uses fish flag 56 = 500000, between the default and the soft case.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
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
| `-1 56 500000` |
| `-2 56 500000` |
| `-3 56 500000` |
| `-4 56 500000` |
| `-5 56 500000` |
| `-6 56 500000` |
| `-7 56 500000` |
| `-8 56 500000` |
| `-9 56 500000` |
| `-10 56 500000` |
| `-11 56 500000` |
| `-29 56 500000` |
| `-30 56 500000` |
| `-31 56 500000` |
| `-32 56 500000` |
| `-33 56 500000` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
