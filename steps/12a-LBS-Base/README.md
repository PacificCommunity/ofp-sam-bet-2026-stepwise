# 12a-LBS-Base

Runtime sensitivity patch for `LBS base N5`.

- Change: Step 12 length-based selectivity baseline with 5 cubic-spline nodes
- Notes: Alias for 12-LengthBasedSel in the sensitivity task so the grid reads 12a, 12b, ... without hiding the baseline.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 5` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
