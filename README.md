# BET 2026 Stepwise

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

BET 2026 MFCL stepwise model inputs. Each folder under `steps/` is a runnable
model folder with a compact README and input manifest.

## Branch Focus

This branch replaces the earlier 24-row length-based selectivity trial with a 94-row axis grid focused on plausible MFCL controls and selected interactions among those controls. All rows reuse `steps/13-LengthBasedSel/model`, are disabled by default, and run only when explicitly selected with `STEP_SELECT`, so the normal `main` stepwise sequence is unchanged.

The grid stays close to options supported by MFCL ongoing-dev: cubic-spline node count (`fish flag 61`), length-based selectivity (`fish flag 26 = 3`), non-decreasing tails (`fish flag 16 = 1`), dome/terminal-zero cutoffs (`fish flags 16 = 2` and `3`), young-zero selectivity (`fish flag 75`), monotone penalty weight (`fish flag 56`), and spline lower-bound penalty (`parest flag 359`).

Design: first vary one axis at a time, then add targeted crosses for node count x monotone-tail penalty, spline-bound x tail, dome/cutoff x tail, and young-zero x tail. This keeps the grid broad enough to diagnose interactions without launching every mathematically possible combination.

### Scenario Families

| Axis | Rows |
| --- | --- |
| Adult + index tail | 17 |
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

