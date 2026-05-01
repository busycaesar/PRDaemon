#!/usr/bin/env bash
# Loads repo and author from config.json, lists open PRs via gh, writes
# cache/pr-review/prs-to-review.json under the repo root (2-space indent; [] when empty).

set -euo pipefail

find_repo_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/config.json" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(find_repo_root "$SCRIPT_DIR")" || {
  echo "error: config.json not found starting from ${SCRIPT_DIR}" >&2
  exit 1
}

CONFIG="${ROOT}/config.json"
CACHE_DIR="${ROOT}/cache/pr-review"
OUTPUT_FILE="${CACHE_DIR}/prs-to-review.json"

REPO="$(jq -r '.repo // empty' "$CONFIG")"
AUTHOR="$(jq -r '.authorUsername // empty' "$CONFIG")"

if [[ -z "$REPO" || -z "$AUTHOR" ]]; then
  echo "error: config.json must set non-empty 'repo' and 'authorUsername'" >&2
  exit 1
fi

mkdir -p "$CACHE_DIR"

gh pr list \
  --repo "$REPO" \
  --search "is:open -author:$AUTHOR" \
  --limit 20 \
  --json number,headRefName,reviews \
  --jq "[.[] | select([.reviews[]? | select(.state == \"APPROVED\" and .author.login == \"$AUTHOR\")] | length == 0) | {number, headRefName}]" \
  | jq '.' >"$OUTPUT_FILE"

echo "Wrote ${OUTPUT_FILE}"
