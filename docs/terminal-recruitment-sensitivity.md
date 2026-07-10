# Terminal-recruitment sensitivity grid

The `experiment/step12-terminal-recruitment-71-73` branch is an isolated,
explicit-select-only suite for diagnosing the terminal recruitment spike. It
does not change the ordinary main workflow: `STEP_SELECT=all` still selects the
17 enabled main models.

The suite runs **104 fits**: 102 generated OPR variants, the Step 11 standard
recruitment control, and the current Step 12 `OPR69-01-50-50` control. No
generated variant uses 69. Generated folders retain the Step 12 data and model
settings; only the documented Phase 3 OPR controls are changed.

## Source-derived limits

The frequency data span 1952–2024, giving 73 real years. The MFCL manual and
`ongoing-dev` source define flags `155`, `217`, `216`, and `218` as coefficient
counts. The source routine also normalizes `end0` to a one-point endpoint, so
the valid saturated annual boundaries are:

| Endpoint treatment | Maximum coefficient count |
| --- | ---: |
| `end0` (no multi-year tie) | 73 |
| `end2` | 72 |
| `end3` | 71 |

Consequently, `73/end0`, `72/end2`, and `71/end3` are valid boundary cases;
74 coefficients are invalid even with `end0`. The generator enforces these
limits before submission. For component endpoint flags, `0` inherits the
global endpoint setting, while `-1` explicitly disables the endpoint. The
focused grid uses `-1` whenever components are intended to remain free.

## Model grid

The 102 generated variants comprise:

- 99 schedule-by-component-profile models: 11 annual/endpoint schedules crossed
  with nine interpretable seasonal, regional, and season-by-region profiles;
- three all-effect boundary diagnostics: `73-73-73-73/end0`,
  `72-72-72-72/end2`, and `71-71-71-71/end3`.

The annual-count balance is deliberately weighted toward the current-data
ceiling:

| Annual coefficients | Generated variants |
| ---: | ---: |
| 73 | 37 |
| 72 | 37 |
| 71 | 28 |

The exact specifications and hypotheses are in
[`R/step12_terminal_sensitivity_config.R`](../R/step12_terminal_sensitivity_config.R)
and each generated `steps/<id>/README.md`. The all-effect cases are
identifiability boundaries, not preferred production candidates.

## Kflow launch

This branch uses the separate Suva task
`ofp-sam-bet-2026-stepwise-terminal-recruitment-717273` and flow group
`bet-2026-terminal-recruitment-717273-20260711`; it does not re-register the
normal main-branch task.

```text
104 fits
  -> 104 Hessians (one per fit)
       -> 104 merges (one per model)
            -> 104 attached-output updates (one per original fit)
                 -> one BET results / MFCL Shiny job
```

The full flow is 417 jobs. Because the suite exceeds 50 models,
`HESSIAN_NSPLIT=1`: Hessians are not partitioned. The attached-output update is
important: a Kflow dependency alone schedules the merge but does not make its
diagnostic archive visible on the originating fit page. The update copies the
merged Hessian back onto that fit, so its **Diagnostics → Hessian** card is
shown once the merge completes. The results job then receives the 104 attached
fit bundles. Non-positive-definite and incomplete Hessians remain visible with
their status, eigenvalue counts, and failure reason rather than being omitted
or reported as successful.

After pushing the branch and setting `KFLOW_API_TOKEN`:

```sh
make kflow-register-terminal-sensitivity
make kflow-register-terminal-sensitivity-results
make kflow-launch-terminal-sensitivity
```

The ignored `work/<flow-group>-launch.json` manifest supports recovery with
`--resume`. Use `--dry-run` or `--limit 1` when checking launcher changes. The
production suite uses `BET_PHASE10_11_CONVERGENCE=-5`, `TRIGGER_NEXT=false`,
and the Suva submitter. `--no-attach-hessians` is available only for a small
legacy-compatible test; production launches keep the default attachment step.

## Review rule

Compare convergence, fit, terminal recruitment shape, population scale,
depletion, and Hessian diagnostics together. A better objective value alone is
not sufficient evidence for adopting a parameterization.
