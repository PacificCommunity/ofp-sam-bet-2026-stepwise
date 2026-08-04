# DM configuration retained in the current Diagnostic model

Step 19a introduces the Job 18718 composition treatment, which is retained
unchanged through Step 22:

- `parest_flags(141)=11`: Dirichlet-multinomial without random effects.
- Eight fishery groups through fish flag 68.
- `parest_flags(342)=25`: effective-sample-size upper asymptote `Nmax=25`.
- `parest_flags(320)=5`: minimum positive-bin span used by the DM likelihood.
- All `fish_pars(22)` concentration intercepts are written as 7, then fixed
  with fish flag 69=0.
- The eight grouped `fish_pars(23)` relative-sample-size exponents are
  estimated from Phase 2 with fish flag 89=1.

The value 7 is the upper-bound estimate reached before Job 18518. Fixing it
means the model starts and remains at that fitted bound; it is not estimated
again in Step 19a. `Nmax=25` is a separate upper asymptote and is not a hard
replacement for an observed sample size.

Tag overdispersion is independent of this composition setting. Step 20 changes
the tag likelihood parameterisation to direct negative-binomial tau and fixes
`fish_pars(4)=0`, so `tau = 1 + exp(0) = 2`; tau is not estimated.
