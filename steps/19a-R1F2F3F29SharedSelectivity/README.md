# 19a Region 1 shared selectivity

This sensitivity reruns the complete native-MFCL `doitall.sh` sequence from
the Job 15363 (`18-GroupedSelectivityRobustness`) scientific parent. It changes
only the Region 1 selectivity sharing and spline dimension.

## Selectivity change

| Fishery | Configuration |
| --- | --- |
| F2, `LL.EAST.1` | Shares one four-node selectivity with F3 and F29 |
| F3, `LL.US.1` | Shares one four-node selectivity with F2 and F29 |
| F29, `Index R1` | Shares one four-node selectivity with F2 and F3 |

The remaining Job 15363 selectivity relationships are retained:

- F30/F4, F31/F7, and F32/F8 retain their matched regional sharing.
- F33 remains independent.
- F1, F5, and F33 retain four nodes; F15 retains five; F25/F26 retain seven.
- All selectivity groups are renumbered to the contiguous range 1-28 after
  merging the former independent F3 group into the F2/F29 group.

The complete flag-24 map is set in Phase 1 and explicitly reasserted in Phase
5. F29 retains its independent flag-99 catchability/likelihood group, so this
sensitivity does not share regional-index catchability.

## Held constant

Every other Job 15363 input and control is unchanged, including fixed natural
mortality, all-relaxed fishery-specific selectivity-form controls, G8
Dirichlet-multinomial weighting with Nmax 25, CPUE error settings, tag controls,
recruitment settings, regional-scaling weight, and all data files.

## Execution

The Kflow sensitivity executes `model/doitall.sh` from Phase 0 through Phase 11
with `/home/mfcl/mfclo64`. It does not use `mfclrtmb` and does not continue from
the Job 15363 final parameter file.
