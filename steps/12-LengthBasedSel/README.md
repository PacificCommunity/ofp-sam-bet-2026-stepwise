# 12 LengthBasedSel

Length-based selectivity test before the OPR step.

## Snapshot

| Field | Value |
| --- | --- |
| Step folder | `steps/12-LengthBasedSel/model` |
| Status | Ready for Kflow smoke runs; full MFCL fit not run here. |

## Changes

| # | Change |
| --- | --- |
| 1 | Uses the same inputs as 11-TimeVaryingCV. |
| 2 | Retains time-varying CPUE CV enabled for index fisheries 29-33. |
| 3 | Sets fish flag 26 from 2 to 3 in `doitall.sh` for the length-based selectivity test. |
| 4 | No OPR controls are applied until 13-OrthogonalPoly. |

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
| 1 | Time-varying CPUE CV flags are retained. |
| 2 | `-999 26 3` is applied for length-based selectivity. |
| 3 | OPR recruitment flags are deliberately not applied in this step. |
| 4 | `bet.reg_scaling` starts in PHASE 5; flags 77-81 configure the regional-scaling MVN prior with weight 50 (approximately CV 0.1). |
| 5 | The active prior window is periods 53-72 (1965-1969), derived from parest flags 79-80 for the 292-period model. |
| 6 | PHASE 1-4 retain CPUE_scaling; PHASE 5 switches to Prior_reg_biomass with index CPUE groups 29-33, fish flag 94 set to 0, and index selectivity groups 25-29. |
| 7 | Generated safeguards cover FRQ regions, MFCL 1007 tag blocks, shed rates, `age_flags(128)`, fail-fast `doitall.sh`, and the PHASE 10/11 env switch. |

## Run Notes

| # | Note |
| --- | --- |
| 1 | The latest `bet.2026.low.recaps.removed.tag` is kept, including the canneries missing-gear reassignment. |
| 2 | Release-specific mixing periods come from the mix-period `.ini`; generated `doitall.sh` removes the inherited `-9999 1 2` override. |
| 3 | Generation validates tag-control dimensions, shed rates, and reporting-rate matrices; source zero mixing periods are raised to 1 for the current MFCL reader. |
| 4 | Positive tag recapture RR, active, target, and penalty cells are validated after copying the latest RR groupings; the fishery 19 repair only remains as a fallback for older sources that still need it. |
| 5 | The step-specific change after time-varying CPUE CV is limited to fish flag 26: `doitall.sh` sets `-999 26 3`. |

## Checks

| # | Check |
| --- | --- |
| 1 | Confirm with the modelling group whether BET should keep the same flag-26 setting after the test fit. |
| 2 | Local MFCL `-makepar` smoke can still report nonzero tag recapture timing or fishery-realization warnings; review upstream tag prep before final production runs. |

## Length-Based Sensitivity Grid

These 95 disabled-by-default rows all start from `steps/12-LengthBasedSel/model`. They are run only when selected explicitly with `STEP_SELECT`, so the normal `all` run stays unchanged. Each sensitivity appends its switches after the base Step 12 selectivity block; MFCL's sequential option parsing therefore uses the appended values as the final settings.

Useful switch shorthand:

| Switch | Meaning in this grid |
| --- | --- |
| `-999 61 N` | Number of cubic-spline nodes for length-specific selectivity. Step 12 baseline is 5 nodes. |
| `-fishery 16 1` | Non-decreasing soft penalty for that fishery's selectivity tail. Valid with length-specific spline selectivity in ongoing-dev. |
| `-fishery 16 2` with `-fishery 3 cutoff` | Dome/terminal-zero style constraint for selected gears. Sensitivities change or remove these cutoffs. |
| `-fishery 56 value` | Non-decreasing penalty strength. Source default is effectively `1000000` when unset. |
| `-fishery 75 value` | Young-age selectivity zero setting used by that MFCL option. |
| `1 359 value` | Spline lower-bound stabilizer, penalizing very low spline coefficients rather than forcing monotonicity. |

