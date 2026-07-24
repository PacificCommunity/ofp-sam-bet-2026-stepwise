# Terminal 2022 without tag release group 59

This sensitivity removes original release group G59 (PTTP, Region 4, August
2020) from the Job 15363 terminal-2022 retrospective input. G59 contains
1,892.776 corrected releases and 319 recaptures through 2022. Original G60 is
retained and becomes fitted release group 59 after one-pass renumbering.

TAG releases and recaptures, the MFCL-1007 INI tag sections, and the FRQ tag
dimension are subset and renumbered together. The resulting model contains 97
release groups. Every non-tag input and model control is identical to the
terminal-2022 reference, including fixed natural mortality, Step 18 grouped
selectivity, and Dirichlet-multinomial G8 weighting with `Nmax=25`.

The model runs the complete native-MFCL `doitall.sh`.
