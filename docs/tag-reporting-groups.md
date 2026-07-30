# Tag reporting-rate inputs

MFCL reads five reporting-rate matrices from `bet.ini`:

| Block | Meaning |
| --- | --- |
| `# tag fish rep` | Initial reporting-rate values. |
| `# tag fish rep group flags` | Group IDs. |
| `# tag_fish_rep active flags` | Estimation switches. |
| `# tag_fish_rep target` | Prior targets. |
| `# tag_fish_rep penalty` | Prior penalties. |

`tag_rep_map.R` is a display and audit sidecar; it is not read by MFCL.

| Steps | Fisheries | Release groups | Treatment |
| --- | ---: | ---: | --- |
| 01 | 41 | 118 | Archived diagnostic layout. |
| 02-04 | 41 | 118 | INI 1007-compatible diagnostic layout; reporting assumptions retained. |
| 05-07 | 33 | 96 | Five-region 2023 tag family with audited fishery/program reporting rates. |
| 08-15 | 33 | 98 | 2026 tag family; base mixing and reporting-rate matrices retained. |
| 16 | 33 | 98 | K=0.20 release-specific mixing; `tag_flags(:,2)=0`. |
| 17-19 | 33 | 98 | Same K=0.20 mixing; `tag_flags(:,2)=1`. |

From Step 08 through Step 19 the five numeric reporting-rate matrices are
identical. F25/F27 and F26/F28 retain separate West and East reporting-rate
groups. Every positive tag recapture is validated against positive active,
initial, target, and penalty cells.

Step 16 reads only tag-flag column 1 from
`SC22-IP10-regionMean@efe3107/BET/ini.mix-period/bet.2026.mix-0.2.ini`.
Step 17 changes only column 2. No `doitall.sh` override replaces the
release-group mixing periods or reporting-rate matrices.
