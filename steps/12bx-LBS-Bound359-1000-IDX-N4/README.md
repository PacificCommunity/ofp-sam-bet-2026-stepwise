# 12bx-LBS-Bound359-1000-IDX-N4

Runtime sensitivity patch for `LBS bound359 1000 IDX N4`.

- Change: 4-node index monotone selectivity with weak spline lower-bound penalty
- Notes: Separates index-tail stabilization from adult longline monotonicity under the lower-bound penalty.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `1 359 1000` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
