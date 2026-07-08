# 13bo-LBS-IDXvsoft-N4

Runtime sensitivity patch for `LBS IDX very soft mono N4`.

- Change: 4-node index non-decreasing selectivity with very soft penalty
- Notes: Tests whether the index tail needs a hard monotone penalty at the N4 node count.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
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

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
