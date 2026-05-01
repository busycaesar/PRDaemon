#!/usr/bin/env bash
# Reads config.yaml next to this script, lists open PRs via gh, writes
# cache/pr-review/prs-to-review.json (2-space indent; [] when empty).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
CONFIG="${ROOT}/config.yaml"

CACHE_DIR="${ROOT}/cache/pr-review"
OUTPUT_FILE="${CACHE_DIR}/prs-to-review.json"

require_cmd() {
  local bin="$1"
  local hint="$2"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "error: \"${bin}\" not found on PATH. ${hint}" >&2
    exit 1
  fi
}

require_gh_authenticated() {
  if ! gh auth status >/dev/null 2>&1; then
    echo "error: GitHub CLI is not logged in. Run: gh auth login" >&2
    exit 1
  fi
}

require_yaml_reader() {
  if command -v yq >/dev/null 2>&1; then
    return 0
  fi
  if command -v ruby >/dev/null 2>&1; then
    return 0
  fi
  echo "error: install yq (https://github.com/mikefarah/yq) or Ruby to read YAML in ${CONFIG}" >&2
  exit 1
}

require_cmd gh "Install from https://cli.github.com/"
require_cmd jq "Install jq (e.g. brew install jq)."
require_gh_authenticated

if [[ ! -f "$CONFIG" ]]; then
  echo "error: missing ${CONFIG} (copy from config.example.yaml if you use one)" >&2
  exit 1
fi

if [[ ! -s "$CONFIG" ]]; then
  echo "error: ${CONFIG} is empty" >&2
  exit 1
fi

require_yaml_reader

read_config_yaml() {
  local key="$1"
  if command -v yq >/dev/null 2>&1; then
    yq eval ".${key}" "$CONFIG"
  else
    ruby -ryaml -e '
      path = ARGV[0]
      key = ARGV[1]
      doc = YAML.load_file(path)
      print doc.is_a?(Hash) ? (doc[key] || doc[key.to_sym] || "").to_s : ""
    ' "$CONFIG" "$key"
  fi
}

REPO="$(read_config_yaml repo)"
AUTHOR="$(read_config_yaml authorUsername)"
REPO="${REPO//$'\r'/}"
AUTHOR="${AUTHOR//$'\r'/}"
REPO="$(printf '%s' "$REPO" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
AUTHOR="$(printf '%s' "$AUTHOR" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

missing_keys=()
is_blank() {
  [[ -z "$1" || "$1" == "null" || "$1" == "~" ]]
}
if is_blank "$REPO"; then
  missing_keys+=("repo")
fi
if is_blank "$AUTHOR"; then
  missing_keys+=("authorUsername")
fi
if [[ ${#missing_keys[@]} -gt 0 ]]; then
  echo "error: ${CONFIG} is missing values for required key(s):" >&2
  printf '  — %s\n' "${missing_keys[@]}" >&2
  echo >&2
  echo "  repo: GitHub repo as owner/name (used with gh --repo)." >&2
  echo "  authorUsername: your username; PRs opened by them are skipped, same for PRs already approved by them." >&2
  echo >&2
  echo "Fill in both keys under ${CONFIG}. See $(dirname "${CONFIG}")/config.example.yaml for a starter file." >&2
  exit 1
fi

if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "error: gh cannot read repository \"${REPO}\". Check repo: in ${CONFIG}, run gh auth login if needed, and confirm you have access." >&2
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
