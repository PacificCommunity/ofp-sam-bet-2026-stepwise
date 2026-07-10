# Terminal-recruitment sensitivity grid

This branch is an isolated, explicit-select-only sensitivity suite for the
terminal recruitment spike. It does not alter the ordinary main workflow:
`STEP_SELECT=all` still contains the 17 enabled main models.

The suite contains **95 fit jobs**: the current Step 11 and Step 12 controls,
plus 93 new variants. Every new folder copies its parent inputs byte-for-byte;
only `model/doitall.sh`, its step README, and the manifest note differ.

## Why this grid exists

The final recruitment estimate can absorb poorly identified information near
the terminal data boundary. In the standard model, the last recruitment
deviations are handled with `parest_flag(400)` and optionally `398`. In OPR,
those controls are turned off and the terminal behavior instead depends on the
orthogonal-polynomial endpoint controls. A better objective value alone is not
enough: fit, recruitment plausibility, scale/depletion, and Hessian diagnostics
must agree.

The current frequency data span 1952–2024: 73 real years. MFCL source defines
`155`, `217`, `216`, and `218` as coefficient counts (not raw polynomial
degrees). The annual capacity therefore depends on its effective terminal
window:

| Effective terminal window | Maximum annual coefficient count |
| ---: | ---: |
| one-point endpoint / `end0` | 73 |
| `end2` | 72 |
| `end3` | 71 |
| `end4` | 70 |
| `end5` | 69 |

`end0` means no effective multi-year terminal tie; MFCL still normalizes it to
a one-point endpoint. Thus `73/end2` is invalid, while `73/end0` and
`72/end2` are valid, scientifically distinct comparisons. The generator has a
source-capacity guard to reject invalid future combinations before any Kflow
job is submitted.

## Model families

| Family | New models | What varies |
| --- | ---: | --- |
| Standard recruitment deviations | 5 | no terminal constraint, 1/2/4-quarter arithmetic-mean constraints, and six zero-deviation terminal quarters |
| OPR endpoint/saturation | 15 | annual vs component endpoint windows, saturated valid ceilings, and retained endpoint linear/quadratic terms |
| Earlier OPR screening settings | 9 | `69-05-50-50`, `69-01-60-60`, and `69-05-60-60`, each with meaningful endpoint comparisons |
| Annual OPR count | 9 | 55–71 annual coefficients under `end2`/`end3`, including a retained-linear-term ceiling test |
| Component OPR count | 15 | regional, season-by-region, and seasonal count reductions/increases |
| Broad OPR envelope | 40 | parsimonious `69-01-01-01`, `69-01-10-10`, `69-69-69-69`, valid all-effect saturation boundaries, and directional component tests |

The exact machine-readable specifications are in
[`R/step12_terminal_sensitivity_config.R`](../R/step12_terminal_sensitivity_config.R).
Each individual `steps/<id>/README.md` states its hypothesis and exact flags.

For standard recruitment deviations, `400` counts recruitment **periods**
(quarters here), not years. `400=0` leaves terminal deviations estimated;
`398=1` replaces constrained terminal recruitment with the arithmetic mean of
earlier natural-scale recruitment. For OPR, the generated Phase 3 comments
document every active `155/217/216/218` and `202:215` control.

## Kflow launch

The normal task remains `ofp-sam-bet-2026-stepwise` on main. This branch
registers a separate task,
`ofp-sam-bet-2026-stepwise-terminal-recruitment`, on the Suva submitter.

```text
fit (one selected model)
  -> one Hessian job
       -> Hessian merge
Hessian merge (all selected models)
  -> one existing BET results job / MFCL Shiny review
```

For the full 95-model grid, the launcher explicitly sets
`HESSIAN_NSPLIT=1`: no per-model Hessian partitioning. It submits 285 dependent
jobs plus one existing BET results job (286 jobs total), all on Suva. The
results job receives the 95 Hessian-merge bundles only: each is the canonical
fit-plus-Hessian model folder, avoiding fit/merge archive collisions in the
MFCL Shiny local-app staging area. A
non-PD Hessian is a valid diagnostic outcome, not a hidden task failure: it is
kept with its PDH status and eigenvalue count. If the Hessian executable or a
part fails, Kflow still passes the failed archive to the merge and results
jobs; the attached model bundle records `incomplete_parts`, `stitch_failed`,
or another explicit failure status/reason rather than silently dropping that
model.

Open the standard `ofp-sam-bet-2026-results` job's MFCL Shiny local app to
compare all completed merge bundles in one session. Its multi-input staging
keeps one merge-preferred model folder per sensitivity, and the Hessian table
shows PDH status, native MFCL non-positive (`<= 0`) and total counts,
strict-negative/zero/positive counts where available, failed parts, and the
failure reason without treating an incomplete diagnostic as a pass.

After the branch is pushed and `KFLOW_API_TOKEN` is available:

```sh
make kflow-register-terminal-sensitivity
# Refreshes only the existing results task; it does not re-register the normal
# main-branch stepwise task from this sensitivity branch.
make kflow-register-terminal-sensitivity-results
make kflow-launch-terminal-sensitivity
```

For a manual one-model UI rerun, set both a concrete `STEP_SELECT` and
`STEPWISE_ALLOW_DISABLED_SELECTED=true`; this opt-in is ignored for `all`.

The launch manifest is written under ignored `work/` and supports recovery:

```sh
python3 scripts/launch_terminal_recruitment_sensitivity.py \
  --resume --manifest work/<flow-group>-launch.json
```

Use `--dry-run` or `--limit 1` first when changing the launcher. The full
suite uses `BET_PHASE10_11_CONVERGENCE=-5` for Hessian-ready fits and sets
`TRIGGER_NEXT=false` so it does not produce 95 downstream report chains.

## Decision rule

Prioritize models that jointly show acceptable convergence, a plausible
terminal recruitment trajectory, stable population scale/depletion, adequate
fit diagnostics, and a positive-definite Hessian. The high-flexibility
all-effect saturation cases are boundary diagnostics, not default production
candidates.
