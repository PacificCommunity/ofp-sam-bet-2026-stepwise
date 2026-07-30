# BET 2026 final exploration

This branch is a compact, clone-and-run archive for the final BET 2026
mixing-period exploration. It contains 12 independent model folders:
six region-mean mixing thresholds crossed with two tag-tau treatments.
It does not depend on the deleted stepwise `steps/` tree.

## Exploration grid

| Tau treatment | K values | Tag likelihood | Estimated tau parameters |
| --- | --- | --- | ---: |
| `K*-tau-estimated` | 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 | Negative binomial (`parest 111=4`) | One common F1-F28 tau |
| `K*-tau-not-estimated` | 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 | Negative binomial (`parest 111=4`) | Zero |

The second mode is not Poisson and does not switch off tag data. It retains
the negative-binomial tag likelihood, keeps fish flags 43/44 inactive, and
does not open `fish_pars(4)` as an estimated parameter.

Every leaf directory under [`explorations/`](explorations/) is self-contained.
It includes `bet.frq`, `bet.ini`, `bet.tag`, `bet.age_length`,
`bet.reg_scaling`, `mfcl.cfg`, its own `doitall.sh`, mapping files, and a
SHA256 manifest. No run-time input is borrowed from another exploration.

## Controls held fixed

- Frozen Job 17805 data and controls.
- F15 length-frequency observations below 70 cm removed.
- Domestic-fishery length-frequency observations with midpoint above 90 cm
  removed.
- F14 and F15 youngest five ages fixed at zero selectivity.
- DM `Nmax=25`, recruitment penalty 0.1, movement prior 0.1, OPR off.
- Fixed age-pars log-M `-2.54930339768360e+00`, verified from the actual
  Job 18386 output archive.
- Region-mean tag-mixing vectors from
  `SC22-IP10-regionMean@efe3107c72774ee73b5e6dc45e44cf51f0fc20e8`.

The K=0.15 final INI is byte-identical to the actual Job 18386 INI:
SHA256 `670940e4815f7f10f734f5de289bbe033657169ffa764a6297d0adc693ce221f`.
The six source INIs and actual Job 17805/18386 records are retained under
[`provenance/`](provenance/).

## Reporting-rate check

The reporting-rate initial values, group flags, active flags, targets, and
penalties are numerically identical between Job 18386 and the authoritative
K=0.15 source INI. The same reporting-rate blocks are retained in all 12
explorations; only the tag-mixing column changes across K. Tag-flag column 2
is one for all 98 release groups.

These runs intentionally use tuna-flow v2.5. Unlike v2.6, v2.5 does not apply
the newer pre-mixing reporting-rate exclusion in the tag likelihood
calculation, even though tag-flag column 2 is present.

## Regional scaling for v2.5

Job 17805/18386 used the v2.6 regional-scaling header
`1965 2 1969 11`. The older v2.5 reader expects the matrix directly, so each
exploration contains the same active 20-by-5 matrix with only that header
removed. The full and headered Job 17805 files remain in `provenance/`.

## Validate or run locally

Validation does not execute MFCL:

```bash
git clone --branch final-exploration \
  https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise.git
cd ofp-sam-bet-2026-stepwise
make validate
```

Run exactly one exploration by selecting its tau mode and K folder:

```bash
make run \
  MODEL=K015-tau-estimated \
  PROGRAM_PATH=/path/to/mfclo64
```

Results are written to
`outputs/<MODEL>/`; the final parameter file is also copied to `final.par`.

## Kflow

[`kflow.yaml`](kflow.yaml) pins
`ghcr.io/pacificcommunity/tuna-flow:v2.5` to image digest
`sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360`.
The default is `MODEL=K015-tau-estimated`. Override `MODEL` with one of the
12 exploration directory names to submit each grid member independently.

No final-exploration MFCL or Kflow job was launched while preparing this
branch.
