# 13ci-LBS-Surface75-2-LLIDX-N4

Runtime sensitivity patch for `LBS surface75 2 + LL+IDX N4`.

- Change: 4-node selectivity with surface young-zero 2 and adult/index monotone
- Notes: Full young-zero plus adult/index tail interaction case.
- Source model: `steps/13-LengthBasedSel/model`
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
| `-1 16 1` |
| `-2 16 1` |
| `-3 16 1` |
| `-4 16 1` |
| `-5 16 1` |
| `-6 16 1` |
| `-7 16 1` |
| `-8 16 1` |
| `-9 16 1` |
| `-10 16 1` |
| `-11 16 1` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
