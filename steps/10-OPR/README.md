# 10 OPR

Orthogonal polynomial recruitment step using the best BET OPR setting from John Hampton's OPR.pptx exploration.

## What Changed

- Uses the same input files as 09-SizeBasedSel.
- Applies the BIGEYE AIC rank-1 OPR model from `OPR.pptx`: `69-01-50-50`.
- The OPR comparison was run on the BET 4R model, but this step carries the best-ranked setting into the current 5-region stepwise path.
- OPR controls are applied in PHASE 3 of `doitall.sh`, so early phases still use the pre-OPR recruitment setup before the transfer.

## Inputs

- `bet.frq`: `bet.2026.wt.as.len.plus.len.frq`, full 2024
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

- `-999 26 3` is retained from 09-SizeBasedSel.
- PHASE 1 and PHASE 2 retain the pre-OPR recruitment setup.
- `1 149 0`, `1 398 0`, `2 177 0`, and `2 32 0` are applied at PHASE 3 for the OPR transfer.
- `1 155 69` and `1 221 69` set the OPR year effect from the `69-01-50-50` setting.
- `1 217 1`, `1 216 50`, and `1 218 50` set season, region, and region-season interaction effects.
- `1 202 2`, `1 210 0`, `1 212 0`, and `1 214 0` apply the terminal constraints shown in John's example `do-OPR` file.
- `2 70`, `2 71`, `2 178`, and `-100000 1:5` recruitment-distribution controls are turned off at the OPR phase.
- `bet.reg_scaling` is read by MFCL starting in PHASE 5 because `parest_flags(77)=50`; `parest_flags(79)` starts the prior at the first period covered by all index fisheries; flags 77-81 follow Nick's 09/06/2026 regional-scaling suggestion.
- For the 292-period full-2024 models, `parest_flags(79)=290` means `292 - 290 + 1 = 3`, so the regional-scaling prior starts at period 3 instead of the invalid period-1 default.
- PHASE 1-4 retain the current CPUE_scaling setup: index fisheries 29-33 share CPUE group 29, share selectivity group 25, and keep Arni's 19/06/2026 sigma settings.
- PHASE 5 switches to Prior_reg_biomass: index CPUE groups become 29-33, fish flag 94 is set to 0, and index selectivity groups become 25-29.
- `doitall.sh` uses `set -eu`, so a failed MFCL phase fails the Kflow job instead of continuing with missing `.par` files.
- PHASE 10/11 convergence is controlled by `BET_PHASE10_11_CONVERGENCE`; default is quick `-3`, and strict production runs can set `-5` without editing model folders.

## Outstanding Checks

- After fitting, confirm the 5-region model behaves consistently with the 4R BET OPR screening result.
- If diagnostics disagree with the 4R screening, revisit the other BET-ranked options from `OPR.pptx`.
- Local MFCL `-makepar` smoke still reports 30 `caught before it was released` tag recapture warnings; review upstream tag prep before final production runs.

## Status

Ready for Kflow smoke runs; full MFCL fit not run here.

