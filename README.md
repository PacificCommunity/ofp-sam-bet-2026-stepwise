# BET 2026 final exploration

This branch is a compact, clone-and-run archive for the final BET 2026
mixing-period exploration and three F10 selectivity-robustness candidates. It
contains 27 independent model folders:
six region-mean mixing thresholds crossed with two tag-tau treatments and
two selectivity treatments, plus three Job 18718-based candidates.
It does not depend on the deleted stepwise `steps/` tree.

## Exploration grid

| Internal model pattern | Public label | K values | Tag likelihood | Tau treatment |
| --- | --- | --- | --- | --- |
| `K*-tau-estimated` | Tau estimated · Parsimonious selectivity | 0.05-0.30 | Negative binomial (`parest 111=4`) | One common F1-F28 tau |
| `K*-tau-not-estimated` | Tau not estimated (original) · Parsimonious selectivity | 0.05-0.30 | Negative binomial (`parest 111=4`) | Not estimated |
| `K*-tau-estimated-sel20c` | Tau estimated · Flexible selectivity | 0.05-0.30 | Negative binomial (`parest 111=4`) | One common F1-F28 tau |
| `K*-tau-not-estimated-sel20c` | Tau not estimated (original) · Flexible selectivity | 0.05-0.30 | Negative binomial (`parest 111=4`) | Not estimated |

The second mode is not Poisson and does not switch off tag data. It retains
the negative-binomial tag likelihood, keeps fish flags 43/44 inactive, and
does not open `fish_pars(4)` as an estimated parameter.

## Selectivity treatments

The 12 parsimonious folders retain the recent controls, including F2/F3
and F7/F9 sharing, the later spline-node choices, independent asymptotic F33
selectivity, and the F14/F15 youngest-five-age constraints.

The 12 flexible folders use the selectivity controls from the actual
Job 15062 `20c-DMG8Nmax25` `doitall.sh`: F1-F28 start in separate groups,
F29-F33 share in Phase 1 and separate in Phase 5, the default five spline
nodes are retained for F1/F2/F3/F5/F29, and F33 remains cubic-spline. The one
deliberate difference from 20c is that the youngest-five-age constraint is
applied to both F14 and F15. The retained data have no positive
length-frequency observations below 70 cm for either fishery (minimum
positive bins: F14 72 cm; F15 70 cm). No non-selectivity control is copied
from 20c.

Every leaf directory under [`explorations/`](explorations/) is self-contained.
It includes `bet.frq`, `bet.ini`, `bet.tag`, `bet.age_length`,
`bet.reg_scaling`, `mfcl.cfg`, its own `doitall.sh`, mapping files, and a
SHA256 manifest. No run-time input is borrowed from another exploration.

## F10 selectivity-robustness candidates

Three additional folders retain all Job 18718 settings:

| Internal model | F10 flag 16 | F10 flag 56 | Treatment |
| --- | ---: | ---: | --- |
| `K020-tau-not-estimated-sel20c-f10-ndpen-weak` | 1 | 10,000 | Weak non-decreasing penalty |
| `K020-tau-not-estimated-sel20c-f10-ndpen-default` | 1 | 1,000,000 | Explicit MFCL default penalty |
| `K020-tau-not-estimated-sel20c-f10-logistic` | not applicable | not applicable | Two-parameter asymptotic logistic form (`flag 57=1`) |

The two penalty candidates keep the five-node cubic spline. The logistic
candidate estimates `fish_pars(9:10)` for F10 and is inherently
non-decreasing. The candidates change no data, mixing, tau, reporting-rate,
natural-mortality, DM or other selectivity control. Their diagnostic evidence,
MFCL manual/source interpretation and acceptance criteria are documented in
[`docs/f10-selectivity-penalty.md`](docs/f10-selectivity-penalty.md).

## Controls held fixed

- Frozen Job 17805 data and controls, except for the explicit Job 18518 DM
  concentration fix below.
- No positive F14 or F15 length-frequency observations below 70 cm; F14
  starts at 72 cm and the F15 observations below 70 cm were removed.
- Domestic-fishery length-frequency observations with midpoint above 90 cm
  removed.
