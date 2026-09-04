---
kind: lesson

title: SQL with cfquery & queryParam
description: |
  Write safe, efficient SQL in CFML using cfquery and queryParam.
  Learn SELECT, INSERT, UPDATE, DELETE and how to prevent SQL injection.

name: sql-cfquery-queryparam
slug: sql-cfquery-queryparam

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- sql
- cfquery
- queryparam

playground:
  name: cf-alex-edcdf975

tasks:
  verify_query_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/tickets.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "tickets.cfm not found or returning error (got ${STATUS})"
        exit 1
      fi
      echo "tickets.cfm is accessible"

  verify_queryparam_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_query_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/tickets.cfm"
      if ! grep -qi "cfqueryparam\|queryParam" "${FILE}" 2>/dev/null; then
        echo "cfqueryparam not found in tickets.cfm — SQL injection risk"
        exit 1
      fi
      echo "cfqueryparam is used — safe SQL"

  verify_select_results:
    machine: dev-machine
    user: laborant
    needs:
      - verify_queryparam_used
    run: |
      BODY=$(curl -s http://localhost:8500/tickets.cfm)
      if ! echo "${BODY}" | grep -qi "ticket\|title\|id"; then
        echo "tickets.cfm does not display query results"
        exit 1
      fi
      echo "Query results are displayed correctly"
---

## SELECT

```cfml
<cfquery name="tickets" datasource="training_db">
  SELECT t.id, t.title, t.status, t.priority, u.name AS submitter
  FROM   hd_tickets t
  JOIN   hd_users   u ON u.id = t.user_id
  ORDER  BY t.created_at DESC
</cfquery>

<cfoutput query="tickets">
  ##tickets.id## — #encodeForHTML(title)# [#status# / #priority#]<br>
</cfoutput>
```

## INSERT with cfqueryparam

```cfml
<cfquery datasource="training_db">
  INSERT INTO hd_tickets (title, description, status, priority, user_id, created_at)
  VALUES (
    <cfqueryparam value="#form.title#"       cfsqltype="cf_sql_varchar">,
    <cfqueryparam value="#form.description#" cfsqltype="cf_sql_varchar">,
    'open',
    <cfqueryparam value="#form.priority#"    cfsqltype="cf_sql_varchar">,
    <cfqueryparam value="#session.userId#"   cfsqltype="cf_sql_integer">,
    <cfqueryparam value="#now()#"            cfsqltype="cf_sql_timestamp">
  )
</cfquery>
```

## Why cfqueryparam?

Without it (dangerous):
```cfml
WHERE id = #url.id#
```

With it (safe):
```cfml
WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
```
