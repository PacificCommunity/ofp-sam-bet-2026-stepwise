# 04b TagReportingMixing

04a new-structure input with `tag_flags(it,2)=1` so reporting rates are excluded during tag mixing periods.

## What Changed

- Uses the same `.frq`, `.tag`, CAAL, FixM, LN(R0), and 5-region controls as 04a-NewStructure.
- Changes only the second tag-flag column: `tag_flags(it,2)=1`.
- This excludes tag reporting rates from predicted tag recaptures only during the specified tag mixing periods.
- Later steps inherit this 04b tag-treatment setting.

## Inputs

- `.frq`: `steps/04-NewStructure/model/bet.frq`; 04a 5-region, 33-fishery structure, terminal year 2021, global CPUE
- `.ini`: `steps/04-NewStructure/model/bet.ini`, with `tag_flags(it,2)=1` applied; FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604; set tag_flags(it,2)=1 for 96 release groups so reporting rates are excluded from predicted tag catches during mixing
- `.tag`: `steps/04-NewStructure/model/bet.tag`; same 04a low-recapture-removed tag input
- `.age_length`: `steps/04-NewStructure/model/bet.age_length`; same 04a old CAAL / age_length input; set age_length effective sample size to 0.75 for 112 records
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `d884ce5` - remove len comps from LL from 2023.new.structure
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `5a4f5fb` - assign unassigned gear to PS from canneries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- 04a-NewStructure 5-region `doitall.sh` controls retained.
- `tag_flags(it,1)=2` still supplies the two-quarter tag mixing period.
- `tag_flags(it,2)=1` excludes reporting rates from predicted tag recaptures during those mixing periods.
- This follows the MFCL warning/recommended treatment and keeps the change separate from the 04a structural transition.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- Compare directly with 04a-NewStructure to isolate the effect of excluding reporting rates during tag mixing periods.
- This substep is the inherited tag-treatment baseline for steps 05-15.

## Outstanding Checks

- After fitting, compare the tag likelihood and early time-at-liberty residuals against 04a-NewStructure.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
