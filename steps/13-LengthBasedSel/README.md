# 13 LengthBasedSel

Length-based selectivity test after the OPR step.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/13-LengthBasedSel/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same inputs as 12-OrthogonalPoly. |
| 2 | Retains time-varying CPUE CV and OPR controls. |
| 3 | Sets fish flag 26 from 2 to 3 in `doitall.sh` for the length-based selectivity test. |

## Inputs

| File | Source / note |
| --- | --- |
| `.frq` | `bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq`, full 2024 with regional CPUE |
| `.ini` | `bet.2026.mix-0.2.ini`, FixM M row applied from the 01-Diag2023 mgc=-5 diagnostic final par; raised 2 zero tag mixing periods to 1 because MFCL >=2.2.7.5 disallows 0; normalized MFCL 1007 tag-control rows for 98 release groups |
| `.tag` | `bet.2026.low.recaps.removed.tag`; latest tag-prep build with updated RR groups and canneries-based reassignment of recaptures with missing gear to purse-seine fisheries before low-recap filtering |
| `.age_length` | `bet.2026.age_length` (updated CAAL); set age_length effective sample size to 0.75 for 181 records |
| `.reg_scaling` | Full `bet.2026.reg_scaling` global CPUE regional-scaling matrix; parest flags select active periods 53-72 (1965-1969) for the prior |
| `input_manifest.csv` | machine-readable source/input notes |

## Generated Input Changes

| Scope | Generated change | Unchanged |
| --- | --- | --- |
| `.frq` | No generated edit; full 2024 regional-CPUE source is used. | Catch, effort, CPUE, and composition records from the selected source. |
| `.ini` | Uses release-specific mixing and latest RR/active/target/penalty matrices from `mix-0.2`, aligns tag-control rows to the selected tag release groups, sets `tag_flags(it,2)=0`, raises source zero mixing periods to `1`, applies fixed M, and validates positive recapture cells. | Positive release-specific mixing values and RR matrix structure. |
| `.tag` | No generated edit. | 2026 low-recapture-removed source tag file. |
| `.age_length` | Changes effective sample size from `1` to `0.75`. | 2026 CAAL records themselves. |

## Source Revisions

| Repository | Commit | Note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Delete YFT/yft.model-785.24062026.txt |
| `ofp-sam-2026-BET-YFT-build-ini` | `386d169` | Correct RR init values |
| `ofp-sam-2026-BET-YFT-tag-prep` | `471b2fd` | Correct RR group init values |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | plus group at age 40 |
| `ofp-sam-bet-2023-diagnostic` | `81fc412` | Format tables after plotting |
| `ofp-sam-2026-BET` | `847d036` | Revert "Fallback selftest projection par generation" |

## Controls

| # | Control |
| --- | --- |
| 1 | 12-OrthogonalPoly controls are retained. |
| 2 | `-999 26 3` is applied for length-based selectivity. |
| 3 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 4 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 5 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 6 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Length-Based Sensitivity Grid

These disabled-by-default rows all start from `steps/13-LengthBasedSel/model`.
They are run only when selected explicitly with `STEP_SELECT`, so the normal
stepwise `all` run stays unchanged. Each sensitivity appends its switches after
the base Step 13 selectivity block; MFCL's sequential option parsing therefore
uses the appended values as the final settings.

Useful switch shorthand:

| Switch | Meaning in this grid |
| --- | --- |
| `-999 61 N` | Set the number of cubic-spline nodes for length-specific selectivity. Step 13 baseline is 5 nodes. |
| `-fishery 16 1` | Add the non-decreasing soft penalty for that fishery's selectivity tail. |
| `-fishery 16 2` with `-fishery 3 cutoff` | Dome or terminal-zero style constraint inherited by selected gears; the sensitivity changes or removes these cutoffs. |
| `-fishery 56 value` | Change the non-decreasing penalty strength. Source default is effectively `1000000` when unset. |
| `-fishery 75 value` | Force young-age selectivity to zero for the first `value` ages/quarters used by that MFCL option. |
| `1 359 value` | Penalize very low spline coefficients, a lower-bound stabilizer rather than a monotonicity setting. |

