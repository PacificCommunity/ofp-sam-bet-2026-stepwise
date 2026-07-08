# 12t-LBS-YoungZero-PSPLDOM-N4

Runtime sensitivity patch for `LBS young-zero PS/PL/DOM N4`.

- Change: 4-node length-based selectivity with age-1 zero selectivity for PS/PL/DOM gears
- Notes: Tests whether small-fish fit is pulling selectivity and depletion upward.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-12 75 1` |
| `-13 75 1` |
| `-16 75 1` |
| `-17 75 1` |
| `-18 75 1` |
| `-19 75 1` |
| `-20 75 1` |
| `-21 75 1` |
| `-22 75 1` |
| `-23 75 1` |
| `-24 75 1` |
| `-25 75 1` |
| `-26 75 1` |
| `-27 75 1` |
| `-28 75 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
