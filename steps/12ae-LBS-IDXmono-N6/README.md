# 12ae-LBS-IDXmono-N6

Runtime sensitivity patch for `LBS IDXmono N6`.

- Change: 6-node length-based selectivity with non-decreasing index selectivity
- Notes: Checks whether index-tail stabilization still helps when the spline is more flexible.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 6` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
