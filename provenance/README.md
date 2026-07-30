# Input provenance

The final exploration inputs were reconstructed from completed Kflow output
archives and the authoritative region-mean INI branch. They were not inferred
from job names.

## Job 17805

- Source commit:
  `6ebfb4a98a933b2e410a1af480532b23873fa9c3`
- Scientific controls: F14/F15 youngest five ages fixed; F15 `<70 cm` and
  domestic-fishery midpoint `>90 cm` length-frequency exclusions; DM
  `Nmax=25`; fixed M; common estimated tag tau; recruitment penalty 0.1;
  movement penalty 0.1; OPR off.
- `job-17805/` retains its actual INI, v2.6 regional-scaling files, selected
  step record, model registry, and extracted final PAR.

## Job 18386

- Source commit:
  `15aabf1b08a991e4a2bc09cb61aa79356caaeda0`
- Output archive SHA256:
  `4199564bcb3dbad047e30bdaac27e7cfe04de502161c6b08e8d81cbc1cddf9b7`
- Exact fixed log-M:
  `-2.54930339768360e+00`
- Its actual K=0.15 `bet.ini` is retained under `job-18386/`.
- Its F15 QC summary records 1,057 observations removed below 70 cm across
  66 affected LF rows. `selected-steps.csv` also records the domestic-fishery
  midpoint-above-90-cm exclusion.

## Region-mean INIs

- Repository: `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini`
- Branch: `SC22-IP10-regionMean`
- Commit: `efe3107c72774ee73b5e6dc45e44cf51f0fc20e8`
- `SC22-IP10-regionMean/` retains the six source INIs verbatim.

Numerically, the source K=0.15 INI and actual Job 18386 INI have identical tag
flags and identical reporting-rate values, group flags, active flags, targets,
and penalties. Their only substantive numeric difference is the age-pars
log-M (`-2.6` versus the verified fixed value above). The remaining textual
difference in the biology block is only `2.93241` versus `2.932410`.

## tuna-flow v2.5 preparation

`prepared-v25-common/` contains the Job 17805 common inputs prepared for the
old regional-scaling reader. `bet.reg_scaling` is the actual active Job 17805
20-by-5 matrix with only its v2.6 four-value header removed.
