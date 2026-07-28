# Full-reg John selectivity stable-doitall sensitivity

## Scope

This campaign contains two independent fits from `bet.ini`:

1. standard mean-plus-deviation recruitment; and
2. OPR 72-01-50-50 with the last-two-real-year end window.

Both retain the recent full-reg model controls: F15 length intervals below
70 cm removed, DOM F21-F23 intervals with midpoint above 90 cm removed,
F14/F15 youngest five selectivity ages fixed at zero, regional scaling over
model periods 3-292, Nmax 25, fixed natural mortality, common estimated tag
tau, recruitment-distribution penalty 0.1, and movement-prior coefficient
0.1.

The only scientific model changes common to both rows are:

- F2/F3 shared selectivity is constrained to be non-decreasing; and
- F33 changes from logistic selectivity to an unconstrained four-node cubic
  spline.

## Selectivity decision

The MFCL manual states that fisheries sharing fish flag 24 must have identical
fish flags 3, 16, 26, 57, 61, 62 and 75. F2 and F3 already share group 2.
Applying fish flag 16 only to F2 would therefore be an internally inconsistent
description of a shared curve. The sensitivity sets fish flag 16 to 1 for both
F2 and F3 and verifies that all seven grouping-sensitive settings match.

MFCL source applies the fish-flag-16 penalty fishery by fishery to the
calculated incident selectivity, while the spline coefficients are shared
through fish flag 24. The requested F2 constraint consequently acts on the
same shared F2/F3 curve. Keeping the group avoids adding another selectivity
curve and confounding the monotonicity sensitivity with an unsharing
sensitivity.

F33 retains fish flags 3=37, 26=2 and 75=2, but uses flags 16=0, 57=3 and
61=4. Here, “unconstrained” means no logistic form and no non-decreasing or
dome-shape penalty; the model's existing youngest- and terminal-age controls
remain.

The inherited Phase-5 comment claimed that index selectivity groups were
separated there, but the source script already assigned independent F29-F33
groups 27-31 in Phase 1. Repeating those switches did not open parameters.
The revised schedule keeps the final index selectivity groups from Phase 1
and does not change spline dimensions between PAR files. This avoids an
unnecessary parameter-remapping path and leaves index CPUE grouping as the
only real index-group change later in the fit.

## Numerical schedule

MFCL source maps parest flag 50 directly to the optimizer criterion as
`10^flag50`; therefore -2, -3 and -4 mean MGC targets of 1e-2, 1e-3 and
1e-4. Parest flag 1 is the maximum function-evaluation budget, not a required
number of evaluations.

The executable was built from `testnewl3.cpp`, not the older `newl3.cpp`.
That source selects quasi-Newton with parest flag 351=0 and limited-memory
Newton with flag 351=1; flag 192 controls the number of saved update pairs.
The manual recommends the default angle bound and about 400 saved terms for a
large-parameter fit, while noting that quasi-Newton generally performs best
for moderate systems. The schedule consequently uses quasi-Newton for the
306-466 parameter pre-recruitment system, LMN400 after recruitment opens the
roughly 1,000-2,000 parameter system, and an independent quasi-Newton
confirmation at the end.

Parest flag 152 reads `gradient.rpt`, checks that its stored active-parameter
count equals the current count, and rescales by `0.1 + abs(previous
gradient)`. Matching dimension alone is not sufficient: the objective must
also be unchanged. Rescaling is therefore restricted to an immediate
stabilization stage after the same model block.

| Stage | Change | Max eval. | MGC | Optimizer / scaling |
|---|---|---:|---:|---|
| 1 | Initial active block, including revised selectivity | 1,500 | 1e-1 | QN, native |
| 2 | DM relative-sample-size exponent | 1,200 | 1e-1 | QN, native |
| 3 | Standard or OPR recruitment | 2,000 / 2,500 | 1e-1 | LMN400, native |
| 4A | Average regional recruitment, or OPR stabilization | 1,500 / 2,500 | 1e-1 / 1e-2 | LMN400, native / rescaled |
| 4B | Full-period regional-scaling penalty | 1,500 | 1e-1 | LMN400, native |
| 4C | Separate regional-index CPUE groups | 1,800 | 1e-1 | LMN400, native |
| 4D | Movement | 2,500 | 1e-1 | LMN400, native |
| 5 | Same-objective spatial stabilization | 4,000 | 1e-2 | LMN400, rescaled |
| 6 | Mean growth | 1,800 | 1e-1 | LMN400, native |
| 7A | Length-at-age variance | 1,500 | 1e-1 | LMN400, native |
| 7B | Same-objective growth stabilization | 3,000 | 1e-2 | LMN400, rescaled |
| 8 | Open SRR | 1,800 | 1e-1 | LMN400, native |
| 9A | Relax SRR penalty and F bound | 2,000 | 1e-2 | LMN400, native |
| 9B | Same-objective SRR stabilization | 3,000 | 1e-3 | LMN400, rescaled |
| 10 | Common tag tau | 3,000 | 1e-2 | LMN400, native |
| 11 | Same-objective final fit | 10,000 | 1e-4 | LMN400, rescaled |
| 12 | Final confirmation and `indepvar.rpt` | 7,000 | 1e-4 | QN, native |

