# BET 2026 OPR phase-placement sensitivity

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

This branch tests whether the difference between standard recruitment and OPR
comes from the OPR representation itself or from introducing OPR too early in
the optimisation sequence.

## Common basis

Every model is copied from the PDH-rebuild branch
`experiment/step12-pdh-termpen100-rebuild`, specifically its Step 11 model.
The `.frq`, `.ini`, `.tag`, age-length, regional-scaling, selectivity, and
doitall controls are therefore the PDH-rebuild versions, not `main`.

Every row runs `doitall.sh` from `bet.ini` and removes only stale generated
PAR files first. No model starts from a saved PAR or another Kflow job.

## Models

| ID | OPR conversion point | Terminal penalty | Purpose |
| --- | --- | ---: | --- |
| `11-Standard-Fix6` | none | standard Fix6 | Fresh standard reference. |
| `12a-OPR-Phase3-P0` | Phase 3 (`02.par → 03.par`) | 0 | Early OPR conversion without penalty. |
| `12b-OPR-Phase3-P100` | Phase 3 | 100 | Early OPR path with terminal penalty. |
| `12c-OPR-Phase8-P0` | Phase 8 (`07.par → 08.par`) | 0 | Converts after movement, regional scaling, and growth control phases. |
| `12d-OPR-Phase8-P100` | Phase 8 | 100 | Same intermediate placement with terminal penalty. |
| `12e-OPR-Phase10-P0` | Phase 10 (`09.par → 10.par`) | 0 | Converts only after standard SRR phases. |
| `12f-OPR-Phase10-P100` | Phase 10 | 100 | Core late-switch candidate with terminal penalty. |

All OPR rows use `72-01-50-50`, endpoint `E2`, and `pf221=0`. The latter is
kept explicit because it is not an active OPR degree control in the reviewed
development source. The transition block always turns off the standard
recruitment penalty, terminal fixed-recruitment settings, standard total-pop
scaling, regional recruitment series/distribution controls, and the five
time-invariant regional distribution flags before enabling OPR.

## Why phase placement matters

MFCL converts standard recruitment estimates to OPR coefficients when OPR is
activated. The conversion point therefore determines what has already been
estimated under the standard representation. If Phase 3 and Phase 10 converge
to different scales despite the same final OPR setting, the result is path or
local-optimum sensitive rather than evidence that OPR alone fixes the scale.

The Phase 10 models are the most informative compact test: selectivity,
movement, growth, and SRR phases have already followed the standard path, but
the terminal OPR refinement still occurs in the normal final phase.

## Execution and Hessians

Run locally with, for example:

```sh
make local STEP_SELECT=12f-OPR-Phase10-P100
```

Kflow submits each model separately. Each successful base fit has five
dependent Hessian parts, followed by one Hessian merge that attaches only its
diagnostic delta to that model's output.

## Files

| Path | Purpose |
| --- | --- |
| `scripts/run_opr_phase_placement.sh` | Full phase-aware PDH-rebuild doitall. |
| `steps/<model>/model/scenario.env` | Phase and penalty for each OPR row. |
| `job-config.R` | Seven-model registry and Kflow labels. |
| `kflow.yaml` | Suva task and tuna-flow v2.2 runtime pins. |