| Model | What it changes | Why run it |
| --- | --- | --- |
| `13b-LBS-N3` | `-999 61 3` | Strongly smooths length-based selectivity to test whether the high depletion comes from too much spline flexibility. |
| `13c-LBS-N4` | `-999 61 4` | Middle case between the 3-node sensitivity and the 5-node Step 13 baseline. |
| `13d-LBS-N6` | `-999 61 6` | Adds flexibility to test whether the baseline result is a low-node artifact. |
| `13e-LBS-IDXmono-N5` | 5 nodes plus `16 = 1` for index fisheries 29-33 | Keeps baseline node count but stabilizes survey/index large-fish selectivity tails. |
| `13f-LBS-IDXmono-N4` | 4 nodes plus `16 = 1` for index fisheries 29-33 | Combines moderate smoothing with monotone index selectivity. |
| `13g-LBS-IDXmono-N3` | 3 nodes plus `16 = 1` for index fisheries 29-33 | Strong smoothing with monotone index selectivity. |
| `13h-LBS-LLmono-N4` | 4 nodes plus `16 = 1` for longline fisheries 1-11 | Tests whether longline large-fish tails are driving the depletion shift. |
| `13i-LBS-LLIDXmono-N4` | 4 nodes plus `16 = 1` for longline 1-11 and index 29-33 | Strong tail-stability diagnostic across the main adult/index gears. |
| `13j-LBS-LLIDXmono-N3` | 3 nodes plus `16 = 1` for longline 1-11 and index 29-33 | Strongest smoothing plus monotone adult/index tail diagnostic. |
| `13k-LBS-LLIDXmono-N5` | 5 nodes plus `16 = 1` for longline 1-11 and index 29-33 | Separates monotone-tail effects from node-count effects. |
| `13l-LBS-LLIDXsoft-N4` | 4 nodes, longline/index `16 = 1`, and `56 = 100000` | Same monotone structure as `13i`, but with a softer penalty. |
| `13m-LBS-LLIDXvsoft-N4` | 4 nodes, longline/index `16 = 1`, and `56 = 10000` | Very soft monotone penalty to see whether hard tail pressure is distorting fit. |
| `13n-LBS-NoDome-N4` | 4 nodes, remove inherited `16 = 2` dome/terminal-zero constraints for fisheries 12, 13, and 16-28 | Tests whether imposed dome or terminal-zero behavior is lifting depletion. |
| `13o-LBS-RelaxLowDome-N4` | 4 nodes, relax the most restrictive `16 = 2` cutoff ages to 20 quarters | Loosens only the lowest terminal-zero cutoffs. |
| `13p-LBS-RelaxDOMPL-N4` | 4 nodes, relax DOM/PL cutoff ages to 20 quarters | Targets domestic/Philippines low-age terminal-zero constraints. |
| `13q-LBS-RelaxPS-N4` | 4 nodes, relax PS/JP cutoff ages to 30 quarters | Targets purse-seine and Japan pole-and-line cutoff constraints. |
| `13r-LBS-DomeMid-N4` | 4 nodes, set all inherited `16 = 2` cutoff ages to 25 quarters | Applies one common middle cutoff for the constrained gears. |
| `13s-LBS-NoLowDome-IDX-N4` | 4 nodes, remove low dome constraints and add index `16 = 1` | Combines relaxed low cutoffs with monotone index tails. |
| `13t-LBS-YoungZero-PSPLDOM-N4` | 4 nodes plus `75 = 1` for PS/PL/DOM gears 12, 13, and 16-28 | Tests whether small-fish selectivity is pulling the fit and depletion upward. |
| `13u-LBS-IDXyoungzero-N4` | 4 nodes, index `16 = 1`, and index `75 = 2` | Stabilizes index tails and removes very young index selectivity. |
| `13v-LBS-HL75-3-N4` | 4 nodes plus `75 = 3` for HL fisheries 14-15 | Relaxes the HL young-zero setting from the inherited stronger value. |
| `13w-LBS-LL75-1-N4` | 4 nodes plus `75 = 1` for longline fisheries 2, 4, 5, 7-10 | Relaxes longline young-zero settings. |
| `13x-LBS-Bound359-1000-N4` | 4 nodes plus `1 359 1000` | Adds a weak lower-bound stabilizer on spline coefficients. |
| `13y-LBS-Bound359-10000-N4` | 4 nodes plus `1 359 10000` | Adds a stronger lower-bound stabilizer on spline coefficients. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment. |
| 2 | Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override. |
| 3 | Generation validates tag-control dimensions, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader. |
| 4 | Positive tag recapture RR, active, target, and penalty cells are validated after copying the latest RR groupings; the fishery 19 repair only remains as a fallback for older sources that still need it. |
| 5 | The step-specific change after OPR is limited to fish flag 26: `doitall.sh` sets `-999 26 3`. |

## Checks

| # | Check |
| --- | --- |
| 1 | Confirm with the modelling group whether BET should keep the same flag-26 setting after the test fit. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |
