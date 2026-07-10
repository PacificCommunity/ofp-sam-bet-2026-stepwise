# 12f097 OPR 71-01-40-50; annual end3; component end3

This is a terminal-recruitment sensitivity derived from the current main-branch parent model.
All MFCL inputs except `model/doitall.sh` are byte-identical to the parent; the copied provenance is retained in `input_manifest.csv`.

## Question

Tests the fully saturated annual basis conditional on a three-year endpoint in every OPR component. Reduces only the regional block, isolating it from the season-by-region interaction.

## Model definition

| Field | Value |
| --- | --- |
| Parent model | `12-OrthogonalPoly` |
| Recruitment parameterisation | `orthogonal-polynomial recruitment (OPR)` |
| Terminal treatment | `155=71`, `217=1`, `216=40`, `218=50`; `202/203=3/0`; `210/211=3/0`; `212/213=3/0`; `214/215=3/0`. With 73 real years and the effective one-point beginning endpoint, MFCL's annual coefficient ceiling is `74 - max(1, end window)`: end window 3 therefore permits at most 71 coefficients. A count of 74 is invalid even with end0. |
| Data / structure held fixed | 1952-2024, 5 regions, 33 fisheries, time-varying index CPUE CV, regional-scaling prior, age-based selectivity |

## Controls written in `doitall.sh`

```text
1 155 71   1 217 1   1 216 40   1 218 50
1 202 3   1 203 0   1 210 3   1 211 0
1 212 3   1 213 0   1 214 3   1 215 0
```

The surrounding comments in `model/doitall.sh` state the active MFCL source semantics and the reason for every changed control.

## Source interpretation

- The interpretation was checked against MFCL `ongoing-dev` commit `b3984d5e4009` and manual commit `e3b82b75de71`.
- The manual's OPR table labels 155/216/217/218 as `Degree+1`; `get_orth_weights.cpp` passes each value minus one to `orthpoly_constant_begin_end()`. Thus 155/217/216/218 are coefficient counts for year/season/region/season-by-region, respectively.
- `202/203` control the annual terminal window and its retained low-order terms; 210/211, 212/213, and 214/215 are the corresponding regional, seasonal, and season-by-region controls.
- For a non-annual endpoint flag, `0` inherits the annual setting. `-1` overrides that inheritance; the source then normalises the resulting zero window to the minimal one-point effective endpoint, so `Free` means no multi-year terminal tie rather than literally zero endpoint points.
- `neworth.cpp` normalises zero beginning/end windows to one point and rejects a degree above `n - begin - end + 1`. Since the executable passes coefficient count minus one, 73/end0, 72/end2, and 71/end3 are the current-data saturated boundaries, while 74 is invalid.

## Kflow and Hessian

The focused collection contains 102 generated OPR variants (71/72/73 annual coefficients: 28/37/37) plus the Step 11 and Step 12 controls, for 104 fits total.

Run this folder as one independent Kflow model job. Because the collection exceeds 50 fits, the terminal-sensitivity launcher submits one unpartitioned Hessian calculation (`nsplit=1`) with this fit as its input dependency, then submits the Hessian merge job. The existing BET results task receives this merge bundle for one-session MFCL Shiny review, preserving its PDH/non-PDH result or explicit incomplete/failure reason. `TRIGGER_NEXT=false` is intentional: this grid should not spawn one report chain per sensitivity model.

## Decision rule

Compare convergence, objective components, terminal recruitment plausibility, population scale/depletion, and the Hessian result together. Do not select a model solely because it has the smallest objective value.
