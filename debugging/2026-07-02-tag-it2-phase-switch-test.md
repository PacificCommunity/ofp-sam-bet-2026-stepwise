# Tag `it2` Phase-Switch Test

This diagnostic branch tests whether the current 2026 tag/reporting-rate
setup can start from a stable `tag_flags(it,2)=1` fit and then switch back to
`tag_flags(it,2)=0` later in the control sequence.

## Mechanism

Set `BET_TAG_IT2_SWITCH_PHASE=N` when launching Kflow.

| Setting | Effect |
| --- | --- |
| blank | Use the model folder's native `bet.ini` tag flags. |
| `2`-`11` | PHASE1 sets all release groups to `tag_flags(it,2)=1`; PHASE `N` sets all release groups back to `tag_flags(it,2)=0`. |

The switch is done by MFCL control commands in `doitall.sh`, not by editing
the source `.ini` files.

## Planned Matrix

Run steps 07-15 for switch phases 4-11 with `BET_PHASE10_11_CONVERGENCE=-3`
and downstream triggers disabled. This isolates the earliest phase where
applying reporting rates during the tag mixing period becomes numerically
stable.
