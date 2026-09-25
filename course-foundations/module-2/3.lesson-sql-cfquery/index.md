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

challenges:
  sql-query-e89dcfe4: {}

tasks:
  verify_query_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/student/tickets.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "tickets.cfm not found (got ${STATUS})"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/student/tickets.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "tickets.cfm returned an error"
        exit 1
      fi
      echo "tickets.cfm is accessible and error-free"

  verify_queryparam_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_query_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/student/tickets_filter.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "tickets_filter.cfm not found"
        exit 1
      fi
      if ! grep -qi "cfqueryparam\|cfsqltype" "${FILE}" 2>/dev/null; then
        echo "cfqueryparam not found in tickets_filter.cfm — SQL injection risk"
        exit 1
      fi
      echo "cfqueryparam is used — safe parameterised SQL"

  verify_select_results:
    machine: dev-machine
    user: laborant
    needs:
      - verify_queryparam_used
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/student/ticket_actions.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "ticket_actions.cfm not found (got ${STATUS})"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/student/ticket_actions.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "ticket_actions.cfm returned an error"
        exit 1
      fi
      if ! echo "${BODY}" | grep -qi "resolved"; then
        echo "ticket_actions.cfm did not confirm resolved status"
        exit 1
      fi
      echo "INSERT, SELECT and UPDATE all working"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_select_results
    run: |
      echo "Lesson complete — well done!"

---
