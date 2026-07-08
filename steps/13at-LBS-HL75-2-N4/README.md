# 13at-LBS-HL75-2-N4

Runtime sensitivity patch for `LBS HL75 2 N4`.

- Change: 4-node length-based selectivity with strongly relaxed HL young-zero age count
- Notes: Tests whether the handline young-age exclusion is too restrictive.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-14 75 2` |
| `-15 75 2` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
