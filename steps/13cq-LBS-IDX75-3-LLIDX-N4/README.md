# 13cq-LBS-IDX75-3-LLIDX-N4

Runtime sensitivity patch for `LBS IDX75 3 + LL+IDX N4`.

- Change: 4-node adult/index monotone selectivity with three young index ages set to zero
- Notes: Strong index young-age exclusion crossed with LL+index adult-tail monotonicity.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
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
| `-29 75 3` |
| `-30 75 3` |
| `-31 75 3` |
| `-32 75 3` |
| `-33 75 3` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
