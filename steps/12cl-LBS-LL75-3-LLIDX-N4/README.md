# 12cl-LBS-LL75-3-LLIDX-N4

Runtime sensitivity patch for `LBS LL75 3 + LL+IDX N4`.

- Change: 4-node selectivity with stronger LL young-zero settings and adult/index monotone
- Notes: Strengthens young-age exclusion while keeping adult/index tails monotone.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-2 75 3` |
| `-4 75 3` |
| `-5 75 3` |
| `-7 75 3` |
| `-8 75 3` |
| `-9 75 3` |
| `-10 75 3` |
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