| Model | Axis | Change | Reason |
| --- | --- | --- | --- |
| `13b-LBS-N3` | Node count | length-based selectivity with 3 cubic-spline nodes | Reduces length-based spline flexibility from the Step 13 baseline of 5 nodes. |
| `13c-LBS-N4` | Node count | length-based selectivity with 4 cubic-spline nodes | Moderate node reduction between the 3-node and 5-node cases. |
| `13d-LBS-N6` | Node count | length-based selectivity with 6 cubic-spline nodes | Increases flexibility to test whether the baseline depletion shift is a low-node artifact. |
| `13e-LBS-IDXmono-N5` | Index tail | baseline 5-node length-based selectivity with non-decreasing index selectivity | Applies the monotone penalty to the five index fisheries only. |
| `13f-LBS-IDXmono-N4` | Index tail | 4-node length-based selectivity with non-decreasing index selectivity | Combines moderate smoothing with monotone survey/index selectivity. |
| `13g-LBS-IDXmono-N3` | Index tail | 3-node length-based selectivity with non-decreasing index selectivity | Strongly smooths the length spline while keeping index selectivity monotone. |
| `13h-LBS-LLmono-N4` | Longline tail | 4-node length-based selectivity with non-decreasing longline selectivity | Strong diagnostic: longline gears can be asymptotic, but dome-shaped targeting is also plausible. |
| `13i-LBS-LLIDXmono-N4` | Adult + index tail | 4-node length-based selectivity with non-decreasing longline and index selectivity | Strong diagnostic for whether large-fish selectivity tails are driving the depletion shift. |
| `13j-LBS-LLIDXmono-N3` | Adult + index tail | 3-node length-based selectivity with non-decreasing longline and index selectivity | Strongest smoothing plus monotone large-fish signal diagnostic. |
| `13k-LBS-LLIDXmono-N5` | Adult + index tail | baseline 5-node length-based selectivity with non-decreasing longline and index selectivity | Separates monotone-tail effects from node-count effects. |
| `13l-LBS-LLIDXsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with a softer monotone penalty | Uses fish flag 56 = 100000 for the monotone fisheries instead of the source default 1000000. |
| `13m-LBS-LLIDXvsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with a very soft monotone penalty | Uses fish flag 56 = 10000 for the monotone fisheries. |
| `13n-LBS-NoDome-N4` | Dome/cutoff | 4-node length-based selectivity with Step 13 dome/terminal-zero constraints removed | Sets fish flag 16 back to 0 for the fisheries that inherited 16 = 2 constraints. |
| `13o-LBS-RelaxLowDome-N4` | Dome/cutoff | 4-node length-based selectivity with low terminal-zero cutoffs relaxed | Raises the most restrictive 16 = 2 cutoff ages to 20 quarters. |
| `13p-LBS-RelaxDOMPL-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL terminal-zero cutoffs relaxed | Targets the DOM/PL low-age terminal-zero constraints only. |
| `13q-LBS-RelaxPS-N4` | Dome/cutoff | 4-node length-based selectivity with PS and JP terminal-zero cutoffs relaxed | Raises the PS/JP 16 = 2 cutoffs to 30 quarters. |
| `13r-LBS-DomeMid-N4` | Dome/cutoff | 4-node length-based selectivity with a common mid terminal-zero cutoff | Sets all inherited 16 = 2 cutoff ages to 25 quarters. |
| `13s-LBS-NoLowDome-IDX-N4` | Dome/cutoff | 4-node length-based selectivity with low dome constraints removed and index monotone | Removes the most restrictive terminal-zero constraints and stabilizes index tails. |
| `13t-LBS-YoungZero-PSPLDOM-N4` | Young-zero | 4-node length-based selectivity with age-1 zero selectivity for PS/PL/DOM gears | Tests whether small-fish fit is pulling selectivity and depletion upward. |
| `13u-LBS-IDXyoungzero-N4` | Young-zero | 4-node length-based selectivity with monotone index selectivity and young-index zero selectivity | Index fisheries get 16 = 1 and 75 = 2. |
| `13v-LBS-HL75-3-N4` | Young-zero | 4-node length-based selectivity with HL young-zero age count relaxed | Changes HL fisheries 14-15 from 75 = 5 to 75 = 3. |
| `13w-LBS-LL75-1-N4` | Young-zero | 4-node length-based selectivity with LL young-zero age count relaxed | Changes longline fisheries that had 75 = 2 to 75 = 1. |
| `13x-LBS-Bound359-1000-N4` | Spline bound | 4-node length-based selectivity with spline lower-bound penalty 359 = 1000 | Adds a weak penalty against spline coefficients getting stuck below -15. |
| `13y-LBS-Bound359-10000-N4` | Spline bound | 4-node length-based selectivity with spline lower-bound penalty 359 = 10000 | Adds a stronger penalty against spline coefficients getting stuck below -15. |
| `13z-LBS-N7` | Node count | length-based selectivity with 7 cubic-spline nodes | Adds flexibility beyond N6 without moving to an unconstrained high-node tail. |
| `13aa-LBS-Bound359-1000-N5` | Spline bound | 5-node length-based selectivity with weak spline lower-bound penalty | Keeps the Step 13 node count and adds the weaker lower-bound stabilizer. |
| `13ab-LBS-Bound359-10000-N5` | Spline bound | 5-node length-based selectivity with stronger spline lower-bound penalty | Keeps baseline node count while testing whether low spline coefficients are destabilizing the fit. |
| `13ac-LBS-Bound359-1000-N6` | Spline bound | 6-node length-based selectivity with weak spline lower-bound penalty | Pairs the more flexible N6 spline with light lower-bound stabilization. |
| `13ad-LBS-Bound359-10000-N6` | Spline bound | 6-node length-based selectivity with stronger spline lower-bound penalty | Tests whether N6 needs stronger protection against very low spline coefficients. |
| `13ae-LBS-IDXmono-N6` | Index tail | 6-node length-based selectivity with non-decreasing index selectivity | Checks whether index-tail stabilization still helps when the spline is more flexible. |
| `13af-LBS-IDXmono-N7` | Index tail | 7-node length-based selectivity with non-decreasing index selectivity | High-flexibility index-tail diagnostic without changing other gears. |
| `13ag-LBS-IDXsoft-N5` | Index tail | 5-node index non-decreasing selectivity with softer penalty | Keeps Step 13 node count and applies fish flag 56 = 100000 to the index group. |
| `13ah-LBS-IDXvsoft-N5` | Index tail | 5-node index non-decreasing selectivity with very soft penalty | Uses fish flag 56 = 10000 for the index group to test penalty-strength sensitivity. |
| `13ai-LBS-IDX75-1-N4` | Young-zero | 4-node index non-decreasing selectivity with one young age set to zero | Tests a light young-age exclusion for all index fisheries in their shared selectivity group. |
| `13aj-LBS-IDX75-3-N4` | Young-zero | 4-node index non-decreasing selectivity with three young ages set to zero | A stronger index young-age exclusion, applied consistently across the shared index group. |
| `13ak-LBS-LLmono-N5` | Longline tail | 5-node length-based selectivity with non-decreasing longline selectivity | Keeps baseline node count while testing adult longline asymptotic tails. |
| `13al-LBS-LLmono-N6` | Longline tail | 6-node length-based selectivity with non-decreasing longline selectivity | Tests whether LL monotone tails remain stable with more flexible length splines. |
| `13am-LBS-LLcoreMono-N4` | Longline tail | 4-node non-decreasing selectivity for core adult longline fisheries | Targets adult longline groups that already carry the inherited young-zero pattern. |
| `13an-LBS-LLcoreMono-N5` | Longline tail | 5-node non-decreasing selectivity for core adult longline fisheries | Same core LL diagnostic at the Step 13 node count. |
| `13ao-LBS-LLrecentMono-N4` | Longline tail | 4-node non-decreasing selectivity for later longline fishery groups | Focuses on the later/regional longline groups 7-11 rather than all longline gears. |
| `13ap-LBS-LLOSmono-N4` | Longline tail | 4-node non-decreasing selectivity for oceanic longline groups | Targets the LL.OS-derived fisheries 5 and 9, including the already monotone old6-derived group. |
| `13aq-LBS-LL75-0-N4` | Young-zero | 4-node length-based selectivity with inherited longline young-zero settings removed | Allows selected longline groups to estimate young-age selectivity rather than forcing the first two ages to zero. |
| `13ar-LBS-LL75-3-N4` | Young-zero | 4-node length-based selectivity with stronger longline young-zero settings | Tests whether excluding one additional young age stabilizes adult longline selectivity. |
| `13as-LBS-HL75-4-N4` | Young-zero | 4-node length-based selectivity with moderately relaxed HL young-zero age count | Intermediate HL setting between the inherited 75 = 5 and the 75 = 3 sensitivity. |
| `13at-LBS-HL75-2-N4` | Young-zero | 4-node length-based selectivity with strongly relaxed HL young-zero age count | Tests whether the handline young-age exclusion is too restrictive. |
| `13au-LBS-LLIDXmono-N6` | Adult + index tail | 6-node non-decreasing longline and index selectivity | Adult/index monotone-tail diagnostic with more flexible selectivity-at-length. |
| `13av-LBS-LLIDXmono-N7` | Adult + index tail | 7-node non-decreasing longline and index selectivity | Highest-node adult/index monotone diagnostic retained in this grid. |
| `13aw-LBS-LLIDXsoft-N5` | Adult + index tail | 5-node non-decreasing longline/index selectivity with softer penalty | Baseline node count with fish flag 56 = 100000 on adult and index groups. |
| `13ax-LBS-LLIDXvsoft-N5` | Adult + index tail | 5-node non-decreasing longline/index selectivity with very soft penalty | Baseline node count with fish flag 56 = 10000 on adult and index groups. |
| `13ay-LBS-LLIDXmidsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with intermediate penalty | Uses fish flag 56 = 500000, between the default and the soft case. |
| `13az-LBS-LLIDXmidvsoft-N4` | Adult + index tail | 4-node non-decreasing longline/index selectivity with mid very-soft penalty | Uses fish flag 56 = 50000, between the soft and very soft cases. |
| `13ba-LBS-LLcoreIDXmono-N4` | Adult + index tail | 4-node non-decreasing core longline and index selectivity | Combines the index group with only core adult longline gears. |
| `13bb-LBS-LLOSIDXmono-N4` | Adult + index tail | 4-node non-decreasing oceanic longline and index selectivity | Combines index monotonicity with the LL.OS-derived adult groups. |
| `13bc-LBS-PSdome20-N4` | Dome/cutoff | 4-node length-based selectivity with main purse-seine dome cutoffs set to 20 | Applies a common lower cutoff to the main associated/unassociated PS groups while respecting shared selectivity groups. |
| `13bd-LBS-PSdome35-N4` | Dome/cutoff | 4-node length-based selectivity with main purse-seine dome cutoffs set to 35 | A high-cutoff PS case that relaxes terminal-zero pressure without removing the dome form. |
| `13be-LBS-DOMPLdome15-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL cutoffs set to 15 | Moderately relaxes the very low domestic and pole-line terminal-zero cutoffs. |
| `13bf-LBS-DOMPLdome25-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL cutoffs set to 25 | Strongly relaxes DOM/PL terminal-zero cutoffs while keeping the dome mechanism. |
| `13bg-LBS-NoPSDome-N4` | Dome/cutoff | 4-node length-based selectivity with PS/JP dome constraints removed | Removes dome/terminal-zero constraints for PS/JP gears only, preserving DOM/PL constraints. |
| `13bh-LBS-NoDOMPLDome-N4` | Dome/cutoff | 4-node length-based selectivity with DOM/PL dome constraints removed | Removes dome/terminal-zero constraints for domestic and pole-line small-fish gears only. |
| `13bi-LBS-Surface75-2-N4` | Young-zero | 4-node length-based selectivity with two young ages set to zero for surface/small-fish gears | A stronger young-age exclusion for PS/PL/DOM gears, applied consistently over shared selectivity groups. |
| `13bj-LBS-LLIDXsoft-N6` | Adult + index tail | 6-node non-decreasing longline/index selectivity with softer penalty | Crosses the flexible N6 spline with the adult/index monotone penalty-strength axis. |
| `13bk-LBS-LLIDXvsoft-N6` | Adult + index tail | 6-node non-decreasing longline/index selectivity with very soft penalty | Tests whether a more flexible spline needs only light monotone-tail guidance. |
| `13bl-LBS-LLIDXsoft-N3` | Adult + index tail | 3-node non-decreasing longline/index selectivity with softer penalty | Crosses the strongest smoothing case with a less rigid monotone-tail penalty. |
| `13bm-LBS-LLIDXvsoft-N3` | Adult + index tail | 3-node non-decreasing longline/index selectivity with very soft penalty | Separates low node count from a hard monotone-tail constraint. |
| `13bn-LBS-IDXsoft-N4` | Index tail | 4-node index non-decreasing selectivity with softer penalty | Adds the missing N4 member of the index-only penalty-strength axis. |
| `13bo-LBS-IDXvsoft-N4` | Index tail | 4-node index non-decreasing selectivity with very soft penalty | Tests whether the index tail needs a hard monotone penalty at the N4 node count. |
| `13bp-LBS-IDXsoft-N6` | Index tail | 6-node index non-decreasing selectivity with softer penalty | Crosses flexible length selectivity with a softer index monotone-tail penalty. |
| `13bq-LBS-IDXvsoft-N6` | Index tail | 6-node index non-decreasing selectivity with very soft penalty | Flexible index-tail case with only light monotone guidance. |
| `13br-LBS-LLmono-N3` | Longline tail | 3-node length-based selectivity with non-decreasing longline selectivity | Adds the low-node member of the longline-only monotone-tail axis. |
| `13bs-LBS-LLmono-N7` | Longline tail | 7-node length-based selectivity with non-decreasing longline selectivity | High-flexibility longline-only monotone-tail diagnostic. |
| `13bt-LBS-Bound359-1000-LLIDX-N4` | Spline bound + tail | 4-node adult/index monotone selectivity with weak spline lower-bound penalty | Crosses the lower-bound stabilizer with the main adult/index tail diagnostic. |
| `13bu-LBS-Bound359-10000-LLIDX-N4` | Spline bound + tail | 4-node adult/index monotone selectivity with stronger spline lower-bound penalty | Tests whether lower-tail spline stabilization and monotone adult/index tails act together. |
| `13bv-LBS-Bound359-1000-LLIDX-N5` | Spline bound + tail | 5-node adult/index monotone selectivity with weak spline lower-bound penalty | Baseline node count crossed with both adult/index monotone tails and weak lower-bound stabilization. |
| `13bw-LBS-Bound359-10000-LLIDX-N5` | Spline bound + tail | 5-node adult/index monotone selectivity with stronger spline lower-bound penalty | Baseline node count with the stronger lower-bound stabilizer and adult/index monotone tails. |
| `13bx-LBS-Bound359-1000-IDX-N4` | Spline bound | 4-node index monotone selectivity with weak spline lower-bound penalty | Separates index-tail stabilization from adult longline monotonicity under the lower-bound penalty. |
| `13by-LBS-Bound359-10000-IDX-N4` | Spline bound | 4-node index monotone selectivity with stronger spline lower-bound penalty | Index-only tail case crossed with the stronger spline lower-bound stabilizer. |
| `13bz-LBS-NoPSDome-IDX-N4` | Dome/cutoff | 4-node selectivity with PS/JP dome constraints removed and index monotone | Checks whether surface-fishery dome assumptions and index tails jointly explain the depletion shift. |
| `13ca-LBS-NoDOMPLDome-IDX-N4` | Dome/cutoff | 4-node selectivity with DOM/PL dome constraints removed and index monotone | Targets domestic and pole-line dome assumptions while stabilizing the index tail. |
| `13cb-LBS-PSdome20-IDX-N4` | Dome/cutoff | 4-node selectivity with main PS dome cutoffs set to 20 and index monotone | Lower PS terminal-zero cutoff crossed with the index-tail diagnostic. |
| `13cc-LBS-PSdome35-IDX-N4` | Dome/cutoff | 4-node selectivity with main PS dome cutoffs set to 35 and index monotone | Higher PS terminal-zero cutoff crossed with index-tail stabilization. |
| `13cd-LBS-DOMPLdome15-IDX-N4` | Dome/cutoff | 4-node selectivity with DOM/PL cutoffs set to 15 and index monotone | Moderate DOM/PL cutoff relaxation crossed with index-tail stabilization. |
| `13ce-LBS-DOMPLdome25-IDX-N4` | Dome/cutoff | 4-node selectivity with DOM/PL cutoffs set to 25 and index monotone | Strong DOM/PL cutoff relaxation crossed with index-tail stabilization. |
| `13cf-LBS-NoDome-LLIDX-N4` | Dome/cutoff + tail | 4-node selectivity with all inherited dome constraints removed and adult/index monotone | Strong interaction case for dome assumptions plus adult/index tail behavior. |
| `13cg-LBS-RelaxLowDome-LLIDX-N4` | Dome/cutoff + tail | 4-node selectivity with low terminal-zero cutoffs relaxed and adult/index monotone | Less extreme dome/tail interaction than removing all dome constraints. |
| `13ch-LBS-Surface75-2-IDX-N4` | Young-zero | 4-node selectivity with surface young-zero 2 and index monotone | Crosses small-fish young-zero settings with index-tail stabilization. |
| `13ci-LBS-Surface75-2-LLIDX-N4` | Young-zero + tail | 4-node selectivity with surface young-zero 2 and adult/index monotone | Full young-zero plus adult/index tail interaction case. |
| `13cj-LBS-LL75-0-LLIDX-N4` | Young-zero + tail | 4-node selectivity with longline young-zero removed and adult/index monotone | Tests whether LL young-age zeros and adult/index monotone tails are compensating for each other. |
| `13ck-LBS-LL75-1-LLIDX-N4` | Young-zero + tail | 4-node selectivity with LL young-zero age count relaxed and adult/index monotone | Middle interaction case between removing and strengthening LL young-age zeros. |
| `13cl-LBS-LL75-3-LLIDX-N4` | Young-zero + tail | 4-node selectivity with stronger LL young-zero settings and adult/index monotone | Strengthens young-age exclusion while keeping adult/index tails monotone. |
| `13cm-LBS-HL75-2-LLIDX-N4` | Young-zero + tail | 4-node selectivity with strongly relaxed HL young-zero count and adult/index monotone | Tests whether handline young-zero assumptions interact with the adult/index tail signal. |
| `13cn-LBS-HL75-4-LLIDX-N4` | Young-zero + tail | 4-node selectivity with moderately relaxed HL young-zero count and adult/index monotone | Intermediate handline young-zero interaction case. |
| `13co-LBS-IDX75-1-LLIDX-N4` | Young-zero + tail | 4-node adult/index monotone selectivity with one young index age set to zero | Light index young-age exclusion crossed with LL+index adult-tail monotonicity. |
| `13cp-LBS-IDX75-2-LLIDX-N4` | Young-zero + tail | 4-node adult/index monotone selectivity with two young index ages set to zero | Middle index young-age exclusion crossed with LL+index adult-tail monotonicity. |
| `13cq-LBS-IDX75-3-LLIDX-N4` | Young-zero + tail | 4-node adult/index monotone selectivity with three young index ages set to zero | Strong index young-age exclusion crossed with LL+index adult-tail monotonicity. |


