---
kind: lesson

title: Chart Generation and Management
description: |
  Generate and customize charts in ColdFusion using cfchart.
  Visualize dynamic data from the database and integrate
  charts seamlessly into your application pages.

name: chart-generation-management
slug: chart-generation-management

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfchart
- data-visualization

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
      echo "chart_demo.cfm is accessible"

  verify_cfchart_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_chart_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm"
      if ! grep -qi "cfchart" "${FILE}" 2>/dev/null; then
        echo "cfchart tag not found in chart_demo.cfm"
        exit 1
      fi
      echo "cfchart is used in chart_demo.cfm"

  verify_chart_data:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfchart_used
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm"
      if ! grep -qi "cfquery\|queryExecute" "${FILE}" 2>/dev/null; then
        echo "chart_demo.cfm does not pull data from a query"
        exit 1
      fi
      echo "Chart is powered by dynamic query data"
---
