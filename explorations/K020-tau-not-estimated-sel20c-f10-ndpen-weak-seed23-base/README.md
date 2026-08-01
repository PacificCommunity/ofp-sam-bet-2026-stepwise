# BET 2026 seed-23 base — standalone doitall

This directory turns the best converged Job 19325 jitter solution into a
reproducible base-model workflow. It retains the Job 19325 model definition:

- K=0.20 and tag tau not estimated;
- F10 five-node cubic spline with the weak non-decreasing penalty
  (`flag 16=1`, `flag 56=10000`);
- all frozen frequency, tag, age-length, regional-scaling, natural-mortality,
  reporting-rate and DM controls unchanged.

The only new behavior is deterministic initialization. Starting from
`bet.ini` with `-makepar`, `doitall.sh` reproduces the exact CV=0.1 seed-23
path used by Job 19325:

1. seed 23 is applied once to the final-active parameters already represented
   after Phase 1;
2. derived seed 2410802 is applied once to the eight `fish_pars(23)` values
   when they first become represented in Phase 2;
3. derived seed 2413829 is applied once to the 25 F29-F33 selectivity
   coefficients after their Phase-5 group separation.

It does not repeatedly jitter the active vector at every phase. The final
Job 19325 seed-23 fit had objective 89054.3397838085, maximum gradient
9.2968286e-05 and 2024 depletion 0.3287955046. It was the best converged
objective, not the lowest-depletion jitter run.

## Run without Kflow

Put the MFCL executable in this directory as `mfclo64`, then run:

```bash
chmod +x mfclo64 doitall.sh
./doitall.sh
```

Alternatively, keep the executable elsewhere:

```bash
PROGRAM_PATH=/absolute/path/to/mfclo64 ./doitall.sh
```

The script also requires R, `mfclkit` 0.0.0.9040 from commit
`34c56de25afecdd13e9f8e94f2e421e37d9c2f9b`, and `FLR4MFCL` 1.7.2.
The completed Kflow output bundles the exact MFCL executable beside the model
files; this requirement is about the model runtime, not knowledge of Kflow.

Run in a fresh copy of this directory. The expected final parameter file is
`11.par`. `seed23-initialization-summary.csv` and the
`seed23-initialization/` directory record the parameters, seeds, hashes and
before/probe/after PAR files used at Phases 1, 2 and 5.

## Subsequent diagnostics

Use this `doitall.sh` as the base doitall for full fits and retrospective
peels. Its parameter mapping is generated from the current PAR dimensions, so
retro peels do not reuse a full-data parameter vector of the wrong length.

The existing mfclkit phase1/doitall jitter workflow remains unchanged. Its
resume marker is detected and the embedded seed-23 base initialization is
skipped, so a diagnostic seed is applied once to the ordinary makepar/Phase-1
reference. Seed 23 remains one member of that ordinary jitter ensemble; it is
not added twice. Profiles and Hessian runs start from the fitted seed-23 base
PAR in the usual way.
