# Job 15989 OPR sensitivity

This model retains the complete Job 15989 configuration and changes only the
recruitment parameterisation in its native MFCL `doitall.sh`.

| Setting | Implementation |
| --- | --- |
| Parent | `21a-R1F2F3F29Shared-MIX015` (Job 15989) |
| Recruitment | Orthogonal-polynomial recruitment (OPR) `72-01-50-50` |
| Terminal treatment | Two-calendar-year end window (`E2`); terminal-recruitment penalty added in Phase 11 |
| Data and structure | Job 15989 five-region, 33-fishery inputs |
| Selectivity | Job 15984 grouping, including shared F2/F3/F29 Region 1 selectivity |
| Tag mixing | SC22-IP10 `K = 0.15` |
| Composition likelihood | Dirichlet-multinomial, G8, `Nmax = 25` |
| Natural mortality | Job 15989 fixed Lorenzen specification |

OPR is introduced in Phase 3 after the standard Phase 1-2 initialization.
The standard recruitment-deviation and regional recruitment-distribution
parameters are disabled when the OPR coefficients are activated. Phase 10
fits the unpenalized OPR model; Phase 11 adds the reviewed terminal-recruitment
penalty and writes the final parameter file.
