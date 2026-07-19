#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(dirname "$script_dir")"

for dir in "$base_dir"/*/; do
  [ -d "$dir" ] || continue

  name="$(basename "$dir")"

  if [ "$name" = "aidu-dev-tools" ]; then
    continue
  fi

  echo "===================== Installing in $name ====================="

  if ! (
    cd "$dir"
    make install
  ); then
    echo "  Skipping: make install failed"
    continue
  fi
done