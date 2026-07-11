#!/usr/bin/env bash
set -euo pipefail

JS_PREAMBLE="preamble-js.txt"
PY_PREAMBLE="preamble-py.txt"
IMPLEMENT=false

usage() {
  cat <<EOF
Usage: ${0##*/} [--implement]

Adds preambles to source files below any src/ directory.

Default mode:
  Dry run only. Shows what would be changed.

Files:
  *.ts, *.tsx, *.js, *.jsx  use preamble-js.txt
  *.py                      use preamble-py.txt

Options:
  --implement   Actually modify the files.
  -h, --help    Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --implement)
      IMPLEMENT=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for preamble in "$JS_PREAMBLE" "$PY_PREAMBLE"; do
  if [[ ! -f "$preamble" ]]; then
    echo "Error: $preamble not found." >&2
    exit 1
  fi
done

changed=0
skipped=0

while IFS= read -r -d '' file; do
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx)
      PREAMBLE="$JS_PREAMBLE"
      ;;
    *.py)
      PREAMBLE="$PY_PREAMBLE"
      ;;
    *)
      echo "skip unsupported: $file"
      skipped=$((skipped + 1))
      continue
      ;;
  esac

  if head -n 20 "$file" | grep -q "Copyright (C) 2026 Dr. Wolfgang Spahn"; then
    echo "skip:      $file"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ "$IMPLEMENT" == true ]]; then
    tmp="$(mktemp)"
    {
      cat "$PREAMBLE"
      echo
      cat "$file"
    } > "$tmp"

    mv "$tmp" "$file"
    echo "added:     $file"
  else
    echo "would add: $file"
  fi

  changed=$((changed + 1))
done < <(
  find . -path "*/src/*" \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" \) \
    -type f -print0
)

echo
echo "Files to change: $changed"
echo "Files skipped:   $skipped"

if [[ "$IMPLEMENT" == true ]]; then
  echo "Mode: implemented"
else
  echo "Mode: dry run"
  echo "Re-run with --implement to modify files."
fi