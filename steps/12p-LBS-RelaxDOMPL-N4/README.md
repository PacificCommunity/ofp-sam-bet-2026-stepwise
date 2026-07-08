# 12p-LBS-RelaxDOMPL-N4

Runtime sensitivity patch for `LBS relax DOM/PL N4`.

- Change: 4-node length-based selectivity with DOM/PL terminal-zero cutoffs relaxed
- Notes: Targets the DOM/PL low-age terminal-zero constraints only.
- Source model: `steps/12-LengthBasedSel/model`
- Patch insertion point: immediately before the maturity weighted-spline line in PHASE 1.

## Switches

| Appended MFCL switch |
| --- |
| `-999 61 4` |
| `-16 3 20` |
| `-21 3 20` |
| `-22 3 20` |
| `-23 3 20` |
| `-24 3 20` |

The appended switches are placed after the base Step 12 selectivity block, so MFCL's sequential option parsing applies these as the final values.
