# 13s-LBS-NoLowDome-IDX-N4

Runtime sensitivity patch for `LBS no low dome + IDX N4`.

- Change: 4-node length-based selectivity with low dome constraints removed and index monotone
- Notes: Removes the most restrictive terminal-zero constraints and stabilizes index tails.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 16 0` |
| `-17 16 0` |
| `-18 16 0` |
| `-21 16 0` |
| `-22 16 0` |
| `-23 16 0` |
| `-24 16 0` |
| `-16 3 37` |
| `-17 3 37` |
| `-18 3 37` |
| `-21 3 37` |
| `-22 3 37` |
| `-23 3 37` |
| `-24 3 37` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
