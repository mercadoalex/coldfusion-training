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
