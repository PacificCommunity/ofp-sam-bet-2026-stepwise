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

The final Diagnostic case includes its original complete `bet.hes`. The index
preserves the published PDH indicators. Cases whose original parts are still
being recovered are not included yet.

To assemble the saved parts with the pinned MFCL executable on
Linux x86-64:

```sh
make hessian-stitch-plan CASE=01-Diag2023
make hessian-stitch CASE=01-Diag2023 OUT=/tmp/bet-hessian-stitch
```

This uses switch `145=11`; original parts and PAR remain alongside the derived
`stitched/` files and `stitch.json` checks. The historical executable hash and
byte equality to the historical merged matrix are unconfirmed.
