# 12bc-LBS-PSdome20-N4

Runtime sensitivity patch for `LBS PS dome20 N4`.

- Change: 4-node length-based selectivity with main purse-seine dome cutoffs set to 20
- Notes: Applies a common lower cutoff to the main associated/unassociated PS groups while respecting shared selectivity groups.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-19 3 20` |
| `-20 3 20` |
| `-25 3 20` |
| `-26 3 20` |
| `-27 3 20` |
| `-28 3 20` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
