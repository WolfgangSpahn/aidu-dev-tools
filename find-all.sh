#!/usr/bin/env bash
set -uo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <search-term>" >&2
  exit 1
fi

search_term="$1"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(dirname "$script_dir")"

for dir in "$base_dir"/*/; do
  [ -d "$dir" ] || continue

  name="$(basename "$dir")"

  if [ "$name" = "aidu-dev-tools" ]; then
    continue
  fi

  echo "===================== Searching in $name ====================="

  (
    cd "$dir" || exit
    find src -type f \( -name "*.py" \) -exec grep --color -Hn "$search_term" {} +
  )
done