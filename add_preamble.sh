#!/usr/bin/env bash

# This script adds a preamble to all Python files in the src directory.
# Usage:
#
#    chmod +x add_preamble.sh
#    export PATH="$HOME/Projects/Python/AIDu_NG/aidu-dev-tool:$PATH"
#    
#   ./add_preamble.sh          # Dry run, shows which files would be updated
#   ./add_preamble.sh execute  # Actually updates the files

set -euo pipefail

EXECUTE=false

if [[ "${1:-}" == "execute" ]]; then
    EXECUTE=true
fi

HEADER='# Copyright (c) 2026 Wolfgang Spahn, PHBern
# Licensed under the MIT License.
# Please follow standard academic practice when using this software in research or publications.
# See LICENSE for the full text.
#'

find src \
    -type d \( -name .venv -o -name __pycache__ \) -prune -o \
    -name "*.py" -type f -print |
while read -r file; do

    if ! head -n 1 "$file" | grep -qxF "# Copyright (c) 2026 Wolfgang Spahn, PHBern"; then

        if [[ "$EXECUTE" == false ]]; then
            echo "Would update: $file"
        else
            tmp=$(mktemp)

            {
                printf '%s\n\n' "$HEADER"
                cat "$file"
            } > "$tmp"

            mv "$tmp" "$file"
            echo "Updated: $file"
        fi

    fi
done

if [[ "$EXECUTE" == false ]]; then
    echo
    echo "Dry run only."
    echo "Run with: $0 execute"
fi