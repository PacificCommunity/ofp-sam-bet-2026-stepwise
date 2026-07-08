# 13aa-LBS-Bound359-1000-N5

Runtime sensitivity patch for `LBS bound359 1000 N5`.

- Change: 5-node length-based selectivity with weak spline lower-bound penalty
- Notes: Keeps the Step 13 node count and adds the weaker lower-bound stabilizer.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 5` |
| `1 359 1000` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
