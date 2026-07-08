# 12ar-LBS-LL75-3-N4

Runtime sensitivity patch for `LBS LL75 3 N4`.

- Change: 4-node length-based selectivity with stronger longline young-zero settings
- Notes: Tests whether excluding one additional young age stabilizes adult longline selectivity.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-2 75 3` |
| `-4 75 3` |
| `-5 75 3` |
| `-7 75 3` |
| `-8 75 3` |
| `-9 75 3` |
| `-10 75 3` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
