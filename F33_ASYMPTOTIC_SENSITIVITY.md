# BET 2026 Region 5 index selectivity sensitivity

The Region 5 longline index (F33) was retained as an independent observation
process and its four-node cubic spline was replaced by a two-parameter
asymptotic logistic selectivity. No extraction fishery shares selectivity or
catchability with F33.

This constraint was tested because the retained F33 size data are sparse:
24 quarterly compositions from 1965-1996 inform a CPUE series spanning
292 quarters from 1952-2024. Peatman et al. (2026) likewise identify the
Region 5 index compositions as sparse. The independently fitted spline was
already effectively asymptotic, providing no evidence for a descending limb.
The logistic form therefore removes weakly informed terminal-age flexibility
without imposing an extraction-fishery selectivity on the index.

The sensitivity retains the S01 extraction-only sharing (F2/F3 and F7/F9),
independent F29-F33 selectivities and catchabilities, fixed Lorenzen natural
mortality, Dirichlet-multinomial composition weighting with eight fishery
groups and \(N_{\max}=25\), SC22-IP10 \(K=0.15\) tag-mixing periods,
reporting-rate priors, CPUE settings and all other model inputs. It is run with
the tuna-flow v2.6 MFCL executable, which applies tag flag 2 consistently by
excluding reporting rates from expected pre-mixing tag returns.

The logistic form should be retained only if index and composition fits are
not materially degraded and Hessian, jitter or retrospective performance
improves.

## Reference

Peatman, T., Castillo-Jordán, C., Teears, T., Magnusson, A., Kim, K., Hampton,
J., & Hamer, P. (2026). *Analysis of size frequency data for the 2026 bigeye
and yellowfin assessments*. WCPFC-SC22-2026-SA-IP06. Western and Central
Pacific Fisheries Commission. <https://meetings.wcpfc.int/node/32346>
