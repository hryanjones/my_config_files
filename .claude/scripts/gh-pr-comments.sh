#!/usr/bin/env bash
# Format GitHub PR review comments for human/AI readability.
# Usage: gh-pr-comments.sh <PR_NUMBER> [repo]
#   repo defaults to the gh CLI's detected current repo.
# Output: each comment with file:line, body, and reply thread.

set -euo pipefail

PR="${1:?Usage: $0 <PR_NUMBER> [owner/repo]}"
REPO_FLAG=""
if [[ -n "${2:-}" ]]; then
  REPO_FLAG="--repo $2"
fi

python3 - "$PR" "${2:-}" <<'PYEOF'
import subprocess, json, sys, textwrap

pr = sys.argv[1]
repo_arg = sys.argv[2]  # "owner/repo" or ""

def gh_api(path):
    # --paginate: GitHub returns 30 items/page by default, silently truncating
    # busy PRs. Without --slurp (needs gh >= 2.47) the pages arrive as
    # back-to-back JSON arrays, so raw_decode them in a loop and flatten.
    if repo_arg:
        owner, repo = repo_arg.split("/", 1)
        path = path.replace("{owner}", owner).replace("{repo}", repo)
    result = subprocess.run(["gh", "api", "--paginate", path], capture_output=True, text=True, check=True)
    decoder = json.JSONDecoder()
    items, text, pos = [], result.stdout.strip(), 0
    while pos < len(text):
        page, end = decoder.raw_decode(text, pos)
        items.extend(page)
        pos = end
        while pos < len(text) and text[pos] in ' \n\r\t':
            pos += 1
    return items

# Review summaries (CHANGES_REQUESTED / APPROVED / COMMENT bodies)
reviews = gh_api(f"repos/{{owner}}/{{repo}}/pulls/{pr}/reviews")
non_empty_reviews = [r for r in reviews if r.get("body", "").strip()]
if non_empty_reviews:
    print("=" * 60)
    print(f"REVIEW SUMMARIES ON PR #{pr} ({len(non_empty_reviews)} with body)")
    print("=" * 60)
    for r in non_empty_reviews:
        user = r["user"]["login"]
        state = r["state"]
        ts = r["submitted_at"]
        print(f"\n[review_id={r['id']}] @{user} ({state}) — {ts}")
        for ln in textwrap.wrap(r["body"], width=100):
            print(f"  {ln}")
    print()

# Inline diff comments
comments = gh_api(f"repos/{{owner}}/{{repo}}/pulls/{pr}/comments")

top_level = [c for c in comments if "in_reply_to_id" not in c]
replies = {}
for c in comments:
    if "in_reply_to_id" in c:
        replies.setdefault(c["in_reply_to_id"], []).append(c)

def fmt_comment(c, indent=0):
    prefix = "  " * indent
    user = c["user"]["login"]
    path = c["path"]
    line = c.get("line") or c.get("original_line") or "?"
    print(f"{prefix}[id={c['id']}] {path}:{line} — @{user}")
    for ln in textwrap.wrap(c["body"], width=100):
        print(f"{prefix}  {ln}")

if top_level:
    print("=" * 60)
    print(f"REVIEW COMMENTS ON PR #{pr} ({len(top_level)} threads)")
    print("=" * 60)
    for i, c in enumerate(top_level, 1):
        print(f"\n--- Thread {i} ---")
        fmt_comment(c)
        for reply in replies.get(c["id"], []):
            print()
            fmt_comment(reply, indent=1)

issue_comments = gh_api(f"repos/{{owner}}/{{repo}}/issues/{pr}/comments")
if issue_comments:
    print(f"\n{'=' * 60}")
    print(f"ISSUE/PR-LEVEL COMMENTS ({len(issue_comments)})")
    print("=" * 60)
    for c in issue_comments:
        user = c["user"]["login"]
        print(f"\n[{c['id']}] @{user}")
        for ln in textwrap.wrap(c["body"], width=100):
            print(f"  {ln}")
PYEOF
