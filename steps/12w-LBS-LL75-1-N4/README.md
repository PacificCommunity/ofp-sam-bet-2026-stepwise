# 12w-LBS-LL75-1-N4

Runtime sensitivity patch for `LBS LL75 1 N4`.

- Change: 4-node length-based selectivity with LL young-zero age count relaxed
- Notes: Changes longline fisheries that had 75 = 2 to 75 = 1.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-2 75 1` |
| `-4 75 1` |
| `-5 75 1` |
| `-7 75 1` |
| `-8 75 1` |
| `-9 75 1` |
| `-10 75 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
