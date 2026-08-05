# Public stepwise report cache

This directory contains the three portable derived files needed to render the
public report in the immutable TunaFlow v2.5 environment:

- `outputs/overview/interactive-model-viewer.html`: offline interactive viewer;
- `outputs/mfclshiny-report-depletion-data.csv`: annual series used to rebuild
  the report-ready stepwise figures;
- `outputs/tables/stepwise-recent-key-quantities.csv`: audited stock-status
  values and their exact model-specific calendar windows.

The cache was generated from the 23 sanitized `model_payload.rds` files in this
repository. It contains no fitted-model input that is absent from those
payloads and does not rerun MFCL. Repository validation checks its SHA-256
hashes, relative payload references, and absence of machine paths or credential
patterns. The recent-period audit checks every configuration using the WCPFC BET
definitions: spawning biomass over T-3 to T, unfished spawning biomass over
T-9 to T, and fishing mortality over T-4 to T-1. The fitted-model payloads
remain the archived source fits.
