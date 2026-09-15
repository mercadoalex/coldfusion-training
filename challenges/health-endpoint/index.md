---
kind: challenge

title: Production Health Endpoint

description: |
  Create a health check endpoint that validates the DB connection and
  returns a JSON response with status "ok" or "degraded". Must respond
  within 2 seconds and return the correct HTTP status code.

categories:
- programming

tagz:
- coldfusion
- production
- health-check

difficulty: medium

createdAt: 2026-09-03
updatedAt: 2026-09-03

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

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_health_http_code
    run: |
      echo "Challenge complete — well done!"
---

## Production Health Endpoint

Create `/opt/coldfusion2025/cfusion/wwwroot/health.cfm` that:

- Runs `SELECT 1` against `training_db`
- Returns `{ "status": "ok" }` with **HTTP 200** when the DB is reachable
- Returns `{ "status": "degraded" }` with **HTTP 503** when the DB fails
- Responds within 2 seconds

```bash
curl -s -w "\nHTTP: %{http_code}\n" http://localhost:8500/health.cfm
# expected: {"status":"ok",...}  HTTP: 200
```

::simple-task
---
:tasks: tasks
:name: verify_health_endpoint
---
#active
Waiting for `health.cfm` to return valid JSON...

#completed
`health.cfm` returns valid JSON. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_health_status
---
#active
Checking that the JSON contains `"status": "ok"` or `"status": "degraded"`...

#completed
Health status field is present and valid. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_health_http_code
---
#active
Checking that `health.cfm` returns HTTP 200 or HTTP 503...

#completed
Correct HTTP status code returned. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
Almost there — waiting for all checks to pass...

#completed
🎉 Congratulations! You have completed all lessons of the ColdFusion 2025 Foundations course. You built real ColdFusion applications from scratch — datasources, ORM, caching, REST APIs, security, performance, CI/CD, and now a production-ready health endpoint. Well done!
::
