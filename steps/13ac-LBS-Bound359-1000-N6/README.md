# 13ac-LBS-Bound359-1000-N6

Runtime sensitivity patch for `LBS bound359 1000 N6`.

- Change: 6-node length-based selectivity with weak spline lower-bound penalty
- Notes: Pairs the more flexible N6 spline with light lower-bound stabilization.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |
| `1 359 1000` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
