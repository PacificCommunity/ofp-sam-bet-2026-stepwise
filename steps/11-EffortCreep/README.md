# 11 EffortCreep

Minimum effort-creep scenario applied to the regional index fisheries.

## What Changed

- Uses 10-OPR controls and applies an effort-creep transform to index fisheries 29-33 in `bet.frq`.
- Retains the `69-01-50-50` OPR setting selected from John Hampton's BET 4R OPR screening.
- The transform follows the available single-region eff-creep file pattern: effort is multiplied by `1 + 0.01 * (year - 1952)`.
- Only positive index-fishery effort values are changed; extraction fisheries and size compositions are untouched.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024, with index effort creep applied
- `bet.ini`: `bet.2026.mix-0.2.ini`, FixM M row applied; raised 41 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0
- `bet.tag`: `bet.2026.low.recaps.removed.tag`
- `bet.age_length`: `bet.2026.age_length` (updated CAAL)
- `bet.reg_scaling`: `bet.2026.reg_scaling` global CPUE regional-scaling matrix, 292 quarterly rows x 5 regions
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `7d636e8` - update frq files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `f6a9e4a` - Assign unassigned fisheries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40

## Control Notes

- 10-OPR `doitall.sh` controls are retained.
- No extra MFCL flag is used for effort creep; the change is in the index-fishery effort values in `bet.frq`.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; `parest_flags(79)` starts the prior at the first period covered by all index fisheries; flags 77-81 follow Nick's 09/06/2026 regional-scaling suggestion.
- For the 292-period full-2024 models, `parest_flags(79)=290` means `292 - 290 + 1 = 3`, so the regional-scaling prior starts at period 3 instead of the invalid period-1 default.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep Arni's 19/06/2026 sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- Confirm that this 1 percent per year linear creep is the intended BET spatial minimum-effort-creep scenario.
- Not yet checked against a separately generated 5-region effort-creep `.frq` because the input repo currently exposes only the single-region eff-creep output.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