## Step Map

Each row is one runnable Kflow model. Lettered rows are deliberate substeps:
they split one scientific change into smaller checks so differences can be
traced without guessing.

| Model | Major step | What changes | Input baseline |
| --- | --- | --- | --- |
| `01-Diag2023` | Diagnostic anchor | Reruns the 2023 diagnostic with the historical MFCL executable. | Archived 2023 diagnostic model. |
| `02a-NewExe` | Executable bridge | Runs the archived 2023 assessment replication inputs with the current MFCL executable. | 2023 assessment replication input set; MFCL 1003 ini. |
| `02b-Ini1007` | Executable bridge | Converts the 02a ini layout from MFCL 1003 to MFCL 1007. | 02a. |
| `02c-LengthWeight` | Executable bridge | Applies the BET 2026 bias-corrected length-weight parameters. | 02b. |
| `03-FixM` | FixM bridge | Applies fixed natural mortality from the 01 diagnostic `mgc=-5` final run. | 02c. |
| `04-NewStructure` | New structure | Switches to the 5-region / 33-fishery structure with global CPUE. | 2026 new-structure input, terminal year 2021. |
| `05-ConvertToLength` | Size data | Converts existing weight compositions to length. | 04. |
| `06-LengthPlusLength` | Size data | Adds the extra length compositions. | 04. |
| `07-DataTo2024` | Data update | Extends the global-CPUE input to 2024. | 06. |
| `08-RegionalCPUE` | CPUE update | Adds regional CPUE and the regional-scaling prior. | 07. |
| `09-NewOtoliths` | Age data | Adds the updated 2026 CAAL / otolith input. | 08. |
| `10-TagMixingKS` | Tag mixing | Uses release-specific mixing periods from the KS 0.2 build. | 09. |
| `11-TimeVaryingCV` | CPUE CV | Adds time-varying CPUE CV. | 10. |
| `12-OrthogonalPoly` | Recruitment | Applies the orthogonal-polynomial recruitment setting. | 11. |
| `13-LengthBasedSel` | Selectivity | Adds length-based selectivity. | 12. |
| `14-EffortCreep` | Effort creep | Applies agreed effort creep to index fisheries. | 13. |
| `15-DataWeighting` | Weighting | First data-weighting run. | 14. |

