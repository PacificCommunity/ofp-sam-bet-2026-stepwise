# 13ap-LBS-LLOSmono-N4

Runtime sensitivity patch for `LBS LL OS mono N4`.

- Change: 4-node non-decreasing selectivity for oceanic longline groups
- Notes: Targets the LL.OS-derived fisheries 5 and 9, including the already monotone old6-derived group.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-5 16 1` |
| `-9 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
