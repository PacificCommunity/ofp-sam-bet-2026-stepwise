# BET 2026 tag-recapture dispersion sensitivity

Tag-recapture counts may be more variable than independent Poisson observations
because recaptures can be clustered by trip, fleet, area and reporting process.
The sensitivity therefore estimates the direct negative-binomial dispersion
parameter, tau, for either all active recapture fisheries combined or three
programme-informed recapture-fishery strata. Larger tau implies greater
extra-Poisson variation and less effective influence from that stratum.

The programme-informed configuration separates (i) F1, F12 and F13, which
contain 141 of 151 post-mixing JPTP recaptures (93.4%); (ii) F25-F28, which
contain 2,239 of 2,405 post-mixing recaptures from PTTP Region 4 releases
(93.1%); and (iii) the remaining active recapture fisheries. This is not a
release-programme-specific likelihood: MFCL indexes tau by recapture fishery
through fish flags 43 and 44. The strata are therefore proxies for programme
and recapture processes, and tau differences should not be interpreted as
differences in tuna behaviour. The complete executable mapping is recorded in
`config/tag-tau-program-informed-map.csv`.

The 96 independent fits cross the tag-dispersion structure with Region 5 index
selectivity, regional recruitment-distribution coefficient, standard or
orthogonal-polynomial recruitment (OPR), the OPR composition effective-sample-
size upper bound, and fixed or late-estimated natural mortality. The native
MFCL tau bound and a common-tau lower bound of 2 are evaluated; the
programme-informed configuration uses the native bound. Natural mortality is
fixed at -2.54930339768360 through Phase 10 and, where requested, is estimated
only in Phases 11-12.

Kflow labels the primary fits consecutively from 1 to 72. Within each six-fit block,
the order is common tau with the native bound, common tau with lower bound 2,
and programme-informed tau with the native bound; each setting is run first
with fixed natural mortality and then with late-estimated natural mortality.
Fits 73-96 repeat the 24 fixed-M, Nmax-25 combinations with parest flag
177=500, which multiplies the tag-recapture likelihood by 0.50. Their matched
primary fits retain the full likelihood weight through the special flag value
zero. This targeted comparison evaluates tag influence without adding
interactions with M estimation or Nmax 1,000.

| Sensitivity | Recruitment | F33 selectivity | Recruitment coefficient | Nmax |
|---:|---|---|---:|---:|
| 1-6 | Standard | Asymptotic | 0.1 | 25 |
| 7-12 | Standard | Asymptotic | 0.2 | 25 |
| 13-18 | Standard | Four-node spline | 0.1 | 25 |
| 19-24 | Standard | Four-node spline | 0.2 | 25 |
| 25-30 | OPR | Asymptotic | 0.1 | 25 |
| 31-36 | OPR | Asymptotic | 0.1 | 1,000 |
| 37-42 | OPR | Asymptotic | 0.2 | 25 |
| 43-48 | OPR | Asymptotic | 0.2 | 1,000 |
| 49-54 | OPR | Four-node spline | 0.1 | 25 |
| 55-60 | OPR | Four-node spline | 0.1 | 1,000 |
| 61-66 | OPR | Four-node spline | 0.2 | 25 |
| 67-72 | OPR | Four-node spline | 0.2 | 1,000 |
| 73-78 | Standard, tag weight 50% | Asymptotic | 0.1-0.2 | 25 |
| 79-84 | Standard, tag weight 50% | Four-node spline | 0.1-0.2 | 25 |
| 85-90 | OPR, tag weight 50% | Asymptotic | 0.1-0.2 | 25 |
| 91-96 | OPR, tag weight 50% | Four-node spline | 0.1-0.2 | 25 |

All fits retain the SC22-IP10 K=0.15 mixing periods, reporting-rate groups and
priors, Dirichlet-multinomial eight-group composition structure, CPUE settings,
data and selectivity sharing outside F33. The OPR configurations use the BET
2026 72-01-50-50 structure, with a two-real-year end window. Nmax is 25 except
for paired OPR sensitivities using the MFCL default of 1,000.

The fixed reporting-rate specification contains 31 group identifiers, of which
12 unique groups are active and estimated. Group 1 is shared by RTTP and PTTP.
F29-F33 and all other inactive programme-fishery combinations have zero
initial value, target and penalty.

| Programme | Active group | Fisheries | Initial mean | Target | Penalty |
|---|---:|---|---:|---:|---:|
| RTTP | 1 | F1, F2, F4-F10 | 0.5000 | 50.00 | 1.0 |
| RTTP | 6 | F14-F18, F21-F22 | 0.5000 | 50.00 | 1.0 |
| RTTP | 7 | F19-F20 | 0.4962 | 49.62 | 354.5 |
| RTTP | 10 | F25, F27 | 0.5121 | 51.21 | 739.2 |
| PTTP | 1 | F1, F2, F4-F10 | 0.5000 | 50.00 | 1.0 |
| PTTP | 13 | F14-F18, F21-F22 | 0.5000 | 50.00 | 1.0 |
| PTTP | 14 | F19-F20 | 0.4962 | 49.62 | 354.5 |
| PTTP | 17 | F25, F27 | 0.5121 | 51.21 | 739.2 |
| PTTP | 18 | F26, F28 | 0.5282 | 52.82 | 231.2 |
| JPTP | 19 | F1 | 0.5000 | 50.00 | 1.0 |
| JPTP | 20 | F2, F4-F10 | 0.5000 | 50.00 | 1.0 |
| JPTP | 23 | F12-F13 | 0.5000 | 50.00 | 1.0 |
| JPTP | 29 | F25, F27 | 0.5000 | 50.00 | 1.0 |

Report interpretation should focus on whether the programme-informed strata
require materially different tau estimates and whether this changes the
tag-index balance, model stability or key derived quantities without degrading
fit to other data sources.
