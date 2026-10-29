#!/usr/bin/env bash
# Fetch a GitHub Actions job's logs within a workflow run, by (partial) job
# name -- resolves the job ID and fetches its logs in one step.
# Usage: gh-run-job-logs.sh <RUN_ID> <JOB_NAME_SUBSTRING> [owner/repo]
#   owner/repo defaults to the gh CLI's detected current repo.
#   If more than one job matches, logs for the FIRST match are printed and a
#   warning listing all matches goes to stderr.
#
# Example:
#   gh-run-job-logs.sh 28974159467 generate
#   gh-run-job-logs.sh 28974159467 deploy-cloudflare | grep -n "Current Version ID"

set -euo pipefail

RUN_ID="${1:?Usage: $0 <RUN_ID> <JOB_NAME_SUBSTRING> [owner/repo]}"
JOB_NAME="${2:?Expected a job name substring}"
REPO="${3:-}"

if [[ -n "$REPO" ]]; then
  API="repos/$REPO"
else
  API="repos/{owner}/{repo}"
fi

MATCHES=$(gh api "$API/actions/runs/$RUN_ID/jobs" --jq ".jobs[] | select(.name | contains(\"$JOB_NAME\")) | \"\(.id)\t\(.name)\"")

if [[ -z "$MATCHES" ]]; then
  echo "Error: no job matching '$JOB_NAME' found in run $RUN_ID" >&2
  exit 1
fi

if [[ $(echo "$MATCHES" | wc -l) -gt 1 ]]; then
  echo "Warning: multiple jobs matched '$JOB_NAME', using the first:" >&2
  echo "$MATCHES" | sed 's/^/  /' >&2
fi

JOB_ID=$(echo "$MATCHES" | head -1 | cut -f1)
gh api "$API/actions/jobs/$JOB_ID/logs"
