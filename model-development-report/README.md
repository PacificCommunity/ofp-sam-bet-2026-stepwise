# Dynamic stepwise report and viewer

This Kflow task produces both:

- `model-development/bet-2026-stepwise-model-development.html`
- `model-development/interactive-model-viewer.html`

The task does not store fitted values or source job numbers in the repository. Use the
submission helper with the current upstream viewer job:

```bash
python3 scripts/submit_stepwise_report.py --viewer-job <job-number>
```

The helper reads `source_jobs`, `source_rows`, model labels, scientific parents, and job
status from Kflow at submission time. It serializes that runtime index into the report job
and stages the selected viewer archive. The R builder then reads the upstream viewer JSON,
figure index, and table index to generate the pathway, model inventory, diagnostic tables,
SC figures, downloads, and the bundled offline viewer.

Use `--include-source-jobs` only when the upstream job does not already contain its viewer
and report-ready figure bundle. In that mode, the task stages the source model payloads and
asks `mfclshiny` to regenerate the figures and viewer.
