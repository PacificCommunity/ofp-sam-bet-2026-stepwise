# 13n-LBS-NoDome-N4

Runtime sensitivity patch for `LBS no dome N4`.

- Change: 4-node length-based selectivity with Step 13 dome/terminal-zero constraints removed
- Notes: Sets fish flag 16 back to 0 for the fisheries that inherited 16 = 2 constraints.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-12 16 0` |
| `-13 16 0` |
| `-16 16 0` |
| `-17 16 0` |
| `-18 16 0` |
| `-19 16 0` |
| `-20 16 0` |
| `-21 16 0` |
| `-22 16 0` |
| `-23 16 0` |
| `-24 16 0` |
| `-25 16 0` |
| `-26 16 0` |
| `-27 16 0` |
| `-28 16 0` |
| `-12 3 37` |
| `-13 3 37` |
| `-16 3 37` |
| `-17 3 37` |
| `-18 3 37` |
| `-19 3 37` |
| `-20 3 37` |
| `-21 3 37` |
| `-22 3 37` |
| `-23 3 37` |
| `-24 3 37` |
| `-25 3 37` |
| `-26 3 37` |
| `-27 3 37` |
| `-28 3 37` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
