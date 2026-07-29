# 24a: Step 23a with MFCL 2.6

This executable sensitivity is an exact clone of
`23a-20c-CommonTagTau`, apart from the pinned runtime/executable and the
regional-scaling header required by that executable.

| Item | Setting |
| --- | --- |
| Scientific parent | `23a-20c-CommonTagTau` |
| Runtime image | `ghcr.io/pacificcommunity/tuna-flow@sha256:7b9dc95f535025a42109ac958c4faa3af96592cd19510ac0be15af4478eccf27` |
| MFCL executable | `/home/mfcl/mfclo64` |
| MFCL version | `2.6.0-tag-premixing-reporting-rate-fix` |
| Executable SHA256 | `13f5b1b6a8873cfd9afc850b3bdcb46d5bb62d28dcc70604362e4c89b29fb682` |
| Regional-scaling period | 1965-02 to 1969-11, unchanged |
| Compatibility header | `1965 2 1969 11` prepended to `bet.reg_scaling` |
| Tau | One common native-bound tau for F1-F28, unchanged |
| Natural mortality | Fixed, unchanged |
| Composition likelihood | DM G8, Nmax 25, unchanged |

After removing the first line of `bet.reg_scaling`, every model file is
byte-identical to Step 23a. The 20-by-5 regional-scaling values,
`bet.reg_scaling.full`, and the complete `doitall.sh` phase and evaluation
structure are unchanged.
