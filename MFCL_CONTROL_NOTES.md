# MFCL controls used in the final pathway

| Control | Value | Interpretation |
| --- | ---: | --- |
| Parest 111 | 4 | Negative-binomial tag likelihood. |
| Fish flags 43/44 | 0/0 | Original 2023 parameterisation; tag tau is not estimated. |
| Parest 121 | 0 from Step 03 | Fix the Lorenzen intercept and slope at incoming values. |
| Age flag 128 | 10 in Step 01; 100 from Step 02 | Preserve initial Z = 1.0 × M across the old and 2.2.7.9-based readers. |
| Fish flag 92 | CV form from Step 02 | F33-F41 use `24/31/20/21/26/23/20/25/47`; final R1-R5 use `35/24/21/24/23`. |
| Fish flag 66 | 1 from Step 11 | Use time-varying CPUE relative-variance multipliers. |
| Parest 77-81 | `100/1/240/220/1` | Activate the five-region MVN regional-scaling prior. |
| Parest 141 | 11 in Step 19 | Dirichlet-multinomial length likelihood without random effects. |
| Parest 320 | 5 in Step 19 | Require a five-bin positive span for DM support. |
| Parest 342 | 25 in Step 19 | DM effective-sample-size upper asymptote. |
| Fish flag 68 | G8 vector | Assign all 33 fisheries to eight DM groups. |
| Fish flag 69 | 0 in Step 19 | Fix grouped `fish_pars(22)` after row 22 is written as 7. |
| Fish flag 89 | 0 in Phase 1; 1 from Phase 2 | Estimate grouped `fish_pars(23)` only after the initial phase. |
| Parest 313 | 0 | No separate 1% LF tail-compression step; DM support is controlled by flag 320. |

The fixed Lorenzen intercept in every model from Step 03 onward is
`-2.54930339768360`. Step 19 writes all 33 copies of `fish_pars(22)` to 7 in
`00.dm-fixed.par` before the first fitted phase; it does not rely on an
unrelated phase to move the parameter to the bound.

Tag reporting rates remain the same numeric means, group IDs, active flags,
targets and penalties from Step 08 onward. Step 16 changes only release-group
mixing periods; Step 17 changes only the pre-mixing reporting-rate exclusion
flag.
