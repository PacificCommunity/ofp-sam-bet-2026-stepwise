# 18a Estimated Lorenzen natural mortality

This sensitivity uses the complete Job 14363 (`17d-AllSelectivityFormRelaxed`)
model specification and estimates the Lorenzen natural-mortality log-intercept
that is fixed in the parent fit.

## Model change

| Setting | Job 14363 parent | Sensitivity |
| --- | --- | --- |
| Lorenzen form | Parest flag 109 = 3 | Unchanged |
| Log-intercept starting value | -2.54930339768360 | Unchanged |
| Natural-mortality coefficients estimated | Parest flag 121 = 0 | Parest flag 121 = 1 |
| Lorenzen length slope | Fixed | Fixed |

Flag 121 remains 0 during staged model construction and changes to 1 in
Phase 10. This preserves the stable Job 14363 pathway before estimating the
single Lorenzen natural-mortality coefficient in the final optimization.
All other model inputs, likelihoods, parameter controls, phase settings and
selectivity specifications are byte-identical to the Job 14363 source model.

## Provenance

| Field | Value |
| --- | --- |
| Scientific parent | Kflow Job 14363, `17d-AllSelectivityFormRelaxed` |
| Parent source commit | `4adbb3941811ec8b7e90a53cec1f435a77a11203` |
| Parent model folder | `steps/17d-AllSelectivityFormRelaxed/model` |
| Sensitivity folder | `steps/18a-LorenzenMEstimated/model` |
| Expected diagnostics | Hessian and total-average-biomass profile |

The parent model is rerun from its frozen inputs. The Lorenzen log-intercept is
released only after the parent model structure has been established.
