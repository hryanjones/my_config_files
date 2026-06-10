#!/usr/bin/env bash
# Show a file's contents at the HEAD of a PR's branch.
# Usage: gh-pr-file.sh <PR_NUMBER> <FILE_PATH> [owner/repo]
#   owner/repo defaults to the gh CLI's detected current repo.

set -euo pipefail

PR="${1:?Usage: $0 <PR_NUMBER> <FILE_PATH> [owner/repo]}"
FILE="${2:?Usage: $0 <PR_NUMBER> <FILE_PATH> [owner/repo]}"
REPO="${3:-}"

if [[ -n "$REPO" ]]; then
  REF=$(gh api "repos/$REPO/pulls/$PR" --jq '.head.ref')
  gh api "repos/$REPO/contents/$FILE?ref=$REF" --jq '.content' | base64 -d
else
  REF=$(gh api "repos/{owner}/{repo}/pulls/$PR" --jq '.head.ref')
  gh api "repos/{owner}/{repo}/contents/$FILE?ref=$REF" --jq '.content' | base64 -d
fi