- F14 and F15 youngest five ages fixed at zero selectivity.
- Job 18518-style DM-noRE controls: `parest 141=11`, `parest 320=5`,
  `Nmax=25`, the eight G8-grouped `fish_pars(22)` concentration intercepts
  fixed at exactly 7 (`flag 69=0`), and the eight grouped
  `fish_pars(23)` relative-sample-size exponents estimated (`flag 89=1`).
- Recruitment penalty 0.1, movement prior 0.1, OPR off.
- Fixed age-pars log-M `-2.54930339768360e+00`, verified from the actual
  Job 18386 output archive.
- Region-mean tag-mixing vectors from
  `SC22-IP10-regionMean@efe3107c72774ee73b5e6dc45e44cf51f0fc20e8`.

The K=0.15 final INI is byte-identical to the actual Job 18386 INI:
SHA256 `670940e4815f7f10f734f5de289bbe033657169ffa764a6297d0adc693ce221f`.
The six source INIs and actual Job 17805/18386/18518 records are retained under
[`provenance/`](provenance/). The exact archived Job 15062 20c `doitall.sh`
and its archive checksums are retained under
[`provenance/job-15062/`](provenance/job-15062/).

## Reporting-rate check

The reporting-rate initial values, group flags, active flags, targets, and
penalties are numerically identical between Job 18386 and the authoritative
K=0.15 source INI. The same reporting-rate blocks are retained in all 27
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
git clone --branch final-exploration-robust \
  https://github.com/PacificCommunity/ofp-sam-bet-2026-stepwise.git
cd ofp-sam-bet-2026-stepwise
make validate
```

Run exactly one exploration by selecting its tau mode and K folder:

```bash
make run \
  MODEL=K015-tau-estimated-sel20c \
  PROGRAM_PATH=/path/to/mfclo64
```

Results are written to
`outputs/<MODEL>/`; the final parameter file is also copied to `final.par`.

## Kflow

[`kflow.yaml`](kflow.yaml) pins
`ghcr.io/pacificcommunity/tuna-flow:v2.5` to image digest
`sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360`.
The public task contains three independent, concurrently submitted campaign
rows. `STEP_SELECT` is set per row to the weak penalty, MFCL-default penalty,
or asymptotic logistic F10 candidate; no fit depends on another.

The model job installs and verifies the current package snapshots at exact
commits:

- `mfclkit@34c56de25afecdd13e9f8e94f2e421e37d9c2f9b`
- `mfclshiny@ff0dfcc0534c743713601dbadca5d9d56c0a4025`

They are used after the MFCL fit to build `model_payload.rds`. The image and
package commits are intentionally pinned separately: tuna-flow v2.5 supplies
the MFCL executable, while the R packages are installed at run time for
reproducible post-processing.

These two package commits are defaults, not permanent constraints. At Kflow
submission, set `MFCLKIT_GITHUB_REF` and `MFCLSHINY_GITHUB_REF` to different
full 40-character commit SHAs to test later package versions. The run-time
installer treats those two values as authoritative, verifies the installed
`RemoteSha` values, and records the versions in
`runtime-package-versions.csv`. This preserves the existing Kflow
version-override workflow without making the MFCL executable mutable.
The job also archives those exact installed packages in
`runtime-package-library.tar.gz`. The MFCL Shiny local app loads that archived
library and rechecks its SHAs, so the viewer uses the same package versions
selected for that individual Kflow run rather than the branch defaults.

## Dependent profiles

Each fitted model has a dependent total-average-biomass profile. The exact
settings are in [`profile.env`](profile.env): 60-140% in 2.5-point steps,
two `robust_fast` continuation chains, a fitted 100% anchor, and no jagged
retry or repair. The profile jobs use the same pinned tuna-flow v2.5 image and
the package commits listed above. They additionally pin
`FLR4MFCL@3faaf84a4867175bfea50d89e4d518c085e84739`, the version used by
completed profile merge Job 18608 (33/33 profile points successful).

The original 24 model jobs were submitted to the public Kflow task
`bet-2026-final-exploration-v25-20260730` as Jobs 18703-18726. The three F10
penalty candidates are submitted independently from this branch to the task
named in `kflow.yaml`.
