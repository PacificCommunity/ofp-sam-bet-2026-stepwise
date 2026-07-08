# 13bd-LBS-PSdome35-N4

Runtime sensitivity patch for `LBS PS dome35 N4`.

- Change: 4-node length-based selectivity with main purse-seine dome cutoffs set to 35
- Notes: A high-cutoff PS case that relaxes terminal-zero pressure without removing the dome form.
- Source model: `steps/13-LengthBasedSel/model`
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

The appended switches are placed after the base Step 13 selectivity block, so MFCL's sequential option parsing applies these as the final values.
