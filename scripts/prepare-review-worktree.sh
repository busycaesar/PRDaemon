#!/usr/bin/env bash
# Prepare ./worktrees/<branch> like code-review.md: fetch, worktree add, or reuse.
# Usage: ./scripts/prepare-review-worktree.sh <branch>
# Run from anywhere inside the git repo; uses git rev-parse for the repo root.

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <branch>" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage
BRANCH="$1"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "error: not inside a git repository." >&2
  exit 1
}

cd "$ROOT"
WT_REL="worktrees/${BRANCH}"

git fetch origin "$BRANCH"

if git worktree add "./${WT_REL}" "$BRANCH"; then
  :
elif [[ -d "./${WT_REL}" ]]; then
  cd "./${WT_REL}"
  git checkout "$BRANCH"
  git pull --ff-only origin "$BRANCH"
  cd "$ROOT"
else
  echo "error: git worktree add failed and no directory at ./${WT_REL}" >&2
  exit 1
fi

WT_ABS="${ROOT}/${WT_REL}"
printf 'Worktree ready at %s\n' "$WT_ABS"
printf 'Enter it with: cd %q\n' "$WT_ABS"
