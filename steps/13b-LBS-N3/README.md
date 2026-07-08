# 13b-LBS-N3

Runtime sensitivity patch for `LBS N3`.

- Change: length-based selectivity with 3 cubic-spline nodes
- Notes: Reduces length-based spline flexibility from the Step 13 baseline of 5 nodes.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 3` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
