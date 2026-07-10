# 11b Standard recruitment deviations: terminal periods free

This is a terminal-recruitment sensitivity derived from the current main-branch parent model.
All MFCL inputs except `model/doitall.sh` are byte-identical to the parent; the copied provenance is retained in `input_manifest.csv`.

## Question

Tests whether removing the existing terminal fixed-recruitment treatment creates the OPR-like terminal spike.

## Model definition

| Field | Value |
| --- | --- |
| Parent model | `11-TimeVaryingCV` |
| Recruitment parameterisation | `standard mean + deviations` |
| Terminal treatment | No fixed terminal recruitment deviations: all terminal quarters are estimated. |
| Data / structure held fixed | 1952-2024, 5 regions, 33 fisheries, time-varying index CPUE CV, regional-scaling prior, age-based selectivity |

## Controls written in `doitall.sh`

```text
1 400 0
1 398 0
```

The surrounding comments in `model/doitall.sh` state the active MFCL source semantics and the reason for every changed control.

## Source interpretation

- MFCL `ongoing-dev` `recinpop_standard.cpp` applies `parest_flag(400)` to ordinary recruitment-deviation time periods.
- With `parest_flag(398)=1`, MFCL replaces fixed terminal recruitments with the arithmetic mean of earlier natural-scale recruitment.
- The current model has four recruitment periods per year, so this sensitivity expresses `400` in quarters.

## Kflow and Hessian

Run this folder as one independent Kflow model job. The terminal-sensitivity launcher submits a 1-part Hessian job with this fit as its input dependency, then submits the Hessian merge job. The existing BET results task receives this merge bundle for one-session MFCL Shiny review, preserving its PDH/non-PDH result or explicit incomplete/failure reason. `TRIGGER_NEXT=false` is intentional: this grid should not spawn one report chain per sensitivity model.

## Decision rule

Compare convergence, objective components, terminal recruitment plausibility, population scale/depletion, and the Hessian result together. Do not select a model solely because it has the smallest objective value.
