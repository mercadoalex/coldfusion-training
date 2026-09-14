---
kind: challenge

title: Datasource Verify

description: |
  Write a CFML script that queries the training_db datasource and returns
  a JSON response with a "db" key set to "ok" if the connection succeeds,
  or "error" with a message if it fails.

categories:
- programming

tagz:
- coldfusion
- datasource
- h2

difficulty: easy

createdAt: 2026-09-03
updatedAt: 2026-09-03

playground:
  name: cf-alex-edcdf975

tasks:
  verify_db_check:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s http://localhost:8500/db-check.cfm)
      if ! echo "${BODY}" | grep -q '"db".*"ok"'; then
        echo "db-check.cfm did not return {\"db\":\"ok\"} — got: ${BODY}"
        exit 1
      fi
      echo "Datasource connection verified"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/db-check.cfm` that:

- Runs `SELECT 1` against `training_db`
- Returns `{ "db": "ok" }` on success
- Returns `{ "db": "error", "message": "..." }` on failure

```bash
curl -s http://localhost:8500/db-check.cfm
```

Expected output: `{"db":"ok"}`

::simple-task
---
:tasks: tasks
:name: verify_db_check
---
#active
Waiting for `db-check.cfm` to return `{"db":"ok"}`...

#completed
Datasource connection verified — `training_db` is reachable! ✓
::
