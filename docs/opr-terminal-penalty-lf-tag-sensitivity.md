# Step 11/12 terminal-recruitment sensitivity

This experiment tests why recent recruitment can spike near the end of the
BET model and whether that behaviour can be reduced without materially
changing the historical fit or population scale. It separates four possible
causes: the OPR terminal boundary, length-frequency/selectivity controls,
recent tagging assumptions, and the ordinary recruitment-deviation
parameterisation used before OPR.

The experiment is diagnostic. A smaller terminal spike, a lower objective, or
a positive-definite Hessian is not sufficient on its own to select an
assessment model. In particular, a terminal constraint can move a spike to the
first unconstrained quarter, and a tag deletion or different tag likelihood
changes the statistical problem being fitted.

## Reproducibility basis

| Item | Value |
| --- | --- |
| Parent models | `11-TimeVaryingCV` and `12-OrthogonalPoly` from the `main` baseline used to create this experiment branch |
| OPR form | `69-01-50-50` |
| MFCL executable | MULTIFAN-CL `2.2.7.9`, assessment executable dated 2026-07-11 |
| Source audit | `ofp-sam-mfcl` `ongoing-dev` commit [`b3984d5e40096eecfa506a3d768f76ef59a32688`](https://github.com/PacificCommunity/ofp-sam-mfcl/commit/b3984d5e40096eecfa506a3d768f76ef59a32688) |
| Full generated grid | [`opr-terminal-penalty-lf-sensitivity-grid.csv`](opr-terminal-penalty-lf-sensitivity-grid.csv) |

Existing OPR, tag, reporting-rate, likelihood, and fishery controls were
checked against the `ongoing-dev` source and the MULTIFAN-CL guide. The new
terminal-recruitment control, `parest_flags(397)`, follows the `2.2.7.9`
executable interface: that completed implementation is newer than the audited
public source commit, so its behaviour is not inferred from the older source.

## Model grid

There are 114 generated sensitivities and two unchanged parents, for 116 fits
in total.

| Family | Generated fits | Purpose |
| --- | ---: | --- |
| Terminal penalty by selectivity | 22 | Cross one- and two-year terminal windows with penalty weights 0, 25, 50, 100, and 200; compare current and group-consistent fishery controls, plus the exact five-fishery proposal at weight 100. |
| Isolated selectivity effect | 6 | Separate the large-fish tail, unobserved young ages, and F17/F18 upper-age hypotheses at the central penalty weight. |
| Tagging diagnostics | 74 | Test tag weight, observation model, overdispersion, reporting rates and their prior precision, mixing, tag loss, and targeted 2021 release deletions in four structural contexts, including two combined final-candidate screens. |
| OPR trend penalty | 4 | Separate the OPR trend penalty from the terminal-mean penalty for one- and two-year windows. |
| Standard recruitment controls | 8 | Repeat key terminal and tag tests with ordinary quarter-specific recruitment deviations from Step 11. |
| Unchanged parents | 2 | Preserve the Step 11 and Step 12 baselines. |

The four tag contexts are deliberately not a full Cartesian product:

- C1: one-year terminal window, no terminal penalty, current fishery controls;
- C2: one-year terminal window, penalty weight 100, current controls;
- C3: one-year terminal window, penalty weight 100, group-consistent controls;
- C4: two-year terminal window, penalty weight 100, group-consistent controls.

This staging identifies the source of a response with substantially fewer
models than multiplying every tag option by every penalty and selectivity
setting.

## Terminal-recruitment controls

The new penalty is active only when all three conditions hold:
`parest_flags(397)>0`, `parest_flags(155)>0`, and
`parest_flags(202)>0`.

| Control | Interpretation in this experiment |
| --- | --- |
| `parest_flags(397)` | Activates the terminal-recruitment penalty. The actual weight is `flag/10`, so weights 25, 50, 100, and 200 use flags 250, 500, 1000, and 2000. |
| `parest_flags(202)` | Number of terminal calendar years. The number of terminal model periods is `parest_flags(202) * age_flags(57)`; `age_flags(57)=4`, so values 1 and 2 mean four and eight quarters. |
| `parest_flags(155)` | Activates the OPR parameterisation in the Step 12 parent. |
| `parest_flags(153)` | OPR trend penalty: `-1` is off, `0` retains the MFCL default weight 0.01, and a positive value uses `flag/10`; the added value `1` therefore means 0.1. |
| `parest_flags(400)` | Number of fixed terminal quarterly deviations in the Step 11 standard-recruitment controls: 0, 4, or 8. |
| `parest_flags(398)` | Enables the arithmetic-mean terminal treatment for the fixed Step 11 cases. |

Every generated OPR case receives the same final 1,000-evaluation phase from
`11.par` to `12.par`. Weight-zero models receive this phase too, which makes
them matched optimisation controls rather than shorter runs.

The main diagnostic is not simply whether the last four or eight quarters are
flat. Quarterly recruitment must also be inspected immediately before the
terminal window. A spike that moves to that boundary indicates displacement
of model pressure rather than removal of its cause.

## Length-frequency and selectivity controls

The exact five-fishery treatment is retained as a diagnostic:

```text
-20 16 0   -20 3 37
-28 16 0   -28 3 37
-26 75 1
-12 75 2
-17 16 2   -17 3 6
```

Fish flag 16 controls the selectivity tail form, fish flag 3 supplies the
associated upper-age cutoff where applicable, and fish flag 75 fixes the
first age classes near zero. The changes test whether previously restricted
large-fish predictions in F20/F28, predicted but unobserved young catches in
F12/F26, and over-predicted large fish in F17 are contributing to the fit and
terminal recruitment response.

The current model shares selectivity groups between F20/F27 and F17/F18. The
exact proposal is therefore intentionally group-inconsistent. The primary
structural comparison propagates the same controls to F27 and F18, while the
six isolated models test the large-fish tail, young-age, and F17/F18 changes
separately. Report both the target fisheries and their shared-group partners;
an improvement in one fishery can otherwise conceal a deterioration in the
other.

## Why the 2021 tag releases are tested

The parent inputs contain two August 2021 releases with very different
information content:

| Release group | Release region | Effective releases | Recaptures | Parent mixing period |
| --- | ---: | ---: | ---: | ---: |
| 18 | 1 | 215.316 | 5 | 2 quarters |
| 60 | 4 | 3,324.809 | 1,061 | 1 quarter |

Release group 60 starts from 6,177 raw releases and a correction factor of
about 0.5383; 1,056 of its 1,061 recaptures occur in fisheries 25-28. It can
therefore carry far more recent abundance information than release group 18.
The grid distinguishes them before interpreting a combined deletion.

Deletion is the last attribution test, not the default remedy. The preferred
sequence is to check observed-versus-predicted returns, likelihood weight,
the conditional observation model, reporting-rate structure, pre-mixing
treatment, and plausible overdispersion before deciding whether a release is
incompatible with the model assumptions.

### Tag controls and caveats

| Sensitivity | MFCL control | Question and limitation |
| --- | --- | --- |
| Likelihood dose response | `parest_flags(177)=300,100,30,1` | Scales the tag likelihood to 0.3, 0.1, 0.03, and 0.001. A zero flag is full weight. Reporting-rate priors remain active, so 0.001 is not a literal no-tag model. |
| Recaptures-conditioned likelihood | `parest_flags(249)=1` | Emphasises relative recapture patterns rather than absolute recapture magnitude. It changes the observation model and cannot be ranked against the base case by raw objective alone. |
| Pooled tag overdispersion | `fish_flags(43)=1`, `fish_flags(44)=1`, `parest_flags(305)=1`, `parest_flags(306)=0` | Estimates one shared direct-tau dispersion parameter. Because flag 305 also switches the negative-binomial parameterisation from the legacy fish-parameter form, this is a compound observation-model diagnostic and not a stand-alone final-model candidate. |
| Binned gamma | `parest_flags(111)=5`, `parest_flags(325)=110` | Uses the binned-gamma tag likelihood and bins observed counts below 1.1. |
| Robust binned gamma | `parest_flags(111)=6`, `parest_flags(325)=110`, `parest_flags(326)=50` | Adds a 0.05 robust mixture. This is an outlier sensitivity, not a mechanism for tuning away an inconvenient cohort. |
| 2021 reporting-rate group | rows 18/60, fisheries 25-28, new group 30 | Separates the dominant recent campaign cells from inherited reporting-rate group 17 using only one additional parameter. |
| Combined reporting-rate candidate | central campaign prior plus `tag_flags(:,2)=1` in C2/C3 | Tests the reporting-rate structure together with the manual-recommended pre-mixing treatment. C3 also uses group-consistent LF controls and is the main final-candidate screen. |
| Wider 2021 reporting-rate prior | penalty 485.2 to 48.52 | Retains target 0.52015 while widening the approximate prior SD from 0.032 to 0.10. This tests prior conflict without a release-by-fishery parameter expansion. |
| Dominant-release prior response | row 60, fisheries 25-28, new group 30; penalties 485.2, 121.3, 48.52, 12.13, and 0 | Keeps the externally derived target at 0.52015 while relaxing prior SD from 0.032 to 0.064, 0.102, 0.203, and finally an unpenalised identifiability endpoint. The five cases are repeated in C2 and C3. |
| Pre-mixing reporting treatment | `tag_flags(18/60,2)=1`, group 60 only, or `tag_flags(:,2)=1` | Excludes uncertain reporting-rate correction during the selected releases' pre-mixing periods. The parent has column 2 set to zero for all releases. |
| Group-60 mixing period | `tag_flags(60,2)=1`; 1, 2, 3, or 4 quarters | Brackets the imputed mixing period while consistently applying the source/manual-recommended pre-mixing reporting-rate treatment. It changes which recaptures enter the regular tag likelihood; it does not remove late recaptures. |
| Fixed tag loss | `parest_flags(360)=1`, shed rate 0.021/quarter | Transfers an external 0.084/year bigeye double-tagging estimate to a quarterly approximation. It is a diagnostic because the estimate is not Pacific-specific. |
| Targeted deletion | group 18, group 60, or both | Rebuilds TAG, FRQ, all MFCL 1007 tag sections, and reporting maps together, then starts from a fresh `-makepar`. There are 97 release groups after one deletion and 96 after both. |

For group 60, increasing the mixing period moves approximately 183, 532,
881, and 991 of the 1,061 recaptures into the pre-mixing treatment at one,
two, three, and four quarters, leaving 878, 529, 180, and 70 in the regular
fit. A longer mixing period can therefore reduce tag influence very strongly.
It must be interpreted as a mixing-assumption sensitivity, not as a harmless
technical setting. The 2021 values are regional imputations rather than
release-specific estimates, which is why the bracket is included. The
one-quarter `TagMixRR60` case and the Q2-Q4 `TagMixRR60Q*` cases all set
`tag_flags(60,2)=1`; a mixing-period result is therefore not confounded with
the inherited, nonrecommended column-2 treatment.

The deletion cases synchronise the `.tag` release and recovery blocks, the
FRQ tag count, the tag flags and tag-shed vector, all five reporting-rate
matrices (while retaining the pooled row), and `tag_rep_map.R`. A fitted
98-release PAR is never reused after changing the release count.

### Reporting-rate prior interpretation

The `ongoing-dev` implementation adds
`penalty * (reporting_rate - target)^2` once for each reporting-rate group.
The guide therefore gives `variance = 1 / (2 * penalty)`. The prior target is
fixed at 0.52015 in every new case; it is not moved after looking at the
recruitment result. The response grid is:

| Penalty | Approximate prior SD | Role |
| ---: | ---: | --- |
| 485.2 | 0.032 | Externally informed central case. |
| 121.3 | 0.064 | One-quarter of the central precision. |
| 48.52 | 0.102 | One-tenth of the central precision. |
| 12.13 | 0.203 | Very weak-prior diagnostic. |
| 0 | unpenalised | Identifiability stress test only. |

Release group 60 has 358, 671, 19, and 8 recaptures in F25-F28,
respectively. One parameter is therefore pooled across those four fisheries;
the sparse F27/F28 cells do not support a further release-by-fishery split.
The campaign-level parameter shared by rows 18 and 60 with penalty 485.2 is the
most plausible grouping because both releases belong to the same programme and
month. The two `TagRR2021MixAll` cases combine that central prior with the
manual-recommended `tag_flags(:,2)=1` pre-mixing treatment; C3 also carries the
group-consistent LF controls and is the main reporting-rate final-candidate
screen. Campaign-prior-only cases remain interaction diagnostics. The group-60
central case tests whether the dominant release alone carries the conflict.
Wider and zero-penalty cases measure prior sensitivity and are not promoted
merely because they flatten recruitment.

A reporting-rate model can be considered further only if the central prior
case removes the spike without moving it to an adjacent quarter, its fitted
rate remains interior and reasonably consistent with the external prior,
group-60 observed/predicted returns improve by fishery, year, and time at
liberty, other cohorts and likelihood components remain stable, and the model
has clean gradients and a positive-definite Hessian. If only a weak or
unpenalised prior removes the spike, the rate approaches its near-one upper
bound, or a weak Hessian direction is dominated by reporting rate and recent recruitment,
the result is evidence of confounding rather than a final-model solution.

## What to compare

Use the following evidence together:

1. Plot quarterly and annual recruitment, including at least eight quarters
   before the terminal window. Report the terminal-to-historical arithmetic
   mean ratio and the terminal penalty contribution.
2. Check whether a penalty response is smooth across weights and whether a
   spike reappears in the first unconstrained quarter. Record changes in the
   historical recruitment series, spawning potential, depletion, fishing
   mortality, and overall population scale.
3. Compare length-frequency fits and residuals for F12, F17, F20, F26, and
   F28, plus the shared-group fisheries F18 and F27. Inspect estimated
   selectivity rather than objective change alone.
4. Split tag observed/predicted returns by release group, recapture year and
   quarter, fishery, region, age/size, and time at liberty. Report `O/E` and,
   where compatible with the likelihood, standardised residuals such as
   `(O-E)/sqrt(tau*E)` and squared residuals relative to `E`.
5. Report total objective and components, the maximum gradient, convergence
   code, estimated parameters at bounds, and the reporting-rate prior and tag
   likelihood contributions separately.
6. Report Hessian status for every model: available or failed,
   positive-definite or not, number of non-positive eigenvalues, smallest
   eigenvalues, and the parameter blocks with the largest loadings in weak
   eigenvectors. Loadings identify directions to investigate; they do not by
   themselves prove a biological cause.

Raw objectives are comparable only for models fitted to the same data with
the same likelihood family and weighting. Do not rank deletion,
recaptures-conditioned, negative-binomial, and binned-gamma models in one
objective-value table. A positive-definite Hessian is useful evidence about
local identifiability, but it does not establish biological plausibility or a
good data fit.

## Kflow execution

The isolated launcher uses Suva and keeps every model independent:

```text
116 independent fits
        |
        +--> 1 Hessian job per fit (nsplit=1 because the grid has >50 models)
                 |
                 +--> 1 Hessian merge per fit
                          |  delta overlay attached directly to that fit
                          |  no separate attachment job
                          v
                 1 results/MFCL Shiny fan-in from 116 merged models
```

The full flow has 116 fit jobs, 116 Hessian jobs, 116 merge/attach jobs, and
one results job (349 jobs total). Each base fit keeps one exact patched native
restart set; its fitted PAR remains compressed inside `model_payload.rds`.
This is required because tag-deletion and reporting-rate inputs cannot safely
be reconstructed from the unmodified parent. A merge publishes only the
Hessian delta and preserves the compact base-model payload, so FRQ/INI/TAG/PAR
content is not repeated in diagnostic outputs. Results are allowed to retain
failed-Hessian status, so a non-PDH or
failed diagnostic remains visible rather than being presented as a normal
Hessian result.

The isolated task and launcher default to a `1e-4` convergence criterion for
MFCL phases 10/11 and the matched phase-12 refinement, keeping the broad
screening grid practical. This remains configurable: pass
`--phase-convergence -5` to
the launcher, or set `BET_PHASE10_11_CONVERGENCE=-5` in Kflow/local execution,
for shortlisted production reruns. A candidate should retain stable estimates,
gradients, and Hessian diagnostics under the stricter setting before adoption.

Generated sensitivities are disabled in the ordinary `all` workflow. Only the
isolated launcher explicitly selects them and sets
`STEPWISE_ALLOW_DISABLED_SELECTED=true`.

Generate or refresh the thin model folders:

```bash
Rscript R/prepare_opr_terminal_penalty_lf_sensitivity.R --overwrite
```

Run one model locally with a native MFCL executable:

```bash
STEP_SELECT=12p008-E1-W100-FGroup \
STEPWISE_ALLOW_DISABLED_SELECTED=true \
PROGRAM_PATH=/path/to/mfclo64 \
Rscript R/run_stepwise.R
```

Review task registration and the complete launch without submitting jobs:

```bash
python3 scripts/register_opr_terminal_penalty_lf_task.py --dry-run
python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --dry-run
```

After the experiment branch is pushed and the previews are checked, omit
`--dry-run` to register the isolated task and launch the flow. The launcher
writes a resumable manifest under the ignored `work/` directory. Use
`--resume --manifest <manifest>` after an interrupted submission; do not start
a second flow for the same manifest.

## Public technical references

- [MULTIFAN-CL user guide repository](https://github.com/PacificCommunity/ofp-sam-mfcl-manual)
- [Analyses of tagging data for tropical tunas, with implications for the structure of WCPO bigeye stock assessments](https://meetings.wcpfc.int/file/2787/download)
- [Developments in the MULTIFAN-CL software 2018-19](https://meetings.wcpfc.int/file/7107/download)
- [Parameter estimation performance of a recapture-conditioned integrated tagging catch-at-age analysis model](https://doi.org/10.1016/j.fishres.2019.105451)
- [Developing a set of diagnostics and outputs for MULTIFAN-CL stock assessments](https://meetings.wcpfc.int/file/7797/download)
- [Analysis of tag seeding data and reporting rates for purse seine fleets](https://meetings.wcpfc.int/file/10950/download)
- [Tag-seeding reporting-rate analysis for the 2023 bigeye and yellowfin assessments](https://meetings.wcpfc.int/file/13013/download)
- [Analysis of tagging data for the 2023 bigeye and yellowfin tuna assessments: corrections to tag releases for tagging conditions](https://meetings.wcpfc.int/file/13015/download)
- [Estimation of tag mixing periods for the 2026 WCPO tuna stock assessments](https://meetings.wcpfc.int/file/21121/download)
- [Tag-shedding rates for tropical tuna species in the Atlantic Ocean estimated from double-tagging data](https://doi.org/10.1016/j.fishres.2021.106211)
