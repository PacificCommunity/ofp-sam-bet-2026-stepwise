# MFCL control notes

This note records the operational meaning of the principal MFCL controls used
in the BET 2026 stepwise models. It makes the generated `doitall.sh` files
auditable without requiring readers to infer control meanings from abbreviated
labels.

The definitions were checked against the MULTIFAN-CL User's Guide and the
`ongoing-dev` source used for the assessment executable. The executable remains
the authority if a future MFCL revision changes a control.

## Natural mortality

| Control | Value | Operational meaning |
| --- | ---: | --- |
| `age_pars(5,1:2)` | `-2.54930339768360, -1` | Fixed Lorenzen natural-mortality intercept and length slope carried from Step 04 onward. |
| `parest 121` | `0` | Estimate no natural-mortality `age_pars(5)` coefficients in that staged run; Lorenzen mortality remains active using the incoming parameter values. |

Flag 121 is the number of estimated natural-mortality `age_pars(5)`
coefficients. Under the Lorenzen formulation, a value of two would estimate the
intercept and length slope. It is not a switch that turns Lorenzen mortality on
or off.

## CPUE indices and regional scaling

| Control | Value | Operational meaning |
| --- | ---: | --- |
| Fish flag 99 | fishery/group ID | Stationary-catchability and CPUE likelihood group identifier. A separate ID separates that index from other groups; it does not by itself establish statistical independence. |
| Fish flag 92 | `35, 24, 21, 24, 23` | Fixed CPUE observation-error scales `0.35, 0.24, 0.21, 0.24, 0.23`, stored by MFCL as integer percentages. |
| Fish flag 94 | `1` in the initial shared group | Use each fishery's flag-92 error scale within the shared flag-99 group. It returns to zero after separate flag-99 groups are introduced. |
| Fish flag 66 | `1` | Use normalized time-varying relative-variance multipliers supplied in the frequency data. |
| Parest 77-81 | assessment settings | Configure the assessment-specific regional-scaling penalty comparing CPUE-derived regional shares with model relative vulnerable abundance. This is separate from the ordinary CPUE likelihood. |

Step 12 introduces the time-varying relative-variance multipliers. Step 13
separately fixes the CPUE observation-error scales selected from stable
preliminary fishery-specific maximum-likelihood calibrations and carries them
across later comparisons. The archived unrounded estimates were `0.354`,
`0.237`, `0.212`, `0.239`, and `0.225`; MFCL executes their flag-92
representations shown above.

## Tag reporting rates

| Input | Operational meaning |
| --- | --- |
| Tag flag column 1 | Number of mixing periods for the release group. |
| Tag flag column 2 = `1` | Do not apply reporting rates to predicted recaptures during those pre-mixing periods; post-mixing reporting rates are unchanged. |
| Reporting-rate setup | Includes initial values, fishery grouping, estimation switches, prior targets, and penalty weights; it is broader than a penalty-only update. |

## Selectivity

| Fish flag | Operational meaning |
| ---: | --- |
| 3 | Terminal spline age and the age from which the older-age dome penalty is applied. |
| 16 = `2` | Apply the older-age dome penalty from the flag-3 age onward. With cubic-spline flag 57 = 3, the penalty weight is 100. |
| 16 = `0` | Switch off the dome/old-age-tail form penalty. Step 15b has 15 active flag-16 controls; Step 16 reconfigures the applicable fleet set for the revised structure and uses `0` for all 14 resulting fisheries. |
| 24 | Selectivity coefficient-sharing group. Fisheries in the same group must have compatible selectivity controls. |
| 26 = `2` | Evaluate selectivity against scaled mean length-at-age. |
| 57 = `3` | Cubic-spline selectivity. |
| 61 = `7` | Seven estimated cubic-spline nodes for fisheries 25 and 26. |
| 75 = `0` | No youngest age classes are forced to near-zero selectivity for fisheries 25 and 26. |

Fisheries 25 and 26 use separate selectivity-sharing groups. Regional index
fisheries 29-33 share a group in the early staged fits and are separated in
staged run 5; the carried parameter file preserves those controls thereafter.

## Length-composition weighting

| Control | Value | Operational meaning |
| --- | ---: | --- |
| Fish flag 49, fisheries 21-23 | `200` | Divide observed length-frequency sample totals by 200 to reduce the influence of the un-reweighted DOM samples. |
| Fish flag 49, Francis step | fishery-specific | Apply external Francis divisors while retaining the normal length-frequency likelihood. This is weighting, not a Francis likelihood family. |
| Parest 141 | `11` | Dirichlet-multinomial length-frequency likelihood without random effects. |
| Parest 311 | `1` | Enable tail-compressed observed and predicted length-frequency arrays. |
| Parest 313 | `1` from Step 09 through Step 20b; `0` in Step 20c | Aggregate length-frequency tails below 1% for the normal-likelihood pathway and comparisons. Reset it to zero in the selected DM model because this percentage threshold is inactive there. |
| Parest 303 | `0` | Keep weight-frequency percentage tail aggregation off after the assessment converts all compositions to length. |
| Parest 320 | `5` | Use the tail-compressed DM path when the first-to-last-positive observed span contains at least five bins. |
| Parest 342 | `25` | Upper asymptote of the transformed DM effective sample size, `Nmax = 25`. |

For Step 20c, `parest 141=11` selects `len_dm_nore()`, and `parest 320=5`
constructs its support from the first to last positive observed length bin.
That function reads the original length frequencies, not the percentage-tail
array constructed with flag 313. Step 20c therefore explicitly resets
`313=0`, with an inline note that the DM likelihood does not read this
percentage threshold. Resetting it also avoids any unrelated percentage-tail
preprocessing and avoids implying that 1% aggregation defines the selected
model; `320=5` is the active DM support control.

`Nmax` is not a hard cap applied directly to Francis effective sample sizes.
MFCL estimates the DM parameter internally and maps it to an effective sample
size that approaches `Nmax` asymptotically. Preliminary Francis diagnostics
were used only to select a defensible external scale for that asymptote.

## Staged fitting

Each numbered block in `doitall.sh` is a sequential MFCL run. It reads the
parameter file written by the previous run, applies the controls in its
here-document, estimates the active parameters, and writes the next parameter
file. These numbered runs should not be confused with MFCL
parameter-estimation phases inside a run.

Important timing in the final stepwise configuration:

- Most CPUE, selectivity, and DM controls are introduced in staged run 1.
- The DM relative-sample-size exponent is released in staged run 2.
- `REGW100` and separation of regional-index selectivity groups are introduced
  in staged run 5 and persist through the carried parameter file.

## Sources checked

- [MULTIFAN-CL User's Guide](https://mfcl.spc.int/index.php?Itemid=116&catid=3&cid=195&m=0&option=com_jdownloads&view=finish),
  accessed 23 July 2026.
- MFCL `ongoing-dev` production-source revision
  `de4abeca920063bf234ce66ec3a0f043c56e885f`, reviewed locally.
- Public MFCL source cross-check revision
  `624dee4f3a9cb4063fde2c3fbd2521dbf907d161`.
