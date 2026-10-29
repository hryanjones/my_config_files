#!/usr/bin/env bash
# Read or update a PR's description (body).
# Usage:
#   gh-pr-description.sh <PR_NUMBER> get [owner/repo]
#   gh-pr-description.sh <PR_NUMBER> set <BODY_FILE> [owner/repo]
#   gh-pr-description.sh <PR_NUMBER> append <BODY_FILE> [owner/repo]
#
# get     Print the current body to stdout
# set     Replace the body with the contents of BODY_FILE
# append  Append the contents of BODY_FILE to the current body
#         (separated by a blank line)

set -euo pipefail

PR="${1:?Usage: $0 <PR_NUMBER> get|set|append [BODY_FILE] [owner/repo]}"
ACTION="${2:?Expected get, set, or append}"

repo_flag() {
  if [[ -n "${REPO}" ]]; then
    echo "--repo ${REPO}"
  fi
}

# gh pr edit trips over the Projects (classic) GraphQL deprecation, so
# write through the REST endpoint instead.
patch_body() {
  local body_file="$1"
  local endpoint="repos/{owner}/{repo}/pulls/${PR}"
  if [[ -n "$REPO" ]]; then
    endpoint="repos/${REPO}/pulls/${PR}"
  fi
  gh api -X PATCH "$endpoint" -F body=@"$body_file" --jq .number > /dev/null
}

case "$ACTION" in
  get)
    REPO="${3:-}"
    # shellcheck disable=SC2046
    gh pr view "$PR" $(repo_flag) --json body --jq .body
    ;;
  set)
    BODY_FILE="${3:?Expected body file after 'set'}"
    REPO="${4:-}"
    patch_body "$BODY_FILE"
    echo "Replaced description of PR #$PR from $BODY_FILE"
    ;;
  append)
    BODY_FILE="${3:?Expected body file after 'append'}"
    REPO="${4:-}"
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    # shellcheck disable=SC2046
    gh pr view "$PR" $(repo_flag) --json body --jq .body > "$TMP"
    printf '\n' >> "$TMP"
    cat "$BODY_FILE" >> "$TMP"
    patch_body "$TMP"
    echo "Appended $BODY_FILE to description of PR #$PR"
    ;;
  *)
    echo "Error: expected get, set, or append; got '$ACTION'" >&2
    exit 1
    ;;
esac
