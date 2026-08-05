# Step 15 flexible selectivity update

This branch diverges from `final-stepwise` at Step 15. The Step 15 controls
reproduce the flexible-selectivity treatment fitted by Kflow Job 18718.

## Isolation from Job 18717

The completed Job 18717 and Job 18718 output archives have identical
`.ini`, `.frq`, `.tag` and `.age_length` inputs. Their archived
`fishery_map.R` files are also identical, but that shared display file carries
the Job 18717 grouping and F33 logistic label and therefore does not describe
the controls executed by Job 18718. The fitted alternatives themselves differ
only in the selectivity controls in `doitall.sh`.

| Setting | Job 18717 | Job 18718 |
| --- | --- | --- |
| Phase 1 extraction groups | F2/F3 and F7/F9 shared | F1-F28 independent |
| Phase 1 index groups | F29-F33 already separate | F29-F33 initially share group 29 |
| Phase 5 index groups | F29-F33 remain separate | F29-F33 split into groups 29-33 |
| F1/F2/F3/F5/F29 nodes | Four | Default five |
| F33 form | Asymptotic logistic | Flexible cubic spline |

Both treatments retain the same fishery-specific spline-age and young-age
controls where those were already selected, including the youngest five ages
fixed at zero for F14 and F15. Job 18718 therefore changes the amount of
selectivity sharing and curve flexibility; it does not change fishery identity,
size data, CAAL, tag mixing, reporting rates, effort creep or DM weighting.

For Steps 15-19, the repository's generated `fishery_map.R` now records both
the Phase-1 and Phase-5 Job 18718 groups, exposes the final Phase-5 groups to
the viewer, and records the executed age-based cubic-spline form and node
counts. This is an audit/display correction only; it does not alter MFCL
inputs or controls. The agreed domestic labels remain `21.DOM.ID.2`,
`22.DOM.PH.2`, and `23.DOM.VN.2`, with group `DOM`; `MISC` is not used.

The source Job 18718 `doitall.sh` SHA256 is
`4a6a76faa6049b1c7a6b149e967c2e9d7653c2db3443c5cdcac9d7d1c2f8d659`.
The validator locks its Phase 1/5 selectivity-control signature to SHA256
`def9bf5fecf1a6e7e5890a8ea9ff2fcc577442334510c8409836bd43caa00400`.

## Scientific interpretation

The flexible treatment avoids imposing the targeted sharing, reduced-node and
logistic constraints used by Job 18717. It is therefore a direct sensitivity
to selectivity complexity. Comparison should focus on composition residuals,
selectivity curves, parameters at bounds, likelihood components and
uncertainty; the label “flexible” does not imply that this treatment is
preferred before those diagnostics are reviewed.

The design is consistent with the assessment guidance to test whether revised
fishery definitions and heterogeneous regional size compositions require
greater selectivity flexibility:

- Punt, A. E., Maunder, M. N., and Ianelli, J. N. (2023), independent review
  of recent WCPO yellowfin tuna assessment (SC19-SA-WP-01).
- Hamer, P. (2026), SPC pre-assessment workshop summary
  (WCPFC-SC22-2026-SA-IP01).
- Peatman, T. et al. (2026), size-frequency analysis for the 2026 bigeye and
  yellowfin assessments (WCPFC-SC22-2026-SA-IP06).

## Step 15 F10 weak non-decreasing penalty

Step 15 introduces the deterministic F10 treatment fitted by Kflow Job 19325
together with the Job 18718 selectivity update, and Steps 16-19 carry both
forward. An
archive-level comparison with Job 18718 found byte-identical `bet.frq`,
`bet.tag`, `bet.age_length`, `bet.reg_scaling`, `mfcl.cfg` and `bet.ini` files.
After comments and wrapper-only text are removed, its executable-control diff
from Job 18718 is exactly:

```text
-10 16 1
-10 56 10000
```

Flag 16 activates the non-decreasing selectivity penalty for F10 and flag 56
sets its weight to 10,000. This is one percent of MFCL's 1,000,000 default
weight when flag 56 is absent. Every affected step deliberately uses its
frozen INI and the normal `mfclo64 -makepar` path. It does not load a jitter
result or any perturbed PAR.
