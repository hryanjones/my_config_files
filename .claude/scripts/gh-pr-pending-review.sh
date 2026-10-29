#!/usr/bin/env bash
# Queue review feedback as PENDING comments on a PR, for a human to review,
# edit, delete and submit from the GitHub UI.
#
# A pending review is visible only to its author, so nothing is published and
# nobody is notified until the author clicks "Finish your review" / "Submit
# review" on the PR. That makes this the safe default for drafted feedback:
# the draft lives on the PR itself, anchored to the right lines, instead of in
# a local markdown file.
#
# Usage:
#   gh-pr-pending-review.sh comment <PR> <FILE> <LINE> (--body-file <path>|<body>) [owner/repo]
#   gh-pr-pending-review.sh reply   <PR> <THREAD_COMMENT_ID> (--body-file <path>|<body>) [owner/repo]
#   gh-pr-pending-review.sh summary <PR> (--body-file <path>|<body>) [owner/repo]
#   gh-pr-pending-review.sh append  <PR> (--body-file <path>|<body>) [owner/repo]
#   gh-pr-pending-review.sh list    <PR> [owner/repo]
#   gh-pr-pending-review.sh discard <PR> [owner/repo]
#
#   comment  Queue an inline comment on FILE:LINE (RIGHT side of the diff).
#   reply    Queue a reply into an existing review thread. THREAD_COMMENT_ID is
#            the numeric id of any comment in that thread, as printed by
#            gh-pr-comments.sh.
#   summary  Replace the review's overall summary body.
#   append   Append to the review's overall summary body.
#   list     Show the current pending review (REST list endpoints hide pending
#            comments, so this is the only way to read them back).
#   discard  Delete the whole pending review and everything queued in it.
#
# The first comment/reply/summary/append call creates the pending review if
# there isn't one; the rest add to it. GitHub allows only one pending review
# per user per PR, so everything queued for a PR lands in the same review.
#
# Non-diff lines: GitHub cannot anchor a pending comment to a line outside the
# diff, and the API fails silently on that. This script detects it and appends
# the finding to the summary body under a `file:line` heading instead, so the
# text is never lost and still stays pending. Use gh-pr-inline-comment.sh only
# when a non-diff finding must be anchored inline and publishing it right away
# is acceptable.
#
# Prefer --body-file for anything multi-line or containing code blocks -- it
# avoids shell quoting mistakes entirely (see the heredoc note in CLAUDE.md).
#
# Examples:
#   gh-pr-pending-review.sh comment 649 public/_redirects 3 --body-file finding.md
#   gh-pr-pending-review.sh reply 1277 3798751610 --body-file reply.md
#   gh-pr-pending-review.sh list 649
#   gh-pr-pending-review.sh discard 649

set -euo pipefail

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'
  exit "${1:-1}"
}

SUBCOMMAND="${1:-}"
[[ -z "$SUBCOMMAND" || "$SUBCOMMAND" == "-h" || "$SUBCOMMAND" == "--help" ]] && usage 0
shift

PR="${1:-}"
[[ -z "$PR" ]] && { echo "Error: missing <PR>" >&2; usage; }
shift

# Consume the body (inline or --body-file) plus the optional trailing
# owner/repo, setting BODY and REPO. Kept as one function so every subcommand
# accepts the two forms identically.
take_body_and_repo() {
  if [[ "${1:-}" == "--body-file" ]]; then
    local path="${2:?Expected a path after --body-file}"
    BODY=$(cat "$path")
    REPO="${3:-}"
  else
    BODY="${1:?Expected body text or --body-file <path>}"
    REPO="${2:-}"
  fi
}

FILE=""
LINE=""
THREAD_COMMENT_ID=""
BODY=""
REPO=""

case "$SUBCOMMAND" in
  comment)
    FILE="${1:?Usage: $0 comment <PR> <FILE> <LINE> (--body-file <path>|<body>) [owner/repo]}"
    LINE="${2:?Expected <LINE> after <FILE>}"
    shift 2
    take_body_and_repo "$@"
    ;;
  reply)
    THREAD_COMMENT_ID="${1:?Usage: $0 reply <PR> <THREAD_COMMENT_ID> (--body-file <path>|<body>) [owner/repo]}"
    shift
    take_body_and_repo "$@"
    ;;
  summary|append)
    take_body_and_repo "$@"
    ;;
  list|discard)
    REPO="${1:-}"
    ;;
  *)
    echo "Error: unknown subcommand '$SUBCOMMAND'" >&2
    usage
    ;;
