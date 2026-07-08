# 12ah-LBS-IDXvsoft-N5

Runtime sensitivity patch for `LBS IDX very soft mono N5`.

- Change: 5-node index non-decreasing selectivity with very soft penalty
- Notes: Uses fish flag 56 = 10000 for the index group to test penalty-strength sensitivity.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 5` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |
| `-29 56 10000` |
| `-30 56 10000` |
| `-31 56 10000` |
| `-32 56 10000` |
| `-33 56 10000` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
