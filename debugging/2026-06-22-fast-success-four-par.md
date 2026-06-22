# 2026-06-22 Fast Success With Only 04.par

One 12-DataWeight40 Kflow run finished very quickly and archived only
`04.par`. That was not a real completed model run.

## What Happened

| Symptom | Cause |
| --- | --- |
| Kflow showed success after only `04.par` existed | `doitall.sh` did not stop when an MFCL phase failed, so later missing-input errors were allowed to continue. |
| PHASE 5 failed before creating `05.par` | The regional-scaling prior defaulted to period 1 because `parest_flags(79)=0`. |
| MFCL error mentioned index fishery 32 starts at period 3 | The regional-scaling prior period must be inside the time range covered by every index fishery. |

## Fix

| Area | Change |
| --- | --- |
| Regional scaling period | Changed `parest_flags(79)` from `0` to `290` in 06-12 PHASE 5. |
| MFCL interpretation | With 292 full-2024 periods, MFCL calculates `preg_start = 292 - 290 + 1 = 3`. |
| Job failure handling | Added `set -eu` to all 12 `doitall.sh` scripts. |
| Generator | Updated `R/prepare_bet_2026_step_inputs.R` so regenerated 04-12 scripts keep fail-fast behavior and 06-12 keep the period-3 regional-scaling start. |

## Why This Matters

If MFCL fails in the middle of `doitall.sh`, the Kflow job should fail
immediately. A quick success with only early `.par` files is misleading and
should now be prevented.

## Verification

- `sh -n` passed for every `steps/*/model/doitall.sh`.
- All 06-12 `doitall.sh` files contain `1 79 290`.
- All 12 `.frq` files have a fishery-region line matching the header fishery
  count.
- All 03-12 `.frq`, `.tag`, and `.ini` tag group counts agree.
- All 06-12 `bet.reg_scaling` files are 292 rows x 5 columns.
