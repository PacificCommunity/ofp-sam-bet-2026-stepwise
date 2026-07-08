# 13bz-LBS-NoPSDome-IDX-N4

Runtime sensitivity patch for `LBS no PS dome + IDX N4`.

- Change: 4-node selectivity with PS/JP dome constraints removed and index monotone
- Notes: Checks whether surface-fishery dome assumptions and index tails jointly explain the depletion shift.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-12 16 0` |
| `-13 16 0` |
| `-17 16 0` |
| `-18 16 0` |
| `-19 16 0` |
| `-20 16 0` |
| `-25 16 0` |
| `-26 16 0` |
| `-27 16 0` |
| `-28 16 0` |
| `-12 3 37` |
| `-13 3 37` |
| `-17 3 37` |
| `-18 3 37` |
| `-19 3 37` |
| `-20 3 37` |
| `-25 3 37` |
| `-26 3 37` |
| `-27 3 37` |
| `-28 3 37` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
