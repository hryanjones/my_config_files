#!/usr/bin/env bash
# Merge a PR's full activity into one chronological timeline: commits,
# comments (including bot comments like the Cloudflare preview-message bot),
# reviews, edits, force-pushes, deploys, closes/reopens, etc. Pulls all of it
# from the single issue-timeline API endpoint -- commits show up there too
# (event "committed"), no separate /pulls/{pr}/commits call needed.
#
# Useful for reconstructing "what happened and when" on a PR -- e.g. did an
# agent revisit the PR body after opening it, did a bot comment land before
# or after a given commit, how long elapsed between PR creation and a given
# event.
#
# Usage: gh-pr-activity-timeline.sh <PR_NUMBER> [owner/repo]
#   owner/repo defaults to the gh CLI's detected current repo.
#
# Example:
#   gh-pr-activity-timeline.sh 980

set -euo pipefail

PR="${1:?Usage: $0 <PR_NUMBER> [owner/repo]}"
REPO="${2:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
API="repos/$REPO"

gh api "$API/issues/$PR/timeline" --paginate --jq '
  [.[] | {
    time: (.created_at // .submitted_at // .author.date // .committer.date // ""),
    actor: (.actor.login // .user.login // .author.name // .review.user.login // "?"),
    event: .event,
    detail: (
      if .event == "committed" then ((.sha // "")[0:7] + " " + (.message // "" | split("\n")[0]))
      elif .event == "commented" then (.body // "" | split("\n")[0] | .[0:100])
      elif .event == "reviewed" then ((.state // "") + (if .body then ": " + (.body | split("\n")[0]) else "" end))
      elif .event == "renamed" then ("\"" + (.rename.from // "") + "\" -> \"" + (.rename.to // "") + "\"")
      elif .event == "edited" then ("changed: " + (.changes // {} | keys | join(",")))
      elif .event == "head_ref_force_pushed" then (("before " + ((.before_commit_sha // "") | .[0:7])) + " -> after " + ((.after_commit_sha // "") | .[0:7]))
      elif .event == "review_requested" then ("requested: " + (.requested_reviewer.login // .requested_team.name // ""))
      elif .event == "deployed" then ("environment: " + (.environment // "?"))
      else ""
      end
    )
  }]
  | sort_by(.time)
  | .[]
  | [.time, .actor, .event, .detail]
  | @tsv
' | (printf 'TIME\tACTOR\tEVENT\tDETAIL\n'; cat) | column -t -s $'\t'
