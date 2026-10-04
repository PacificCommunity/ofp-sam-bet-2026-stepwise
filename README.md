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

Saved native PARs and input-source checksums are retained in `reproduce/`.
Verify the compact archive without executing MFCL:

```sh
make verify
```

See [native restoration](reproduce/README.md) for case keys and engine checks.
Step 01 uses its preserved older executable. To regenerate every saved native
fit on 64-bit x86 Linux, run `make rerun CASE=all OUT=/tmp/bet-steps`.
Full fits use the original case-specific `doitall.sh` and its inputs.

See [step sequence and reproduction details](docs/reproduction.md),
[selectivity changes](docs/selectivity-update.md) and the source locks in
`config/public-run-provenance.csv` before a full rerun.
