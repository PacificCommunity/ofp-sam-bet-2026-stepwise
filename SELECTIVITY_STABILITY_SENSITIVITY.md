# BET 2026 selectivity-stability sensitivity

## Report-ready rationale

A selectivity-stability sensitivity was prepared to test whether limited sharing
among comparable longline extraction fisheries could improve numerical and
retrospective stability while retaining model fit. Regional index fisheries were
assigned independent selectivities because their size compositions were weighted
by estimated relative abundance and restricted to weight samples from Japanese
longliners, whereas extraction-fishery compositions were weighted by catch.
Selectivity was shared only for two longline extraction pairs with compatible
gear and spatial definitions and similar fitted curves: the Region 1 fisheries
F2 and F3, and the Region 3-West fisheries F7 and F9. The associated purse-seine
fisheries F19, F25 and F26 remained independent, and the Job 15989 spline-node
settings were retained. All biological, catchability, tagging,
composition-likelihood and data-weighting settings were held constant.

## Model specification

| Component | Sensitivity setting | Basis |
| --- | --- | --- |
| Regional indices | F29-F33 independent; Job 15989 node settings retained | Index compositions have a distinct relative-abundance weighting and sampling process. Independent selectivities prevent extraction-fishery compositions from constraining the index observation process. |
| Region 1 longline extraction | F2 + F3 shared; four nodes | Same region and gear class, both treated as catch-weighted extraction fisheries; the independently fitted curves were similar. |
| Region 3-West longline extraction | F7 + F9 shared; five nodes | Same region, gear class and extraction-fishery reweighting framework; fitted curves were similar. |
| Associated purse seine | F19, F25 and F26 independent; F25/F26 retain seven nodes | The selected Step 16 configuration introduced independent, flexible curves to address structured composition residuals. Retaining that choice protects the existing purse-seine fit. |
| Region 2 unassociated purse seine | F20 independent; five nodes | F20 was not similar to the regional unassociated fisheries F27-F28; no new constraint is imposed. |
| Other fisheries | Independent; existing node settings retained | No additional sharing was supported jointly by fishery definition and fitted-curve similarity. |

The screening metric was the root-mean-square difference between selectivity at
age over the 40 model age classes. Representative fitted-curve differences were
0.091 for F2/F3 and 0.074 for F7/F9. These values support testing the
specified pooling but do not establish that the fisheries must share
selectivity.

The sensitivity has 154 independently estimated spline coefficients compared
with 140 in the Job 15989 reference configuration. The increase results from
separating F29-F32 from extraction-fishery curves; sharing F7/F9 partially
offsets that increase. All fishery-specific node settings are otherwise
unchanged. The sensitivity retains fixed Lorenzen natural mortality,
Dirichlet-multinomial composition weighting with eight fishery groups and
\(N_{\max}=25\), SC22-IP10 \(K=0.15\) release-group mixing periods, the
reporting-rate specification, regional CPUE settings and all other
non-selectivity controls. It should be evaluated against the reference fit using
objective-function components, composition and CPUE residuals, Hessian
definiteness, jitter convergence, retrospective patterns and derived
stock-status quantities. It will be retained only if the overall and component
fits are not materially degraded and numerical or retrospective stability
improves.

## Interpretation

Peatman et al. (2026) describe the fishery definitions and size-composition
preparation used here; they do not prescribe selectivity sharing. The tested
groups are therefore an assessment-model sensitivity informed jointly by those
data-generating processes and the fitted selectivity curves. The paper also
recommends time-block selectivities for longline fisheries that switch from
weight-as-length to observed-length compositions. Time blocking is not included
here so that this run isolates the effect of fishery grouping.

## Reference

Peatman, T., Castillo-Jordán, C., Teears, T., Magnusson, A., Kim, K., Hampton,
J., & Hamer, P. (2026). *Analysis of size frequency data for the 2026 bigeye
and yellowfin assessments*. WCPFC-SC22-2026-SA-IP06. Western and Central
Pacific Fisheries Commission. <https://meetings.wcpfc.int/node/32346>
