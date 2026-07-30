# Final mixing-period explorations

Each directory is a complete, independent MFCL working directory. No file is
borrowed from another exploration at run time.

| Directory | Tag likelihood and tau treatment |
| --- | --- |
| `tau-estimated/K*` | Negative binomial; one common F1-F28 tau is estimated |
| `tau-not-estimated-step20c/K*` | Negative binomial; Step 20c treatment with no estimated tau |

Each mode contains `K005`, `K010`, `K015`, `K020`, `K025`, and `K030`,
corresponding to region-mean mixing thresholds 0.05 through 0.30.

The non-INI inputs are frozen from the actual Job 17805 archive and are
byte-identical to those in the actual Job 18386 archive. Each `bet.ini` uses
the corresponding tag-mixing vector from
`SC22-IP10-regionMean@efe3107c72774ee73b5e6dc45e44cf51f0fc20e8`, with the
fixed log-M replaced by the verified Job 18386 value
`-2.54930339768360e+00`.

Every folder retains the Job 17805/18386 controls: F15 observations below
70 cm and domestic-fishery observations with midpoint above 90 cm are already
removed from `bet.frq`; DM `Nmax=25`; M remains fixed; recruitment and
movement penalties are 0.1; and OPR is off. The two modes differ only in the
final tag-tau treatment described above. The Step 20c mode does not turn the
tag likelihood into Poisson: it retains negative-binomial flag 111=4, leaves
fish flags 43/44 inactive, and estimates zero `fish_pars(4)` parameters.

`bet.reg_scaling` contains the active 20-by-5 matrix without the four-value
tuna-flow v2.6 header, because these explorations target tuna-flow v2.5.
`MANIFEST.sha256` covers every run-time file in its directory.
