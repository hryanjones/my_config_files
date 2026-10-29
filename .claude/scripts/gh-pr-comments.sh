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

# Your own PENDING review, if any. The REST list endpoints above omit pending
# comments entirely (even from their author), so without this a drafted review
# is invisible here and easy to duplicate.
def gh_graphql(query, variables):
    payload = json.dumps({"query": query, "variables": variables})
    result = subprocess.run(["gh", "api", "graphql", "--input", "-"],
                            input=payload, capture_output=True, text=True)
    if not result.stdout.strip():
        return None
    response = json.loads(result.stdout)
    if response.get("errors"):
        return None
    return response["data"]

if repo_arg:
    owner, name = repo_arg.split("/", 1)
else:
    name_with_owner = subprocess.run(
        ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
        capture_output=True, text=True, check=True).stdout.strip()
    owner, name = name_with_owner.split("/", 1)

pending_data = gh_graphql("""
query($owner:String!, $name:String!, $pr:Int!) {
  repository(owner:$owner, name:$name) {
    pullRequest(number:$pr) {
      reviews(first:5, states:[PENDING]) {
        nodes {
          databaseId body url
          comments(first:100) {
            nodes { path line originalLine body replyTo { databaseId } }
          }
        }
      }
    }
  }
}
""", {"owner": owner, "name": name, "pr": int(pr)})

pending = (pending_data or {}).get("repository", {}).get("pullRequest", {}).get("reviews", {}).get("nodes") or []
for review in pending:
    queued = review["comments"]["nodes"]
    print("=" * 60)
    print(f"YOUR PENDING REVIEW ON PR #{pr} — NOT YET SUBMITTED ({len(queued)} queued)")
    print("=" * 60)
    print(f"[review_id={review['databaseId']}] {review['url']}")
    print("Visible only to you. Submit or discard it from the PR's Files changed tab,")
    print("or manage it with gh-pr-pending-review.sh.")
    print("\n--- summary body ---")
    for ln in textwrap.wrap(review["body"], width=100) or ["(empty)"]:
        print(f"  {ln}")
    for i, c in enumerate(queued, 1):
        line = c["line"] or c["originalLine"] or "?"
        target = f"{c['path']}:{line}"
        if c["replyTo"]:
            target += f" (reply to comment {c['replyTo']['databaseId']})"
        print(f"\n[queued {i}] {target}")
        for ln in textwrap.wrap(c["body"], width=100):
            print(f"  {ln}")
    print()

# Review summaries (CHANGES_REQUESTED / APPROVED / COMMENT bodies)
reviews = gh_api(f"repos/{{owner}}/{{repo}}/pulls/{pr}/reviews")
# Exclude PENDING: the viewer's own unsubmitted review comes back from this REST
# endpoint too, and it is already rendered in full above.
non_empty_reviews = [r for r in reviews if r.get("body", "").strip() and r.get("state") != "PENDING"]
if non_empty_reviews:
    print("=" * 60)
    print(f"REVIEW SUMMARIES ON PR #{pr} ({len(non_empty_reviews)} with body)")
    print("=" * 60)
    for r in non_empty_reviews:
        user = r["user"]["login"]
        state = r["state"]
        ts = r.get("submitted_at") or "(not submitted)"
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
