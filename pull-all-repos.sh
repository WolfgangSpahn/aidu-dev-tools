#!/usr/bin/env bash
set -u
set -o pipefail

if [[ -t 1 ]]; then
  red=$'\033[31m'
  green=$'\033[32m'
  yellow=$'\033[33m'
  cyan=$'\033[36m'
  bold=$'\033[1m'
  reset=$'\033[0m'
else
  red=""
  green=""
  yellow=""
  cyan=""
  bold=""
  reset=""
fi

usage() {
  cat <<EOF
Usage: ${0##*/} [--force] [DIR]

Pulls all immediate child Git repositories of DIR.

Without --force, this is a forgiving sync script:
  - fetches origin
  - checks the current branch
  - repairs missing upstream if origin/<branch> exists
  - pulls with --ff-only
  - does not reset
  - does not clean
  - does not delete local files
  - does not overwrite local commits

It never pushes and never changes the remote.

Options:
  --force  Discard tracked local changes and local commits by resetting each
           branch to its upstream. Untracked and ignored files are preserved,
           so local installs and build environments remain intact.
  -h, --help
           Show this help.

Examples:
  ${0##*/}
  ${0##*/} --force
  ${0##*/} /path/to/parent
  ${0##*/} --force /path/to/parent
EOF
}

parent_dir="."
force=0
dir_set=0

while (($# > 0)); do
  case "$1" in
    --force)
      force=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option '$1'." >&2
      usage >&2
      exit 2
      ;;
    *)
      if ((dir_set)); then
        echo "Error: only one directory may be specified." >&2
        usage >&2
        exit 2
      fi
      parent_dir="$1"
      dir_set=1
      ;;
  esac
  shift
done

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
    echo "${yellow}[NO GIT]${reset} $repo"
    ((any_no_git += 1))
    continue
  fi

  echo
  echo "${bold}== $repo ==${reset}"

  branch="$(git -C "$d" branch --show-current 2>/dev/null || true)"

  if [[ -z "$branch" ]]; then
    echo "${yellow}[ATTENTION]${reset} Detached HEAD - not pulling"
    ((any_attention += 1))
    continue
  fi

  echo "${cyan}[BRANCH]${reset} $branch"

  if ! git -C "$d" remote get-url origin >/dev/null 2>&1; then
    echo "${red}[FAIL]${reset} No remote named 'origin'"
    ((any_failed += 1))
    continue
  fi

  echo "${cyan}[FETCH]${reset} origin"

  if ! git -C "$d" fetch origin --quiet --prune; then
    echo "${red}[FAIL]${reset} fetch origin failed"
    ((any_failed += 1))
    continue
  fi

  upstream=""

  if upstream="$(git -C "$d" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"; then
    echo "${cyan}[UPSTREAM]${reset} $upstream"
  else
    candidate="origin/$branch"

    if git -C "$d" show-ref --verify --quiet "refs/remotes/$candidate"; then
      echo "${cyan}[UPSTREAM]${reset} Missing. Setting '$branch' -> '$candidate'"

      if ! git -C "$d" branch --set-upstream-to="$candidate" "$branch"; then
        echo "${red}[FAIL]${reset} Could not set upstream to '$candidate'"
        ((any_failed += 1))
        continue
      fi

      upstream="$candidate"
    else
      echo "${yellow}[ATTENTION]${reset} No upstream configured and '$candidate' does not exist"
      echo "            Manual command could be:"
      echo "            git -C \"$repo\" branch --set-upstream-to=origin/<branch> $branch"
      ((any_attention += 1))
      continue
    fi
  fi

  status="$(git -C "$d" status --porcelain)"
  tracked_status="$(git -C "$d" status --porcelain --untracked-files=no)"

  if [[ -n "$status" ]]; then
    echo "${yellow}[LOCAL CHANGES]${reset} Working tree is not clean"
    echo "                Pulling with local changes may fail if files overlap."
  else
    echo "${green}[LOCAL CHANGES]${reset} none"
  fi

  local_sha="$(git -C "$d" rev-parse HEAD)"
  upstream_sha="$(git -C "$d" rev-parse "$upstream")"
  base_sha="$(git -C "$d" merge-base HEAD "$upstream")"

  if ((force)); then
    echo "${yellow}[FORCE]${reset} Resetting tracked files and commits to '$upstream'"

    if git -C "$d" reset --hard "$upstream"; then
      if [[ "$local_sha" == "$upstream_sha" && -z "$tracked_status" ]]; then
        echo "${green}[OK]${reset} Already up to date"
        ((any_clean += 1))
      else
        echo "${green}[OK]${reset} Reset to '$upstream'; untracked and ignored files preserved"
        ((any_updated += 1))
      fi
    else
      echo "${red}[FAIL]${reset} reset --hard '$upstream' failed"
      ((any_failed += 1))
    fi

    continue
  fi

  if [[ "$local_sha" == "$upstream_sha" ]]; then
    echo "${green}[OK]${reset} Already up to date"
    ((any_clean += 1))
    continue
  fi

  if [[ "$local_sha" == "$base_sha" ]]; then
    echo "${cyan}[PULL]${reset} Fast-forwarding from '$upstream'"

    if git -C "$d" pull --ff-only; then
      echo "${green}[OK]${reset} Updated"
      ((any_updated += 1))
    else
      echo "${red}[FAIL]${reset} pull --ff-only failed"
      ((any_failed += 1))
    fi

    continue
  fi

  if [[ "$upstream_sha" == "$base_sha" ]]; then
    echo "${yellow}[ATTENTION]${reset} Local branch is ahead of '$upstream'"
    echo "            No pull needed, but you have local commits not on remote."
    echo "            To push them:"
    echo "            git -C \"$repo\" push"
    ((any_attention += 1))
    continue
  fi

  echo "${yellow}[ATTENTION]${reset} Local and remote branches have diverged"
  echo "            Refusing automatic merge/rebase."
  echo "            Inspect manually:"
  echo "            git -C \"$repo\" status"
  echo "            git -C \"$repo\" log --oneline --graph --decorate --all -20"
  ((any_attention += 1))
done

echo
echo "${bold}Summary:${reset}"
echo "  ${green}Updated repos:        $any_updated${reset}"
echo "  ${green}Already up to date:   $any_clean${reset}"
echo "  ${yellow}Need attention:       $any_attention${reset}"
echo "  ${red}Failed:               $any_failed${reset}"
echo "  ${yellow}Non-git folders seen: $any_no_git${reset}"

if [[ "$any_failed" -ne 0 ]]; then
  echo
  echo "${red}Finished with failures.${reset}" >&2
  exit 1
fi

if [[ "$any_attention" -ne 0 ]]; then
  echo
  echo "${yellow}Finished. Some repositories need attention.${reset}"
  exit 3
fi

echo
echo "${green}All Git repositories pulled cleanly.${reset}"
exit 0
