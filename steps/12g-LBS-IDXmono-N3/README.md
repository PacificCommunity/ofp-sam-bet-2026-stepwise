# 12g-LBS-IDXmono-N3

Runtime sensitivity patch for `LBS IDXmono N3`.

- Change: 3-node length-based selectivity with non-decreasing index selectivity
- Notes: Strongly smooths the length spline while keeping index selectivity monotone.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 3` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
