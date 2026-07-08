# 13y-LBS-Bound359-10000-N4

Runtime sensitivity patch for `LBS bound359 10000 N4`.

- Change: 4-node length-based selectivity with spline lower-bound penalty 359 = 10000
- Notes: Adds a stronger penalty against spline coefficients getting stuck below -15.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `1 359 10000` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
