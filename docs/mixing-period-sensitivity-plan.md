# Job 16594 mixing-period sensitivity plan

This campaign contains 20 independent fits:

- nine release-group mixing-period vectors from
  `PacificCommunity/ofp-sam-2026-BET-YFT-build-ini@5b2fb6053e34a58ef61275a68d8a67ec988833c1`
  (`SC22-IP10-based/BET/ini.mix-period`);
- one additional vector with `tag_flags(:,1)=2` for all release groups;
- each vector is paired with `tag_flags(:,2)=1` and `tag_flags(:,2)=0`.

The exact Job 16594 `bet.ini` is the baseline
(`SHA256 4bd5c08a2b79b722725a7940beee57bb4cf227dc62440afccca486aea9d42e8a`).
Only the first two columns of its 98-row `# tag flags` matrix are changed.

| Plot/model numbers | Mixing vector | RR treatment / exact setting | Release groups changed from Job 16594 | Counts of mixing values `0 / 1 / 2 / 3 / 4` |
|---|---|---:|---:|---:|
| `01`, `02` | SC22-IP10 `K=0.05` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 80 | `0 / 2 / 2 / 4 / 90` |
| `03`, `04` | SC22-IP10 `K=0.10` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 70 | `0 / 7 / 6 / 7 / 78` |
| `05`, `06` | SC22-IP10 `K=0.15` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 0 | `1 / 13 / 48 / 20 / 16` |
| `07`, `08` | SC22-IP10 `K=0.20` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 32 | `2 / 21 / 64 / 2 / 9` |
| `09`, `10` | SC22-IP10 `K=0.25` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 36 | `6 / 22 / 60 / 2 / 8` |
| `11`, `12` | SC22-IP10 `K=0.30` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 41 | `14 / 35 / 40 / 1 / 8` |
| `13`, `14` | SC22-IP10 `K=0.35` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 43 | `18 / 31 / 41 / 0 / 8` |
| `15`, `16` | SC22-IP10 `K=0.40` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 43 | `35 / 14 / 41 / 0 / 8` |
| `17`, `18` | SC22-IP10 `K=0.45` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 92 | `41 / 47 / 2 / 7 / 1` |
| `19`, `20` | All release groups `=2` | post-mix only (`tag2=1`) / all periods (`tag2=0`) | 50 | `0 / 0 / 98 / 0 / 0` |

`K=0.15` with `tag_flags(:,2)=1` is an exact scientific duplicate of Job
16594. It remains in the 20-row grid so that every mixing vector has the same
paired design.

## Frozen Job 16594 settings

The following are identical in all 20 fits:

- fixed-M controls, including `age_pars[5,1] = -2.54930339768360`;
- natural-mortality scalar `0.112362446639794`;
- length-weight parameters `3.073533e-05 2.932410`;
- all five reporting-rate matrices: means, group flags, active flags, targets,
  and penalties;
- `tag_flags(:,3:10)`;
- all `.frq`, `.tag`, age-length, regional-scaling, fishery-map, reporting-map,
  `doitall.sh`, and MFCL configuration inputs;
- standard recruitment, F33 logistic/asymptotic selectivity, common/native tau,
  recruitment penalty `0.1`, DM Nmax `25`, fixed M, and full tag likelihood;
- the Job 16594 tuna-flow v2.6 image digest, package commits, Suva resources,
  and MFCL executable.

Run the fail-closed materialization check before registration or submission:

```bash
Rscript --vanilla scripts/validate_mixing_period_sensitivity.R
```
