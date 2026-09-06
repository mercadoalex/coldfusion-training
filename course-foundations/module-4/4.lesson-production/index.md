---
kind: lesson

title: Production Readiness & Monitoring
description: |
  Prepare a ColdFusion application for production: health checks,
  log aggregation, alerting, blue/green deployments and backup strategies.

name: production-readiness-monitoring
slug: production-readiness-monitoring

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- observability

tagz:
- coldfusion
- monitoring
- production

playground:
  name: cf-alex-edcdf975

tasks:
  verify_health_endpoint:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s --max-time 2 http://localhost:8500/health.cfm)
      if ! echo "${BODY}" | python3 -m json.tool > /dev/null 2>&1; then
        echo "health.cfm does not return valid JSON"
        exit 1
      fi
      echo "health.cfm returns valid JSON"

  verify_health_status:
    machine: dev-machine
    user: laborant
    needs:
      - verify_health_endpoint
    run: |
      BODY=$(curl -s --max-time 2 http://localhost:8500/health.cfm)
      STATUS=$(echo "${BODY}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))")
      if [ "${STATUS}" != "ok" ] && [ "${STATUS}" != "degraded" ]; then
        echo "health.cfm status must be 'ok' or 'degraded', got '${STATUS}'"
        exit 1
      fi
      echo "Health status is '${STATUS}'"

  verify_health_http_code:
    machine: dev-machine
    user: laborant
    needs:
      - verify_health_status
    run: |
      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:8500/health.cfm)
      if [ "${HTTP_CODE}" != "200" ] && [ "${HTTP_CODE}" != "503" ]; then
        echo "health.cfm must return 200 or 503, got ${HTTP_CODE}"
        exit 1
      fi
      echo "Health endpoint returns correct HTTP status ${HTTP_CODE}"
---
