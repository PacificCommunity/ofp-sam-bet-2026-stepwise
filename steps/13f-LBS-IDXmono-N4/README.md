# 13f-LBS-IDXmono-N4

Runtime sensitivity patch for `LBS IDXmono N4`.

- Change: 4-node length-based selectivity with non-decreasing index selectivity
- Notes: Combines moderate smoothing with monotone survey/index selectivity.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
