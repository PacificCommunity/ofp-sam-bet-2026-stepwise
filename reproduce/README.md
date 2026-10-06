# Saved stepwise fits

[Download native.tar.gz](https://raw.githubusercontent.com/PacificCommunity/ofp-sam-bet-2026-stepwise/main/reproduce/native.tar.gz). It is included in a normal clone;
[files.json](files.json) lists the archived files and checksums.

The package restores the original final PARs for all 23 completed cases.
The archive contains 22 PARs and the Step 01 executable; the final Diagnostic
PAR is restored from a pinned public Git file.
Their native inputs and original `doitall.sh` reuse pinned public Git files.
The older Step 01 executable is included; later cases use the checksum-verified
public 2.2.7.9 executable. Pre-Step10 cases do not use regional scaling priors.

On 64-bit x86 Linux, from the repository root:

```sh
make verify
make rerun CASE=all OUT=/tmp/bet-steps
```

Choose `20-Tau2Fixed` instead of `all` for one case. The final Diagnostic case
is `S0.90-F2-tau2-fixed`. Each run uses a function-evaluation ceiling of 1, preserves every
input and checks the original objective, native dimensions, spawning biomass,
no-fishing biomass and MSY quantities. Reference reports are restored from
existing public payloads using base R; large generated outputs are omitted.

`make verify` checks the compact archive without executing MFCL. For a full
fit, restore its matching executable and use the original fitting runner:

```sh
make restore CASE=20-Tau2Fixed OUT=/tmp/bet-step-inputs
make refit CASE=20-Tau2Fixed OUT=/tmp/bet-step-refit PROGRAM_PATH=/tmp/bet-step-inputs/mfclo64
```

This runs one step from `doitall.sh`, with its original configuration and
selectivity files. The full runner also requires the pinned R packages listed
in the existing reproduction details.

Published results and figures remain unchanged. The historical executed binary
hashes remain unconfirmed; native output checks establish compatibility.

## Saved Hessians

[Model index](hessian-index.csv) lists the original Hessian files, final PARs and
checksums. Download only the required case:

```sh
make hessian CASE=01-Diag2023 OUT=/tmp/bet-hessian
```

Native part archives retain the original row blocks and matching final PAR.
They do not require another derivative calculation. `make hessian-verify` checks
the manifest; pass `CASE=... ARCHIVE=/absolute/model.tar.gz` to verify an offline archive.

All 23 cases are available: 22 original native Hessian part sets and the final
Diagnostic model's complete `bet.hes`. The index retains the published PDH indicators.

To assemble the saved parts with the pinned MFCL executable on
Linux x86-64:

```sh
make hessian-stitch-plan CASE=01-Diag2023
make hessian-stitch CASE=01-Diag2023 OUT=/tmp/bet-hessian-stitch
```

This uses switch `145=11`; original parts and PAR remain alongside the derived
`stitched/` files and `stitch.json` checks. The historical executable hash and
byte equality to the historical merged matrix are unconfirmed.

To calculate native derivatives again, use this recorded historical recipe.
Give each part a new directory with the matching `make restore` inputs,
executable and `final.par`. For a new fit, run `make refit` above and use its
last PAR as `final.par`. Check the parameter layout before reusing that case's
inclusive `row_bounds` in [hessians.json](hessians.json).

```sh
./mfclo64 bet.frq final.par hessian.par \
  -switch 3 1 145 1 1 223 FIRSTROW 1 224 LASTROW
```

Replace `FIRSTROW` and `LASTROW` with those bounds; repeat for every part.
Each writes `bet.hes` with `145=1`. `make hessian-stitch` uses saved parts only.
Use the restored older executable for `01-Diag2023`.
This derivative calculation has not been tested by CI.

Original records say `completed` with `nonzero_status`. The scanner labels them
`failed` for "Only one non zero slot in this sample", sometimes with tag reporting
warnings during mixing. These labels do not establish convergence; the published
PDH indicators remain unchanged.

## Original derivative logs

The optional archive keeps all 86 original native MFCL derivative logs,
including likelihood, penalty and row-progress traces. Restore them without
running MFCL:

```sh
make hessian-logs OUT=/absolute/bet-native-mfcl-logs
```

Files are arranged as `CASE/part_N/mfcl_hessian_log.txt`.
[native-logs.json](native-logs.json) records exact file hashes and matches each
part to the saved Hessian row bounds. Original execution-directory lines remain
in the logs. To check a downloaded archive, use
`make hessian-logs-verify ARCHIVE=/absolute/archive.tar.gz`.
