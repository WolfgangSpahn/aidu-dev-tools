#!/usr/bin/env bash
set -euo pipefail
set -o errtrace

trap 'rc=$?; echo "ERROR: command failed with exit $rc: \"$BASH_COMMAND\" at line ${LINENO}" >&2' ERR

# Color setup: only use colors when stdout is a terminal
if [[ -t 1 ]]; then
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  MAGENTA=$'\033[35m'
  CYAN=$'\033[36m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  MAGENTA=""
  CYAN=""
  BOLD=""
  RESET=""
fi

ok()      { echo "${GREEN}$*${RESET}"; }
warn()    { echo "${YELLOW}$*${RESET}"; }
bad()     { echo "${RED}$*${RESET}"; }
info()    { echo "${CYAN}$*${RESET}"; }
heading() { echo "${BOLD}${BLUE}$*${RESET}"; }

usage() {
  cat <<EOF
Usage: ${0##*/} [DIR]

Checks Git status for each immediate child directory of DIR.
If DIR is omitted, the current directory is used.

A repository is considered SYNCED when:
  - working tree is clean
  - current branch has an upstream
  - local branch has no commits ahead of upstream
  - upstream has no commits ahead of local

This script fetches remote refs first, so it can detect when GitHub/upstream
is newer than the local branch.

Exit codes:
  0  all repositories are synced
  1  one or more repositories are dirty, ahead, behind, diverged, or invalid
  2  invalid argument/path

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
  bad "Error: directory '$parent_dir' not found." >&2
  exit 2
fi

any_problem=0

shopt -s nullglob

for d in "$parent_dir"/*/; do
  [[ -d "$d" ]] || continue

  repo="${d%/}"

  if ! git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    warn "[NO GIT] $repo"
    continue
  fi

  echo
  heading "== $repo =="

  branch="$(git -C "$d" branch --show-current 2>/dev/null || true)"

  if [[ -z "$branch" ]]; then
    bad "[PROBLEM] Detached HEAD"
    any_problem=1
    continue
  fi

  if ! upstream="$(git -C "$d" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"; then
    bad "[PROBLEM] Branch '$branch' has no upstream configured"
    any_problem=1
    continue
  fi

  if ! status="$(git -C "$d" status --porcelain 2>/dev/null)"; then
    bad "[PROBLEM] Failed to read working tree status"
    any_problem=1
    continue
  fi

  info "[BRANCH]   $branch"
  info "[UPSTREAM] $upstream"

  if ! git -C "$d" fetch --quiet --prune; then
    bad "[PROBLEM] Fetch failed"
    any_problem=1
    continue
  fi

  read behind ahead < <(
    git -C "$d" rev-list --left-right --count "$upstream"...HEAD 2>/dev/null || echo "0 0"
  )

  has_problem=0

  if [[ -n "$status" ]]; then
    warn "[LOCAL DIRTY] Working tree has local changes"
    git -C "$d" status --short || true
    has_problem=1
  fi

  if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
    bad "[DIVERGED] local ahead=$ahead, remote ahead=$behind"
    has_problem=1
  elif [[ "$ahead" -gt 0 ]]; then
    warn "[LOCAL AHEAD] unpushed local commits: ahead=$ahead"
    has_problem=1
  elif [[ "$behind" -gt 0 ]]; then
    warn "[REMOTE AHEAD] GitHub/upstream has new commits: behind=$behind"
    has_problem=1
  fi

  if [[ "$ahead" -gt 0 ]]; then
    echo
    warn "-- Local commits not on remote:"
    git -C "$d" --no-pager log --oneline "$upstream"..HEAD || true
  fi

  if [[ "$behind" -gt 0 ]]; then
    echo
    warn "-- Remote commits not local:"
    git -C "$d" --no-pager log --oneline HEAD.."$upstream" || true

    echo
    warn "-- Files changed on remote:"
    git -C "$d" diff --name-status HEAD.."$upstream" || true
  fi

  if [[ "$has_problem" -eq 0 ]]; then
    ok "[SYNCED] Local branch matches upstream and working tree is clean"
  else
    any_problem=1
  fi
done

echo

if [[ "$any_problem" -ne 0 ]]; then
  bad "One or more repositories are not synced with upstream." >&2
  exit 1
fi

ok "All checked repositories are synced with upstream."
exit 0