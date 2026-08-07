# Dynamic 22-step pathway report and viewer

This Kflow task produces both:

- `model-development/bet-2026-stepwise-model-development.html`
- `model-development/interactive-model-viewer.html`

The repository stores one compact, checksum-locked payload per model under
`data/stepwise/models/`. Render directly from those payloads with:

```bash
./run-report
```

The published report and viewer use stable step identifiers. Local execution
references and archive locations are tracked outside the public assets. The report
builder reads the repository payloads and generates the pathway, model inventory,
diagnostic tables, figures, downloads and bundled offline viewer without rerunning MFCL.

Use `--include-source-jobs` only when the upstream job does not already contain its viewer
and report-ready figure bundle. In that mode, the task stages the source model payloads and
asks `mfclshiny` to regenerate the figures and viewer.

The pathway proceeds from ordinary-makepar Step 19 to tau=2 at Step 20,
adds only the weak F33 non-decreasing penalty at Step 21, and changes only
fixed steepness to 0.90 at Step 22 (the current Diagnostic model).
