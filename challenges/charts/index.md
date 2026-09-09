---
kind: challenge

title: Dynamic Chart from Live Data

description: |
  Create chart_demo.cfm that queries hd_tickets and renders a cfchart.
  The page must return HTTP 200, use cfchart, and pull data from a cfquery
  or queryExecute call.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfchart

playground:
  name: cf-alex-edcdf975

tasks:
  verify_chart_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/chart_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "chart_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "chart_demo.cfm accessible"

  verify_cfchart_tag:
    machine: dev-machine
    user: laborant
    needs:
      - verify_chart_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm"
      if ! grep -qi "cfchart" "${FILE}" 2>/dev/null; then
        echo "cfchart tag not found"
        exit 1
      fi
      echo "cfchart used"

  verify_query_data:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfchart_tag
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm"
      if ! grep -qi "cfquery\|queryExecute" "${FILE}" 2>/dev/null; then
        echo "No query found — chart must use live data"
        exit 1
      fi
      echo "Chart powered by query data"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm` that:

1. Runs a `cfquery` or `queryExecute` against `hd_tickets`
2. Renders the result as a `<cfchart>` (bar, pie, or line — your choice)

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/chart_demo.cfm
```

Open the **ColdFusion** browser tab to see the rendered chart.
