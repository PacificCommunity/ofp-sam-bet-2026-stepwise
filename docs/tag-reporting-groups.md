# Tag Reporting-Rate Inputs

This note is a compact map of the MFCL tag reporting-rate inputs. It is for
checking file structure, not for defining extra stepwise model changes.

## What MFCL Reads

MFCL reads tag reporting rates from `bet.ini`. `tag_rep_map.R` is generated
only as a human-readable audit lookup.

| `bet.ini` block | Meaning |
| --- | --- |
| `# tag fish rep` | Initial reporting-rate values. |
| `# tag fish rep group flags` | Group IDs linking release rows and fisheries. |
| `# tag_fish_rep active flags` | Estimation switches. |
| `# tag_fish_rep target` | Prior targets. |
| `# tag_fish_rep penalty` | Prior penalties. |

Rows are tag release groups plus one pooled tagged-population row. Columns are
fisheries.

```text
expected reporting-rate rows = tag release groups + 1 pooled row
```

## Step Families

| Steps | Fisheries | Release groups | Reporting-rate rows | What to check |
| --- | ---: | ---: | ---: | --- |
| `01-Diag2023`, `02-NewExe1003` | 41 | 118 | 119 | 2023 diagnostic shape retained. |
| `03-Ini1007` through `05-LengthWeight` | 41 | 118 | 119 | MFCL 1007 layout without changing the diagnostic tag grouping. |
| `06-NewStructure` through `09-TailCompression1Pct` | 33 | 96 | 97 | Five-region 2023 tag grouping; Step 09 changes only the LF tail control. |
| `10-DataTo2024` through `16-SelectivityUpdate` | 33 | 98 | 99 | 2026 tag build with aligned reporting-rate matrices and the base mixing periods. |
| `17-MIX015` through `20c-DMG8Nmax25` | 33 | 98 | 99 | Release-group-specific mixing periods are read from the mix-period `.ini`; reporting-rate exclusion begins at Step 18. |

## Alignment Checks

Generated inputs check three tag sections before Kflow submission:

| Check | Pass condition |
| --- | --- |
| Reporting-rate matrices | Each matrix has `release groups + 1` rows and one column per fishery. |
| Tag-control rows | One row per release group. |
| Tag shed rate | One value per release group. |

For `10`-`16`, the selected 2026 tag file has 98 release groups and the latest
source reporting matrices already have 99 rows, including the pooled row. The
generator copies the latest RR/active/target/penalty blocks from the mix-period
ini, then checks the dimensions and positive-recapture cells before writing
each model folder.

## Generated Changes To Tag Inputs

The `.tag` file is copied unchanged for steps 10-20. The changes below are
edits to generated `bet.ini` files so MFCL sees tag controls and RR matrices
that match the selected `.tag`.

| Scope | Source | Change in generated `bet.ini` |
| --- | --- | --- |
| `.tag`, steps 10-20 | `bet.2026.low.recaps.removed.tag` | Copied unchanged from the tag-prep repo. |
| Tag flags, steps 06-09 | `bet.2023.new.structure.ini` | Source has 98 identical tag-control rows for a 96-release-group tag file; generated rows are trimmed to 96. |
| RR matrices, steps 06-09 | `config/rrpttp26-reporting-rates.csv` | Maps the SC22 BET purse-seine means and penalties to the 96 release rows, retaining separate West and East groups. |
| Tag flags, steps 10-16 | `bet.2026.ini` | Latest 98 rows kept; column 2 `tag_flags(it,2)` set from `1` to `0`. |
| RR matrices, steps 10-20 | `bet.2026.mix-0.2.ini` | Five RR/active/target/penalty blocks, including updated group IDs, are kept at 99 rows. |
| Mixing periods, steps 17-20 | `bet.2026.mix-0.15.ini` | The selected MIX015 release-group-specific mixing periods begin at Step 17 and are carried unchanged. |
| Tag flags, step 17 | Selected MIX015 state | Column 2 `tag_flags(it,2)` remains `0`. |
| Tag flags, steps 18-20 | Generated Step 17 state | Column 2 `tag_flags(it,2)` changes to `1` at Step 18 and is carried unchanged. |
| Positive recapture RR check, steps 06-20 | Generated `.ini` and selected `.tag` | Every positive recapture must have nonzero RR, active, target, and penalty cells. |

The older fishery 19 repair helper remains available for older upstream inputs
that still have inactive RR cells, but the pinned 2026 source combination
passes by validation rather than by applying that repair.

The current source combination is
`ofp-sam-2026-BET-YFT-build-ini@d48e396` and
`ofp-sam-2026-BET-YFT-tag-prep@6d66dc3`. These revisions include the audited
BET reporting-rate grouping and conflicting-prior checks. Steps 10-16 record
`bet.2026.ini` as the primary INI and `bet.2026.mix-0.2.ini` as the five-block
reporting-rate source. Steps 17-20 use the selected
`bet.2026.mix-0.15.ini` mixing-period column. The generated files preserve the
source reporting-rate group IDs; `tag_flags(it,2)` is `0` through Step 17 and
`1` from Step 18 onward. Fishery display names and regions in `fishery_map.R` are
synchronized from `BET/bet.RR.2026.csv`; `tag_rep_map.R` then uses those same
labels so MFCLShiny reads a consistent pair of sidecars. Starting at step 06,
F25/F27 and F26/F28 use separate West and East reporting-rate groups. Step 10
retains those groups while mapping the same fishery-level specification to
the two additional 2026 release rows. Other grouped initial values are
harmonized where native MFCL requires a shared start.

The BET purse-seine means and penalties follow Table 3 of Peatman et al.
(2026), *Analysis of tag seeding data for the 2026 bigeye and yellowfin
assessments: reporting rates for purse seine fleets*,
WCPFC-SC22-2026-SA-IP05. The configuration retains the higher-precision
analysis values used by the final stepwise model.

The full cell-by-cell audit remains in each model folder as
`steps/<step_id>/model/tag_rep_map.R`.
