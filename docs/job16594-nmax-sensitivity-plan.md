# Job 16594 DM Nmax sensitivity

This campaign runs four independent native-MFCL fits from the exact model
inputs and complete `doitall.sh` sequence used by Job 16594.

| Row | Step | DM Nmax | MFCL parest flag 342 | Common tau |
|---:|---|---:|---:|---|
| 01 | `JOB16594-NMAX10` | 10 | 10 | estimated |
| 02 | `JOB16594-NMAX15` | 15 | 15 | estimated |
| 03 | `JOB16594-NMAX40` | 40 | 40 | estimated |
| 04 | `JOB16594-NMAX50` | 50 | 50 | estimated |

The Job 16594 reference has Nmax 25 and is not rerun. For each sensitivity,
the only scientific control changed is the DM effective-sample-size upper
asymptote supplied through parest flag 342.

All models retain:

- the exact Job 16594 input files and phase sequence;
- G8 Dirichlet-multinomial composition grouping;
- SC22-IP10 K=0.15 release-group mixing periods;
- `tag_flags(:,2)=1`, so reporting rates are omitted in pre-mixing windows;
- one common native-bound tag-recapture tau estimated across F1-F28;
- fixed Lorenzen natural mortality;
- full tag-recapture likelihood weight;
- regional recruitment-distribution penalty 0.1;
- all selectivity, CPUE, reporting-rate, length-weight and data settings.

The runtime script fails unless the final `.par` retains the requested value
of parest flag 342 and exactly one estimated `fish_pars(4)` common-tau
parameter.
