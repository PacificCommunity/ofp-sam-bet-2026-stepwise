# Terminal 2022 without tag release groups 59 and 60

This sensitivity removes both recent PTTP Region 4 releases from the Job 15363
terminal-2022 retrospective input: original G59 (August 2020; 1,892.776
corrected releases and 319 recaptures) and original G60 (August 2021;
3,324.809 corrected releases and 1,037 recaptures).

Both exclusions are calculated simultaneously from the original 98-group
index. TAG releases and recaptures, the MFCL-1007 INI tag sections, and the FRQ
tag dimension are then subset and renumbered together. The resulting model
contains 96 release groups. Every non-tag input and model control is identical
to the terminal-2022 reference, including fixed natural mortality, Step 18
grouped selectivity, and Dirichlet-multinomial G8 weighting with `Nmax=25`.

The model runs the complete native-MFCL `doitall.sh`.
