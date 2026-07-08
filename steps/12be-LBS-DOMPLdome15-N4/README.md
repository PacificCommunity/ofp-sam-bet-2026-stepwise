# 12be-LBS-DOMPLdome15-N4

Runtime sensitivity patch for `LBS DOM/PL dome15 N4`.

- Change: 4-node length-based selectivity with DOM/PL cutoffs set to 15
- Notes: Moderately relaxes the very low domestic and pole-line terminal-zero cutoffs.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 3 15` |
| `-21 3 15` |
| `-22 3 15` |
| `-23 3 15` |
| `-24 3 15` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
