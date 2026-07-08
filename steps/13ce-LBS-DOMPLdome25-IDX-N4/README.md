# 13ce-LBS-DOMPLdome25-IDX-N4

Runtime sensitivity patch for `LBS DOM/PL dome25 + IDX N4`.

- Change: 4-node selectivity with DOM/PL cutoffs set to 25 and index monotone
- Notes: Strong DOM/PL cutoff relaxation crossed with index-tail stabilization.
- Source model: `steps/13-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 3 25` |
| `-21 3 25` |
| `-22 3 25` |
| `-23 3 25` |
| `-24 3 25` |
| `-29 16 1` |
| `-30 16 1` |
| `-31 16 1` |
| `-32 16 1` |
| `-33 16 1` |

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
