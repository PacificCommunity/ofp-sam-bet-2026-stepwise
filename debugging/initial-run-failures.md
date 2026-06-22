# Initial Run Debugging Notes

Short version: most early failures were not because Kflow itself was broken.
The MFCL input files were present, but several files did not describe the same
model structure.

## What Broke

- `.frq` header said 33 fisheries, but the fishery-region line originally had
  only 28 extraction fisheries.
- Some `.ini` files were labelled MFCL 1007 but had no `# tag flags` block.
- Some mix-period `.ini` files had zero tag mixing periods, which current MFCL
  rejects.
- Some `.frq` records had absent-LF markers followed by stray LF bins.
- 04/05 used 2021-chopped `.frq` files but 2026 91-release `.ini/.tag` files,
  so MFCL stopped at tag release group 18 hitting the terminal model period.

## What Fixed It

- Added index fishery regions 1-5 so the `.frq` fishery-region line has all 33
  fisheries.
- Inserted explicit `# tag flags` for 03-07.
- Changed zero tag mixing periods to 1 for 08-12 mix-period `.ini` files.
- Normalized 84 old absent-LF `.frq` records.
- Made 04/05 use the 03-RegFish 90-release `.ini/.tag` setup and reset their
  chopped `.frq` tag-group header from 91 to 90.

## Examples

- Fishery regions:
  before, `.frq` had 33 fisheries in the header but only 28 region entries.
  After, the line ends with index fishery regions `1 2 3 4 5`.
- Tag flags:
  before, some 1007 `.ini` files jumped from `# number of age classes` to the
  next block. After, they include one `# tag flags` row per tag release group.
- Mix periods:
  before, some 08-12 release groups had mixing period `0`. After, those rows
  start with `1`, which current MFCL accepts.
- Absent LF records:
  before, some `.frq` records had `-1` followed by leftover LF bins. After,
  those records are normalized so MFCL reads the next fields correctly.
- 04/05 chopped tag setup:
  before, the 2021-chopped `.frq` still declared 91 tag groups and used 2026
  `.ini/.tag`. After, 04/05 declare 90 tag groups and use the 03-RegFish
  90-release `.ini/.tag`.

## Core Idea

MFCL needs `.frq`, `.ini`, `.tag`, `.age_length`, and `doitall.sh` to agree on
the same structure: fishery count, tag group count, terminal year, and tag
mixing setup.

The main fix was aligning those contracts step by step.

## Remaining Known Noise

- `caught before it was released` tag warnings still appear in local
  `-makepar` smoke checks. These are known upstream tag-prep warnings and are
  documented in the model READMEs.
- Full results/report should only be submitted after the active 12 input jobs
  finish successfully.
