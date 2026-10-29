#!/usr/bin/env bash
# Edit an existing PR comment by ID, regardless of which of the three GitHub
# comment types it is (a resolvable PR review comment, a commit/fallback
# comment, or a top-level PR issue comment) -- tries each endpoint in turn
# and reports which one matched.
#
# Usage:
#   gh-pr-edit-comment.sh <COMMENT_ID> <BODY> [owner/repo]
#   gh-pr-edit-comment.sh <COMMENT_ID> --body-file <path> [owner/repo]
#
# The --body-file form is safer for multi-line/code-block bodies -- it avoids
# shell quoting pitfalls entirely (e.g. accidentally escaping backticks inside
# a quoted heredoc, which posts literal backslashes).
#
# Example:
#   gh-pr-edit-comment.sh 3546023343 "Claude 🤖: corrected wording."
#   gh-pr-edit-comment.sh 191714225 --body-file /tmp/comment-body.md

set -euo pipefail

COMMENT_ID="${1:?Usage: $0 <COMMENT_ID> <BODY>|--body-file <path> [owner/repo]}"
shift

if [[ "${1:-}" == "--body-file" ]]; then
  BODY_FILE="${2:?Expected a path after --body-file}"
  BODY=$(cat "$BODY_FILE")
  shift 2
else
  BODY="${1:?Expected body text}"
  shift
fi

REPO="${1:-}"

python3 - "$COMMENT_ID" "$BODY" "$REPO" <<'PYEOF'
import json
import subprocess
import sys

comment_id, body, repo_arg = sys.argv[1], sys.argv[2], sys.argv[3]

def expand(path):
    if repo_arg:
        owner, repo = repo_arg.split("/", 1)
        return path.replace("{owner}", owner).replace("{repo}", repo)
    return path

def gh_patch(path):
    # Pass the body as JSON over stdin rather than --field: --field/-f treats a
    # value starting with "@" as "read from this file", and a body that happens
    # to start with "@" (e.g. "@someone ...") would silently misfire.
    return subprocess.run(
        ["gh", "api", expand(path), "--method", "PATCH", "--input", "-"],
        input=json.dumps({"body": body}),
        capture_output=True,
        text=True,
    )

endpoints = [
    ("PR review comment", f"repos/{{owner}}/{{repo}}/pulls/comments/{comment_id}"),
    ("commit comment", f"repos/{{owner}}/{{repo}}/comments/{comment_id}"),
    ("issue comment", f"repos/{{owner}}/{{repo}}/issues/comments/{comment_id}"),
]

errors = []
for kind, path in endpoints:
    result = gh_patch(path)
    if result.returncode == 0:
        resp = json.loads(result.stdout)
        print(f"Updated {kind} id={comment_id}: {resp['html_url']}")
        sys.exit(0)
    errors.append((kind, result.stderr.strip()))

print(f"Error: comment id={comment_id} did not match any comment type.", file=sys.stderr)
for kind, err in errors:
    print(f"  as {kind}: {err}", file=sys.stderr)
sys.exit(1)
PYEOF
