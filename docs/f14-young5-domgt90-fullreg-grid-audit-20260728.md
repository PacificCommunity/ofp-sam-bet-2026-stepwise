# F14 youngest-five + DOM QC + full regional-scaling sensitivity audit

This branch adds eight independent `doitall` sensitivities to the existing
eight-model DOM-QC grid. The earlier jobs are not stopped or replaced. The
only new axis is the regional-scaling window.

## Controls retained in all eight fits

- F15 length-frequency bins below 70 cm are removed.
- DOM fisheries F21-F23 length-frequency bins with midpoint above 90 cm are
  removed; selectivity is not changed by this data filter.
- Fish flags 75 for F14 and F15 are both 5, fixing the youngest five
  selectivity age classes at zero.
- Nmax is 25, tag tau is estimated as one common parameter, natural mortality
  is fixed, the SC22-IP10 mixing value is 0.15, and the Phase 10/11 convergence
  criterion is 1e-4.
- The eight rows cross recruitment penalty 0.1/0.2, movement-prior penalty
  0.1/0.2, and standard versus OPR 72-01-50-50 end2 recruitment.

## Full-period regional scaling

The preserved source `bet.reg_scaling.full` contains 292 five-region rows for
model periods 1-292. Current MFCL requires every regional index to cover the
active prior window. Index fishery 32 starts at period 3, so an attempted
period-1 start (`parest 79=292`) is rejected explicitly by the executable.

The executable input therefore uses the full mutually supported index window:

- active periods: 3-292 (1952Q3-2024Q4);
- executable matrix: calendar header plus 290 data rows;
- `parest flag 79=290`;
- `parest flag 80=0`, retaining the final model period;
- complete archived source: 292 data rows, unchanged.

The staged executable matrix SHA256 is
`4c43bf2c0853b02626047bd84d54a0b62942f9316bed8734f43b696fbe84c1b5`.
The complete source SHA256 is
`dea4c281f7dc46a7412b7ad2e78906ee57b51b62cf1a18c4609381132bf752ed`.

An actual one-evaluation run with MFCL 2.2.7.9 completed successfully with
these inputs and calculated a nonzero regional-scaling likelihood penalty
(`506.394690989305`), confirming that the engine read and applied the active
matrix.
