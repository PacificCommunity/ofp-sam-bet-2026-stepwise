# 12ad-LBS-Bound359-10000-N6

Runtime sensitivity patch for `LBS bound359 10000 N6`.

- Change: 6-node length-based selectivity with stronger spline lower-bound penalty
- Notes: Tests whether N6 needs stronger protection against very low spline coefficients.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |
| `1 359 10000` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
