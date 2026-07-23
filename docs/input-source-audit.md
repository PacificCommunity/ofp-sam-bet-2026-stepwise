# Input Source Audit

This page answers one question: after pulling the source input repos, what is
copied as-is and what is intentionally changed in the generated model folders?

## Short Answer

| Input | Source-exact? | Intentional generated change |
| --- | --- | --- |
| `.frq` | Yes for steps 01-13. | Step 08 uses the authoritative regional CPUE replacement as supplied; it has two fewer F32 1952 quarterly records than Step 07 and no transform. Steps 14-15 change only index-fishery effort values for effort creep. |
| `.tag` | Yes for all steps. | None. `tag_rep_map.R` is an MFCLShiny display/audit sidecar, not an MFCL input. |
| `.age_length` | Records are copied from source. | Steps 04-15 set effective sample size from `1` to `0.75`. |
| `.ini` | 01 and 02a are unchanged from source. Later steps are generated from source baselines. | MFCL 1007 conversion, BET 2026 L-W, `LN(R0)` from 04 onward, FixM, tag/RR alignment, and current-reader compatibility edits. |
| `bet.reg_scaling` | Steps 08-15 contain source rows 53-72 by default. | This exact 20x5 compact matrix is streamed into the flag-defined prior window. |
| `bet.reg_scaling.full` | The full 292x5 source is copied for steps 08-15. | Preserved for alternative-period sensitivities; MFCL does not read this filename. |

## Source Repos Checked

| Repo | Current source commit | BET-side note |
| --- | --- | --- |
| `ofp-sam-2026-BET-YFT-frq-build` | `f89e066` | Latest pulled changes affect YFT files only; BET `.frq` sources used here are unchanged. |
| `ofp-sam-2026-BET-YFT-build-ini` | `f8faf7c` | BET base and mix-period INIs contain the updated RR group IDs and initial values. |
| `ofp-sam-2026-BET-YFT-tag-prep` | `e0b427d` | Current source. BET grouping changes were introduced in `3dad64e`; `e0b427d` changes YFT only and leaves the BET files identical to `3dad64e`. |
| `ofp-sam-2026-BET-YFT-age-length-build` | `a26b694` | Source CAAL records are used; generated files only change effective sample size. |

## By File Type

| File type | Steps | Source file | Generated difference |
| --- | --- | --- | --- |
| `.frq` | 01-07 | Selected source in `frq-build`, diagnostic repo, or archived 2023 replication inputs. | None found in byte-for-byte source checks. |
| `.frq` | 08-13 | `BET/bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq` | Authoritative regional CPUE replacement; two fewer F32 1952 quarterly records than Step 07, copied without transformation. |
| `.frq` | 14-15 | `BET/bet.2026.new-strucure.regional-cpue.wt-as-len-plus-len.frq` | Effort values for index fisheries 29-33 are multiplied by the agreed effort-creep schedule. |
| `.tag` | 01-15 | Selected source `.tag` for each step family. | None. |
| `.age_length` | 01-03 | Diagnostic or archived 2023 replication source. | None. |
| `.age_length` | 04-08 | `BET/bet.2023.new-structure.age_length` | 112 effective-sample-size values change from `1` to `0.75`. |
| `.age_length` | 09-15 | `BET/bet.2026.age_length` | 181 effective-sample-size values change from `1` to `0.75`. |
| `bet.reg_scaling` | 08-15 | `BET/bet.2026.reg_scaling` | Extracts rows 53-72 and all 5 region columns as the MFCL input. |
| `bet.reg_scaling.full` | 08-15 | `BET/bet.2026.reg_scaling` | Copies all 292 rows and 5 region columns for sensitivity regeneration. |

## INI Edits