esac

python3 - "$SUBCOMMAND" "$PR" "$REPO" "$FILE" "$LINE" "$THREAD_COMMENT_ID" "$BODY" <<'PYEOF'
import json
import subprocess
import sys

subcommand, pr, repo_arg, path_arg, line_arg, thread_comment_id, body = sys.argv[1:8]

# A pending review must be created with a non-empty body: GitHub rejects any
# later edit of a review whose body is empty ("Could not edit a review with a
# missing body"), which would make the non-diff fallback below impossible.
PLACEHOLDER_BODY = "Ryan's Claude 🤖: see inline comments."


def run(cmd, stdin=None):
    return subprocess.run(cmd, input=stdin, capture_output=True, text=True)


def fail(message):
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


def resolve_repo():
    if repo_arg:
        owner, name = repo_arg.split("/", 1)
        return owner, name
    result = run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"])
    if result.returncode != 0:
        fail(f"could not determine the current repo: {result.stderr.strip()}")
    owner, name = result.stdout.strip().split("/", 1)
    return owner, name


OWNER, NAME = resolve_repo()


def graphql(query, variables):
    # Pass query and variables as one JSON document on stdin rather than as
    # -f/-F flags: -f would coerce every value to a string (breaking Int line
    # numbers) and treats a leading "@" as a filename.
    payload = json.dumps({"query": query, "variables": variables})
    result = run(["gh", "api", "graphql", "--input", "-"], stdin=payload)
    if result.returncode != 0 and not result.stdout.strip():
        fail(f"GraphQL request failed: {result.stderr.strip()}")
    response = json.loads(result.stdout)
    if response.get("errors"):
        messages = "; ".join(e.get("message", str(e)) for e in response["errors"])
        fail(f"GraphQL: {messages}")
    return response["data"]


def rest(path, method="GET", fields=None):
    cmd = ["gh", "api", f"repos/{OWNER}/{NAME}/{path}", "--method", method]
    if fields is not None:
        cmd += ["--input", "-"]
        result = run(cmd, stdin=json.dumps(fields))
    else:
        result = run(cmd)
    if result.returncode != 0:
        fail(f"{method} {path} failed: {result.stderr.strip()}")
    return json.loads(result.stdout) if result.stdout.strip() else {}


def find_pending_review():
    data = graphql(
        """
        query($owner:String!, $name:String!, $pr:Int!) {
          repository(owner:$owner, name:$name) {
            pullRequest(number:$pr) {
              reviews(first:5, states:[PENDING]) {
                nodes { id databaseId body url }
              }
            }
          }
        }
        """,
        {"owner": OWNER, "name": NAME, "pr": int(pr)},
    )
    nodes = data["repository"]["pullRequest"]["reviews"]["nodes"]
    return nodes[0] if nodes else None


def create_pending_review():
    head_sha = rest(f"pulls/{pr}")["head"]["sha"]
    # Omitting "event" is what makes the review PENDING rather than submitted.
    created = rest(
        f"pulls/{pr}/reviews",
        method="POST",
        fields={"commit_id": head_sha, "body": PLACEHOLDER_BODY},
    )
    print(f"Started pending review id={created['id']} on PR #{pr}", file=sys.stderr)
    return {
        "id": created["node_id"],
        "databaseId": created["id"],
        "body": PLACEHOLDER_BODY,
        "url": created["html_url"],
    }


def ensure_pending_review():
    return find_pending_review() or create_pending_review()


def require_pending_review():
    review = find_pending_review()
    if review is None:
        fail(f"no pending review on PR #{pr}")
    return review


def set_body(review, new_body):
    graphql(
        """
        mutation($rid:ID!, $body:String!) {
          updatePullRequestReview(input:{pullRequestReviewId:$rid, body:$body}) {
            pullRequestReview { id }
          }
        }
        """,
        {"rid": review["id"], "body": new_body},
    )


def append_body(review, addition):
    current = review["body"]
    if current == PLACEHOLDER_BODY:
        current = ""
    combined = f"{current}\n\n{addition}".strip() if current else addition
    set_body(review, combined)
    return combined


