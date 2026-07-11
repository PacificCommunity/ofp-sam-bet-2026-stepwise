# 12p067-Y71-E3-W000-FBase-P221-71

Reproduces the supplied OPR settings 155=71, 221=71, 216=50, 217=1, and 202=3 while retaining the parent interaction count 218=50. A difference from the paired flag-zero row would identify assessment-executable behaviour not present in public ongoing-dev.

## Controls

- OPR profile: `71-01-50-50`; terminal window: 3 calendar year(s) = 12 quarters; component endpoint: `0`.
- Legacy annual OPR override: `parest_flag(221)=71`.
- Terminal penalty: requested weight `0`; `parest_flag(397)=0`; final matched phase: 1,000 evaluations.
- OPR trend flag: `parest_flag(153)=0`.
- Selectivity profile: `baseline`.
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

> This is one half of a matched flag-221 compatibility check. Public ongoing-dev marks flag 221 obsolete; compare the two rows directly before interpreting either as a biological sensitivity.
