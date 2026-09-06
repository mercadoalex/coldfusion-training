---
kind: challenge

title: Datasource Verify
description: |
  Write a CFML script that queries the training_db datasource and returns
  a JSON response with a "db" key set to "ok" if the connection succeeds,
  or "error" with a message if it fails.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- datasource
- h2

playground:
  name: cf-alex-edcdf975
---

## Task

Create `/opt/coldfusion2025/cfusion/wwwroot/db-check.cfm` that:
- Runs `SELECT 1` against `training_db`
- Returns `{ "db": "ok" }` on success
- Returns `{ "db": "error", "message": "..." }` on failure

## Verify

```bash
curl -s http://localhost:8500/db-check.cfm | grep '"db":"ok"'
```