The loose 1e-1 intermediate criterion follows the manual's explicit advice
to obtain approximate solutions rapidly until the final phase. Precision is
added only after a complete interacting block is open. This is faster than
forcing every transient model to 1e-2 or 1e-3 and is more stable than carrying
a poorly solved SRR surface directly into tau.

MFCL stdout is tee-streamed to the Kflow job log (`MFCL_LIVE_LOG=true`) while
the complete phase logs are retained in the output archive. This permits live
inspection of objective values, MGC and phase progress.

### Why this parameter order

1. **Selectivity first.** It directly controls the LF prediction surface and
   the new F2/F3 and F33 forms must exist before DM sample-size scaling is
   estimated.
2. **DM CEST next.** The exponent weights composition residual information;
   estimating it before the selected LF curves exist would calibrate it to a
   transient selectivity model.
3. **Recruitment before spatial penalties.** Standard recruitment opens the
   large time-by-region block; OPR replaces that block with its polynomial
   basis. Regional scaling acts on the resulting regional population
   trajectory, so it follows recruitment.
4. **Regional scaling, then index CPUE groups.** The regional-scaling target is
   introduced before index catchability/likelihood groups are separated,
   avoiding simultaneous changes to the objective and index parameter
   dimension.
5. **Movement after recruitment and regional scaling.** Movement redistributes
   the regional population and is strongly confounded with both. It is opened
   separately and the entire spatial block is then rescaled and stabilized.
6. **Growth mean before growth variance.** Source allocation shows flags
   12-14 add the von Bertalanffy mean parameters and flags 15-16 add
   length-at-age variance parameters. Opening mean and variance together
   creates an avoidable scale/shape trade-off.
7. **SRR before tau.** SRR adds/changes population-dynamics curvature and its
   penalty is relaxed in a separate native-scale stage. Only after a rescaled
   SRR stabilization is the single common tag-overdispersion parameter opened.
8. **Final rescaled fit, then native QN confirmation.** This separates rapid
   high-dimensional convergence from the final independent check that the
   reported MGC is not an artifact of temporary coordinate scaling or one
   minimizer implementation.

The live full-reg jobs 17821-17828 provided a numerical cross-check. In the
OPR example, baseline external Phases 8 and 9 each exhausted 500 evaluations
with final MGC about 0.53 and 0.55, and the common-tau phase was still running
after more than 2,300 evaluations. That is the empirical reason for the new
9A/9B split and for stopping native tau at 1e-2 before the rescaled final fit.

## Sources reviewed

- Exact tuna-flow v2.6 MFCL source commit
  `a5a83cd6e8aef512d22890234c40b0fa465843eb` (parent
  `origin/ongoing-dev` `aad7241ca72634ef7509038e1bcb5fcfb957df04`):
  `src/testnewl3.cpp`, `src/newmult.cpp`, `src/newmau5a.cpp`,
  `src/alldevpn.cpp`, `src/rshort1.cpp`, and `src/newm_io3.cpp`.
- MFCL manual commit `4503c2abd234f3be95ec73e4375cf19df69859e2`:
  *Running MULTIFAN-CL*, *Model overview*, *Interpreting results*, and the
  flag appendix.
- [ADMB minimizer manual](https://ftp.admb-project.org/admb-11.2/manuals/autodif-11.2.pdf):
  convergence criteria and maximum-function-evaluation behavior.
- [ADMB optimizer tips](https://www.admb-project.org/docs/tutorials/admb-tips.html):
  interpretation of maximum gradient.
- [WCPFC description of the MULTIFAN-CL doitall approach](https://meetings.wcpfc.int/file/5568/download):
  progressive freeing of parameters across phases.

The staged schedule improves the numerical path but does not itself prove
that the final solution is a local minimum. Final MGC, objective trajectory,
parameter bounds, Hessian eigenvalues, and model diagnostics must still be
checked from the completed output archive.
