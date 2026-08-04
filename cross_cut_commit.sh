#!/usr/bin/env bash
set -u
set -o pipefail

# Match check_child_git_status.sh: color only interactive terminal output.
if [[ -t 1 ]]; then
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  CYAN=$'\033[36m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; BOLD=""; RESET=""
fi

ok()      { echo "${GREEN}$*${RESET}"; }
warn()    { echo "${YELLOW}$*${RESET}"; }
bad()     { echo "${RED}$*${RESET}"; }
info()    { echo "${CYAN}$*${RESET}"; }
heading() { echo "${BOLD}${BLUE}$*${RESET}"; }

usage() {
  cat <<EOF
Usage: ${0##*/} [-n|--dry-run] [-y|--yes] [-m MESSAGE] [DIR]

Stage, commit, and push changes in every immediate child Git repository of DIR.
DIR defaults to the current directory. Repositories without changes are skipped.

Safety checks:
  - only real child repository roots are considered
  - child symlinks are accepted only when they resolve exactly to a Git root
  - duplicate links to the same physical repository are processed once
  - detached HEAD and unfinished Git operations are rejected
  - each branch must track origin/<branch>
  - remote refs are fetched before any commit
  - behind/diverged branches and existing unpushed commits are rejected
  - suspicious secret filenames and untracked files over 20 MiB are rejected
  - every repository is preflighted before any commit is created
  - every commit is created before the first push begins

Options:
  -m, --message MESSAGE  Commit message (required; prompted on a terminal)
  -n, --dry-run          Print the repositories and changes; do not modify them
  -y, --yes              Skip the final confirmation prompt
  -h, --help             Show this help

Examples:
  ${0##*/} -m "Update shared localization" /path/to/AIDu_NG
  ${0##*/} --dry-run -m "Preview only"
EOF
}

dry_run=0
assume_yes=0
message=""
parent_dir="."
max_untracked_bytes=$((20 * 1024 * 1024))

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) dry_run=1; shift ;;
    -y|--yes) assume_yes=1; shift ;;
    -m|--message)
      [[ $# -ge 2 ]] || { bad "Error: $1 requires a value." >&2; exit 2; }
      message="$2"
      shift 2
      ;;
    --) shift; break ;;
    -*) bad "Error: unknown option '$1'." >&2; usage >&2; exit 2 ;;
    *) parent_dir="$1"; shift; [[ $# -eq 0 ]] || { bad "Error: too many arguments." >&2; exit 2; } ;;
  esac
done

if [[ -z "${message//[[:space:]]/}" && -t 0 ]]; then
  read -r -p "Commit message: " message
fi
if [[ -z "${message//[[:space:]]/}" ]]; then
  bad "Error: a non-empty commit message is required (-m MESSAGE)." >&2
  exit 2
fi
if [[ "$message" == *$'\n'* || "$message" == *$'\r'* ]]; then
  bad "Error: use a single-line commit message." >&2
  exit 2
fi
if [[ ! -d "$parent_dir" ]]; then
  bad "Error: directory '$parent_dir' not found." >&2
  exit 2
fi

parent_dir="$(cd "$parent_dir" && pwd -P)"
declare -a repos=()
declare -a dirty_repos=()
declare -a committed_repos=()
declare -A seen_roots=()
preflight_failed=0

shopt -s nullglob
for directory in "$parent_dir"/*/; do
  repo="${directory%/}"
  [[ -e "$repo/.git" ]] || continue
  root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$root" ]] || continue
  root="$(cd "$root" && pwd -P)"
  resolved_repo="$(cd "$repo" 2>/dev/null && pwd -P || true)"
  if [[ "$root" != "$resolved_repo" ]]; then
    warn "[SKIP] $repo is not its own Git root (root: $root)"
    continue
  fi
  if [[ -n ${seen_roots[$root]+x} ]]; then
    warn "[SKIP] $repo resolves to already included repository $root"
    continue
  fi
  seen_roots["$root"]=1
  if [[ -L "$repo" ]]; then
    info "[LINK] $repo -> $root"
  fi
  # Operate on the physical root. This avoids Git/path surprises when a child
  # entry is a supported symlink to a repository elsewhere on disk.
  repos+=("$root")
done

if [[ ${#repos[@]} -eq 0 ]]; then
  warn "No immediate child Git repositories found in $parent_dir."
  exit 0
fi

info "Preflighting ${#repos[@]} repositories under $parent_dir"
for repo in "${repos[@]}"; do
  echo
  heading "== $repo =="
  status="$(git -C "$repo" status --porcelain=v1 --untracked-files=all)"
  if [[ -z "$status" ]]; then
    ok "[CLEAN] No changes"
    continue
  fi
  dirty_repos+=("$repo")

  branch="$(git -C "$repo" branch --show-current 2>/dev/null || true)"
  if [[ -z "$branch" ]]; then
    bad "[FAIL] Detached HEAD" >&2
    preflight_failed=1
    continue
  fi

  git_dir="$(git -C "$repo" rev-parse --absolute-git-dir)"
  operation=""
  for marker in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply BISECT_LOG; do
    if [[ -e "$git_dir/$marker" ]]; then operation="$marker"; break; fi
  done
  if [[ -n "$operation" ]]; then
    bad "[FAIL] Unfinished Git operation: $operation" >&2
    preflight_failed=1
    continue
  fi

  if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
    bad "[FAIL] Missing origin remote" >&2
    preflight_failed=1
    continue
  fi
  upstream="$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  if [[ "$upstream" != "origin/$branch" ]]; then
    bad "[FAIL] '$branch' must track 'origin/$branch' (found '${upstream:-none}')" >&2
    preflight_failed=1
    continue
  fi
  if ! git -C "$repo" fetch origin --quiet --prune; then
    bad "[FAIL] fetch origin failed" >&2
    preflight_failed=1
    continue
  fi
  read -r behind ahead < <(git -C "$repo" rev-list --left-right --count "$upstream...HEAD")
  if [[ "$behind" -ne 0 || "$ahead" -ne 0 ]]; then
    bad "[FAIL] Branch must equal upstream before mass commit (behind=$behind ahead=$ahead)" >&2
    preflight_failed=1
    continue
  fi

  suspicious="$(printf '%s\n' "$status" | sed -E 's/^...//' | grep -Ei '(^|/)(\.env($|\.)|.*\.(pem|key|p12|pfx)$|id_(rsa|dsa|ecdsa|ed25519)$|credentials?\.(json|ya?ml)$|secrets?\.(json|ya?ml)$)' || true)"
  if [[ -n "$suspicious" ]]; then
    bad "[FAIL] Suspicious credential/secret filename(s):" >&2
    printf '  %s\n' "$suspicious" >&2
    preflight_failed=1
    continue
  fi

  oversized=0
  while IFS= read -r -d '' relative; do
    [[ -f "$repo/$relative" ]] || continue
    bytes="$(stat -c %s "$repo/$relative")"
    if [[ "$bytes" -gt "$max_untracked_bytes" ]]; then
      bad "[FAIL] Untracked file exceeds 20 MiB: $relative ($bytes bytes)" >&2
      oversized=1
    fi
  done < <(git -C "$repo" ls-files --others --exclude-standard -z)
  if [[ "$oversized" -ne 0 ]]; then
    preflight_failed=1
    continue
  fi

  ok "[READY] branch=$branch upstream=$upstream"
  printf '%s\n' "$status" | sed 's/^/  /'
done

echo
if [[ "$preflight_failed" -ne 0 ]]; then
  bad "Preflight failed. No files were staged, committed, or pushed." >&2
  exit 1
fi
if [[ ${#dirty_repos[@]} -eq 0 ]]; then
  ok "All repositories are clean. Nothing to do."
  exit 0
fi
if [[ "$dry_run" -eq 1 ]]; then
  info "Dry run complete. Would commit and push ${#dirty_repos[@]} repositories."
  exit 0
fi
if [[ "$assume_yes" -ne 1 ]]; then
  if [[ ! -t 0 ]]; then
    bad "Error: confirmation requires a terminal; use --yes for automation." >&2
    exit 2
  fi
  read -r -p "Commit and push ${#dirty_repos[@]} repositories with message '$message'? [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || { warn "Cancelled. No changes made."; exit 0; }
fi

echo
info "Creating local commits (nothing is pushed until all commits succeed)"
for repo in "${dirty_repos[@]}"; do
  heading "== $repo =="
  if ! git -C "$repo" add .; then
    bad "[FAIL] git add failed; no repositories were pushed." >&2
    exit 1
  fi
  if git -C "$repo" diff --cached --quiet; then
    warn "[SKIP] No staged changes after git add"
    continue
  fi
  if ! git -C "$repo" commit -m "$message"; then
    bad "[FAIL] commit failed; no repositories were pushed." >&2
    warn "Local commits already created in earlier repositories remain unpushed." >&2
    exit 1
  fi
  committed_repos+=("$repo")
done

if [[ ${#committed_repos[@]} -eq 0 ]]; then
  warn "No commits were created. Nothing to push."
  exit 0
fi

echo
info "Pushing ${#committed_repos[@]} repositories"
push_failed=0
for repo in "${committed_repos[@]}"; do
  branch="$(git -C "$repo" branch --show-current)"
  heading "== $repo ($branch) =="
  if git -C "$repo" push origin "$branch"; then
    ok "[OK] Pushed"
  else
    bad "[FAIL] Push failed; the local commit is retained for retry." >&2
    push_failed=1
  fi
done

if [[ "$push_failed" -ne 0 ]]; then
  bad "Finished with push failures. Successful pushes were not rolled back." >&2
  exit 1
fi

ok "All ${#committed_repos[@]} repositories committed and pushed successfully."
