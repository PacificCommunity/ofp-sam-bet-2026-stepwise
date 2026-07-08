# 12bv-LBS-Bound359-1000-LLIDX-N5

Runtime sensitivity patch for `LBS bound359 1000 LL+IDX N5`.

- Change: 5-node adult/index monotone selectivity with weak spline lower-bound penalty
- Notes: Baseline node count crossed with both adult/index monotone tails and weak lower-bound stabilization.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 5` |
| `1 359 1000` |
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
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
