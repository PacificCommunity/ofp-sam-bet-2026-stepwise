# 12r-LBS-DomeMid-N4

Runtime sensitivity patch for `LBS dome mid N4`.

- Change: 4-node length-based selectivity with a common mid terminal-zero cutoff
- Notes: Sets all inherited 16 = 2 cutoff ages to 25 quarters.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-12 3 25` |
| `-13 3 25` |
| `-16 3 25` |
| `-17 3 25` |
| `-18 3 25` |
| `-19 3 25` |
| `-20 3 25` |
| `-21 3 25` |
| `-22 3 25` |
| `-23 3 25` |
| `-24 3 25` |
| `-25 3 25` |
| `-26 3 25` |
| `-27 3 25` |
| `-28 3 25` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
