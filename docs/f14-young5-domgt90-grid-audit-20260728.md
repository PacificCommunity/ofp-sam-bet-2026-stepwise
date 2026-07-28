# F14-young5 DOM >90 cm grid audit (2026-07-28)

All eight rows are independent `doitall` fits from the frozen S03
`bet.ini` and input files. They retain the verified F15 `<70 cm` length
filter and then apply the DOM filter to fisheries 21–23 only.

The FRQ uses 95 two-centimetre intervals with lower bounds
10, 12, ..., 198 cm and midpoints 11, 13, ..., 199 cm. Because the
historical `>90 cm` rule was applied to raw lengths that are unavailable
after binning, this sensitivity removes bins with midpoint `>90 cm`;
equivalently, intervals with lower bound `>=90 cm`. The bin convention
and this unavoidable approximation are recorded in every job's
`dom-lf-qc-summary.csv`.

| Fishery | LF rows before | Rows affected | Count before | Count removed | LF rows after |
|---|---:|---:|---:|---:|---:|
| 21.DOM.ID.2 | 40 | 3 | 2,130 | 56 | 39 |
| 22.DOM.PH.2 | 138 | 123 | 108,385 | 6,146 | 138 |
| 23.DOM.VN.2 | 21 | 16 | 50,146 | 1,702 | 21 |
| Total | 199 | 142 | 160,661 | 7,904 | 198 |

F21 2010Q3 contains only observations above the cutoff, so its empty
length composition is converted to the FRQ's existing no-composition
form. Its catch/effort prefix is retained verbatim. No samples are
renormalised and no selectivity controls are changed.

Verified hashes:

- frozen source FRQ:
  `d77f97c348409f845f1f0fc801af808d15b6cb119349d1f083308cfc9d4fba8c`
- after F15 `<70 cm` QC:
  `3abf83821f8d696b36f020a80f48f99445f9e15046bdb3741adfac778c82ad60`
- after F15 and DOM QC:
  `9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3`
