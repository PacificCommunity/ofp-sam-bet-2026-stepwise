# 12al-LBS-LLmono-N6

Runtime sensitivity patch for `LBS LLmono N6`.

- Change: 6-node length-based selectivity with non-decreasing longline selectivity
- Notes: Tests whether LL monotone tails remain stable with more flexible length splines.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |
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

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
