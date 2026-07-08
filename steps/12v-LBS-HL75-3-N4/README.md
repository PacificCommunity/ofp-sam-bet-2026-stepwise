# 12v-LBS-HL75-3-N4

Runtime sensitivity patch for `LBS HL75 3 N4`.

- Change: 4-node length-based selectivity with HL young-zero age count relaxed
- Notes: Changes HL fisheries 14-15 from 75 = 5 to 75 = 3.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-14 75 3` |
| `-15 75 3` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