### Scenario Families

| Axis | Rows |
| --- | --- |
| Adult + index tail | 17 |
| Baseline | 1 |
| Dome/cutoff | 18 |
| Dome/cutoff + tail | 2 |
| Index tail | 11 |
| Longline tail | 9 |
| Node count | 4 |
| Spline bound | 8 |
| Spline bound + tail | 4 |
| Young-zero | 12 |
| Young-zero + tail | 9 |

### Scenario Table

| Model | Axis | Change | Switches | Reason |
| --- | --- | --- | --- | --- |
| `12a-LBS-Base` | Baseline | Step 12 length-based selectivity baseline with 5 cubic-spline nodes | -999 61=5 | Alias for 12-LengthBasedSel in the sensitivity task so the grid reads 12a, 12b, ... without hiding the baseline. |
| `12b-LBS-N3` | Node count | length-based selectivity with 3 cubic-spline nodes | -999 61=3 | Reduces length-based spline flexibility from the Step 12 baseline of 5 nodes. |
| `12c-LBS-N4` | Node count | length-based selectivity with 4 cubic-spline nodes | -999 61=4 | Moderate node reduction between the 3-node and 5-node cases. |
| `12d-LBS-N6` | Node count | length-based selectivity with 6 cubic-spline nodes | -999 61=6 | Increases flexibility to test whether the baseline depletion shift is a low-node artifact. |
| `12e-LBS-IDXmono-N5` | Index tail | baseline 5-node length-based selectivity with non-decreasing index selectivity | fish flag 16=1 (5 fisheries); -999 61=5 | Applies the monotone penalty to the five index fisheries only. |
| `12f-LBS-IDXmono-N4` | Index tail | 4-node length-based selectivity with non-decreasing index selectivity | fish flag 16=1 (5 fisheries); -999 61=4 | Combines moderate smoothing with monotone survey/index selectivity. |
| `12g-LBS-IDXmono-N3` | Index tail | 3-node length-based selectivity with non-decreasing index selectivity | fish flag 16=1 (5 fisheries); -999 61=3 | Strongly smooths the length spline while keeping index selectivity monotone. |
| `12h-LBS-LLmono-N4` | Longline tail | 4-node length-based selectivity with non-decreasing longline selectivity | fish flag 16=1 (11 fisheries); -999 61=4 | Strong diagnostic: longline gears can be asymptotic, but dome-shaped targeting is also plausible. |
| `12i-LBS-LLIDXmono-N4` | Adult + index tail | 4-node length-based selectivity with non-decreasing longline and index selectivity | fish flag 16=1 (16 fisheries); -999 61=4 | Strong diagnostic for whether large-fish selectivity tails are driving the depletion shift. |
| `12j-LBS-LLIDXmono-N3` | Adult + index tail | 3-node length-based selectivity with non-decreasing longline and index selectivity | fish flag 16=1 (16 fisheries); -999 61=3 | Strongest smoothing plus monotone large-fish signal diagnostic. |
| `12k-LBS-LLIDXmono-N5` | Adult + index tail | baseline 5-node length-based selectivity with non-decreasing longline and index selectivity | fish flag 16=1 (16 fisheries); -999 61=5 | Separates monotone-tail effects from node-count effects. |
| `12l-LBS-LLIDXsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with a softer monotone penalty | fish flag 16=1 (16 fisheries); -999 61=4; fish flag 56=100000 (16 fisheries) | Uses fish flag 56 = 100000 for the monotone fisheries instead of the source default 1000000. |
| `12m-LBS-LLIDXvsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with a very soft monotone penalty | fish flag 16=1 (16 fisheries); -999 61=4; fish flag 56=10000 (16 fisheries) | Uses fish flag 56 = 10000 for the monotone fisheries. |
| `12n-LBS-NoDome-N4` | Dome/cutoff | 4-node length-based selectivity with Step 12 dome/terminal-zero constraints removed | fish flag 16=0 (15 fisheries); -999 61=4; fish flag 3=37 (15 fisheries) | Sets fish flag 16 back to 0 for the fisheries that inherited 16 = 2 constraints. |
| `12o-LBS-RelaxLowDome-N4` | Dome/cutoff | 4-node length-based selectivity with low terminal-zero cutoffs relaxed | -999 61=4; fish flag 3=20 (7 fisheries) | Raises the most restrictive 16 = 2 cutoff ages to 20 quarters. |
| `12p-LBS-RelaxDOMPL-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL terminal-zero cutoffs relaxed | -999 61=4; fish flag 3=20 (5 fisheries) | Targets the DOM/PL low-age terminal-zero constraints only. |
| `12q-LBS-RelaxPS-N4` | Dome/cutoff | 4-node length-based selectivity with PS and JP terminal-zero cutoffs relaxed | -999 61=4; fish flag 3=30 (10 fisheries) | Raises the PS/JP 16 = 2 cutoffs to 30 quarters. |
| `12r-LBS-DomeMid-N4` | Dome/cutoff | 4-node length-based selectivity with a common mid terminal-zero cutoff | -999 61=4; fish flag 3=25 (15 fisheries) | Sets all inherited 16 = 2 cutoff ages to 25 quarters. |
| `12s-LBS-NoLowDome-IDX-N4` | Dome/cutoff | 4-node length-based selectivity with low dome constraints removed and index monotone | fish flag 16=0 (7 fisheries); fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=37 (7 fisheries) | Removes the most restrictive terminal-zero constraints and stabilizes index tails. |
| `12t-LBS-YoungZero-PSPLDOM-N4` | Young-zero | 4-node length-based selectivity with age-1 zero selectivity for PS/PL/DOM gears | fish flag 75=1 (15 fisheries); -999 61=4 | Tests whether small-fish fit is pulling selectivity and depletion upward. |
| `12u-LBS-IDXyoungzero-N4` | Young-zero | 4-node length-based selectivity with monotone index selectivity and young-index zero selectivity | fish flag 16=1 (5 fisheries); fish flag 75=2 (5 fisheries); -999 61=4 | Index fisheries get 16 = 1 and 75 = 2. |
| `12v-LBS-HL75-3-N4` | Young-zero | 4-node length-based selectivity with HL young-zero age count relaxed | fish flag 75=3 (2 fisheries); -999 61=4 | Changes HL fisheries 14-15 from 75 = 5 to 75 = 3. |
| `12w-LBS-LL75-1-N4` | Young-zero | 4-node length-based selectivity with LL young-zero age count relaxed | fish flag 75=1 (7 fisheries); -999 61=4 | Changes longline fisheries that had 75 = 2 to 75 = 1. |
| `12x-LBS-Bound359-1000-N4` | Spline bound | 4-node length-based selectivity with spline lower-bound penalty 359 = 1000 | -999 61=4; 1 359=1000 | Adds a weak penalty against spline coefficients getting stuck below -15. |
| `12y-LBS-Bound359-10000-N4` | Spline bound | 4-node length-based selectivity with spline lower-bound penalty 359 = 10000 | -999 61=4; 1 359=10000 | Adds a stronger penalty against spline coefficients getting stuck below -15. |
| `12z-LBS-N7` | Node count | length-based selectivity with 7 cubic-spline nodes | -999 61=7 | Adds flexibility beyond N6 without moving to an unconstrained high-node tail. |
| `12aa-LBS-Bound359-1000-N5` | Spline bound | 5-node length-based selectivity with weak spline lower-bound penalty | -999 61=5; 1 359=1000 | Keeps the Step 12 node count and adds the weaker lower-bound stabilizer. |
| `12ab-LBS-Bound359-10000-N5` | Spline bound | 5-node length-based selectivity with stronger spline lower-bound penalty | -999 61=5; 1 359=10000 | Keeps baseline node count while testing whether low spline coefficients are destabilizing the fit. |
| `12ac-LBS-Bound359-1000-N6` | Spline bound | 6-node length-based selectivity with weak spline lower-bound penalty | -999 61=6; 1 359=1000 | Pairs the more flexible N6 spline with light lower-bound stabilization. |
| `12ad-LBS-Bound359-10000-N6` | Spline bound | 6-node length-based selectivity with stronger spline lower-bound penalty | -999 61=6; 1 359=10000 | Tests whether N6 needs stronger protection against very low spline coefficients. |
| `12ae-LBS-IDXmono-N6` | Index tail | 6-node length-based selectivity with non-decreasing index selectivity | fish flag 16=1 (5 fisheries); -999 61=6 | Checks whether index-tail stabilization still helps when the spline is more flexible. |
| `12af-LBS-IDXmono-N7` | Index tail | 7-node length-based selectivity with non-decreasing index selectivity | fish flag 16=1 (5 fisheries); -999 61=7 | High-flexibility index-tail diagnostic without changing other gears. |
| `12ag-LBS-IDXsoft-N5` | Index tail | 5-node index non-decreasing selectivity with softer penalty | fish flag 16=1 (5 fisheries); -999 61=5; fish flag 56=100000 (5 fisheries) | Keeps Step 12 node count and applies fish flag 56 = 100000 to the index group. |
| `12ah-LBS-IDXvsoft-N5` | Index tail | 5-node index non-decreasing selectivity with very soft penalty | fish flag 16=1 (5 fisheries); -999 61=5; fish flag 56=10000 (5 fisheries) | Uses fish flag 56 = 10000 for the index group to test penalty-strength sensitivity. |
| `12ai-LBS-IDX75-1-N4` | Young-zero | 4-node index non-decreasing selectivity with one young age set to zero | fish flag 16=1 (5 fisheries); fish flag 75=1 (5 fisheries); -999 61=4 | Tests a light young-age exclusion for all index fisheries in their shared selectivity group. |
| `12aj-LBS-IDX75-3-N4` | Young-zero | 4-node index non-decreasing selectivity with three young ages set to zero | fish flag 16=1 (5 fisheries); fish flag 75=3 (5 fisheries); -999 61=4 | A stronger index young-age exclusion, applied consistently across the shared index group. |
| `12ak-LBS-LLmono-N5` | Longline tail | 5-node length-based selectivity with non-decreasing longline selectivity | fish flag 16=1 (11 fisheries); -999 61=5 | Keeps baseline node count while testing adult longline asymptotic tails. |
| `12al-LBS-LLmono-N6` | Longline tail | 6-node length-based selectivity with non-decreasing longline selectivity | fish flag 16=1 (11 fisheries); -999 61=6 | Tests whether LL monotone tails remain stable with more flexible length splines. |
| `12am-LBS-LLcoreMono-N4` | Longline tail | 4-node non-decreasing selectivity for core adult longline fisheries | fish flag 16=1 (8 fisheries); -999 61=4 | Targets adult longline groups that already carry the inherited young-zero pattern. |
| `12an-LBS-LLcoreMono-N5` | Longline tail | 5-node non-decreasing selectivity for core adult longline fisheries | fish flag 16=1 (8 fisheries); -999 61=5 | Same core LL diagnostic at the Step 12 node count. |
| `12ao-LBS-LLrecentMono-N4` | Longline tail | 4-node non-decreasing selectivity for later longline fishery groups | fish flag 16=1 (5 fisheries); -999 61=4 | Focuses on the later/regional longline groups 7-11 rather than all longline gears. |
| `12ap-LBS-LLOSmono-N4` | Longline tail | 4-node non-decreasing selectivity for oceanic longline groups | fish flag 16=1 (2 fisheries); -999 61=4 | Targets the LL.OS-derived fisheries 5 and 9, including the already monotone old6-derived group. |
| `12aq-LBS-LL75-0-N4` | Young-zero | 4-node length-based selectivity with inherited longline young-zero settings removed | fish flag 75=0 (7 fisheries); -999 61=4 | Allows selected longline groups to estimate young-age selectivity rather than forcing the first two ages to zero. |
| `12ar-LBS-LL75-3-N4` | Young-zero | 4-node length-based selectivity with stronger longline young-zero settings | fish flag 75=3 (7 fisheries); -999 61=4 | Tests whether excluding one additional young age stabilizes adult longline selectivity. |
| `12as-LBS-HL75-4-N4` | Young-zero | 4-node length-based selectivity with moderately relaxed HL young-zero age count | -999 61=4; fish flag 75=4 (2 fisheries) | Intermediate HL setting between the inherited 75 = 5 and the 75 = 3 sensitivity. |
| `12at-LBS-HL75-2-N4` | Young-zero | 4-node length-based selectivity with strongly relaxed HL young-zero age count | fish flag 75=2 (2 fisheries); -999 61=4 | Tests whether the handline young-age exclusion is too restrictive. |
| `12au-LBS-LLIDXmono-N6` | Adult + index tail | 6-node non-decreasing longline and index selectivity | fish flag 16=1 (16 fisheries); -999 61=6 | Adult/index monotone-tail diagnostic with more flexible selectivity-at-length. |
| `12av-LBS-LLIDXmono-N7` | Adult + index tail | 7-node non-decreasing longline and index selectivity | fish flag 16=1 (16 fisheries); -999 61=7 | Highest-node adult/index monotone diagnostic retained in this grid. |
| `12aw-LBS-LLIDXsoft-N5` | Adult + index tail | 5-node non-decreasing longline/index selectivity with softer penalty | fish flag 16=1 (16 fisheries); -999 61=5; fish flag 56=100000 (16 fisheries) | Baseline node count with fish flag 56 = 100000 on adult and index groups. |
| `12ax-LBS-LLIDXvsoft-N5` | Adult + index tail | 5-node non-decreasing longline/index selectivity with very soft penalty | fish flag 16=1 (16 fisheries); -999 61=5; fish flag 56=10000 (16 fisheries) | Baseline node count with fish flag 56 = 10000 on adult and index groups. |
| `12ay-LBS-LLIDXmidsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with intermediate penalty | fish flag 16=1 (16 fisheries); -999 61=4; fish flag 56=500000 (16 fisheries) | Uses fish flag 56 = 500000, between the default and the soft case. |
| `12az-LBS-LLIDXmidvsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with mid very-soft penalty | fish flag 16=1 (16 fisheries); -999 61=4; fish flag 56=50000 (16 fisheries) | Uses fish flag 56 = 50000, between the soft and very soft cases. |
| `12ba-LBS-LLcoreIDXmono-N4` | Adult + index tail | 4-node non-decreasing core longline and index selectivity | fish flag 16=1 (13 fisheries); -999 61=4 | Combines the index group with only core adult longline gears. |
| `12bb-LBS-LLOSIDXmono-N4` | Adult + index tail | 4-node non-decreasing oceanic longline and index selectivity | fish flag 16=1 (7 fisheries); -999 61=4 | Combines index monotonicity with the LL.OS-derived adult groups. |
| `12bc-LBS-PSdome20-N4` | Dome/cutoff | 4-node length-based selectivity with main purse-seine dome cutoffs set to 20 | -999 61=4; fish flag 3=20 (6 fisheries) | Applies a common lower cutoff to the main associated/unassociated PS groups while respecting shared selectivity groups. |
| `12bd-LBS-PSdome35-N4` | Dome/cutoff | 4-node length-based selectivity with main purse-seine dome cutoffs set to 35 | -999 61=4; fish flag 3=35 (6 fisheries) | A high-cutoff PS case that relaxes terminal-zero pressure without removing the dome form. |
| `12be-LBS-DOMPLdome15-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL cutoffs set to 15 | -999 61=4; fish flag 3=15 (5 fisheries) | Moderately relaxes the very low domestic and pole-line terminal-zero cutoffs. |
| `12bf-LBS-DOMPLdome25-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL cutoffs set to 25 | -999 61=4; fish flag 3=25 (5 fisheries) | Strongly relaxes DOM/PL terminal-zero cutoffs while keeping the dome mechanism. |
| `12bg-LBS-NoPSDome-N4` | Dome/cutoff | 4-node length-based selectivity with PS/JP dome constraints removed | fish flag 16=0 (10 fisheries); -999 61=4; fish flag 3=37 (10 fisheries) | Removes dome/terminal-zero constraints for PS/JP gears only, preserving DOM/PL constraints. |
| `12bh-LBS-NoDOMPLDome-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL dome constraints removed | fish flag 16=0 (5 fisheries); -999 61=4; fish flag 3=37 (5 fisheries) | Removes dome/terminal-zero constraints for domestic and pole-line small-fish gears only. |
| `12bi-LBS-Surface75-2-N4` | Young-zero | 4-node length-based selectivity with two young ages set to zero for surface/small-fish gears | fish flag 75=2 (15 fisheries); -999 61=4 | A stronger young-age exclusion for PS/PL/DOM gears, applied consistently over shared selectivity groups. |
| `12bj-LBS-LLIDXsoft-N6` | Adult + index tail | 6-node non-decreasing longline/index selectivity with softer penalty | fish flag 16=1 (16 fisheries); -999 61=6; fish flag 56=100000 (16 fisheries) | Crosses the flexible N6 spline with the adult/index monotone penalty-strength axis. |
| `12bk-LBS-LLIDXvsoft-N6` | Adult + index tail | 6-node non-decreasing longline/index selectivity with very soft penalty | fish flag 16=1 (16 fisheries); -999 61=6; fish flag 56=10000 (16 fisheries) | Tests whether a more flexible spline needs only light monotone-tail guidance. |
| `12bl-LBS-LLIDXsoft-N3` | Adult + index tail | 3-node non-decreasing longline/index selectivity with softer penalty | fish flag 16=1 (16 fisheries); -999 61=3; fish flag 56=100000 (16 fisheries) | Crosses the strongest smoothing case with a less rigid monotone-tail penalty. |
| `12bm-LBS-LLIDXvsoft-N3` | Adult + index tail | 3-node non-decreasing longline/index selectivity with very soft penalty | fish flag 16=1 (16 fisheries); -999 61=3; fish flag 56=10000 (16 fisheries) | Separates low node count from a hard monotone-tail constraint. |
| `12bn-LBS-IDXsoft-N4` | Index tail | 4-node index non-decreasing selectivity with softer penalty | fish flag 16=1 (5 fisheries); -999 61=4; fish flag 56=100000 (5 fisheries) | Adds the missing N4 member of the index-only penalty-strength axis. |
| `12bo-LBS-IDXvsoft-N4` | Index tail | 4-node index non-decreasing selectivity with very soft penalty | fish flag 16=1 (5 fisheries); -999 61=4; fish flag 56=10000 (5 fisheries) | Tests whether the index tail needs a hard monotone penalty at the N4 node count. |
| `12bp-LBS-IDXsoft-N6` | Index tail | 6-node index non-decreasing selectivity with softer penalty | fish flag 16=1 (5 fisheries); -999 61=6; fish flag 56=100000 (5 fisheries) | Crosses flexible length selectivity with a softer index monotone-tail penalty. |
| `12bq-LBS-IDXvsoft-N6` | Index tail | 6-node index non-decreasing selectivity with very soft penalty | fish flag 16=1 (5 fisheries); -999 61=6; fish flag 56=10000 (5 fisheries) | Flexible index-tail case with only light monotone guidance. |
| `12br-LBS-LLmono-N3` | Longline tail | 3-node length-based selectivity with non-decreasing longline selectivity | fish flag 16=1 (11 fisheries); -999 61=3 | Adds the low-node member of the longline-only monotone-tail axis. |
| `12bs-LBS-LLmono-N7` | Longline tail | 7-node length-based selectivity with non-decreasing longline selectivity | fish flag 16=1 (11 fisheries); -999 61=7 | High-flexibility longline-only monotone-tail diagnostic. |
| `12bt-LBS-Bound359-1000-LLIDX-N4` | Spline bound + tail | 4-node adult/index monotone selectivity with weak spline lower-bound penalty | fish flag 16=1 (16 fisheries); -999 61=4; 1 359=1000 | Crosses the lower-bound stabilizer with the main adult/index tail diagnostic. |
| `12bu-LBS-Bound359-10000-LLIDX-N4` | Spline bound + tail | 4-node adult/index monotone selectivity with stronger spline lower-bound penalty | fish flag 16=1 (16 fisheries); -999 61=4; 1 359=10000 | Tests whether lower-tail spline stabilization and monotone adult/index tails act together. |
| `12bv-LBS-Bound359-1000-LLIDX-N5` | Spline bound + tail | 5-node adult/index monotone selectivity with weak spline lower-bound penalty | fish flag 16=1 (16 fisheries); -999 61=5; 1 359=1000 | Baseline node count crossed with both adult/index monotone tails and weak lower-bound stabilization. |
| `12bw-LBS-Bound359-10000-LLIDX-N5` | Spline bound + tail | 5-node adult/index monotone selectivity with stronger spline lower-bound penalty | fish flag 16=1 (16 fisheries); -999 61=5; 1 359=10000 | Baseline node count with the stronger lower-bound stabilizer and adult/index monotone tails. |
| `12bx-LBS-Bound359-1000-IDX-N4` | Spline bound | 4-node index monotone selectivity with weak spline lower-bound penalty | fish flag 16=1 (5 fisheries); -999 61=4; 1 359=1000 | Separates index-tail stabilization from adult longline monotonicity under the lower-bound penalty. |
| `12by-LBS-Bound359-10000-IDX-N4` | Spline bound | 4-node index monotone selectivity with stronger spline lower-bound penalty | fish flag 16=1 (5 fisheries); -999 61=4; 1 359=10000 | Index-only tail case crossed with the stronger spline lower-bound stabilizer. |
| `12bz-LBS-NoPSDome-IDX-N4` | Dome/cutoff | 4-node selectivity with PS/JP dome constraints removed and index monotone | fish flag 16=0 (10 fisheries); fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=37 (10 fisheries) | Checks whether surface-fishery dome assumptions and index tails jointly explain the depletion shift. |
| `12ca-LBS-NoDOMPLDome-IDX-N4` | Dome/cutoff | 4-node selectivity with DOM/PL dome constraints removed and index monotone | fish flag 16=0 (5 fisheries); fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=37 (5 fisheries) | Targets domestic and pole-line dome assumptions while stabilizing the index tail. |
| `12cb-LBS-PSdome20-IDX-N4` | Dome/cutoff | 4-node selectivity with main PS dome cutoffs set to 20 and index monotone | fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=20 (6 fisheries) | Lower PS terminal-zero cutoff crossed with the index-tail diagnostic. |
| `12cc-LBS-PSdome35-IDX-N4` | Dome/cutoff | 4-node selectivity with main PS dome cutoffs set to 35 and index monotone | fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=35 (6 fisheries) | Higher PS terminal-zero cutoff crossed with index-tail stabilization. |
| `12cd-LBS-DOMPLdome15-IDX-N4` | Dome/cutoff | 4-node selectivity with DOM/PL cutoffs set to 15 and index monotone | fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=15 (5 fisheries) | Moderate DOM/PL cutoff relaxation crossed with index-tail stabilization. |
| `12ce-LBS-DOMPLdome25-IDX-N4` | Dome/cutoff | 4-node selectivity with DOM/PL cutoffs set to 25 and index monotone | fish flag 16=1 (5 fisheries); -999 61=4; fish flag 3=25 (5 fisheries) | Strong DOM/PL cutoff relaxation crossed with index-tail stabilization. |
| `12cf-LBS-NoDome-LLIDX-N4` | Dome/cutoff + tail | 4-node selectivity with all inherited dome constraints removed and adult/index monotone | fish flag 16=0 (15 fisheries); fish flag 16=1 (16 fisheries); -999 61=4; fish flag 3=37 (15 fisheries) | Strong interaction case for dome assumptions plus adult/index tail behavior. |
| `12cg-LBS-RelaxLowDome-LLIDX-N4` | Dome/cutoff + tail | 4-node selectivity with low terminal-zero cutoffs relaxed and adult/index monotone | fish flag 16=1 (16 fisheries); -999 61=4; fish flag 3=20 (7 fisheries) | Less extreme dome/tail interaction than removing all dome constraints. |
| `12ch-LBS-Surface75-2-IDX-N4` | Young-zero | 4-node selectivity with surface young-zero 2 and index monotone | fish flag 16=1 (5 fisheries); fish flag 75=2 (15 fisheries); -999 61=4 | Crosses small-fish young-zero settings with index-tail stabilization. |
| `12ci-LBS-Surface75-2-LLIDX-N4` | Young-zero + tail | 4-node selectivity with surface young-zero 2 and adult/index monotone | fish flag 16=1 (16 fisheries); fish flag 75=2 (15 fisheries); -999 61=4 | Full young-zero plus adult/index tail interaction case. |
| `12cj-LBS-LL75-0-LLIDX-N4` | Young-zero + tail | 4-node selectivity with longline young-zero removed and adult/index monotone | fish flag 75=0 (7 fisheries); fish flag 16=1 (16 fisheries); -999 61=4 | Tests whether LL young-age zeros and adult/index monotone tails are compensating for each other. |
| `12ck-LBS-LL75-1-LLIDX-N4` | Young-zero + tail | 4-node selectivity with LL young-zero age count relaxed and adult/index monotone | fish flag 16=1 (16 fisheries); fish flag 75=1 (7 fisheries); -999 61=4 | Middle interaction case between removing and strengthening LL young-age zeros. |
| `12cl-LBS-LL75-3-LLIDX-N4` | Young-zero + tail | 4-node selectivity with stronger LL young-zero settings and adult/index monotone | fish flag 16=1 (16 fisheries); fish flag 75=3 (7 fisheries); -999 61=4 | Strengthens young-age exclusion while keeping adult/index tails monotone. |
| `12cm-LBS-HL75-2-LLIDX-N4` | Young-zero + tail | 4-node selectivity with strongly relaxed HL young-zero count and adult/index monotone | fish flag 16=1 (16 fisheries); fish flag 75=2 (2 fisheries); -999 61=4 | Tests whether handline young-zero assumptions interact with the adult/index tail signal. |
| `12cn-LBS-HL75-4-LLIDX-N4` | Young-zero + tail | 4-node selectivity with moderately relaxed HL young-zero count and adult/index monotone | fish flag 16=1 (16 fisheries); -999 61=4; fish flag 75=4 (2 fisheries) | Intermediate handline young-zero interaction case. |
| `12co-LBS-IDX75-1-LLIDX-N4` | Young-zero + tail | 4-node adult/index monotone selectivity with one young index age set to zero | fish flag 16=1 (16 fisheries); fish flag 75=1 (5 fisheries); -999 61=4 | Light index young-age exclusion crossed with LL+index adult-tail monotonicity. |
| `12cp-LBS-IDX75-2-LLIDX-N4` | Young-zero + tail | 4-node adult/index monotone selectivity with two young index ages set to zero | fish flag 16=1 (16 fisheries); fish flag 75=2 (5 fisheries); -999 61=4 | Middle index young-age exclusion crossed with LL+index adult-tail monotonicity. |
| `12cq-LBS-IDX75-3-LLIDX-N4` | Young-zero + tail | 4-node adult/index monotone selectivity with three young index ages set to zero | fish flag 16=1 (16 fisheries); fish flag 75=3 (5 fisheries); -999 61=4 | Strong index young-age exclusion crossed with LL+index adult-tail monotonicity. |

