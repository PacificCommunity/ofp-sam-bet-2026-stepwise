# 06 LengthPlusLength

Data to 2021, global CPUE, adding length compositions that were not used in the past.

## What Changed

- Uses `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq` from the frq-build repo.
- Keeps the 04b-TagReportingMixing `.ini`, tag, and old CAAL inputs so this step isolates the additional length-composition data.
- Applies FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604 through the inherited 04b-TagReportingMixing ini.

## Inputs

- `.frq`: `bet.2023.new-structure.global-cpue.wt-as-len-plus-len.frq`; terminal year 2021, global CPUE
- `.ini`: `steps/04b-TagReportingMixing/model/bet.ini`, FixM M row applied from 01-Diag2023 mgc=-5 final.par from Kflow job 000604
- `.tag`: `steps/04b-TagReportingMixing/model/bet.tag`
- `.age_length`: `bet.2023.new-structure.age_length` (old CAAL); set age_length effective sample size to 0.75 for 112 records
- `input_manifest.csv`: machine-readable source/input notes

## Source Revisions

- `ofp-sam-2026-BET-YFT-frq-build`: `d884ce5` - remove len comps from LL from 2023.new.structure
- `ofp-sam-2026-BET-YFT-build-ini`: `b39cbfd` - updated ini files to reflect updated tag files
- `ofp-sam-2026-BET-YFT-tag-prep`: `5a4f5fb` - assign unassigned gear to PS from canneries
- `ofp-sam-2026-BET-YFT-age-length-build`: `a26b694` - plus group at age 40
- `ofp-sam-bet-2023-diagnostic`: `81fc412` - Format tables after plotting

## Control Notes

- 04b-TagReportingMixing 5-region `doitall.sh` controls retained.
- The step inherits 04b's `tag_flags(it,2)=1` treatment so reporting rates are excluded from predicted tag catches during mixing.
- Generated `.frq` files include region locations for every fishery, including index fisheries, and MFCL 1007 `.ini` files carry explicit tag flags immediately after `# number of age classes`.
- Generated `.ini` files also validate that `# tag flags`, `# tag shed rate`, and the five tag reporting-rate matrices match the selected tag release-group count.
- `age_flags(128)` is kept at 100 so the current MFCL reader interprets the initial equilibrium natural-mortality multiplier as 1.0.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Run Note

- Compare directly with 05-ConvertToLength to isolate the extra length-composition records.

## Outstanding Checks

- Review fit impacts before deciding whether length-composition weighting needs adjustment.
- Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.
