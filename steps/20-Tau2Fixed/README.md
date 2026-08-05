# 20 Tag tau fixed at 2

Fix direct negative-binomial tag tau at 2 from ordinary Step 19 initialization.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/20-Tau2Fixed/model` |
| Status | Ready for an independent Suva fit. |

## Changes

| # | Change |
| --- | --- |
| 1 | Only the fitted-model tau treatment changes. |
| 2 | No seed, jitter or fitted checkpoint is used. |
| 3 | The model files are extracted from the public fixed-tau exploration recipe. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | Diagnostic FRQ with unused weight-frequency structure removed; no observation changed |
| `.ini` | Fixed h=0.80 tau=2 exploration INI |
| `doitall.sh` | Locked no-seed direct-tau fitting and audit recipe |
| `model-inputs/S0.80-F1.conf` | Fixed steepness/selectivity selection |
| `selectivity-models/F1.csv` | Explicit 33-fishery selectivity controls |

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
