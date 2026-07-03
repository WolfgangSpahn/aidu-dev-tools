#!/usr/bin/env bash
set -u
set -o pipefail

usage() {
  cat <<EOF
Usage: ${0##*/} [DIR]

Pulls all immediate child Git repositories of DIR.

This is a forgiving sync script:
  - fetches origin
  - checks the current branch
  - repairs missing upstream if origin/<branch> exists
  - pulls with --ff-only
  - does not reset
  - does not clean
  - does not delete local files
  - does not overwrite local commits

It never pushes and never changes the remote.

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
any_attention=0
any_updated=0
any_clean=0
any_no_git=0

shopt -s nullglob

for d in "$parent_dir"/*/; do
  [[ -d "$d" ]] || continue

  repo="${d%/}"

  if ! git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[NO GIT] $repo"
    any_no_git=1
    continue
  fi

  echo
  echo "== $repo =="

  branch="$(git -C "$d" branch --show-current 2>/dev/null || true)"

  if [[ -z "$branch" ]]; then
    echo "[ATTENTION] Detached HEAD - not pulling"
    any_attention=1
    continue
  fi

  echo "[BRANCH] $branch"

  if ! git -C "$d" remote get-url origin >/dev/null 2>&1; then
    echo "[FAIL] No remote named 'origin'"
    any_failed=1
    continue
  fi

  echo "[FETCH] origin"

  if ! git -C "$d" fetch origin --quiet --prune; then
    echo "[FAIL] fetch origin failed"
    any_failed=1
    continue
  fi

  upstream=""

  if upstream="$(git -C "$d" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"; then
    echo "[UPSTREAM] $upstream"
  else
    candidate="origin/$branch"

    if git -C "$d" show-ref --verify --quiet "refs/remotes/$candidate"; then
      echo "[UPSTREAM] Missing. Setting '$branch' -> '$candidate'"

      if ! git -C "$d" branch --set-upstream-to="$candidate" "$branch"; then
        echo "[FAIL] Could not set upstream to '$candidate'"
        any_failed=1
        continue
      fi

      upstream="$candidate"
    else
      echo "[ATTENTION] No upstream configured and '$candidate' does not exist"
      echo "            Manual command could be:"
      echo "            git -C \"$repo\" branch --set-upstream-to=origin/<branch> $branch"
      any_attention=1
      continue
    fi
  fi

  status="$(git -C "$d" status --porcelain)"

  if [[ -n "$status" ]]; then
    echo "[LOCAL CHANGES] Working tree is not clean"
    echo "                Pulling with local changes may fail if files overlap."
  else
    echo "[LOCAL CHANGES] none"
  fi

  local_sha="$(git -C "$d" rev-parse HEAD)"
  upstream_sha="$(git -C "$d" rev-parse "$upstream")"
  base_sha="$(git -C "$d" merge-base HEAD "$upstream")"

  if [[ "$local_sha" == "$upstream_sha" ]]; then
    echo "[OK] Already up to date"
    any_clean=1
    continue
  fi

  if [[ "$local_sha" == "$base_sha" ]]; then
    echo "[PULL] Fast-forwarding from '$upstream'"

    if git -C "$d" pull --ff-only; then
      echo "[OK] Updated"
      any_updated=1
    else
      echo "[FAIL] pull --ff-only failed"
      any_failed=1
    fi

    continue
  fi

  if [[ "$upstream_sha" == "$base_sha" ]]; then
    echo "[ATTENTION] Local branch is ahead of '$upstream'"
    echo "            No pull needed, but you have local commits not on remote."
    echo "            To push them:"
    echo "            git -C \"$repo\" push"
    any_attention=1
    continue
  fi

  echo "[ATTENTION] Local and remote branches have diverged"
  echo "            Refusing automatic merge/rebase."
  echo "            Inspect manually:"
  echo "            git -C \"$repo\" status"
  echo "            git -C \"$repo\" log --oneline --graph --decorate --all -20"
  any_attention=1
done

echo
echo "Summary:"
echo "  Updated repos:        $any_updated"
echo "  Already up to date:   $any_clean"
echo "  Need attention:       $any_attention"
echo "  Failed:               $any_failed"
echo "  Non-git folders seen: $any_no_git"

if [[ "$any_failed" -ne 0 ]]; then
  echo
  echo "Finished with failures." >&2
  exit 1
fi

if [[ "$any_attention" -ne 0 ]]; then
  echo
  echo "Finished. Some repositories need attention."
  exit 3
fi

echo
echo "All Git repositories pulled cleanly."
exit 0