## Substep Logic

| Block | Substeps | Reason |
| --- | --- | --- |
| `02` executable bridge | `02a`, `02b`, `02c` | Separates current executable effects, MFCL 1007 ini conversion, and the BET 2026 bias-corrected L-W parameter update. |
| `05`-`15` | one row each | Each row adds one later assessment change on top of the selected baseline. |
| `13` length-based sensitivity | `13b`-`13cq` | Disabled-by-default sensitivity rows that reuse Step 13 and test length-spline nodes, monotone tails, dome/terminal-zero cutoffs, young-zero selectivity, and spline lower-bound penalties. See `steps/13-LengthBasedSel/README.md`. |

## Names Used Here

| Name | Meaning |
| --- | --- |
| 2023 assessment replication input set | The archived 2023 BET replication model inputs stored in `ofp-sam-2026-BET/mfcl/inputs/2023_rep`. |
| MFCL 1003 ini | Older ini layout with no explicit `# tag flags` block; tag mixing is still set in `doitall.sh`. |
| MFCL 1007 ini | Newer ini layout with explicit `# tag flags`, tag shed rates, and reporting-rate matrix sections. |
| `BET_PHASE10_11_CONVERGENCE` | Run-time convergence knob used by Kflow/local runs. Set `-3` for quick checks or `-5` for stricter production reruns; it applies to every selected step/substep. |

