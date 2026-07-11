# 12p057-C3-TagDisp

Uses parest_flag(305)=1 and fish_flags(43/44)=1 to estimate one shared direct-tau negative-binomial dispersion parameter with source-supported bounds. Because parest_flag(305) also changes the negative-binomial parameterisation from the legacy fish-parameter form, this is a compound observation-model diagnostic rather than a stand-alone final-model candidate.

## Controls

- OPR profile: `69-01-50-50`; terminal window: 1 calendar year(s) = 4 quarters.
- Terminal penalty: requested weight `100`; `parest_flag(397)=1000`; final matched phase: 1,000 evaluations.
- OPR trend flag: `parest_flag(153)=0`.
- Selectivity profile: `group_consistent`.
- Tag likelihood scalar flag: `parest_flag(177)=0`.
- Tag observation model: `negative_binomial`; estimate pooled dispersion: `true`.
- Tag-release deletion: `none`; 2021 reporting-rate scope: `shared`.
- Mixing-period reporting treatment: `inherited`; dominant 2021 mixing period override: `none`.
- Long-term tag loss: `none`.

## Interpretation

This is a sensitivity, not an accepted assessment configuration. Compare quarterly recruitment (including the quarter immediately outside the terminal window), tag observed/predicted residuals by release/fishery/year/time-at-liberty, length fits for fisheries 12/17/20/26/28 and their shared groups, objective components, population scale, gradients, and Hessian eigen diagnostics.

Raw objectives are not directly comparable when the tag dataset or tag likelihood family differs. A reduced spike is evidence about the source of model pressure; it is not by itself a reason to discard data or select a model.

## Reproducibility

The runner copies `steps/12-OrthogonalPoly/model`, applies `patch.R`, creates a new `00.par` with MFCL, and stores the compact payload, input hashes/specification, and one exact patched restart-input set with the base fit. Diagnostic delta outputs do not duplicate that restart set; parent data are not committed in this thin folder.
