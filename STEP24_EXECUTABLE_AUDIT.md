# Step 24 executable-only audit

Step 24 reruns the four Step 23 configurations to isolate the effect of the
new MFCL executable.

| Item | Step 23 | Step 24 |
| --- | --- | --- |
| tuna-flow image | `sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360` | `sha256:7b9dc95f535025a42109ac958c4faa3af96592cd19510ac0be15af4478eccf27` |
| MFCL executable | `/home/mfcl/mfclo64` | `/home/mfcl/mfclo64` |
| MFCL build | `2.5.0-strict-tag-nb-dm-report` | `2.6.0-tag-premixing-reporting-rate-fix` |
| MFCL SHA256 | `f5bc1e232a86e51f920bce7271d8e0930d0b160e4d18dc46de44078f0fa24cd0` | `13f5b1b6a8873cfd9afc850b3bdcb46d5bb62d28dcc70604362e4c89b29fb682` |

The v2.6 image digest was resolved again from `tuna-flow:v2.6` on
2026-07-30 and matched the image used by Kflow Job 18400. The contained
executable identifies its source as
`PacificCommunity/ofp-sam-mfcl@a5a83cd`.

At that source revision, MFCL reads four calendar values before the active
regional-scaling matrix and checks them against parest flags 79 and 80. Job
18400's output archive contains the exact compatible form:

```text
1965 2 1969 11
<20 rows by 5 regions>
```

Accordingly, Step 24 prepends only that header to `bet.reg_scaling`.
`bet.reg_scaling.full` remains the unchanged 292-by-5 audit matrix. For each
Step 23/24 pair:

- removing the Step 24 header makes `bet.reg_scaling` byte-identical;
- every other file in `model/`, including `bet.ini`, `bet.frq`,
  `bet.tag`, `bet.age_length`, and `doitall.sh`, is byte-identical;
- M, DM G8/Nmax25, the common tau setup, reporting rates, mixing periods,
  selectivity controls, phase order, convergence, and evaluation limits are
  unchanged.

An exact Step 24a `doitall.sh` smoke run in the pinned v2.6 image completed
input loading and entered MFCL optimization (`f eval 5` was observed before
the 25-second test timeout). The inherited zero mixing-period diagnostic is
printed by this build, but its source has the corresponding exit call
disabled; it did not stop the exact run.