def add_inline_comment(review, file_path, line, text):
    data = graphql(
        """
        mutation($rid:ID!, $path:String!, $line:Int!, $body:String!) {
          addPullRequestReviewThread(input:{
            pullRequestReviewId:$rid, path:$path, line:$line, side:RIGHT, body:$body
          }) { thread { id } }
        }
        """,
        {"rid": review["id"], "path": file_path, "line": int(line), "body": text},
    )
    # GitHub returns a null thread with no error when the line is outside the
    # diff, so a null here is the only signal that the comment did not land.
    thread = data["addPullRequestReviewThread"]["thread"]
    return thread["id"] if thread else None


def resolve_thread_node(comment_id):
    data = graphql(
        """
        query($owner:String!, $name:String!, $pr:Int!) {
          repository(owner:$owner, name:$name) {
            pullRequest(number:$pr) {
              reviewThreads(first:100) {
                nodes { id comments(first:100) { nodes { databaseId } } }
              }
            }
          }
        }
        """,
        {"owner": OWNER, "name": NAME, "pr": int(pr)},
    )
    wanted = int(comment_id)
    for thread in data["repository"]["pullRequest"]["reviewThreads"]["nodes"]:
        if any(c["databaseId"] == wanted for c in thread["comments"]["nodes"]):
            return thread["id"]
    fail(f"comment id={comment_id} is not in any review thread on PR #{pr}")


def add_thread_reply(review, thread_node, text):
    data = graphql(
        """
        mutation($tid:ID!, $rid:ID!, $body:String!) {
          addPullRequestReviewThreadReply(input:{
            pullRequestReviewThreadId:$tid, pullRequestReviewId:$rid, body:$body
          }) { comment { id } }
        }
        """,
        {"tid": thread_node, "rid": review["id"], "body": text},
    )
    return data["addPullRequestReviewThreadReply"]["comment"]["id"]


def do_comment():
    review = ensure_pending_review()
    thread_id = add_inline_comment(review, path_arg, line_arg, body)
    if thread_id:
        print(f"Queued pending comment on {path_arg}:{line_arg} — {review['url']}")
        return
    heading = f"**`{path_arg}:{line_arg}`** (not in the diff, so not anchorable inline)"
    append_body(review, f"{heading}\n\n{body}")
    print(
        f"Note: {path_arg}:{line_arg} is not in the diff — appended to the review "
        f"summary instead of anchoring it inline.",
        file=sys.stderr,
    )
    print(f"Queued in review summary — {review['url']}")


def do_reply():
    thread_node = resolve_thread_node(thread_comment_id)
    review = ensure_pending_review()
    add_thread_reply(review, thread_node, body)
    print(f"Queued pending reply to thread {thread_comment_id} — {review['url']}")


def do_summary():
    review = ensure_pending_review()
    set_body(review, body)
    print(f"Set review summary — {review['url']}")


def do_append():
    review = ensure_pending_review()
    append_body(review, body)
    print(f"Appended to review summary — {review['url']}")


def do_list():
    review = find_pending_review()
    if review is None:
        print(f"No pending review on PR #{pr}.")
        return
    data = graphql(
        """
        query($rid:ID!) {
          node(id:$rid) {
            ... on PullRequestReview {
              url
              comments(first:100) {
                nodes { path line originalLine body replyTo { databaseId } }
              }
            }
          }
        }
        """,
        {"rid": review["id"]},
    )
    node = data["node"]
    comments = node["comments"]["nodes"]
    print(f"PENDING REVIEW on PR #{pr} — {node['url']}")
    print(f"  (visible only to you until you submit it on the PR)\n")
    print("--- summary body ---")
    print(review["body"] or "(empty)")
    print(f"\n--- {len(comments)} queued comment(s) ---")
    for i, c in enumerate(comments, 1):
        line = c["line"] or c["originalLine"] or "?"
        target = f"{c['path']}:{line}"
        if c["replyTo"]:
            target += f" (reply to {c['replyTo']['databaseId']})"
        print(f"\n[{i}] {target}")
        for ln in c["body"].splitlines():
            print(f"  {ln}")


def do_discard():
    review = require_pending_review()
    rest(f"pulls/{pr}/reviews/{review['databaseId']}", method="DELETE")
    print(f"Discarded pending review id={review['databaseId']} on PR #{pr}")


{
    "comment": do_comment,
    "reply": do_reply,
    "summary": do_summary,
    "append": do_append,
    "list": do_list,
    "discard": do_discard,
}[subcommand]()
PYEOF
