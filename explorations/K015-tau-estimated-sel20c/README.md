# K015 — tau estimated — 20c selectivity

Self-contained Job 17805-control exploration using the Joe all-region-mean
mixing-period vector at K=0.15. Run it through the repository-level `run.sh`
with `MODEL=K015-tau-estimated-sel20c`.

This `bet.ini` is byte-identical to the one in the actual Job 18386 output
archive (SHA256 `670940e4815f7f10f734f5de289bbe033657169ffa764a6297d0adc693ce221f`).
The fixed log-M is `-2.54930339768360e+00`; common tag tau is estimated.

The Job 18518 DM treatment is fixed: `Nmax=25`, the G8-grouped
`fish_pars(22)=7`, and flag 69 is off. Grouped `fish_pars(23)` remains
estimated.

## Selectivity treatment

This variant changes only the fishery-selectivity controls. It uses the
Phase 1 and Phase 5 settings in the actual Job 15062 `20c-DMG8Nmax25`
`doitall.sh`, with one deliberate addition: both F14 and F15 use fishery
flag 75=5 because neither fishery has observations below 70 cm in the
retained length-frequency data. All data, mixing, tau, DM, M,
reporting-rate, and regional-scaling settings remain those of the
corresponding base exploration.
