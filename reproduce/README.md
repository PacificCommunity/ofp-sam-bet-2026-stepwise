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
python3 reproduce/run-native.py all /tmp/bet-steps
```

Choose `20-Tau2Fixed` instead of `all` for one case. The final Diagnostic case
is `S0.90-F2-tau2-fixed`. Each run uses a function-evaluation ceiling of 1, preserves every
input and checks the original objective, native dimensions, spawning biomass,
no-fishing biomass and MSY quantities. Reference reports are restored from
existing public payloads using base R; large generated outputs are omitted.

`python3 reproduce/restore.py --verify` checks the compact archive without
executing MFCL. Full fits use the original case directory and `doitall.sh`, with
`PROGRAM_PATH` pointing to its matching executable. Retain that directory's
configuration and selectivity files.

Published results and figures remain unchanged. The historical executed binary
hashes remain unconfirmed; native output checks establish compatibility.
