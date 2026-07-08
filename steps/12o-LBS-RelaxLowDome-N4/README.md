# 12o-LBS-RelaxLowDome-N4

Runtime sensitivity patch for `LBS relax low dome N4`.

- Change: 4-node length-based selectivity with low terminal-zero cutoffs relaxed
- Notes: Raises the most restrictive 16 = 2 cutoff ages to 20 quarters.
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

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
