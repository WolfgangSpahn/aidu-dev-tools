#!/usr/bin/env bash
set -u

usage() {
  cat <<EOF
Usage: ${0##*/} [DIR]

Force-resets all immediate child Git repositories of DIR to their upstream branch.

Remote is treated as the master/source of truth.
Local state is discarded completely.

This script modifies only local repositories.
It never pushes and never changes the remote.

Effects per repo:
  - fetch remote refs
  - reset current local branch to its upstream branch
  - delete untracked files
  - delete ignored files

WARNING:
  This destroys all local changes, staged changes, untracked files,
  ignored files, build folders, virtual environments, and unpushed commits.

Examples:
  ${0##*/}
  ${0##*/} /path/to/parent
EOF
}

parent_dir="."

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n ${1:-} ]]; then
  parent_dir="$1"
fi

if [[ ! -d "$parent_dir" ]]; then
  echo "Error: directory '$parent_dir' not found." >&2
  exit 2
fi

any_failed=0
any_skipped=0

shopt -s nullglob

for d in "$parent_dir"/*/; do
  [[ -d "$d" ]] || continue

  repo="${d%/}"

  if ! git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[NO GIT] $repo"
    continue
  fi

  echo
  echo "== $repo =="

  branch="$(git -C "$d" branch --show-current 2>/dev/null || true)"

  if [[ -z "$branch" ]]; then
    echo "[SKIP] Detached HEAD"
    any_skipped=1
    continue
  fi

  if ! upstream="$(git -C "$d" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"; then
    echo "[SKIP] Branch '$branch' has no upstream configured"
    any_skipped=1
    continue
  fi

  echo "[REMOTE MASTER] $upstream"
  echo "[FETCH] Updating remote-tracking refs"

  if ! git -C "$d" fetch --quiet --prune; then
    echo "[FAIL] fetch failed"
    any_failed=1
    continue
  fi

  echo "[RESET] Forcing local '$branch' to exactly match '$upstream'"

  if ! git -C "$d" reset --hard "$upstream"; then
    echo "[FAIL] reset --hard '$upstream' failed"
    any_failed=1
    continue
  fi

  echo "[CLEAN] Removing untracked and ignored local files"

  if ! git -C "$d" clean -fdx; then
    echo "[FAIL] clean -fdx failed"
    any_failed=1
    continue
  fi

  echo "[OK] Local repo now matches remote upstream"
done

echo

if [[ "$any_failed" -ne 0 ]]; then
  echo "Finished with failures." >&2
  exit 1
fi

if [[ "$any_skipped" -ne 0 ]]; then
  echo "Finished. Some repositories were skipped."
  exit 0
fi

echo "All repositories reset to their remote upstream."
exit 0