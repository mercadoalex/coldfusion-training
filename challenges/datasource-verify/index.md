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

- Queries `training_db` with `SELECT 1` (or any valid query)
- Returns `Content-Type: application/json`
- Returns `{"db":"ok"}` on success
- Returns `{"db":"error","message":"..."}` on failure, wrapping the error in a `try/catch`

Try it on your own first — then use the hints below if you need them.

---

::details-box
---
:summary: 👉 Hint — not sure where to start?
---
Revisit **Module 2 Lesson 1 — Datasource Configuration** and **Lesson 3 — cfquery**.

Key things you need:
- Set the `Content-Type` header with `cfheader` before any output: `<cfheader name="Content-Type" value="application/json">`
- Use `cfquery` or `queryExecute()` with `datasource="training_db"`
- Wrap the query in `<cftry>` / `<cfcatch>` so connection failures return the error JSON instead of a CF error page
- Use `serializeJSON({ db: "ok" })` or write the JSON string directly with `writeOutput()`
- The checker looks for `"db"` and `"ok"` in the response body — your JSON key must be exactly `db`
::

::details-box
---
:summary: 👉 Skeleton — need the structure?
---
Fill in the blanks:

```cfml
<cfheader name="______" value="______">
<cftry>
  <cfquery name="test" datasource="______">
    SELECT ______
  </cfquery>
  <cfoutput>{"db":"______"}</cfoutput>
  <cfcatch type="any">
    <cfoutput>{"db":"______","message":"#encodeForJSON(cfcatch.message)#"}</cfoutput>
  </cfcatch>
</cftry>
```
::

::remark-box
---
kind: info
---
No full solution is provided — use the hint and the skeleton. The productive struggle of figuring out the last piece is exactly what makes this stick.
::

---

### Verify your work

```bash
curl -s http://localhost:8500/db-check.cfm
# Expected: {"db":"ok"}
```

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
