# 13cb-LBS-PSdome20-IDX-N4

Runtime sensitivity patch for `LBS PS dome20 + IDX N4`.

- Change: 4-node selectivity with main PS dome cutoffs set to 20 and index monotone
- Notes: Lower PS terminal-zero cutoff crossed with the index-tail diagnostic.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-19 3 20` |
| `-20 3 20` |
| `-25 3 20` |
| `-26 3 20` |
| `-27 3 20` |
| `-28 3 20` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
