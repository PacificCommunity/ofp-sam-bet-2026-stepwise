# Final DM configuration

Step 19 uses the Job 18717 composition treatment:

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
again in Step 19. `Nmax=25` is a separate upper asymptote and is not a hard
replacement for an observed sample size.

Tag overdispersion is independent of this composition setting. The final
model retains negative-binomial tags with the original 2023 parameterisation
and does not estimate tau.
