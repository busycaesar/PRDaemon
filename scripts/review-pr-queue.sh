#!/usr/bin/env bash
# For each entry in cache/pr-review/prs-to-review.json, sets PR_NUMBER and BRANCH
# to match code-review.md ({ number } → PR_NUMBER, { headRefName } → BRANCH).
# Proceed using the steps in code-review.md with those variables in scope.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
QUEUE="${ROOT}/cache/pr-review/prs-to-review.json"
CODE_REVIEW_MD="${ROOT}/code-review.md"

if ! command -v jq >/dev/null 2>&1; then
  echo 'error: jq is required to read the JSON queue.' >&2
  exit 1
fi

if [[ ! -f "$QUEUE" ]]; then
  echo "error: queue file not found: ${QUEUE}" >&2
  exit 1
fi

if [[ ! -f "$CODE_REVIEW_MD" ]]; then
  echo "error: code-review instructions not found: ${CODE_REVIEW_MD}" >&2
  exit 1
fi

if [[ "$(jq -r 'type' "$QUEUE")" != "array" ]]; then
  echo "error: ${QUEUE} must be a JSON array." >&2
  exit 1
fi

export CODE_REVIEW_MD

while IFS= read -r item; do
  PR_NUMBER="$(jq -r '.number // empty' <<<"$item")"
  BRANCH="$(jq -r '.headRefName // empty' <<<"$item")"

  if [[ -z "$PR_NUMBER" || -z "$BRANCH" || "$PR_NUMBER" == "null" || "$BRANCH" == "null" ]]; then
    echo "warning: skipping entry missing number or headRefName: ${item}" >&2
    continue
  fi

  export PR_NUMBER BRANCH

  printf 'PR_NUMBER=%s BRANCH=%s  → follow steps in %s\n' "$PR_NUMBER" "$BRANCH" "$CODE_REVIEW_MD"
done < <(jq -c '.[]' "$QUEUE")
