# BET 2026 DM and Nmax rationale

## Decision summary

| Item | Rationale | BET 2026 implementation |
| --- | --- | --- |
| Why use DM? | The Dirichlet-multinomial likelihood estimates overdispersion within the model, allowing the effective information in length-frequency data to differ from the nominal sample size. | Use DM for the selected composition likelihood. |
| Why retain an upper bound? | Preliminary fits showed that large `Nmax` values gave the length-frequency component greater influence and worsened CPUE fit. An upper bound helps preserve balance among likelihood components in the integrated model. | Treat `Nmax` as a cap, not as a target effective sample size. |
| Why 25? | `Nmax=25` is a rounded value just above the 95th percentile of preliminary fishery-level Francis effective sample-size estimates. It limits only the extreme upper tail while retaining variation estimated by the DM. | Apply `Nmax=25` in `17b-DMG8Nmax25`. |
| How was it assessed? | No single component was used as the decision criterion. Length-frequency fit, CPUE fit, convergence, parameter bounds, and Hessian stability were considered jointly. | Carry `17b-DMG8Nmax25` as the final selected stepwise model. |

## Report-ready text

Length-composition data were fitted using a Dirichlet-multinomial likelihood,
which estimates overdispersion and thereby allows their effective information
content to be inferred within the model. Preliminary fits indicated that high
maximum effective sample sizes increased the influence of the
length-frequency component and reduced the fit to CPUE indices. The maximum
effective sample size was therefore capped at 25 to maintain balance among
likelihood components. This rounded value was selected just above the 95th
percentile of preliminary fishery-level Francis effective sample-size
estimates, so the cap primarily constrained the extreme upper tail rather than
prescribing a common weight. The selected value was evaluated using
composition and CPUE fits, convergence, parameter bounds, and Hessian
stability.

## Interpretation limits

- `Nmax=25` does not mean that length-frequency data receive 25 observations in every period.
- `Nmax=25` is not a 95% weight; the 95th percentile only provides an empirical scale for the cap.
- DM still estimates overdispersion and relative composition information within the imposed upper bound.
- The numerical cap is specific to the BET 2026 data and model configuration and should be reassessed if those inputs change.

## Method reference

Thorson, J.T., Johnson, K.F., Methot, R.D., and Taylor, I.G. (2017).
[Model-based estimates of effective sample size in stock assessment models
using the Dirichlet-multinomial distribution](https://doi.org/10.1016/j.fishres.2016.06.005).