| Steps | Source baseline | Generated `.ini` edits | Why |
| --- | --- | --- | --- |
| 01 | 2023 diagnostic `bet.ini` | No edit. | Keeps the historical diagnostic input exactly as run in 2023. |
| 02a | Archived 2023 replication `bet.ini` | No edit. The ini remains MFCL 1003 format. | Isolates the current executable effect before changing the ini layout. |
| 02b | 02a generated input | Sets ini version to `1007`; inserts 118 `# tag flags` rows with two-quarter mixing and `tag_flags(it,2)=0`; inserts a zero tag-shed vector; inserts MFCL 1007 defaults for `LN(R0)=25` and Richards growth parameter `0`. | Converts the 2023 replication ini into a current-reader layout without changing the assessment data. |
| 02c | 02b generated input | Changes `# Length-weight parameters` from `3.063397e-05 2.932384` to `3.073533e-05 2.932410`. `LN(R0)` remains `25`. | Isolates the BET 2026 bias-corrected L-W update before later structural changes. |
| 03 | 02c generated input | Replaces the `# age_pars` natural-mortality row with the fixed-M row from the 01 diagnostic `mgc=-5` final par. | Carries the chosen diagnostic M estimate and 02c L-W update into later current-executable runs. |
| 04-06 | `BET/bet.2023.new.structure.ini` from `ofp-sam-2026-BET-YFT-build-ini@f8faf7c`, with `config/rrpttp26-reporting-rates.csv` | Applies FixM, `LN(R0)=17`, BET 2026 L-W, and tag/RR alignment. The 96-release-group tag source is `ofp-sam-2026-BET-YFT-tag-prep@e0b427d`; SC22 BET means and penalties are mapped by tag programme and fishery, with West and East groups kept separate. | Introduces the final reporting-rate specification with the 33-fishery structure instead of retaining a pooled West/East group. |
| 07-09 | Primary base `BET/bet.2026.ini` plus `config/rrpttp26-reporting-rates.csv` | Keeps two-quarter mixing from the base, maps the carried SC22 BET reporting-rate specification to the expanded 2026 tag rows, sets `tag_flags(it,2)=0`, and validates positive recaptures. | Extends the tag-release rows without changing the reporting-rate means, penalties, or West/East grouping. |
| 10-15 | `BET/ini.mix-period/bet.2026.mix-0.2.ini` from `ofp-sam-2026-BET-YFT-build-ini@f8faf7c` | Uses release-specific KS mixing and updated RR group IDs from one primary INI; sets `tag_flags(it,2)=0`, raises two zero mixing periods to `1`, and validates positive recaptures. | Preserves KS mixing without reverting the refreshed reporting-rate grouping. |

Current tag-flag check:

| File | Release rows | Mixing-period column | `tag_flags(it,2)` column |
| --- | ---: | --- | --- |
| Source `bet.2023.new.structure.ini` | 98 tag-control rows for a 96-release-group tag file | all `2` | all `1` |
| Generated step 04 ini | 96 | all `2` | all `0` |
| Source `bet.2026.ini` | 98 | all `2` | all `1` |
| Generated step 07 ini | 98 | all `2` | all `0` |
| Source `bet.2026.mix-0.2.ini` | 98 | `0`, `1`, `2`, `3`, `4` release-specific values | all `1` |
| Generated step 10 ini | 98 | source `0` values raised to `1`; other values retained | all `0` |

Generated steps 04-15 harmonize starting values within one reporting-rate
group where native MFCL requires a common grouped start. Every positive tag
recapture is then validated against nonzero RR, active, target, and penalty
cells. This harmonization does not change reporting-rate group flags.
Starting at step 04, PTTP West and East are separate groups 17 and 18 and use
the final SC22 BET means and penalties. Step 07 maps that same specification
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
| 14-15 | 29-33 | 1,440 per step | 1%/yr for 1952-1976, then 0.5%/yr for 1977-2024. |

Only positive effort values are changed. Catch, size compositions, tag inputs,
and regional-scaling inputs are not changed by the effort-creep step.
