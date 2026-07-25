# 22 Tag-recapture dispersion sensitivity

This post-selection sensitivity estimates negative-binomial tag-recapture
dispersion (`tau`) while retaining the Step 21a data and model specification.
MFCL assigns tau by recapture fishery, so JPTP and PTTP Region 4 scenarios use
recapture-fishery proxies rather than release-programme parameters.

## Design

| Setting | Specification |
| --- | --- |
| Parent specification | Step 21a / Job 15989: final DM model, Job 15984 selectivity grouping, SC22-IP10 K=0.15 mixing |
| Group structures | Ten nested structures, from one common tau to 19 data-supported recapture-fishery strata |
| Tau lower bounds | 2, 3 and 4; corresponding starts are 3, 4 and 5 |
| JPTP proxy | F1, F12 and F13: 141 of 151 post-mixing JPTP recaptures |
| PTTP Region 4 proxy | F25-F28: 2,239 of 2,405 post-mixing recaptures from Region 4 releases |
| Index fisheries | F29-F33 inactive for tau because they contain no tag recaptures |

The complete structures are in `config/tag-tau-scenarios.csv`; their executable
maps are defined in `model/tag_tau_scenarios.sh`.

## Held constant

Fixed Lorenzen natural mortality (`-2.54930339768360`), reporting-rate groups,
initial values, priors and penalties, DM G8 weighting with `Nmax=25`, the
F2/F3/F29 shared selectivity and all other Step 21a controls are unchanged.
No fixed tag-likelihood multiplier is applied.

## Validation gate

Before full fits, Job 15984 final-par smoke tests must confirm that the G01,
G05 and G10 structures open exactly 1, 4 and 19 tau parameters, respectively.
