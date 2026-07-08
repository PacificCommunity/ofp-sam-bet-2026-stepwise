# 13an-LBS-LLcoreMono-N5

Runtime sensitivity patch for `LBS LL core mono N5`.

- Change: 5-node non-decreasing selectivity for core adult longline fisheries
- Notes: Same core LL diagnostic at the Step 13 node count.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 5` |
| `-1 16 1` |
| `-2 16 1` |
| `-4 16 1` |
| `-5 16 1` |
| `-7 16 1` |
| `-8 16 1` |
| `-9 16 1` |
| `-10 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
