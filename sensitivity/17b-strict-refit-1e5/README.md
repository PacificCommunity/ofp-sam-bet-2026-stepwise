# 17b strict refit to MGC 1e-5

This sensitivity continues the completed `17b-DMG8Nmax25` fit from Kflow Job
14067. It starts from that fit's final parameter estimates rather than
repeating the full stepwise estimation schedule.

The refit uses the current MFCL executable with:

- a maximum-gradient-component target of `1e-5`;
- the limited-memory Newton minimizer;
- 400 stored update steps; and
- up to 20,000 function evaluations.

The scientific inputs and model configuration are inherited unchanged from
the completed 17b fit. A 50-part Hessian calculation is submitted separately
from the completed strict-refit output.
