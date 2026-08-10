# 22 BET 2026 Diagnostic model

Retain Step 21 and fix steepness at 0.90, reproducing public Diagnostic Job 21641.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/22-Diagnostic/model` |
| Status | Locked to the public Diagnostic main and completed Job 21641 reference. |

## Changes

| # | Change |
| --- | --- |
| 1 | Only INI sv(29) changes from 0.80 to 0.90; age flag 162 remains zero. |
| 2 | No seed, jitter or fitted checkpoint is used. |
| 3 | The committed bet.ini must match the model configuration exactly and is copied byte-for-byte at runtime; scientific input values are not rewritten. |
| 4 | The model files are extracted from the current public Diagnostic main recipe. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | Diagnostic FRQ with unused weight-frequency structure removed; no observation changed |
| `.ini` | Fixed h=0.90 Diagnostic INI |
| `doitall.sh` | Locked no-seed direct-tau fitting, explicit-input and audit recipe |
| `model-inputs/Diagnostic.conf` | Fixed steepness/selectivity selection |
| `selectivity-models/Diagnostic.csv` | Explicit 33-fishery selectivity controls |

## Controls

| # | Control |
| --- | --- |
| 1 | Negative-binomial likelihood is retained. |
| 2 | Tau is fixed with parest 111/305/306=4/1/0, fish flags 43/44=0 and all fish_pars(4)=0. |
| 3 | DM G8/Nmax25, fixed concentration 7, M, mixing, reporting rates, CPUE and biological inputs are retained. |

## Checks

| # | Check |
| --- | --- |
| 1 | No extra unresolved build items for this transition beyond fitting diagnostics. |
