# 23a: Step 20c with one common tag tau

This sensitivity is an exact clone of `20c-DMG8Nmax25` except for the
tag-recapture tau controls added to `doitall.sh` from Phase 10 onward.

| Item | Setting |
| --- | --- |
| Scientific parent | `20c-DMG8Nmax25` |
| Tag likelihood | Negative binomial (`parest 111=4`) |
| Tau parameterization | `tau = 1 + exp(fish_pars(4))` (`parest 305=1`) |
| Tau bounds | Native transformed bounds, theta `[-5, 5]` (`parest 306=0`) |
| Tau grouping | One common parameter for F1-F28; F29-F33 inactive |
| Tau start | theta `0`, hence tau `2` |
| Natural mortality | Fixed; age flag 121 remains `0` |
| Composition likelihood | DM G8, Nmax 25 |
| Executable | `/home/mfcl/mfclo64` |
| Runtime image | `ghcr.io/pacificcommunity/tuna-flow@sha256:c87f1f6d9d4f62dc447844b58afe35f96af175bf933cb6cffbbbe39a59172360` |

All model files other than `doitall.sh` are byte-identical to the parent.
Phases 0-9 of `doitall.sh` are also identical. The final script checks that
exactly one tau is estimated and writes `tag-tau-audit.csv`.
