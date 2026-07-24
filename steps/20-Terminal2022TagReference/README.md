# Terminal 2022 tag reference

This model is the reference cell for the controlled G59/G60 tag-cohort
sensitivity. It reproduces the Job 15363 terminal-2022 retrospective input
while retaining all 98 original release groups.

- G59: PTTP, Region 4, August 2020; 1,892.776 corrected releases and 319
  recaptures through 2022.
- G60: PTTP, Region 4, August 2021; 3,324.809 corrected releases and 1,037
  recaptures through 2022.
- Terminal year: 2022.
- Model controls: Step 18 grouped selectivity, fixed natural mortality,
  Dirichlet-multinomial G8 weighting with `Nmax=25`, and all-relaxed
  selectivity-form controls.

The model runs the complete native-MFCL `doitall.sh`. It is fitted under the
same executable, phases, and convergence criterion as the three exclusion
cells.
