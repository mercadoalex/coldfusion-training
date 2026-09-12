#!/usr/bin/env bash
# Push all 22 foundation challenges to iximiuz Labs platform
# Run from: /Users/alexmarket/Desktop/coldfusion_training

set -uo pipefail
LABCTL=/Users/alexmarket/.iximiuz/labctl/bin/labctl

# Format: "directory-name:platform-slug-with-hash"
CHALLENGES=(
  "hello-cfml:hello-cfml-9cc7ac40"
  "cfml-syntax:cfml-syntax-0b4b2335"
  "scope-inspector:scope-inspector-5e09720b"
  "application-lifecycle:application-lifecycle-84261e98"
  "oop-cfc:oop-cfc-88277abe"
  "html5-page:html5-page-5ef19f87"
  "multimedia:multimedia-c7c70611"
  "datasource-verify:datasource-verify-be971bb2"
  "sql-query:sql-query-9af1b639"
  "orm-entity:orm-entity-4c08a96a"
  "caching:caching-10837ff1"
  "charts:charts-0e333dfe"
  "commandbox-server:commandbox-server-9bac5899"
  "lucee:lucee-5db89516"
  "student-api:student-api-7309bb97"
  "testing:testing-8f70b2b0"
  "websockets:websockets-6e5e8d19"
  "soap-webservices:soap-webservices-8f4e8ae9"
  "security:security-c2586cd1"
  "performance:performance-9b4234b3"
  "cicd-pipeline:cicd-pipeline-6f98584e"
  "health-endpoint:health-endpoint-a895d35e"
)

echo "=== Pushing 22 challenges to iximiuz Labs platform ==="
echo ""

SUCCESS=0
FAIL=0

for ENTRY in "${CHALLENGES[@]}"; do
  DIR="${ENTRY%%:*}"
  SLUG="${ENTRY##*:}"
  echo "→ Pushing: $SLUG  (dir: challenges/$DIR)"
  if $LABCTL content push -f challenge "$SLUG" -d "challenges/$DIR" 2>&1; then
    echo "  ✓ OK"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "  ✗ FAILED"
    FAIL=$((FAIL + 1))
  fi
  echo ""
done

echo "=== Done: $SUCCESS succeeded, $FAIL failed ==="
