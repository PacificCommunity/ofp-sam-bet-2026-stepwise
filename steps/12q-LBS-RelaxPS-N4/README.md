# 12q-LBS-RelaxPS-N4

Runtime sensitivity patch for `LBS relax PS N4`.

- Change: 4-node length-based selectivity with PS and JP terminal-zero cutoffs relaxed
- Notes: Raises the PS/JP 16 = 2 cutoffs to 30 quarters.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-12 3 30` |
| `-13 3 30` |
| `-17 3 30` |
| `-18 3 30` |
| `-19 3 30` |
| `-20 3 30` |
| `-25 3 30` |
| `-26 3 30` |
| `-27 3 30` |
| `-28 3 30` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
