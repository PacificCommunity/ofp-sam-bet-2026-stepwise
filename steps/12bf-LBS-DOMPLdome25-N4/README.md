# 12bf-LBS-DOMPLdome25-N4

Runtime sensitivity patch for `LBS DOM/PL dome25 N4`.

- Change: 4-node length-based selectivity with DOM/PL cutoffs set to 25
- Notes: Strongly relaxes DOM/PL terminal-zero cutoffs while keeping the dome mechanism.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 3 25` |
| `-21 3 25` |
| `-22 3 25` |
| `-23 3 25` |
| `-24 3 25` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
