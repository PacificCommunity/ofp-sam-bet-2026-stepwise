# 12as-LBS-HL75-4-N4

Runtime sensitivity patch for `LBS HL75 4 N4`.

- Change: 4-node length-based selectivity with moderately relaxed HL young-zero age count
- Notes: Intermediate HL setting between the inherited 75 = 5 and the 75 = 3 sensitivity.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-14 75 4` |
| `-15 75 4` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
