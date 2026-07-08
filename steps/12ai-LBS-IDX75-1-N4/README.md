# 12ai-LBS-IDX75-1-N4

Runtime sensitivity patch for `LBS IDX75 1 N4`.

- Change: 4-node index non-decreasing selectivity with one young age set to zero
- Notes: Tests a light young-age exclusion for all index fisheries in their shared selectivity group.
- Source model: `steps/12-LengthBasedSel/model`
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
| `-29 75 1` |
| `-30 75 1` |
| `-31 75 1` |
| `-32 75 1` |
| `-33 75 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
