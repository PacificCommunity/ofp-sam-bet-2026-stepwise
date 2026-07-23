# BET 2026 DM and Nmax rationale

## Decision summary

| Item | Rationale | BET 2026 implementation |
| --- | --- | --- |
| Why use DM? | The Dirichlet-multinomial likelihood estimates overdispersion within the model, allowing the effective information in length-frequency data to differ from the nominal sample size. | Use DM for the selected composition likelihood. |
| What is Nmax? | MFCL calculates effective sample size (ESS) as `N_eff = Nmax(1 + lambda)/(Nmax + lambda)`. The fitted `N_eff` approaches `Nmax` as the DM concentration `lambda` increases. | Set parest flag 342 to the assumed maximum ESS; zero uses the MFCL default of 1,000. |
| Why retain an upper asymptote? | Preliminary fits showed that large `Nmax` values gave the length-frequency component greater influence and worsened CPUE fit. A finite asymptote helps preserve balance among likelihood components in the integrated model. | Treat `Nmax` as an upper asymptote, not as a target effective sample size or a hard clipping rule. |
| Why 25? | The 95th percentile of composition-level Francis ESS ranged from 22.22 to 23.81 across 2,399 positive LF compositions in matched robust-normal fits. | Apply `Nmax=25`, an upper-tail cap just above this range, in `20c-DMG8Nmax25`; Steps 20a, 20b, and 20c are independent sibling alternatives from Step 19. |
| How was it assessed? | No single component was used as the decision criterion. Length-frequency fit, CPUE fit, convergence, parameter bounds, and Hessian stability were considered jointly. | Carry `20c-DMG8Nmax25` as the final selected stepwise model. |

## Report-ready text

Length-composition data were fitted using a Dirichlet-multinomial likelihood,
which estimates overdispersion and thereby allows their effective information
content to be inferred within the model. Preliminary fits indicated that high
maximum effective sample sizes increased the influence of the
length-frequency component and reduced the fit to CPUE indices. The upper
asymptote was therefore set to 25 to maintain balance among likelihood
components. The 95th percentile of the composition-level Francis effective
sample size (ESS) ranged from 22.22 to 23.81 across 2,399 positive
length-frequency compositions in matched robust-normal fits; 25 was selected
as an upper-tail cap just above this range. These diagnostics supplied an
external calibration scale only. MFCL estimated the DM parameter internally
and calculated `N_eff = Nmax(1 + lambda)/(Nmax + lambda)`, which approaches
25 smoothly as `lambda` increases. The selected value was evaluated using
composition and CPUE fits, convergence, parameter bounds, and Hessian
stability.

The Step 09 value `parest 313=1` is retained through the normal-likelihood
pathway and its comparison branches, then explicitly reset to `0` in Step 20c
because the DM likelihood does not use that percentage threshold. Its
length-bin support is controlled by `parest 320=5`.

## Interpretation limits

- `Nmax=25` does not mean that length-frequency data receive 25 observations in every period.
- `Nmax=25` is not a 95% weight and is not a hard clipping rule applied to Francis estimates.
- DM still estimates overdispersion and relative composition information within the imposed upper asymptote.
- The numerical asymptote is specific to the BET 2026 data and model configuration and should be reassessed if those inputs change.

## Method reference

Thorson, J.T., Johnson, K.F., Methot, R.D., and Taylor, I.G. (2017).
[Model-based estimates of effective sample size in stock assessment models
using the Dirichlet-multinomial distribution](https://doi.org/10.1016/j.fishres.2016.06.005).

The MFCL definition and transformation are documented in the
[MULTIFAN-CL user manual](https://github.com/PacificCommunity/ofp-sam-mfcl-manual/blob/4503c2abd234f3be95ec73e4375cf19df69859e2/MFCL-manual_MASTER.pdf)
(Section 5.5.4 and Appendix A, pp. 198-199) and implemented in
[`len_dm_nore.cpp`](https://github.com/PacificCommunity/ofp-sam-mfcl/blob/151cee309f4a1a523e28ba9b23869cda1f102782/src/len_dm_nore.cpp#L136-L162).
The assessment-specific 95th-percentile calibration is recorded in the
[BET 2026 exploration repository](https://github.com/PacificCommunity/ofp-sam-bet-2026-exploration/blob/c940601bb95797a5cc5b4a2dbc01cfd6daa86a70/README.md#nmax-calibration).
