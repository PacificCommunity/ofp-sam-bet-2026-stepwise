# 12ao-LBS-LLrecentMono-N4

Runtime sensitivity patch for `LBS LL recent mono N4`.

- Change: 4-node non-decreasing selectivity for later longline fishery groups
- Notes: Focuses on the later/regional longline groups 7-11 rather than all longline gears.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-7 16 1` |
| `-8 16 1` |
| `-9 16 1` |
| `-10 16 1` |
| `-11 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
