#!/usr/bin/env bash

set -euo pipefail

matrix_file=${1:-.github/org-ci-matrix.json}
fixture_file=${ORG_CI_HEALTH_FIXTURE:-}
api_url=${GITHUB_API_URL:-https://api.github.com}
summary_file=${GITHUB_STEP_SUMMARY:-}

failures=0
checked=0

write_line() {
  printf '%s\n' "$1"
  if [[ -n "$summary_file" ]]; then
    printf '%s\n' "$1" >> "$summary_file"
  fi
}

write_line '| Repository | Workflow | Latest conclusion | Updated |'
write_line '| --- | --- | --- | --- |'

while IFS=$'\t' read -r repository workflow; do
  checked=$((checked + 1))

  if [[ -n "$fixture_file" ]]; then
    response=$(jq -c --arg repository "$repository" --arg workflow "$workflow" \
      '[.[] | select(.repository == $repository and .workflow == $workflow)] | first // {total_count: 0}' \
      "$fixture_file")
  else
    response=$(curl --fail-with-body --silent --show-error \
      --retry 3 --retry-delay 2 \
      -H 'Accept: application/vnd.github+json' \
      -H 'User-Agent: shippercli-org-ci-health' \
      -H 'X-GitHub-Api-Version: 2022-11-28' \
      -H "Authorization: Bearer ${GITHUB_TOKEN:?GITHUB_TOKEN is required}" \
      "${api_url}/repos/${repository}/actions/workflows/${workflow}/runs?per_page=1") || {
        write_line "| \`$repository\` | \`$workflow\` | API error | unavailable |"
        failures=$((failures + 1))
        continue
      }
  fi

  total=$(jq -r '.total_count // 0' <<< "$response")
  if [[ "$total" == '0' ]]; then
    write_line "| \`$repository\` | \`$workflow\` | missing | unavailable |"
    failures=$((failures + 1))
    continue
  fi

  conclusion=$(jq -r '.workflow_runs[0].conclusion // .conclusion // "in_progress"' <<< "$response")
  updated=$(jq -r '.workflow_runs[0].updated_at // .updated_at // "unknown"' <<< "$response")
  write_line "| \`$repository\` | \`$workflow\` | $conclusion | $updated |"
  [[ "$conclusion" == 'success' ]] || failures=$((failures + 1))
done < <(jq -r '.[] | [.repository, .workflow] | @tsv' "$matrix_file")

printf 'Checked %d repositories; failures: %d.\n' "$checked" "$failures"
(( failures == 0 ))