## Source Inputs And Generated Edits

These model folders are generated from source input repos, then checked and
edited by `R/prepare_bet_2026_step_inputs.R`. The exact per-step source file and
edit note is in `steps/<step_id>/input_manifest.csv`.

| File | Source repo | Generated edits |
| --- | --- | --- |
| `.frq` | `ofp-sam-2026-BET-YFT-frq-build` | Copied exactly except steps 14-15, where index-fishery effort creep is applied. |
| `.tag` | `ofp-sam-2026-BET-YFT-tag-prep` | Copied exactly. `tag_rep_map.R` is only an audit file. |
| `.age_length` | `ofp-sam-2026-BET-YFT-age-length-build` | Records copied from source; steps 04-15 change effective sample size from `1` to `0.75`. |
| `.ini` | `ofp-sam-2026-BET-YFT-build-ini` and archived diagnostic inputs | Step-specific generated edits apply BET 2026 L-W, `LN(R0)` from 04 onward, FixM, tag/RR alignment, and MFCL-reader compatibility checks. |
| `bet.reg_scaling` | `ofp-sam-2026-BET-YFT-frq-build` | Steps 08-15 use rows 53-72 from the global CPUE regional-scaling source; parest flags 77-81 define the matching 1965-1969 model-period window. |

Current BET input sources from `origin/main`:

