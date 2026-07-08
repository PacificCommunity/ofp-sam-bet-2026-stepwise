# 13ck-LBS-LL75-1-LLIDX-N4

Runtime sensitivity patch for `LBS LL75 1 + LL+IDX N4`.

- Change: 4-node selectivity with LL young-zero age count relaxed and adult/index monotone
- Notes: Middle interaction case between removing and strengthening LL young-age zeros.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-2 75 1` |
| `-4 75 1` |
| `-5 75 1` |
| `-7 75 1` |
| `-8 75 1` |
| `-9 75 1` |
| `-10 75 1` |
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

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
