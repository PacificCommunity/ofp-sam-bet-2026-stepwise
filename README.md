[![Preservation checks](https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise/actions/workflows/verify-preserved-results.yml/badge.svg?branch=main)](https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise/actions/workflows/verify-preserved-results.yml?query=branch%3Amain)

# BET 2026 stepwise pathway to the Diagnostic model — 04 Aug

<a id="step-sequence"></a>
<a id="important-controls"></a>
<a id="rebuild-and-validate"></a>
<a id="kflow-runtime"></a>
<a id="audit-files"></a>
<a id="report-and-interactive-viewer"></a>

[Report](https://pacificcommunity.github.io/ofp-sam-bet-2026-stepwise/bet-2026-stepwise-model-development.html)
· [Interactive viewer](https://pacificcommunity.github.io/ofp-sam-bet-2026-stepwise/interactive-model-viewer.html).

The pathway contains 23 model configurations across 22 numbered steps,
including the alternative Step 14a. Each committed `steps/*/model/` directory
contains its own inputs and fitting recipe. Fits start independently;
they do not use a preceding step's fitted PAR.

From the repository root:

```sh
make verify
make results
```

The checks verify the saved files. The report uses
the archived fitted-model payloads and portable cache, so results can be
reviewed immediately without refitting.

The self-contained [native bundle](reproduce/standalone.zip) includes all 23
final PARs, the matching input files, fitting scripts and shared engines.

```sh
make list
make prepare CASE=20-Tau2Fixed OUT=/tmp/bet-inputs
make rerun CASE=20-Tau2Fixed OUT=/tmp/bet-step
```

Preparation uses base R and does not execute MFCL. Native reruns require Linux
x86-64; they check the original objective, parameter count and central values.
Use R, Make and system archive/hash tools for these reader commands.
For a complete fit, `make refit CASE=20-Tau2Fixed OUT=/tmp/bet-refit`
runs the preserved `doitall.sh` and settings in a new directory.
Use `CASE=all` for every saved fit. Step 01 uses its preserved older executable;
Steps 01–09 intentionally omit regional scaling. See [native restoration](reproduce/README.md)
for the original full-fit scripts and source checks.

See [step sequence and reproduction details](docs/reproduction.md),
[selectivity changes](docs/selectivity-update.md) and the source locks in
`config/public-run-provenance.csv` before a full rerun.
