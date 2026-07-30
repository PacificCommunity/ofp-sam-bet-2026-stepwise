# Job 15062 20c selectivity provenance

`doitall.sh` is the byte-identical MFCL input script retained in the actual
completed Kflow Job 15062 output archive for model `20c-DMG8Nmax25`.

- Job: `15062`
- Job key: `20c-dm-length-composition-weighting`
- Source commit: `656b82b74b58a5520dc1d13a86ebb1cb54b342c3`
- Output archive SHA256:
  `9e1aedde63db28fa642c3220436f29b341b13fd30a8a6a9f4aff4015d790121a`
- Archived `doitall.sh` SHA256:
  `11fc97e3d3798df7ca766229bcb7187cc6c78753d772afaf28e312eab5e2d15e`
- Container:
  `ghcr.io/pacificcommunity/tuna-flow@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360`

The `sel20c` variants use only the Phase 1 and Phase 5 fishery-selectivity
controls from this script, with the deliberate F14 constraint documented
below. They do not copy Job 15062 data, DM, tag-tau, mixing-period,
reporting-rate, regional-scaling, or natural-mortality settings.

Relative to the original 12 final-exploration models, the 20c selectivity
controls:

- give F1-F28 separate Phase 1 selectivity groups and initially group
  F29-F33 together;
- separate F29-F33 into groups 29-33 in Phase 5;
- do not apply the later F2/F3 and F7/F9 selectivity sharing;
- retain the default five spline nodes for F1, F2, F3, F5, and F29;
- retain cubic-spline selectivity for F33; and
- retain the F15 youngest-five-age constraint.

The final-exploration variants additionally apply the same youngest-five-age
constraint (`fishery flag 75=5`) to F14. This is the only deliberate
selectivity difference from the archived 20c controls. In the retained
`bet.frq`, neither F14 nor F15 has positive observations below 70 cm (minimum
positive bins are 72 cm and 70 cm, respectively).