| Source repo | Commit used |
| --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` |
| `ofp-sam-2026-BET-YFT-build-ini` | `386d169` |
| `ofp-sam-2026-BET-YFT-tag-prep` | `471b2fd` |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` |

For the exact source-vs-generated comparison, see
[`docs/input-source-audit.md`](docs/input-source-audit.md).

Latest refresh:

| Source repo | BET files pulled into generated inputs |
| --- | --- |
| `ofp-sam-2026-BET-YFT-build-ini@386d169` | `BET/bet.2023.new.structure.ini`, `BET/bet.2026.ini`, `BET/ini.mix-period/bet.2026.mix-0.2.ini`, and related RR summary CSVs with corrected RR initial values. |
| `ofp-sam-2026-BET-YFT-tag-prep@471b2fd` | `BET/bet.2023.new.structure-low.recaps.removed.tag`, `BET/bet.2026.low.recaps.removed.tag`, and related RR summary CSVs with corrected RR group initial values. |

## Where To Look

| Path | Use |
| --- | --- |
| `steps/<step_id>/README.md` | short step summary, generated input changes, controls, and checks |
| `steps/<step_id>/input_manifest.csv` | source files, commits, and generated-input notes |
| `steps/<step_id>/model/` | MFCL-ready model folder |
| `docs/run-configuration.md` | Kflow/local-run settings and output layout |
| `docs/input-source-audit.md` | concise source-vs-generated input comparison |
| `docs/tag-reporting-groups.md` | short guide to MFCL tag reporting-rate inputs |
| `R/prepare_bet_2026_step_inputs.R` | reproducible input-generation entry point |
| `debugging/` | troubleshooting records |

