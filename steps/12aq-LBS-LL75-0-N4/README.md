# 12aq-LBS-LL75-0-N4

Runtime sensitivity patch for `LBS LL75 0 N4`.

- Change: 4-node length-based selectivity with inherited longline young-zero settings removed
- Notes: Allows selected longline groups to estimate young-age selectivity rather than forcing the first two ages to zero.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-2 75 0` |
| `-4 75 0` |
| `-5 75 0` |
| `-7 75 0` |
| `-8 75 0` |
| `-9 75 0` |
| `-10 75 0` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
