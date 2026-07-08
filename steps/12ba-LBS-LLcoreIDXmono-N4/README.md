# 12ba-LBS-LLcoreIDXmono-N4

Runtime sensitivity patch for `LBS LL core + IDXmono N4`.

- Change: 4-node non-decreasing core longline and index selectivity
- Notes: Combines the index group with only core adult longline gears.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-1 16 1` |
| `-2 16 1` |
| `-4 16 1` |
| `-5 16 1` |
| `-7 16 1` |
| `-8 16 1` |
| `-9 16 1` |
| `-10 16 1` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