## Assessment Notes

| Topic | Note |
| --- | --- |
| Regional scaling | Steps 08-15 use an active-window `bet.reg_scaling` matrix for periods 53-72. Native MFCL allocates the regional-scaling input to the flag-defined window and streams the compact file into that matrix. |
| Effort creep | Steps 14-15 apply 1%/yr for 1952-1976 and 0.5%/yr for 1977-2024 to index fisheries 29-33. |
| Region maps | Steps 01-03 use the 2023 9-region asset; steps 04-15 use the 2026 5-region asset. See [`docs/region-map-assets.md`](docs/region-map-assets.md). |
| Tag reporting rates | MFCL reads the reporting-rate blocks in `bet.ini`; `tag_rep_map.R` is only a human-readable check. See [`docs/tag-reporting-groups.md`](docs/tag-reporting-groups.md). |
| Length-weight | Step 02c changes BET L-W from the 2023 value `3.063397e-05 2.932384` to the bias-corrected 2026 value `3.073533e-05 2.932410`; later steps retain it. |
| Tag input source | Steps 04-15 use BET tag/ini sources from `ofp-sam-2026-BET-YFT-build-ini@386d169` and `ofp-sam-2026-BET-YFT-tag-prep@471b2fd`. The refreshed source repos correct RR initial/group initial values; generated inputs still preserve the stepwise policies documented in each manifest. |
| Tag mixing source | Steps 10-15 use `ofp-sam-2026-BET-YFT-build-ini@386d169` `BET/ini.mix-period/bet.2026.mix-0.2.ini`; source zero mixing periods for release groups 43 and 46 are raised to `1`, while `tag_flags(it,2)=0` is retained and RR/active/target/penalty cells are validated against positive recaptures. |
