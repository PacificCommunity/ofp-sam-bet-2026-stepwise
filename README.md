# BET 2026 late-transfer OPR sensitivity

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

This branch tests whether orthogonal-polynomial recruitment (OPR) can retain
the scale of the converged standard Step-11 solution while reducing recruitment
parameter complexity. It is a targeted sensitivity, not the replacement
stepwise sequence.

## Design

All models use the same Step-11 input data, selectivity controls, and MFCL
2.2.7.9 executable. Every row runs its own model-local `doitall.sh` from the
initial inputs: it recreates `00.par` through the standard Step-11 `11.par`,
then applies the terminal-treatment or OPR setting. Thus no fit silently
depends on a checked-in PAR, a previous Kflow job, or a filename convention.

For OPR rows, MFCL makes the standard-to-OPR change only after the fresh
standard Step-11 fit has completed. Its first OPR call performs the native
pre-minimisation conversion of the fitted standard recruitment estimates to
OPR coefficients before the OPR refit.

## Models

| ID | Setting | Why it is included |
| --- | --- | --- |
| `11-Reference-Fix6` | Standard recruitment; `pf398=1`, `pf400=6` | Rebuilds the current Step-11 reference. |
| `11a-Standard-Free` | Standard recruitment; terminal constraints off | Separates terminal treatment from OPR. |
| `11b-Standard-Fix8` | Standard recruitment; `pf398=1`, `pf400=8` | Matches the eight-quarter span of OPR `E2`. |
| `12a-OPR72-E2-P0` | `72-01-50-50`, `E2`, `pf397=0` | Late-transfer OPR without a terminal penalty. |
| `12b-OPR72-E2-P100` | `72-01-50-50`, `E2`, `pf397=100` | Main two-calendar-year terminal-penalty candidate. |
| `12c-OPR73-E1-P0` | `73-01-50-50`, `E1`, `pf397=0` | Fully flexible annual effect, no terminal penalty. |
| `12d-OPR73-E1-P100` | `73-01-50-50`, `E1`, `pf397=100` | Fully flexible annual effect with a four-quarter terminal penalty. |
| `12e-OPR72-E2-SpatialFree-P100` | `72-01-50-50`; year `E2`, spatial endpoints free; `pf397=100` | Tests whether spatial endpoint tying shifts the scale. |
| `12f-OPR72-E2-Int72-P100` | `72-01-50-72`, `E2`, `pf397=100` | Tests region-season interaction rank without changing the annual terminal rule. |
| `12g-OPR73-E1-Saturated-P0` | `73-73-73-73`, `E1`, `pf397=0` | Representation ceiling: tests whether a saturated OPR can preserve the standard solution. |

`73-E2` is deliberately absent. With 73 calendar years, the `E2` endpoint
constraint permits at most 72 annual OPR coefficients; `73-E2` is invalid.
`E1` is the fully flexible annual alternative. `pf221` is set to zero because
it is legacy compatibility state, not an independent OPR setting.

## What is being tested

The key distinction is between the two possible outcomes below.

| Observation | Interpretation |
| --- | --- |
| The OPR conversion checkpoint resembles Step 11, then moves during refitting. | The likelihood, penalties, or a different local optimum changes scale. |
| The checkpoint is already at a different scale. | The selected OPR basis / endpoint constraint cannot reproduce the standard recruitment surface closely enough. |

The terminal-recruitment penalty is tested only after the unpenalized OPR
conversion stage. In MFCL 2.2.7.9, `pf397=100` is the reviewed terminal penalty
setting; it controls terminal recruitment relative to the historical level. It
does not by itself impose the absolute population scale.

The branch does not force scale by reactivating the standard-recruitment total
population parameters (`age_flags(177)` or `age_flags(32)`), or by using
`pf389` as an abundance prior. Those would change the question from an OPR
parameterisation sensitivity to an externally imposed scale constraint.

## Execution

Each sensitivity has a model-local `doitall.sh`, a preserved
`standard-doitall.sh`, and a model-specific `scenario.env`. It writes:

```text
initial MFCL inputs
  -> 00.par ... 11.par       # complete standard Step-11 fit
  -> transfer.par       # native standard-to-OPR conversion checkpoint
  -> final.par          # scenario refit used for diagnostics
```

The standard terminal controls write `final.par` after their fresh `11.par`.

Useful controls are:

| Variable | Default | Meaning |
| --- | ---:| --- |
| `BET_LATE_TRANSFER_EVALUATIONS` | `1` | Minimal post-conversion checkpoint evaluation. |
| `BET_LATE_OPR_FINAL_EVALUATIONS` | `20000` | Final OPR refit budget. |
| `BET_LATE_STANDARD_FINAL_EVALUATIONS` | `20000` | Standard terminal-control refit budget. |
| `BET_LATE_TRANSFER_CONVERGENCE` | `-4` | Final-refit convergence tolerance; use `-5` for a strict rerun. |

For local use:

```sh
make local STEP_SELECT=12b-OPR72-E2-P100
```

Kflow submits every base model independently, so a failed or delayed model
does not prevent the other scenarios from starting.

## Hessian plan

Each base fit is submitted independently. Its diagnostic chain is:

```text
model fit -> five Hessian parts -> Hessian merge -> delta attached to that model
```

The merge attaches only the Hessian delta, preserving the base model payload
and allowing MFCL Shiny to show the Hessian directly from the corresponding
base job. A failed model does not block the other model/Hessian chains.

## Files

| Path | Purpose |
| --- | --- |
| `job-config.R` | Model registry and Kflow labels. |
| `scripts/run_late_transfer_sensitivity.sh` | Shared post-Step-11 terminal/OPR runner called by each `doitall.sh`. |
| `steps/<model>/model/scenario.env` | Exact setting for each sensitivity. |
| `R/run_stepwise.R` | Generic model runner; this task uses `RUN_MODE=doitall` for every row. |
| `kflow.yaml` | Suva task, resources, runtime package pins, and controls. |
