#!/usr/bin/env bash

set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/matrix.json" <<'JSON'
[
  {"repository":"example/healthy","workflow":"ci.yml"},
  {"repository":"example/missing","workflow":"ci.yml"}
]
JSON

cat > "$tmp/healthy.json" <<'JSON'
[
  {"repository":"example/healthy","workflow":"ci.yml","total_count":1,"conclusion":"success","updated_at":"2026-09-24T00:00:00Z"},
  {"repository":"example/missing","workflow":"ci.yml","total_count":1,"conclusion":"success","updated_at":"2026-09-24T00:00:00Z"}
]
JSON

if ! ORG_CI_HEALTH_FIXTURE="$tmp/healthy.json" "$root/scripts/check-org-ci-health.sh" "$tmp/matrix.json" >/dev/null; then
  echo 'healthy fixture unexpectedly failed' >&2
  exit 1
fi

cat > "$tmp/missing.json" <<'JSON'
[
  {"repository":"example/healthy","workflow":"ci.yml","total_count":1,"conclusion":"success","updated_at":"2026-09-24T00:00:00Z"}
]
JSON

if ORG_CI_HEALTH_FIXTURE="$tmp/missing.json" "$root/scripts/check-org-ci-health.sh" "$tmp/matrix.json" >/dev/null; then
  echo 'missing workflow fixture unexpectedly passed' >&2
  exit 1
fi

echo 'organization CI health fixtures passed'
