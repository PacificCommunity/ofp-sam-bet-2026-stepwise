# F33 Index R5 selectivity robustness

## Scientific parent and frozen controls

The Index R5 sensitivities use fitted Job 19326 as the scientific parent.
F10 remains the two-parameter MFCL asymptotic logistic and F1-F3 are tested
with either their Job 19326 five-node splines or the independently estimated
four-node treatment used by Job 19600. All data and non-selectivity controls
remain frozen.

F33 contains 292 quarterly records. Twenty-four records contain 95-bin length
compositions, of which 21 have a raw sample-size sum of at least the model's
50-observation filtering threshold. These historical samples span 1965-1996,
so the functional-form test is not a CPUE-only sensitivity.

## MFCL controls

The MFCL manual's age-specific selectivity section defines:

- fish flag 57=1: two-parameter asymptotic logistic using fish pars 9 and 10;
- fish flag 57=3: cubic spline with the node count in fish flag 61;
- fish flag 16=1: a non-decreasing selectivity penalty; and
- fish flag 56: the non-decreasing penalty weight.

The manual also states that fish flag 16 should not be combined with the
flag-57 functional forms. The implementation in `selectivity_form_penalty()`
uses a default weight of 1,000,000 when flag 56 is zero and adds
`weight * decline^3` for every decrease in selectivity. The logistic
implementation is asymptotic and normalizes the terminal age to one.

F33 is shared with the other regional indices during early staged fits and
becomes an independent selectivity group in Phase 5. Each F33 treatment is
therefore activated only after the Phase-5 group separation. This retains the
exact Job 19326 initialization through Phase 4 and avoids mixing incompatible
flag-16 or flag-57 settings within a shared selectivity group.

## Penalty strength

The fitted Job 19326 F33 curve is already non-decreasing, so its added penalty
is zero at the parent fit. Applied without re-optimizing to the two archived
low-depletion jitter curves, a weight of 1,000,000 contributes approximately:

| Archived fit | F33 terminal selectivity | Added penalty |
|---|---:|---:|
| seed 2 | 0.835 | 28.5 |
| seed 20 | 0.641 | 300.7 |

Seed 2 improves the unpenalized objective by approximately 922 units relative
to Job 19326, so the default penalty cannot offset that advantage at the
archived curve. The corresponding break-even weight is approximately
32.3 million. The selected 100-million weight is about 3.1 times that value
and contributes approximately 2,854 units at the archived seed-2 curve.

This calculation motivates the pre-specified strength but does not assume the
re-optimized model cannot find another route to the same depletion basin.
Seeds 2 and 20 are therefore required stress tests for every sensitivity.

## Job 19326 retrospective evidence

The peel-specific PAR and REP files are embedded as compressed artifacts
inside each archived `retro_info.rds`, even though the visible top-level
`final.par` in the compact worker archive is the unpeeled parent copy. Direct
recovery of those REP artifacts shows that only the 2018 terminal-year peel
(peel 6) enters the low-depletion pattern:

- terminal depletion 0.1703;
- F33 peak at age 15 and terminal selectivity 0.7414;
- F29 terminal selectivity 0.8431;
- F1-F3 terminal selectivities 1.0000, 0.8753, and 1.0000; and
- time-invariant regional recruitment shares R1=0.2906 and R5=0.1105,
  compared with Job 19326 R1=0.1160 and R5=0.2508.

All six other peels retain an asymptotic F33 curve with terminal selectivity
1.0 and have terminal depletion between 0.292 and 0.347. The 2018 peel is
therefore closely related to the archived seed-2/seed-20 basin: it combines an
R1-heavy/R5-light recruitment allocation, higher older-age selectivity in the
Region-1 fisheries and F29, and a dome-shaped F33. At the unreoptimized 2018
curve, the F33 non-decreasing contribution is about 108.8 under the MFCL
default weight and 10,877 under the selected 100-million weight.

## Factorial sensitivity

The four new independent fits are:

| F1-F3 spline nodes | F33 treatment |
|---:|---|
| 5 | flag 57=1 logistic |
| 5 | flag 57=3 five-node spline; flags 16=1 and 56=100,000,000 |
| 4 | flag 57=1 logistic |
| 4 | flag 57=3 five-node spline; flags 16=1 and 56=100,000,000 |

Job 19326 and Job 19600 provide the corresponding five-node and four-node F33
unconstrained controls. Evaluation must compare convergence, objective and
likelihood components, F33 length-composition residuals, F1-F3/F29/F33
selectivity, regional recruitment allocation, depletion, and the seed-2 and
seed-20 restart results.
