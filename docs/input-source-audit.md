# Input Source Audit

This page answers one question: after pulling the source input repos, what is
copied as-is and what is intentionally changed in the generated model folders?

## Short Answer

| Input | Source-exact? | Intentional generated change |
| --- | --- | --- |
| `.frq` | Yes for steps 01-18. | Step 11 uses the authoritative regional CPUE replacement as supplied; it has two fewer F32 1952 quarterly records than Step 10 and no transform. Steps 19-20 change only index-fishery effort values for effort creep. |
| `.tag` | Yes for all steps. | None. `tag_rep_map.R` is an MFCLShiny display/audit sidecar, not an MFCL input. |
| `.age_length` | Records are copied from source. | Steps 06-13 retain the pre-update age input. Step 14 adds the new conditional age-at-length data with the 0.75 weighting factor used in the 2023 BET assessment; Step 15 compares spatial weighting, and SUB075 is carried from 15b onward. |
| `.ini` | Steps 01 and 02 are unchanged from their respective source inputs. Later steps are generated from source baselines. | MFCL 1007 conversion at Step 03, FixM at Step 04, BET 2026 L-W at Step 05, the five-region `LN(R0)` setting from Step 06, tag/RR alignment, and current-reader compatibility edits. |
| `bet.reg_scaling` | Steps 11-20 contain source rows 53-72 by default. | This exact 20x5 compact matrix is streamed into the flag-defined prior window. |
| `bet.reg_scaling.full` | The full 292x5 source is copied for steps 11-20. | Preserved for alternative-period sensitivities; MFCL does not read this filename. |

## Source Repos Checked

| Repo | Current source commit | BET-side note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Latest pulled changes affect YFT files only; BET `.frq` sources used here are unchanged. |
| `ofp-sam-2026-BET-YFT-build-ini` | `5b2fb60` (`SC22-IP10-based`) | All build-ini sources use this branch, not `main`; it contains the aligned RR matrices and SC22-IP10 Appendix A mixing periods. |
| `ofp-sam-2026-BET-YFT-tag-prep` | `6d66dc3` | Current low-recapture-filtered BET tag source with the audited reporting-rate grouping update. |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | Source CAAL records are used; generated files only change effective sample size. |

## By File Type

| File type | Steps | Source file | Generated difference |
| --- | --- | --- | --- |
| `.frq` | 01-10 | Selected source in `frq-build`, diagnostic repo, or archived 2023 replication inputs. | None found in byte-for-byte source checks. |
| `.frq` | 11-18 | `BET/bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq` | Authoritative regional CPUE replacement; two fewer F32 1952 quarterly records than Step 10, copied without transformation. |
| `.frq` | 19-20 | `BET/bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq` | Effort values for index fisheries 29-33 are multiplied by the agreed effort-creep schedule. |
| `.tag` | 01-20 | Selected source `.tag` for each step family. | None. |
| `.age_length` | 01-05 | Diagnostic or archived 2023 replication source. | None. |
| `.age_length` | 06-13 | `BET/bet.2023.new-structure.age_length` | 112 effective-sample-size values change from `1` to `0.75`. |
| `.age_length` | 14 | New 2026 conditional age-at-length source with weighting factor 0.75 | Establishes the common new-age-data reference state using the 2023 BET assessment weighting. |
| `.age_length` | 15a-15b | REG075 or SUB075 source | Compares the two spatial age-weighting treatments against Step 14. |
| `.age_length` | 16-20 | SUB075 source | Carries the selected Step 15b treatment unchanged. |
| `bet.reg_scaling` | 11-20 | `BET/bet.2026.reg_scaling` | Extracts rows 53-72 and all 5 region columns as the MFCL input. |
| `bet.reg_scaling.full` | 11-20 | `BET/bet.2026.reg_scaling` | Copies all 292 rows and 5 region columns for sensitivity regeneration. |

## INI Edits

