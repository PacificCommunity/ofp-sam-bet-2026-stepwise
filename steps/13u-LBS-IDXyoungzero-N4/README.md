# 13u-LBS-IDXyoungzero-N4

Runtime sensitivity patch for `LBS IDX young-zero N4`.

- Change: 4-node length-based selectivity with monotone index selectivity and young-index zero selectivity
- Notes: Index fisheries get 16 = 1 and 75 = 2.
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
| `-29 75 2` |
| `-30 75 2` |
| `-31 75 2` |
| `-32 75 2` |
| `-33 75 2` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
