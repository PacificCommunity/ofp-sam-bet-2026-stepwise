# Audit of the transition to the current Diagnostic model

The selected pathway starts from ordinary-makepar Step 19a. Step 19b is a
historical comparison branch only; its seed-23 initialization is never carried
into Steps 20-22.

| Comparison | Intended change | Verified unchanged |
| --- | --- | --- |
| 19a → 19b | Replace only `doitall.sh` with the exact Job 19835 CV=0.1, seed-23 Phase 1/2/5 initialization recipe. | All scientific inputs and controls. |
| 19a → 20 | Use direct negative-binomial controls `111/305/306=4/1/0`; keep flags 43/44 at zero; write all `fish_pars(4)=0`, fixing tau at 2. | M, steepness 0.80, DM parameters, effort creep, reporting rates, tag mixing, length/age data and F1-F33 selectivity. |
| 20 → 21 | Set only F33 flags 16/56 from `0/0` to `1/10000`, matching the existing weak F10 non-decreasing penalty. | Every other selectivity field and all other model inputs/controls. |
| 21 → 22 | Change only INI `sv(29)` from 0.80 to 0.90; age flag 162 remains zero. | Tau=2, M, DM parameters, effort creep, all data and the complete F1-F33 selectivity table. |

Step 20 also adopts the approved Diagnostic FRQ serialization cleanup: the
unused weight-frequency dimensions and trailing placeholder are removed. The
7,449 catch, effort and length-frequency observation records are unchanged, so
this is not an additional scientific model change.

## Locked identities

| Item | Locked value |
| --- | --- |
| Job 19835 `doitall.sh` | `56351fb284553a5f533720872ed9120d9803e43b8fd6160397f61383747749fc` |
| Step 19a pre-cleanup `bet.frq` | `9b8f4630b5b8bec8b8292e8207cc789b00542d29338faf6187f3c9af55504aa3` |
| Steps 20-22 cleaned `bet.frq` | `d0d84f0a498e6a62681f2a58ffc1ba53dab9e3d6af856b4ad1fd907196250004` |
| Step 22 `bet.ini` (`sv(29)=0.90`) | `fbd064c3d0ccb4d2e1b9beb06fe3eacf0180677821e6a1773d20b308474d984e` |
| Step 22 Diagnostic recipe | public Diagnostic `main@0d6db041478a582d44577d14915048d3ee60866b` |
| Diagnostic Job 21641 reference `final.par` | `21dcaea9db8c89ddc8c29fa3c3a5e514b50bef6e26587c168c00c05f35fbebc3` |

The validator also confirms the Job 21641 reference PAR has
`parest 111/305/306=4/1/0`, all 33 flags 43/44 equal to zero and all 33
`fish_pars(4)=0`. Therefore `tau=1+exp(0)=2` is fixed, with zero estimated tau
parameters.
