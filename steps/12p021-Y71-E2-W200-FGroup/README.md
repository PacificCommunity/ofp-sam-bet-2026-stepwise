# 12p021-Y71-E2-W200-FGroup

Tests 71 annual OPR coefficients with a 2-calendar-year endpoint and penalty weight 200. This distinguishes genuine terminal smoothing from a spike merely moving to the first free quarter.

## Controls

- OPR profile: `71-01-50-50`; terminal window: 2 calendar year(s) = 8 quarters; component endpoint: `0`.
- Legacy annual OPR override: `parest_flag(221)=0`.
- Terminal penalty: requested weight `200`; `parest_flag(397)=2000`; final matched phase: 1,000 evaluations.
- OPR trend flag: `parest_flag(153)=0`.
- Selectivity profile: `group_consistent`.
- Length-composition effective-sample-size divisor: `inherited mixed 20/40`; weight-composition divisors are unchanged.
- Tag likelihood scalar flag: `parest_flag(177)=0`.
- Tag observation model: `negative_binomial`; estimate pooled dispersion: `false`.
- Tag-release deletion: `none`; 2021 reporting-rate scope: `shared`.
- Mixing-period reporting treatment: `inherited`; dominant 2021 mixing period override: `none`.
- Long-term tag loss: `none`.

## Interpretation

This is a sensitivity, not an accepted assessment configuration. Compare quarterly recruitment (including the quarter immediately outside the terminal window), tag observed/predicted residuals by release/fishery/year/time-at-liberty, length fits for fisheries 12/17/20/26/28 and their shared groups, objective components, population scale, gradients, and Hessian eigen diagnostics.

Raw objectives are not directly comparable when the tag dataset or tag likelihood family differs. A reduced spike is evidence about the source of model pressure; it is not by itself a reason to discard data or select a model.

## Reproducibility

The runner copies `steps/12-OrthogonalPoly/model`, applies `patch.R`, creates a new `00.par` with MFCL, and stores the compact payload, input hashes/specification, and one exact patched restart-input set with the base fit. Diagnostic delta outputs do not duplicate that restart set; parent data are not committed in this thin folder.

> This is the source-consistent reviewed default: it includes all five requested fishery changes and propagates the F20/F17 settings to F27/F18 because MFCL requires other selectivity flags to be identical within fish-flag-24 groups.
