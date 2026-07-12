#!/usr/bin/env bash
# Fresh standard-recruitment reference: never reuse an inherited PAR file.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

shopt -s nullglob
rm -f -- [0-9]*.par final.par transfer.par

exec ./standard-doitall.sh
