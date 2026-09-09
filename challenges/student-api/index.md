---
kind: challenge

title: Ticket REST API
description: |
  Build a REST endpoint /api/tickets.cfm that returns a JSON object
  containing all open tickets from training_db. The endpoint must return
  HTTP 200, Content-Type application/json, and a non-empty tickets array.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- rest
- api
- sql

playground:
  name: cf-alex-edcdf975
---

## Task

Create `/opt/coldfusion2025/cfusion/wwwroot/api/tickets.cfm` that:
- Queries `hd_tickets` joined to `hd_users` from `training_db`
- Returns a JSON object `{ "total": N, "tickets": [...] }`
- Sets `Content-Type: application/json`
- Returns HTTP 200

## Hint

```cfml
<cfscript>
  cfheader(name="Content-Type", value="application/json");
  q = queryExecute(
    "SELECT t.id, t.title, t.status, t.priority, u.name AS submitter
     FROM   hd_tickets t
     JOIN   hd_users   u ON u.id = t.user_id
     ORDER  BY t.created_at DESC",
    {}, { datasource: "training_db" }
  );
  writeOutput(serializeJSON({ "total": q.recordCount, "tickets": queryToArray(q) }));
</cfscript>
```

## Verify

```bash
curl -s http://localhost:8500/api/tickets.cfm | python3 -m json.tool
# expect: {"total": 10, "tickets": [...]}
```
