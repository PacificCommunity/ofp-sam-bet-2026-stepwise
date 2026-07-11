# BET 2026 Step 12 terminal-recruitment sensitivities

<p align="right">
  <a href="kflow.yaml"><img src="kflow-ready.svg" alt="Kflow ready task"></a>
</p>

This branch isolates terminal-recruitment behaviour in the BET 2026 Step 12
OPR model. It contains 73 generated sensitivities plus the unchanged Step 11
control (74 fits); unchanged models from `main` are intentionally omitted.

The design tests whether the terminal recruitment spike is driven by OPR
complexity, the terminal boundary or penalty, LF/selectivity assumptions,
length-composition weight, or recent tagging information.

## Sensitivity models

| Family | Fits | Main comparison |
| --- | ---: | --- |
| OPR count, endpoint, and terminal penalty | 27 | Annual counts 73/72/71; no endpoint or 1--3 terminal calendar years; penalty weights 0--200. |
| LF/selectivity and LF weighting | 15 | Reviewed group-consistent controls versus original, exact-five, isolated mechanisms, and LF divisors 40/80. |
| Tagging | 21 | Tag weight, observation model, mixing period, 2021 reporting-rate priors, and diagnostic release deletions. |
| Standard recruitment deviations | 5 | Free, 4-quarter, and 8-quarter terminal deviations plus two tag-attribution cases. |
| OPR trend penalty | 2 | Trend penalty off versus weight 0.1, separate from the terminal-mean penalty. |
| Compatibility and benchmark | 3 | Matched `parest_flags(221)=0/71` pair and one labelled OPR69 executable benchmark. |
| **Generated total** | **73** | The unchanged Step 11 model supplies the 74th fit and inherited 6-quarter standard-recruitment control. |

The primary OPR counts are 73, 72, and 71. Their saturated endpoint pairs are
73/end1, 72/end2, and 71/end3. OPR69 is retained only as a numerical benchmark,
and the flag-221 pair is only an executable-compatibility check; neither is a
final candidate.

Generated models use the reviewed group-consistent LF/selectivity changes by
default. Original and exact-five-only controls remain in the grid so their
effects can be separated.

## Reading a model name

`Y73-E1-W100-FGroup` means 73 annual OPR coefficients, one terminal calendar
year, terminal-mean penalty weight 100, and group-consistent LF controls.

## Run and outputs

```bash
python3 scripts/launch_opr_terminal_penalty_lf_sensitivity.py --help
```

The Kflow pipeline is:

```text
74 fits -> 74 independent Hessians -> 74 delta merges -> 1 results bundle
```

It runs on Suva with `tuna-flow:v2.2`. The default convergence is `1e-4`;
shortlisted models can be rerun at `1e-5` without regenerating inputs.
Use `--fits-only` to screen fits first and add selected Hessians later.

Detailed rationale and interpretation are in
[`docs/opr-terminal-penalty-lf-tag-sensitivity.md`](docs/opr-terminal-penalty-lf-tag-sensitivity.md).
The exact 73-model design is in
[`docs/opr-terminal-penalty-lf-sensitivity-grid.csv`](docs/opr-terminal-penalty-lf-sensitivity-grid.csv).
