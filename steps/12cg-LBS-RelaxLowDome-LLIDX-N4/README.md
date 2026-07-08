# 12cg-LBS-RelaxLowDome-LLIDX-N4

Runtime sensitivity patch for `LBS relax low dome + LL+IDX N4`.

- Change: 4-node selectivity with low terminal-zero cutoffs relaxed and adult/index monotone
- Notes: Less extreme dome/tail interaction than removing all dome constraints.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 3 20` |
| `-17 3 20` |
| `-18 3 20` |
| `-21 3 20` |
| `-22 3 20` |
| `-23 3 20` |
| `-24 3 20` |
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

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
