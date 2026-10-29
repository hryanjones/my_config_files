#!/usr/bin/env bash
# Post a reply to a PR review comment thread, or a top-level PR comment.
#
# NOTE: this publishes immediately and notifies watchers. To queue replies for
# Ryan to review and submit as a batch, use `gh-pr-pending-review.sh reply`.
# Usage:
#   gh-pr-reply.sh <PR_NUMBER> --thread <COMMENT_ID> <BODY> [owner/repo]
#   gh-pr-reply.sh <PR_NUMBER> --issue <BODY> [owner/repo]
#
# --thread <id>  Reply to an existing review-comment thread (inline diff comment)
# --issue        Post a top-level comment on the PR issue

set -euo pipefail

PR="${1:?Usage: $0 <PR_NUMBER> --thread <id>|--issue <body> [owner/repo]}"
shift

MODE="${1:?Expected --thread or --issue}"
shift

if [[ "$MODE" == "--thread" ]]; then
  COMMENT_ID="${1:?Expected comment ID after --thread}"
  shift
  BODY="${1:?Expected body text}"
  shift
  REPO="${1:-}"
elif [[ "$MODE" == "--issue" ]]; then
  COMMENT_ID=""
  BODY="${1:?Expected body text}"
  shift
  REPO="${1:-}"
else
  echo "Error: expected --thread or --issue, got $MODE" >&2
  exit 1
fi

python3 - "$PR" "$MODE" "$COMMENT_ID" "$BODY" "$REPO" <<'PYEOF'
import subprocess, json, sys

pr, mode, comment_id, body, repo_arg = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

def expand(path):
    if repo_arg:
        owner, repo = repo_arg.split("/", 1)
        return path.replace("{owner}", owner).replace("{repo}", repo)
    return path

def gh_post(path, payload):
    cmd = ["gh", "api", expand(path), "--method", "POST"]
    for k, v in payload.items():
        cmd += ["--field", f"{k}={v}"]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return json.loads(result.stdout)

if mode == "--thread":
    resp = gh_post(f"repos/{{owner}}/{{repo}}/pulls/{pr}/comments/{comment_id}/replies", {"body": body})
    print(f"Posted reply id={resp['id']} to thread {comment_id}")
else:
    resp = gh_post(f"repos/{{owner}}/{{repo}}/issues/{pr}/comments", {"body": body})
    print(f"Posted issue comment id={resp['id']} on PR #{pr}")
PYEOF
