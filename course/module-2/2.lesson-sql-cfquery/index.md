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
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/students.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "students.cfm not found or returning error (got ${STATUS})"
        exit 1
      fi
      echo "students.cfm is accessible"

  verify_queryparam_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_query_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/students.cfm"
      if ! grep -qi "cfqueryparam\|queryParam" "${FILE}" 2>/dev/null; then
        echo "cfqueryparam not found in students.cfm — SQL injection risk"
        exit 1
      fi
      echo "cfqueryparam is used — safe SQL"

  verify_select_results:
    machine: dev-machine
    user: laborant
    needs:
      - verify_queryparam_used
    run: |
      BODY=$(curl -s http://localhost:8500/students.cfm)
      if ! echo "${BODY}" | grep -qi "student\|name\|id"; then
        echo "students.cfm does not display query results"
        exit 1
      fi
      echo "Query results are displayed correctly"
---

## SELECT

```cfml
<cfquery name="students" datasource="training_db">
  SELECT id, name, email
  FROM students
  ORDER BY name
</cfquery>

<cfoutput query="students">
  #id# — #name# — #email#<br>
</cfoutput>
```

## INSERT with cfqueryparam

```cfml
<cfquery datasource="training_db">
  INSERT INTO students (name, email)
  VALUES (
    <cfqueryparam value="#form.name#" cfsqltype="cf_sql_varchar">,
    <cfqueryparam value="#form.email#" cfsqltype="cf_sql_varchar">
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
