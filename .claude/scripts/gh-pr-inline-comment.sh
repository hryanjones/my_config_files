#!/usr/bin/env bash
# Post an inline comment on a specific file+line in a PR.
# For diff lines: creates a resolvable PR review comment.
# For non-diff lines: falls back to a commit comment (inline but not resolvable).
#
# Usage: gh-pr-inline-comment.sh <PR> <FILE> <LINE> <BODY> [owner/repo]
#
# Example:
#   gh-pr-inline-comment.sh 649 public/_redirects 3 "Claude 🤖: This causes a double redirect."

set -euo pipefail

PR="${1:?Usage: $0 <PR> <FILE> <LINE> <BODY> [owner/repo]}"
FILE="${2:?Usage: $0 <PR> <FILE> <LINE> <BODY> [owner/repo]}"
LINE="${3:?Usage: $0 <PR> <FILE> <LINE> <BODY> [owner/repo]}"
BODY="${4:?Usage: $0 <PR> <FILE> <LINE> <BODY> [owner/repo]}"
REPO="${5:-}"

# Use explicit if/else — ${REPO:-{owner}/{repo}} misparses due to nested braces.
if [[ -n "$REPO" ]]; then
  API="repos/$REPO"
else
  API="repos/{owner}/{repo}"
fi

COMMIT=$(gh api "$API/pulls/$PR" --jq '.head.sha')

post_review_comment() {
  gh api "$API/pulls/$PR/reviews" \
    --method POST \
    --field commit_id="$COMMIT" \
    --field event="COMMENT" \
    --field body="" \
    --field "comments[][path]=$FILE" \
    --field "comments[][line]=$LINE" \
    --field "comments[][side]=RIGHT" \
    --field "comments[][body]=$BODY"
}

post_commit_comment() {
  echo "Note: line $LINE not in diff — posting as commit comment (inline but not resolvable)" >&2
  gh api "$API/commits/$COMMIT/comments" \
    --method POST \
    --field body="$BODY" \
    --field path="$FILE" \
    --field line="$LINE"
}

# Try review comment first; fall back to commit comment if line not in diff.
post_review_comment 2>/dev/null || post_commit_comment
