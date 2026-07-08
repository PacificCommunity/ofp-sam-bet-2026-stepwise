# 12bi-LBS-Surface75-2-N4

Runtime sensitivity patch for `LBS surface75 2 N4`.

- Change: 4-node length-based selectivity with two young ages set to zero for surface/small-fish gears
- Notes: A stronger young-age exclusion for PS/PL/DOM gears, applied consistently over shared selectivity groups.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-12 75 2` |
| `-13 75 2` |
| `-16 75 2` |
| `-17 75 2` |
| `-18 75 2` |
| `-19 75 2` |
| `-20 75 2` |
| `-21 75 2` |
| `-22 75 2` |
| `-23 75 2` |
| `-24 75 2` |
| `-25 75 2` |
| `-26 75 2` |
| `-27 75 2` |
| `-28 75 2` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
