# F10 selectivity-robustness candidates

## Objective

The Job 18718 fitted base curve and the lowest-objective jitter solution
(seed 14) should be retained as closely as possible, while preventing the
distinct low-depletion basin represented by seed 10. Two soft-penalty
treatments and one deliberately restrictive asymptotic logistic treatment
are compared.

## Diagnostic evidence

F10 `LL.ALL.5` remained a five-node cubic spline in all compared fits.
The values below are spline coefficients on the model scale, not
selectivity probabilities.

| Fit | Node 4 | Node 5 | Node 5 - node 4 | Terminal-knot ratio |
| --- | ---: | ---: | ---: | ---: |
| Job 18718 base | 0.6677 | 0.6909 | 0.0233 | 1.024 |
| Jitter seed 14 | 0.8074 | 0.5109 | -0.2965 | 0.743 |
| Jitter seed 10 | 0.8814 | 0.0478 | -0.8336 | 0.434 |

The fitted F10 selectivity at age was:

| Age | Job 18718 base | Seed 14 | Seed 10 | Existing retro range |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 1.000 | 0.960 | 0.804 | 0.963-0.999 |
| 30 | 0.967 | 0.765 | 0.462 | 0.776-0.984 |
| 40 | 0.960 | 0.741 | 0.430 | 0.754-0.977 |

Across the 25 converged jitter fits, the F10 fifth spline coefficient had a
Spearman correlation of 0.827 with terminal depletion. Seed 10 was the only
fit below 0.400 for this coefficient. Its objective was 694.31 units higher
than seed 14.

## Regional biomass evidence

The archived fitted parameters for all 25 converged jitters were evaluated
with the tuna-flow v2.5 executable in plot mode, without re-optimizing. Seed
10 was the lowest of the 25 fits for every Area 5 quantity below:

| Terminal 2024 quantity | Seed 10 / Job 18718 base | Seed 10 / other-jitter median | Rank |
| --- | ---: | ---: | ---: |
| F10 `LL.ALL.5` vulnerable biomass | 0.443 | 0.449 | 1/25 |
| F33 `Index R5` vulnerable biomass | 0.709 | 0.556 | 1/25 |
| Area 5 adult biomass | 0.581 | 0.568 | 1/25 |
| Area 5 total biomass | 0.480 | 0.454 | 1/25 |

Area 5 represented 15.1% of terminal total biomass in seed 10, compared with
23.8% in the base and a 24.0% median across the other jitters. This was not an
isolated F10 scaling effect: seed 10 also had the lowest Area 1 and highest
Area 3 and Area 4 biomass among the 25 fits. The declining F10 tail therefore
identifies a distinct solution with a broader spatial redistribution of
biomass, rather than only changing the F10 vulnerable-biomass definition.
Regional index vulnerable biomasses are reported separately because
fishery-specific selectivities make their cross-area sums non-comparable as a
population biomass total.

## Manual and source-code interpretation

The MFCL manual defines:

- fishery flag 16 = 1 as the non-decreasing-selectivity constraint;
- fishery flag 56 as its penalty weight;
- fishery flag 57 = 1 as two-parameter asymptotic logistic selectivity;
- fishery flag 57 = 3 as cubic-spline selectivity; and
- fishery flag 61 as the number of estimated spline nodes.

The tuna-flow v2.5 source confirms that flag 16 = 1 adds
`weight * sum(decline^3)` over decreases in the estimated selectivity curve.
If flag 56 is zero, the source uses a default weight of 1,000,000; otherwise
it uses the explicit flag-56 value. The five spline coefficients remain
estimated because flags 57 = 3 and 61 = 5 are unchanged.

The rendered manual table contains `10-6` for the default weight. The
executable source uses `1.e+6`; the two candidates therefore record explicit
weights to remove that ambiguity.

## Candidate comparison

Applying the source-code penalty formula to the existing fitted curves gives:

| Fit | Weak weight 10,000 | Default weight 1,000,000 |
| --- | ---: | ---: |
| Job 18718 base | 0.0049 | 0.49 |
| Seed 14 | 1.22 | 121.64 |
| Seed 10 | 14.46 | 1,445.57 |

The weak candidate is the primary base-preserving treatment. The explicit
default candidate tests whether a much stronger non-decreasing constraint is
needed to eliminate the low-depletion basin. The third candidate sets F10
flag 57 to 1, replacing the spline with the manual-defined asymptotic logistic
curve while estimating the two parameters stored in `fish_pars(9:10)`. It
does not need flag 16 or flag 56 because the logistic form is inherently
non-decreasing.

Acceptance requires comparison with Job 18718 for objective, maximum
gradient, F10 selectivity and derived quantities, followed by jitter and
retrospective checks. No candidate is selected in advance.
