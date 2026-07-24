# 18 Grouped selectivity robustness

This sensitivity reruns the complete native-MFCL `doitall.sh` sequence using
the Job 14363 (`17d-AllSelectivityFormRelaxed`) model specification, with only
the selectivity sharing and spline dimensions changed.

## Selectivity configuration

| Fishery | Configuration |
| --- | --- |
| F29, Index R1 | Shares selectivity with F2 (`02.LL.EAST.1`) |
| F30, Index R2 | Shares selectivity with F4 (`04.LL.ALL.2`) |
| F31, Index R3 | Shares selectivity with F7 (`07.LL.WEST.3`) |
| F32, Index R4 | Shares selectivity with F8 (`08.LL.EAST.3`) |
| F33, Index R5 | Independent selectivity |
| F1, F3, F5, F33 | Four cubic-spline nodes |
| F15 | Five cubic-spline nodes |
| F25, F26 | Seven cubic-spline nodes |
| All other fisheries | Independent five-node selectivity |

The selectivity groups are set in Phase 1 and retained in Phase 5. Fisheries
F29-F33 retain independent flag-99 catchability/likelihood groups in Phase 5,
so the selectivity sharing does not share regional-index catchability.

## Held constant

All other Job 14363 controls and inputs are unchanged, including fixed natural
mortality, all-relaxed fishery-specific selectivity-form controls, G8
Dirichlet-multinomial weighting with Nmax 25, CPUE error settings, tag controls,
recruitment settings, and the data files.

## Execution

The Kflow sensitivity executes `model/doitall.sh` from Phase 0 through Phase 11
with `/home/mfcl/mfclo64`. It does not use `mfclrtmb` and does not continue from
the Job 14363 final parameter file.
