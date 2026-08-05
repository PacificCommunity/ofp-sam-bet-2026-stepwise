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
| 16 | 33 | 98 | Release-group-specific mixing periods estimated using a KS D-statistic cutoff of 0.20; `tag_flags(:,2)=0`. |
| 17-19 | 33 | 98 | Same KS D-statistic mixing-period treatment; `tag_flags(:,2)=1`. |

Step 05 is the first step that applies the current reporting-rate
specification. The preceding 41-fishery matrices cannot be used directly
after the structural change, so all five matrices are rebuilt from the audited
33-fishery table. This includes the programme- and fishery-specific group IDs,
active flags, initial values, targets and penalties. The principal updated
purse-seine controls are:

| Fisheries and programme | Initial value | Target | Penalty |
| --- | ---: | ---: | ---: |
| F19/F20, RTTP and PTTP | 0.4962 | 49.62 | 354.5 |
| F25/F27, RTTP and PTTP | 0.5121 | 51.21 | 739.2 |
| F26/F28, PTTP | 0.5282 | 52.82 | 231.2 |

Introducing these controls at Step 05 is part of constructing a valid
reporting-rate map for the revised fishery structure. Consequently, the
Step 04-to-Step 05 comparison represents the combined structural transition,
including its required reporting-rate remapping. Step 17 does not introduce
new reporting-rate values; it changes only their treatment within pre-mixing
windows.

From Step 08 through Step 22 the five numeric reporting-rate matrices are
identical. F25/F27 and F26/F28 retain separate West and East reporting-rate
groups. Every positive tag recapture is validated against positive active,
initial, target, and penalty cells.

Step 16 reads only tag-flag column 1 from
`SC22-IP10-regionMean@efe3107/BET/ini.mix-period/bet.2026.mix-0.2.ini`.
Step 17 changes only column 2. No `doitall.sh` override replaces the
release-group mixing periods or reporting-rate matrices.
