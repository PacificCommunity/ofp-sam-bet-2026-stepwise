# Step 15 flexible selectivity update

This branch diverges from `final-stepwise` at Step 15. The Step 15 controls
reproduce the flexible-selectivity treatment fitted by Kflow Job 18718.

## Isolation from Job 18717

The completed Job 18717 and Job 18718 output archives have identical
`.ini`, `.frq`, `.tag` and `.age_length` inputs. Their `fishery_map.R` files
are also identical. The fitted alternatives differ only in the selectivity
controls in `doitall.sh`.

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
