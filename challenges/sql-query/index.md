---
kind: challenge

title: Safe SQL Queries

description: |
  Create tickets.cfm that queries hd_tickets, displays results, and uses
  cfqueryparam (or queryExecute named bindings) for every parameterised value.
  The page must return HTTP 200 and show ticket data.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- sql
- cfqueryparam

playground:
  name: cf-alex-edcdf975

tasks:
  verify_tickets_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/tickets.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "tickets.cfm returned ${STATUS}"
        exit 1
      fi
      echo "tickets.cfm accessible"

  verify_shows_data:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tickets_page
    run: |
      BODY=$(curl -s http://localhost:8500/tickets.cfm)
      if ! echo "${BODY}" | grep -qi "ticket\|title\|id"; then
        echo "tickets.cfm does not display ticket data"
        exit 1
      fi
      echo "Ticket data displayed"

  verify_queryparam:
    machine: dev-machine
    user: laborant
    needs:
      - verify_shows_data
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/tickets.cfm"
      if ! grep -qi "cfqueryparam\|queryParam" "${FILE}" 2>/dev/null; then
        echo "cfqueryparam not used — SQL injection risk"
        exit 1
      fi
      echo "cfqueryparam is used"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/tickets.cfm` that:

1. Queries `hd_tickets` (JOIN `hd_users` for the submitter name)
2. Displays at least the ticket ID, title, status, and priority
3. Uses `cfqueryparam` or named bindings in `queryExecute` for any parameter

```bash
curl -s http://localhost:8500/tickets.cfm | grep -i "ticket\|title"
```
