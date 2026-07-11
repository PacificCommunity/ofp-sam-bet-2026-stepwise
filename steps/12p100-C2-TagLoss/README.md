# 12p100-C2-TagLoss

Applies a fixed continuous tag-loss rate of 0.021 per quarter to all releases (0.084/year divided across four model periods), based on an external bigeye double-tagging estimate. This transfer is diagnostic and should not replace a Pacific-specific estimate.

## Controls

- OPR profile: `69-01-50-50`; terminal window: 1 calendar year(s) = 4 quarters.
- Terminal penalty: requested weight `100`; `parest_flag(397)=1000`; final matched phase: 1,000 evaluations.
- OPR trend flag: `parest_flag(153)=0`.
- Selectivity profile: `baseline`.
- Tag likelihood scalar flag: `parest_flag(177)=0`.
- Tag observation model: `negative_binomial`; estimate pooled dispersion: `false`.
- Tag-release deletion: `none`; 2021 reporting-rate scope: `shared`.
- Mixing-period reporting treatment: `inherited`; dominant 2021 mixing period override: `none`.
- Long-term tag loss: `all` at 0.021 per quarter.

## Interpretation

This is a sensitivity, not an accepted assessment configuration. Compare quarterly recruitment (including the quarter immediately outside the terminal window), tag observed/predicted residuals by release/fishery/year/time-at-liberty, length fits for fisheries 12/17/20/26/28 and their shared groups, objective components, population scale, gradients, and Hessian eigen diagnostics.

Raw objectives are not directly comparable when the tag dataset or tag likelihood family differs. A reduced spike is evidence about the source of model pressure; it is not by itself a reason to discard data or select a model.

## Reproducibility

The runner copies `steps/12-OrthogonalPoly/model`, applies `patch.R`, creates a new `00.par` with MFCL, and stores the compact payload, input hashes/specification, and one exact patched restart-input set with the base fit. Diagnostic delta outputs do not duplicate that restart set; parent data are not committed in this thin folder.
