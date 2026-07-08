# 12cc-LBS-PSdome35-IDX-N4

Runtime sensitivity patch for `LBS PS dome35 + IDX N4`.

- Change: 4-node selectivity with main PS dome cutoffs set to 35 and index monotone
- Notes: Higher PS terminal-zero cutoff crossed with index-tail stabilization.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-19 3 35` |
| `-20 3 35` |
| `-25 3 35` |
| `-26 3 35` |
| `-27 3 35` |
| `-28 3 35` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
