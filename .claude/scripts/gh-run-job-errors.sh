#!/usr/bin/env bash
# Fetch a job's logs (by name substring within a run, via gh-run-job-logs.sh)
# and show lines matching common failure patterns with context, for a quick
# "what went wrong" check without paging through the entire log.
# Usage: gh-run-job-errors.sh <RUN_ID> <JOB_NAME_SUBSTRING> [PATTERN] [owner/repo]
#   PATTERN is a grep -E pattern, defaulting to common failure markers.
#
# Example:
#   gh-run-job-errors.sh 28974159467 generate
#   gh-run-job-errors.sh 28974159467 generate "digest failed"

set -euo pipefail

RUN_ID="${1:?Usage: $0 <RUN_ID> <JOB_NAME_SUBSTRING> [PATTERN] [owner/repo]}"
JOB_NAME="${2:?Expected a job name substring}"
PATTERN="${3:-ERROR|Traceback|##\[error\]|[Ff]ailed|FAILED|Exception}"
REPO="${4:-}"

SELF_DIR=$(dirname "$0")
"$SELF_DIR/gh-run-job-logs.sh" "$RUN_ID" "$JOB_NAME" "$REPO" | grep -n -E "$PATTERN" -A5
