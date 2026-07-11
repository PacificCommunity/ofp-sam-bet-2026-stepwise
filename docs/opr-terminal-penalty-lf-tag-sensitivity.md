# Step 11/12 terminal-recruitment sensitivity

This experiment asks why recruitment increases sharply near the end of the
BET model and whether that behaviour can be reduced without trading it for a
poorer historical fit, a different population scale, or weak identifiability.
It separates five mechanisms: annual OPR complexity, the terminal boundary
and penalty, LF/selectivity structure, length-composition weight, and recent
tag information. Ordinary recruitment deviations from Step 11 provide the
non-OPR comparison.

This is a diagnostic experiment. A smaller spike, a lower objective, or a
positive-definite Hessian does not by itself identify an assessment model. A
terminal control can move pressure to the first unconstrained quarter, and a
different tag likelihood or dataset changes the statistical problem being
fitted.

## Reproducibility basis

| Item | Value |
| --- | --- |
| Parent inputs | `11-TimeVaryingCV` and `12-OrthogonalPoly` from `main` when this branch was created |
| Candidate annual OPR counts | 73, 72, and 71; seasonal/region/interaction counts fixed at `01-50-50` |
| Generated-model LF default | All reviewed F12/F17/F20/F26/F28 changes, with required propagation to grouped F18/F27 partners |
| MFCL executable | MULTIFAN-CL `2.2.7.9`, assessment executable dated 2026-07-11 |
| Source audit | `ofp-sam-mfcl` `ongoing-dev` commit [`b3984d5e40096eecfa506a3d768f76ef59a32688`](https://github.com/PacificCommunity/ofp-sam-mfcl/commit/b3984d5e40096eecfa506a3d768f76ef59a32688) |
| Guide audit | `ofp-sam-mfcl-manual` `master` commit [`1266ff1107e67fa9321d5c704bb9a6103e07ae23`](https://github.com/PacificCommunity/ofp-sam-mfcl-manual/commit/1266ff1107e67fa9321d5c704bb9a6103e07ae23) |
| Machine-readable design | [`opr-terminal-penalty-lf-sensitivity-grid.csv`](opr-terminal-penalty-lf-sensitivity-grid.csv) |

Existing OPR, tag, reporting-rate, likelihood, fishery, and composition-weight
controls were checked against the public development source and guide. The
terminal-recruitment flag `parest_flags(397)` follows the supplied `2.2.7.9`
executable specification because that completed implementation is newer than
the audited public source commit.

## Curated model grid

There are 73 generated sensitivities and one unchanged Step 11 control, for 74
fits. Other unchanged stepwise models are omitted because they add no
information to this experiment.

| Family | Generated fits | Purpose |
| --- | ---: | --- |
| Annual OPR count x penalty | 15 | Cross 73/72/71 at the same four-quarter endpoint with penalty weights 0, 25, 50, 100, and 200. |
| Endpoint window | 9 | Compare 72/end2, 71/end2, and 71/end3 at weights 0, 100, and 200; the first and last are the saturated boundaries. |
| Endpoint-free OPR | 3 | Compare 73/72/71 with no multi-year OPR endpoint and no terminal penalty. |
| LF/selectivity structure | 9 | Compare the reviewed group-consistent default, original controls, exact-five-only diagnostic, and isolated LF mechanisms. |
| Length-composition weight | 6 | Compare uniform LF divisors 40 and 80 at each of the central OPR 73/72/71 cases without changing WF weight. |
| Tagging structure | 21 | Stage tag weight, observation model, 2021 reporting-rate/mixing assumptions, dominant-release deletion, and one full-2021 deletion. |
| OPR trend penalty | 2 | Test trend weights separately from the terminal-mean penalty. |
| Standard recruitment deviations | 5 | Compare a pure free endpoint, 4/8-quarter endpoints, and two tag-attribution cases before OPR; unchanged Step 11 supplies the inherited 6-quarter control. |
| Supplied flag-221 compatibility pair | 2 | Compare the received OPR71/end3 flag-221 setting with a matched flag-zero control. |
| Supplied benchmark reproduction | 1 | Reproduce one reported OPR69 result exactly; excluded from candidate selection. |

This is not a full Cartesian product. The sequence is deliberate: establish
the penalty response, check whether LF structure or LF weight explains it,
attribute remaining pressure to tag assumptions, and then rerun only plausible
structures at stricter convergence.

## Why 73, 72, and 71

The FRQ spans 1952--2024, which gives 73 real calendar years. In the OPR
implementation `parest_flags(155)` is the annual coefficient count and the
polynomial degree is one less than that count. With annual terminal pooling,
the valid ceiling is:

```text
annual coefficient ceiling = 74 - max(1, parest_flags(202))
```

The corresponding saturated boundary pairs are therefore:

| Annual count | `parest_flags(202)` | Fixed terminal period | Role |
| ---: | ---: | ---: | --- |
| 73 | 1 | 4 quarters | Fully saturated annual effect with one terminal calendar year. |
| 72 | 2 | 8 quarters | Saturated annual effect with two terminal calendar years. |
| 71 | 3 | 12 quarters | Saturated annual effect with three terminal calendar years. |

The central 73/72/71 comparison holds `parest_flags(202)=1` for all three so
only annual complexity changes. Separate 72/end2 and 71/end3 rows test the
coupled endpoint boundary. A 73/end2 model and every annual-count 74 model are
excluded because they exceed the source-derived ceiling. The seasonal,
regional, and season-by-region counts remain `1`, `50`, and `50`; “73 is
saturated” refers only to the annual OPR component, not to every recruitment
cell being independent.

### Flag-221 compatibility check

One supplied OPR71/end3 case also sets `parest_flags(221)=71`:

```text
parest_flags(155) = 71
parest_flags(221) = 71
parest_flags(216) = 50
parest_flags(217) = 1
parest_flags(202) = 3
```

The Step 12 parent interaction count `parest_flags(218)=50` is retained. In
the audited public `ongoing-dev` source, active OPR code takes the annual count
from flag 155; the old flag-221 override block is commented out, and the guide
appendix marks parest flag 221 obsolete. The grid therefore contains a matched
pair with original Step 12 LF controls, no terminal penalty, and flag 221 set
to 0 versus 71. Public-source behaviour predicts identical fits. A difference
under `2.2.7.9` would identify executable-specific behaviour and should be
confirmed before that setting is used biologically. Neither row is a final
candidate.

## Terminal-recruitment controls

The new terminal penalty is active only when all three supplied conditions
hold: `parest_flags(397)>0`, `parest_flags(155)>0`, and
`parest_flags(202)>0`.

| Control | Interpretation here |
| --- | --- |
| `parest_flags(397)` | Terminal-recruitment penalty; actual weight is `flag/10`, so weights 25, 50, 100, and 200 use 250, 500, 1000, and 2000. |
| `parest_flags(202)` | Terminal calendar years; multiply by `age_flags(57)=4` for quarters. |
| `parest_flags(210/212/214)` | Component endpoints; `0` inherits the annual endpoint and `-1` explicitly disables multi-year pooling. |
| `parest_flags(153)` | OPR trend penalty; `-1` is off, `0` uses the default 0.01, and a positive value is `flag/10`. |
| `parest_flags(400)` | Fixed terminal quarterly deviations in standard-recruitment controls. |
| `parest_flags(398)` | Arithmetic-mean treatment for fixed standard recruitment deviations. |

Every generated OPR case starts from its newly fitted Step 12 `11.par` and
receives the same 1,000-evaluation phase to `12.par`. Weight-zero rows receive
the same phase and are therefore matched optimisation controls.

The single benchmark reproduction uses `69-01-50-50`, end2, terminal penalty
flag 1000 (weight 100), and the same extra 1,000 evaluations. It reproduces the
reported 8-quarter result and is labelled `supplied-benchmark`; it is not a
candidate model and does not justify using 69 in the main grid.

Quarterly recruitment must be inspected before as well as inside the terminal
window. A spike that moves to the first free quarter is a boundary response,
not evidence that the underlying data conflict has disappeared.

## Reviewed LF/selectivity default

All generated core, tag, trend, and standard-recruitment cases use these
reviewed, group-consistent controls by default:

```text
-20 16 0   -20 3 37
-27 16 0   -27 3 37
-28 16 0   -28 3 37
-26 75 1
-12 75 2
-17 16 2   -17 3 6
-18 16 2   -18 3 6
```

The model-fit rationale for each change is:

| Fishery | Change | Reason tested |
| --- | --- | --- |
| F20, F28 | Restore default large-fish tail (`ff16=0`, `ff3=37`). | The inherited restriction prevents prediction of observed large fish. |
| F26 | `ff75=1`. | The model predicts age-1 catch where none is observed. |
| F12 | `ff75=2`. | The model predicts age-1/2 catch where none is observed. |
| F17 | `ff16=2`, `ff3=6`. | The inherited setting over-predicts larger fish. |
| F27, F18 | Match the paired F20 and F17 controls, respectively. | MFCL fish flag 24 groups F20/F27 and F17/F18, and the guide requires other selectivity-feature flags to be identical within each group. |

All five requested changes are therefore retained, and F20/F17 are propagated
to their grouped partners rather than leaving an internally inconsistent flag
set. Three `review_exact` rows deliberately apply only the five listed changes
as a grouping diagnostic. Three original-control rows and three
isolated-mechanism rows distinguish the direct fit gain from grouped and
individual effects. Fits must be checked for all seven fisheries.

## Length-composition weight

MFCL fish flag 49 is the divisor used to convert an LF sample size to its
effective size. The parent uses divisor 20 for most fisheries and 40 for an
inherited lower-weight subset. A larger divisor gives less LF influence.

The design uses two global settings at each of the OPR 73/72/71 central
penalty cases. They are appended after every inherited fishery-specific switch,
because MFCL applies those switches in order and the last value wins:

| Uniform divisor | Role | Effective-N implication |
| ---: | --- | --- |
| 40 | Moderate, already used by the later Step 15 weighting convention. | Leaves inherited divisor-40 fisheries unchanged and halves the 21 divisor-20 fisheries. |
| 80 | Strong diagnostic. | Halves every LF effective sample size relative to uniform 40. |

The current FRQ contains 2,612 LF samples and no WF samples; after the existing
minimum-sample rule, 2,399 LF samples contribute. Fish flag 50, which controls
weight-composition sample sizes, is unchanged. These models test
whether LF information contributes to the recruitment spike; they are not a
proposal to choose a weight after seeing which one flattens recruitment.

## Recent-tag attribution

The parent has two August 2021 releases with very different information:

| Release group | Region | Effective releases | Recaptures | Parent mixing period |
| --- | ---: | ---: | ---: | ---: |
| 18 | 1 | 215.316 | 5 | 2 quarters |
| 60 | 4 | 3,324.809 | 1,061 | 1 quarter |

Release group 60 begins with 6,177 raw releases and a correction factor near
0.5383; 1,056 of 1,061 recaptures occur in F25--F28. It can therefore carry
much more recent abundance information than group 18. The curated tag rows are:

| Block | Fits | Question |
| --- | ---: | --- |
| Tag-likelihood weight | 3 | Does the response decline smoothly at likelihood scalars 0.3, 0.1, and 0.03? |
| Observation model | 3 | Compare recaptures-conditioned likelihood, one pooled direct-tau dispersion parameter, and a robust binned-gamma diagnostic. |
| Pre-mixing treatment | 2 | Compare all-release pre-mixing reporting treatment with and without the terminal penalty. |
| 2021 reporting rate/mixing | 8 | Test a pooled campaign prior, a dominant-release prior, central/wider prior precision, all-release treatment, and group-60 mixing periods 2/4; repeat central cases at 72/71. |
| Release deletion | 5 | Attribute group 60 at 73 with/without penalty and at 72/71 with penalty, plus remove both 2021 releases once as the full-deletion upper bound. |

The central 2021 reporting-rate target remains 0.52015. Its penalty 485.2 is
an approximate prior SD of 0.032 under the source implementation
`penalty * (rate - target)^2`; the wider penalty 48.52 gives an approximate SD
of 0.102. The target is not moved after inspecting recruitment. Campaign rows
pool releases 18 and 60 across F25--F28 into one new reporting-rate group;
dominant-release rows apply that grouping only to release 60. Sparse cells are
not split into release-by-fishery parameters.

Changing the group-60 mixing period changes which returns receive the regular
tag treatment, so it is a biological/observation-process sensitivity rather
than a harmless numerical switch. The group-60 cases consistently set the
source/manual-supported pre-mixing reporting treatment. The deletion rows are
last-resort attribution tests: they rebuild TAG, the FRQ tag count, every MFCL
1007 tag section, and the reporting map, then start from a fresh `-makepar`.
They are not automatic proposals to discard data.

Raw objective values are not directly comparable after changing tag data,
tag likelihood family, or likelihood weight. A reporting-rate structure is
credible only if the fitted rate remains interior and compatible with its
prior, observed/predicted returns improve by fishery/year/time-at-liberty,
other cohorts remain stable, and weak Hessian directions are not dominated by
recent recruitment and reporting rate.

## What to compare

1. Plot quarterly and annual recruitment, including at least eight quarters
   before the constrained window. Report terminal/historical arithmetic means
   and the terminal-penalty contribution.
2. Check whether the response is smooth across penalty weights and whether the
   spike moves to the first free quarter. Track historical recruitment,
   spawning potential, depletion, fishing mortality, and population scale.
3. Compare LF fits and selectivity for F12, F17, F18, F20, F26, F27, and F28;
   compare the uniform-40/uniform-80 LF-weight response separately.
4. Split observed/predicted tag returns by release, recapture year/quarter,
   fishery, region, and time at liberty. Report the reporting-rate prior and tag
   likelihood components separately.
5. Report objective components, maximum gradient, convergence code, and
   parameters at bounds. Compare raw objectives only for identical data,
   likelihood family, and weight.
6. Report Hessian availability, positive-definite status, non-positive
   eigenvalue count, smallest eigenvalues, and dominant parameter blocks in
   weak eigenvectors. Loadings identify directions to investigate; they do not
   prove a biological cause.

Shortlisting requires stable biology and fit, no displaced spike, acceptable
gradients, and a positive-definite Hessian at `1e-4`. A proposed assessment
case must then retain those properties when rerun at `1e-5`.

## Kflow execution

The isolated launcher targets Suva and keeps each diagnostic independent:

```text
74 independent fits
       |
       +--> one Hessian per fit (nsplit=1 because model count is >50)
                |
                +--> one per-fit merge that attaches only the Hessian delta
                         |
                         +--> one results/MFCL Shiny fan-in from 74 models
```

The complete flow is 74 fit jobs, 74 Hessian jobs, 74 merge/attach jobs, and
one results job: 223 jobs. Diagnostic branches depend only on their own fit,
not on one another. Each merge preserves the compact base payload and adds
only its diagnostic delta, so FRQ/INI/TAG/PAR content is not duplicated. A
failed or non-positive-definite Hessian remains visible with its failure and
non-positive eigenvalue counts.

The launcher defaults to `1e-4` for phases 10/11 and the matched phase 12. Use
`--phase-convergence -5`, or set `BET_PHASE10_11_CONVERGENCE=-5`, for a
shortlisted rerun. Generated steps remain disabled in the ordinary `all`
workflow; only this launcher sets `STEPWISE_ALLOW_DISABLED_SELECTED=true`.

Refresh deterministic thin folders:

```bash
Rscript R/prepare_opr_terminal_penalty_lf_sensitivity.R --overwrite
```

Choose a generated ID from the CSV and run it locally:

```bash
STEP_SELECT=<generated-step-id> \
STEPWISE_ALLOW_DISABLED_SELECTED=true \
BET_PHASE10_11_CONVERGENCE=-4 \
PROGRAM_PATH=/path/to/mfclo64 \
Rscript R/run_stepwise.R
```

Preview registration and all jobs without submission:

```bash
python3 scripts/register_opr_terminal_penalty_lf_task.py --dry-run
python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --dry-run
```

After the branch is pushed and previews pass, omit `--dry-run` to update the
isolated task or launch the flow. The launcher writes a resumable manifest in
ignored `work/`; resume that manifest rather than starting a duplicate flow.

## Public technical references

- [MULTIFAN-CL user guide repository](https://github.com/PacificCommunity/ofp-sam-mfcl-manual)
- [Analyses of tagging data for tropical tunas, with implications for WCPO bigeye assessments](https://meetings.wcpfc.int/file/2787/download)
- [Developments in MULTIFAN-CL 2018--19](https://meetings.wcpfc.int/file/7107/download)
- [Recapture-conditioned integrated tagging model performance](https://doi.org/10.1016/j.fishres.2019.105451)
- [MULTIFAN-CL assessment diagnostics](https://meetings.wcpfc.int/file/7797/download)
- [Tag-seeding reporting rates for 2023 BET/YFT assessments](https://meetings.wcpfc.int/file/13013/download)
- [Tag-release corrections for 2023 BET/YFT assessments](https://meetings.wcpfc.int/file/13015/download)
- [Tag mixing periods for the 2026 WCPO assessments](https://meetings.wcpfc.int/file/21121/download)
