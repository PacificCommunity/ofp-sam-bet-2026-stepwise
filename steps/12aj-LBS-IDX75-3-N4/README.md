# 12aj-LBS-IDX75-3-N4

Runtime sensitivity patch for `LBS IDX75 3 N4`.

- Change: 4-node index non-decreasing selectivity with three young ages set to zero
- Notes: A stronger index young-age exclusion, applied consistently across the shared index group.
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
| `-29 75 3` |
| `-30 75 3` |
| `-31 75 3` |
| `-32 75 3` |
| `-33 75 3` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
