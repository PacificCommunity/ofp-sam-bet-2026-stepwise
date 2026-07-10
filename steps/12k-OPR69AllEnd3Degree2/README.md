# 12k OPR: three-year endpoint with linear annual and component trends retained

This is a terminal-recruitment sensitivity derived from the current main-branch parent model.
All MFCL inputs except `model/doitall.sh` are byte-identical to the parent; the copied provenance is retained in `input_manifest.csv`.

## Question

Allows the linear basis term to vary across the three-year endpoint while flattening quadratic and higher terms.

## Model definition

| Field | Value |
| --- | --- |
| Parent model | `12-OrthogonalPoly` |
| Recruitment parameterisation | `orthogonal-polynomial recruitment (OPR)` |
| Terminal treatment | `155=69`, `217=1`, `216=50`, `218=50`; `202/203=3/2`; `210/211=3/2`; `212/213=3/2`; `214/215=3/2`. With 73 real years and the default one-point initial endpoint, the annual coefficient ceiling for end window 3 is 71. |
| Data / structure held fixed | 1952-2024, 5 regions, 33 fisheries, time-varying index CPUE CV, regional-scaling prior, age-based selectivity |

## Controls written in `doitall.sh`

```text
1 155 69   1 217 1   1 216 50   1 218 50
1 202 3   1 203 2   1 210 3   1 211 2
1 212 3   1 213 2   1 214 3   1 215 2
```

The surrounding comments in `model/doitall.sh` state the active MFCL source semantics and the reason for every changed control.

## Source interpretation

- MFCL `ongoing-dev` `get_orth_poly_info.cpp` and `get_orth_weights.cpp` define 155/217/216/218 as coefficient counts; the polynomial degree is count minus one.
- `202/203` control the annual terminal window and its retained low-order terms; 210/211, 212/213, and 214/215 are the corresponding regional, seasonal, and season-by-region controls.
- `neworth.cpp` rejects a coefficient count above the endpoint-constrained capacity, so 73 annual coefficients are used only with a one-point annual endpoint.

## Kflow and Hessian

Run this folder as one independent Kflow model job. The terminal-sensitivity launcher submits a 1-part Hessian job with this fit as its input dependency, then submits the Hessian merge job. The existing BET results task receives this merge bundle for one-session MFCL Shiny review, preserving its PDH/non-PDH result or explicit incomplete/failure reason. `TRIGGER_NEXT=false` is intentional: this grid should not spawn one report chain per sensitivity model.

## Decision rule

Compare convergence, objective components, terminal recruitment plausibility, population scale/depletion, and the Hessian result together. Do not select a model solely because it has the smallest objective value.
