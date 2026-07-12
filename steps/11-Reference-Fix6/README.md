# 11 Standard reference — Fix6

Rebuilds the standard Step-11 model from its model inputs and retains the
existing six-period arithmetic-mean terminal treatment (`pf398=1`, `pf400=6`).
It is the common comparison reference and is run with the ordinary full
`doitall.sh`, not from a bundled PAR.

The other rows in this branch use the completed standard reference PAR as their
starting point so that each OPR comparison changes recruitment parameterisation
without rerunning the earlier fitting sequence.
