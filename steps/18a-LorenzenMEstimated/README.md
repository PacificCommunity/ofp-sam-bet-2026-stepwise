# 18a Estimated Lorenzen natural mortality

This sensitivity continues directly from the completed Job 14363
(`17d-AllSelectivityFormRelaxed`) final parameter file and estimates the
Lorenzen natural-mortality log-intercept that is fixed in the parent fit.

## Model change

| Setting | Job 14363 parent | Sensitivity |
| --- | --- | --- |
| Lorenzen form | Parest flag 109 = 3 | Unchanged |
| Log-intercept starting value | -2.54930339768360 | Unchanged |
| Natural-mortality coefficients estimated | Parest flag 121 = 0 | Runtime switch 121 = 1 |
| Lorenzen length slope | Fixed | Fixed |

The fit starts from the Job 14363 final parameter state. A single continuation
optimization activates flag 121 = 1, with 10,000 function evaluations and a
maximum-gradient convergence target of 1e-4. The parent final parameter values
provide all other starting values, and the Lorenzen length slope remains fixed.

## Provenance

| Field | Value |
| --- | --- |
| Scientific parent | Kflow Job 14363, `17d-AllSelectivityFormRelaxed` |
| Parent source commit | `4adbb3941811ec8b7e90a53cec1f435a77a11203` |
| Parent model folder | `steps/17d-AllSelectivityFormRelaxed/model` |
| Sensitivity folder | `steps/18a-LorenzenMEstimated/model` |
| Expected diagnostics | Hessian and total-average-biomass profile |

The parent model is not rebuilt from its initial inputs. Its archived compact
payload supplies the final parameter file used by this continuation fit.
