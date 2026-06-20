#!/usr/bin/env bash
set -euo pipefail
# ensure ERR trap is inherited by subshells
set -o errtrace

# Report failing command and line when the script exits due to an error
trap 'rc=$?; echo "ERROR: command failed with exit $rc: \"$BASH_COMMAND\" at line ${LINENO}" >&2' ERR

usage() {
  cat <<EOF
Usage: ${0##*/} [DIR]

Checks git status for each immediate child directory of the current directory
or for child directories of the optional DIR argument. A repository is
considered "PUSHED" when the working tree is clean and the current branch
has no un-pushed commits to its upstream. Exits with code 0 if all
repositories are PUSHED, and 1 if any repo has unstaged changes or un-pushed
commits.

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
  parent_dir=$1
fi

if [[ ! -d "$parent_dir" ]]; then
  echo "Error: directory '$parent_dir' not found." >&2
  exit 2
fi

any_dirty=0

shopt -s nullglob
for d in "$parent_dir"/*/; do
  # skip if not a directory
  [[ -d "$d" ]] || continue

  # check if this directory is inside a git work tree
  if git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # local working tree status; handle git failures gracefully
    if ! status=$(git -C "$d" status --porcelain 2>/dev/null); then
      echo "Error: failed to run 'git status' in ${d%/}" >&2
      any_dirty=1
      continue
    fi

    # determine push status: does branch have an upstream and are there unpushed commits?
    pushed_ok=1
    push_msg=""

    # try to get the upstream; if none, treat as not pushed
    if git -C "$d" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
      # compute ahead/behind counts
      read behind ahead < <(git -C "$d" rev-list --left-right --count @{u}...HEAD 2>/dev/null || echo "0 0")
      if [[ $ahead -gt 0 ]]; then
        pushed_ok=0
        push_msg="un-pushed commits (ahead=$ahead)"
      fi
    else
      pushed_ok=0
      push_msg="no upstream configured"
    fi

      if [[ -n "$status" || $pushed_ok -eq 0 ]]; then
      any_dirty=1
      echo "[DIR DIRTY] ${d%/}"
      if [[ -n "$status" ]]; then
        git -C "$d" status --short || true
      fi
      if [[ $pushed_ok -eq 0 ]]; then
        echo "-- Push state: $push_msg"
      fi
      echo
    else
      echo "[PUSHED] ${d%/}"
    fi
  else
    echo "[NO GIT] ${d%/}"
  fi
done

if [[ $any_dirty -ne 0 ]]; then
  echo "One or more repositories have changes or un-pushed commits." >&2
  exit 1
fi

echo "All checked repositories are PUSHED."
exit 0
