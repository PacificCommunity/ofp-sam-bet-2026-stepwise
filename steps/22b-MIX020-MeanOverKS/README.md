# 22b MIX0.2 mean over KS

This sensitivity reproduces the complete frozen input state of Step 21 and
changes only the first column of the 98-row `# tag flags` matrix in `bet.ini`.

## Comparison

| Field | Value |
| --- | --- |
| Baseline | `21-MIX015-SC22IP10Cutoff` |
| Target method | Mean over KS |
| Target mixing-period source | `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini`, branch `SC22-IP10-based` |
| Target source commit | `5b2fb6053e34a58ef61275a68d8a67ec988833c1` |
| Target source file | `BET/ini.mix-period/bet.2026.mix-0.2.ini` |
| Changed field | `tag_flags(:,1)` only |
| Changed release groups | 32 of 98 |

The Step 21 and target mixing-period counts and transitions are:

| Audit | Result |
| --- | --- |
| Step 21 counts | 0 quarters: 1; 1 quarter: 13; 2 quarters: 48; 3 quarters: 20; 4 quarters: 16 |
| K=0.2 counts | 0 quarters: 2; 1 quarter: 21; 2 quarters: 64; 3 quarters: 2; 4 quarters: 9 |
| Changed transitions | 2→1: 6; 3→0: 1; 3→1: 1; 3→2: 17; 4→1: 1; 4→2: 5; 4→3: 1 |

`mixing_period_audit.csv` records the before-and-after value for every release
group. Columns 2–10 of the tag-flags matrix and every line outside that matrix
are unchanged.

## Held constant

The following files are byte-identical to Step 21:

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

Only the mixing-period column is copied from the target INI. Reporting-rate
values, group flags, active flags, targets and penalties remain exactly as in
Step 21; no other section of the SC22-IP10 INI is imported.

At K=0.2, the 98 integer mixing periods are identical to the current
main-branch mean-over-period values. Steps 22a and 22b therefore have
byte-identical MFCL inputs while retaining distinct source-method provenance.

## Purpose

This isolates the K=0.2 mean-over-KS assignment from the Step 21 K=0.15 state
and records its equivalence to the current mean-over-period assignment.
