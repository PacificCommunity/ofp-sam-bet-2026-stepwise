# Selectivity-form sensitivity

## Purpose

These models test whether inference from the Step 17b BET 2026 DM model is sensitive to the dome/old-age-tail selectivity-form penalties for F15 and F22. The reference fitted model is Kflow Job 13328.

The reference penalty was 276.371. F22 `DOM.PH.2` contributed 101.92 (36.9%) and F15 `HL.PH.2` contributed 98.71 (35.7%); together they accounted for 72.6% of the total. Their influence is therefore tested separately and jointly.

## Models

| Model | Change from Step 17b | Purpose |
| --- | --- | --- |
| `18a-F22FormRelaxed` | F22 fishery flag 16: `2` to `0` | Remove the F22 dome/old-age-tail penalty only. |
| `18b-F15FormRelaxed` | F15 fishery flag 16: `2` to `0` | Remove the F15 dome/old-age-tail penalty only. |
| `18c-F15F22FormRelaxed` | F15 and F22 fishery flag 16: `2` to `0` | Remove both dominant penalties. |

All other data, biological assumptions, selectivity settings, DM configuration (`G8PSSET`, `Nmax = 25`), regional-scaling weight (`REGW100`), tag settings and estimation phases are unchanged. These are assumption sensitivities, not candidate replacements selected in advance.

## Evaluation

Compare convergence, Hessian eigenvalues, likelihood components, fitted F15/F22 selectivity, biomass-profile curvature and key derived quantities. A marked reduction in the low-biomass profile cost would indicate that the lower profile limb is sensitive to these old-age selectivity assumptions.
