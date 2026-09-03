---
kind: challenge

title: Production Health Endpoint
description: |
  Create a health check endpoint that validates the DB connection and
  returns a JSON response with status "ok" or "degraded". Must respond
  within 2 seconds and return the correct HTTP status code.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- production
- health-check

playground:
  name: cf-alex-edcdf975
---

## Task

Create `/opt/coldfusion2025/cfusion/wwwroot/health.cfm`:
- Returns HTTP 200 when DB is OK: `{ "status": "ok", "db": "ok" }`
- Returns HTTP 503 when DB fails: `{ "status": "degraded", "db": "error" }`
- Responds within 2 seconds

## Verify

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/health.cfm
# expected: 200
curl -s http://localhost:8500/health.cfm | grep '"status":"ok"'
```