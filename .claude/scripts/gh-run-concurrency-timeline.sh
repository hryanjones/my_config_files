#!/usr/bin/env bash
# Show a chronological timeline of runs for a single GitHub Actions workflow,
# including each run's job count and the PR/branch its head commit actually
# belongs to -- useful for diagnosing "run silently didn't do its job" cases
# caused by a `concurrency:` group swallowing/cancelling runs.
#
# Gotcha this exists for: for `workflow_run`-triggered workflows, the run's
# own `headBranch` (as reported by `gh run list` / the runs API) reflects the
# run's *execution context*, which GitHub pins to the repo's default branch
# for security reasons -- NOT the branch that actually triggered it. That
# makes a burst of runs look like they all belong to `main` when they're
# really scattered across several PR branches. This script resolves the real
# source by looking up the PR associated with each run's `headSha` instead
# (the sha IS accurate), and shows job count so a `cancelled` run with 0 jobs
# (evicted from the concurrency queue before it ever started) is easy to
# tell apart from one that actually ran and then failed or was cancelled
# mid-job.
#
# Usage: gh-run-concurrency-timeline.sh <WORKFLOW_FILE> [LIMIT=30] [owner/repo]
#   owner/repo defaults to the gh CLI's detected current repo.
#
# Example:
#   gh-run-concurrency-timeline.sh preview-message.yml 40
#   gh-run-concurrency-timeline.sh preview-message.yml 40 epoch-research/epoch-website-astro

set -euo pipefail

WORKFLOW="${1:?Usage: $0 <WORKFLOW_FILE> [LIMIT=30] [owner/repo]}"
LIMIT="${2:-30}"
REPO="${3:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
API="repos/$REPO"

RUNS=$(gh run list --workflow="$WORKFLOW" --limit "$LIMIT" \
  --json databaseId,event,status,conclusion,createdAt,headBranch,headSha,displayTitle \
  --jq 'sort_by(.createdAt)')

declare -A PR_CACHE

printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' CREATED EVENT STATE JOBS SHA "PR/BRANCH" TITLE
echo "$RUNS" | jq -c '.[]' | while IFS= read -r run; do
  ID=$(jq -r '.databaseId' <<<"$run")
  EVENT=$(jq -r '.event' <<<"$run")
  CREATED=$(jq -r '.createdAt' <<<"$run")
  SHA=$(jq -r '.headSha' <<<"$run")
  SHA_SHORT="${SHA:0:7}"
  TITLE=$(jq -r '.displayTitle' <<<"$run")
  CONCLUSION=$(jq -r '.conclusion' <<<"$run")
  STATUS=$(jq -r '.status' <<<"$run")
  STATE="${CONCLUSION:-$STATUS}"

  JOB_COUNT=$(gh api "$API/actions/runs/$ID/jobs" --jq '.jobs | length' 2>/dev/null || echo "?")

  if [[ -z "${PR_CACHE[$SHA]+x}" ]]; then
    PR_INFO=$(gh api "$API/commits/$SHA/pulls" --jq '.[0] | "#\(.number) (\(.head.ref))"' 2>/dev/null || true)
    PR_CACHE[$SHA]="${PR_INFO:-"(no open PR)"}"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$CREATED" "$EVENT" "$STATE" "$JOB_COUNT" "$SHA_SHORT" "${PR_CACHE[$SHA]}" "$TITLE"
done | column -t -s $'\t'
