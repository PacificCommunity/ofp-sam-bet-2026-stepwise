# 13d-LBS-N6

Runtime sensitivity patch for `LBS N6`.

- Change: length-based selectivity with 6 cubic-spline nodes
- Notes: Increases flexibility to test whether the baseline depletion shift is a low-node artifact.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
