#!/usr/bin/env bash
# Dispatch a workflow_dispatch-triggered workflow against a ref, then find the
# resulting run and watch it to completion (blocks -- run this in the
# background if you don't want to wait inline).
# Usage: gh-workflow-dispatch-and-watch.sh <WORKFLOW_FILE> <REF> [-- <extra gh workflow run flags>]
#
# Example:
#   gh-workflow-dispatch-and-watch.sh data-update.yml ryan/ai-data-centers-updates -- \
#     -f deployment=cloudflare -f s3Dir=ryan/ai-data-centers-updates

set -euo pipefail

WORKFLOW="${1:?Usage: $0 <WORKFLOW_FILE> <REF> [-- <extra flags>]}"
REF="${2:?Expected a ref/branch}"
shift 2
if [[ "${1:-}" == "--" ]]; then shift; fi

gh workflow run "$WORKFLOW" --ref "$REF" "$@"

# Give GitHub a moment to register the new run before listing it.
sleep 5

RUN_ID=$(gh run list --workflow="$WORKFLOW" --branch="$REF" --limit 1 --json databaseId --jq '.[0].databaseId')
echo "Watching run $RUN_ID (https://github.com/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/actions/runs/$RUN_ID)..." >&2
gh run watch "$RUN_ID" --exit-status
