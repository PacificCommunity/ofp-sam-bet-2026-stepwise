# 13c-LBS-N4

Runtime sensitivity patch for `LBS N4`.

- Change: length-based selectivity with 4 cubic-spline nodes
- Notes: Moderate node reduction between the 3-node and 5-node cases.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
