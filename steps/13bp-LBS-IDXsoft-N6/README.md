# 13bp-LBS-IDXsoft-N6

Runtime sensitivity patch for `LBS IDX soft mono N6`.

- Change: 6-node index non-decreasing selectivity with softer penalty
- Notes: Crosses flexible length selectivity with a softer index monotone-tail penalty.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |
| `-29 56 100000` |
| `-30 56 100000` |
| `-31 56 100000` |
| `-32 56 100000` |
| `-33 56 100000` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
