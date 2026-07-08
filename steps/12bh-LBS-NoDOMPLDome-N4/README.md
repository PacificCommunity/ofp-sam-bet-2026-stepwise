# 12bh-LBS-NoDOMPLDome-N4

Runtime sensitivity patch for `LBS no DOM/PL dome N4`.

- Change: 4-node length-based selectivity with DOM/PL dome constraints removed
- Notes: Removes dome/terminal-zero constraints for domestic and pole-line small-fish gears only.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 16 0` |
| `-21 16 0` |
| `-22 16 0` |
| `-23 16 0` |
| `-24 16 0` |
| `-16 3 37` |
| `-21 3 37` |
| `-22 3 37` |
| `-23 3 37` |
| `-24 3 37` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
