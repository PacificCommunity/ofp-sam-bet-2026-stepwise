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
| `01-Diag2023`, `02a-NewExe` | 41 | 118 | 119 | 2023 diagnostic shape retained. |
| `02b-Ini1007`, `02c-LnR0`, `03-FixM` | 41 | 118 | 119 | MFCL 1007 layout without changing the diagnostic tag grouping. |
| `04-NewStructure`, `05-ConvertToLength`, `06-LengthPlusLength` | 33 | 96 | 97 | 5-region tag grouping. |
| `07-DataTo2024`, `08-RegionalCPUE`, `09-NewOtoliths` | 33 | 98 | 99 | 2026 tag build with aligned reporting-rate matrices. |
| `10-TagMixingKS` to `15-DataWeighting` | 33 | 98 | 99 | Release-specific mixing periods are read from the mix-period `.ini`. |

## Alignment Checks

Generated inputs check three tag sections before Kflow submission:

| Check | Pass condition |
| --- | --- |
| Reporting-rate matrices | Each matrix has `release groups + 1` rows and one column per fishery. |
| Tag-control rows | One row per release group. |
| Tag shed rate | One value per release group. |

For `07`-`09`, the selected 2026 tag file has 98 release groups while the source
`bet.2026.ini` reporting matrices had fewer rows. The generator fills the
missing release rows by matching `(program, region, year, month)` from the
previous new-structure ini, then keeps the pooled row last.

The full cell-by-cell audit remains in each model folder as
`steps/<step_id>/model/tag_rep_map.R`.