| Steps | Source baseline | Generated `.ini` edits | Why |
| --- | --- | --- | --- |
| 01 | 2023 diagnostic `bet.ini` | No edit. | Keeps the historical diagnostic input exactly as run in 2023. |
| 02 | Archived 2023 replication `bet.ini` | No edit. The ini remains MFCL 1003 format. | Isolates the current executable effect before changing the ini layout. |
| 03 | Step 02 generated input | Sets ini version to `1007`; inserts 118 `# tag flags` rows with two-quarter mixing and `tag_flags(it,2)=0`; inserts a zero tag-shed vector; inserts MFCL 1007 defaults for `LN(R0)=25` and Richards growth parameter `0`. | Converts the 2023 replication ini into a current-reader layout without changing the assessment data. |
| 04 | Step 03 generated input | Replaces the `# age_pars` natural-mortality row with the fixed-M row from the 01 diagnostic `mgc=-5` final par. | Establishes fixed M before updating the length-weight conversion. |
| 05 | Step 04 generated input | Changes `# Length-weight parameters` from `3.063397e-05 2.932384` to `3.073533e-05 2.932410`; the fixed-M row is unchanged. | Isolates the BET 2026 bias-corrected L-W update after fixed M. |
| 06-08 | `BET/bet.2023.new.structure.ini` from `ofp-sam-2026-BET-YFT-build-ini@5b2fb60` (`SC22-IP10-based`), with `config/rrpttp26-reporting-rates.csv` | Applies FixM, `LN(R0)=17`, BET 2026 L-W, and tag/RR alignment. The 96-release-group tag source is `ofp-sam-2026-BET-YFT-tag-prep@6d66dc3`; SC22 BET means and penalties are mapped by tag programme and fishery, with West and East groups kept separate. | Introduces the final reporting-rate specification with the 33-fishery structure instead of retaining a pooled West/East group. |
| 09 | Same 2021 five-region inputs as Step 08 | No `.ini` edit; only doitall parest flag 313 changes from `0` to `1`. | Introduces LF tail aggregation after weight-to-length conversion and observed-length supplementation. |
| 10-16 | `BET/bet.2026.ini` from `SC22-IP10-based` plus `config/rrpttp26-reporting-rates.csv` | Keeps two-quarter mixing from the base, maps the carried SC22 BET reporting-rate specification to the expanded 2026 tag rows, sets `tag_flags(it,2)=0`, and validates positive recaptures. | Extends the tag-release rows without changing the reporting-rate means, penalties, or West/East grouping. |
| 17 | The same branch base plus `BET/ini.mix-period/bet.2026.mix-0.15.ini` | Copies only the SC22-IP10 release-group mixing-period column and retains `tag_flags(it,2)=0`. The five RR matrices remain identical to Steps 10-16. | Isolates the mixing-period change while reporting rates still apply during the configured periods. |
| 18-20 | The same branch base and MIX015 source, rebuilt independently | Keeps the Step 17 mixing periods and changes only `tag_flags(it,2)` from `0` to `1`. Step 20c additionally resets parest flag 313 from `1` to `0` when selecting the DM likelihood; flag 320=5 controls DM length-bin support. | Removes reporting rates only from predicted recaptures within the pre-mixing windows, without changing their post-mixing use or numeric values, groups, targets, or penalties; also avoids carrying an inactive normal-likelihood threshold into the final DM input. |

Current tag-flag check:

| File | Release rows | Mixing-period column | `tag_flags(it,2)` column |
| --- | ---: | --- | --- |
| Source `bet.2023.new.structure.ini` | 98 tag-control rows for a 96-release-group tag file | all `2` | all `1` |
| Generated step 06 ini | 96 | all `2` | all `0` |
| Source `bet.2026.ini` | 98 | all `2` | all `1` |
| Generated step 10 ini | 98 | all `2` | all `0` |
| Source `bet.2026.mix-0.15.ini` from `SC22-IP10-based` | 98 | `0`, `1`, `2`, `3`, `4` release-group-specific values | all `1` |
| Generated step 17 ini | 98 | selected MIX015 release-group-specific values | all `0` |
| Generated step 18 ini | 98 | selected MIX015 release-group-specific values | all `1` |

Generated steps 06-20 harmonize starting values within one reporting-rate
group where native MFCL requires a common grouped start. Every positive tag
recapture is then validated against nonzero RR, active, target, and penalty
cells. This harmonization does not change reporting-rate group flags.
Starting at step 06, PTTP West and East are separate groups 17 and 18 and use
the final SC22 BET means and penalties. Step 10 maps that same specification
to the expanded 2026 tag rows. The reporting-rate source is machine-readable
in each `input_manifest.csv`. The older fishery
19 fallback repair remains in the generator only for older source
inputs that still need it; it is not the active change for this pull.

For regional-scaling sensitivities, regenerate with
`BET_REG_SCALING_START_PERIOD` and `BET_REG_SCALING_END_PERIOD`. The generator
slices the corresponding rows from `bet.reg_scaling.full` into the executable
filename and updates flags 79-80 against the unchanged 292-period timeline.

## Effort Creep Details

| Steps | Fisheries | Records changed | Rule |
| --- | ---: | ---: | --- |
| 19-20 | 29-33 | 1,440 per step | 1%/yr for 1952-1976, then 0.5%/yr for 1977-2024. |

Only positive effort values are changed. Catch, size compositions, tag inputs,
and regional-scaling inputs are not changed by the effort-creep step.
