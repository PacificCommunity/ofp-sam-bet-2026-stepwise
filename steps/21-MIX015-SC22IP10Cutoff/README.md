# 21 MIX0.15 SC22-IP10 cutoff sensitivity

This sensitivity reproduces the fitted-input state of Kflow Job 15062
(`20c-DMG8Nmax25`) and changes only the first column of the 98-row
`# tag flags` matrix in `bet.ini`.

## Comparison

| Field | Value |
| --- | --- |
| Baseline | Kflow Job 15062 actual output archive |
| Baseline repository commit | `656b82b74b58a5520dc1d13a86ebb1cb54b342c3` |
| Target mixing-period source | `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini`, branch `SC22-IP10-based` |
| Target source commit | `5b2fb6053e34a58ef61275a68d8a67ec988833c1` |
| Target source file | `BET/ini.mix-period/bet.2026.mix-0.15.ini` |
| Changed field | `tag_flags(:,1)` only |
| Changed release groups | 39 of 98 |

The baseline and target mixing-period counts and transitions are:

| Audit | Result |
| --- | --- |
| Job 15062 counts | 1 quarter: 2; 2 quarters: 87; 4 quarters: 9 |
| SC22-IP10 K=0.15 counts | 0 quarters: 1; 1 quarter: 13; 2 quarters: 48; 3 quarters: 20; 4 quarters: 16 |
| Changed transitions | 2→0: 1; 2→1: 11; 2→3: 20; 2→4: 7 |

`mixing_period_audit.csv` records the before-and-after value for every release
group. Columns 2–10 of the tag-flags matrix and every line outside that matrix
are unchanged.

## Held constant

The following files are byte-identical to the actual Job 15062 frozen inputs:

- `bet.frq`
- `bet.tag`
- `bet.age_length`
- `bet.reg_scaling`
- `bet.reg_scaling.full`
- `doitall.sh`
- `mfcl.cfg`
- `fishery_map.R`
- `tag_rep_map.R`
- `cpue_mle_sigma_audit.csv`

Within `bet.ini`, only 39 first-column values in the tag-flags matrix differ.
The Dirichlet-multinomial G8 grouping, Nmax 25, reporting-rate treatment,
biology, selectivity, regional scaling, and all remaining controls are
therefore inherited exactly from Job 15062.

## Purpose

This isolates the effect of the SC22-IP10 release-group cutoff implementation
at K=0.15 from the implementation used in the actual Job 15062 fit.
