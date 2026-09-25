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

challenges:
  charts-0e333dfe: {}

tasks:
  verify_bar_chart:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/student/chart_demo.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "chart_demo.cfm not found"
        exit 1
      fi
      if ! grep -qi "cfchart" "${FILE}" 2>/dev/null; then
        echo "cfchart tag not found in chart_demo.cfm"
        exit 1
      fi
      if ! grep -qi "cfquery\|queryExecute" "${FILE}" 2>/dev/null; then
        echo "No query found in chart_demo.cfm — chart must use live data"
        exit 1
      fi
      echo "chart_demo.cfm exists with cfchart powered by a query"

  verify_pie_chart:
    machine: dev-machine
    user: laborant
    needs:
      - verify_bar_chart
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/student/chart_demo.cfm"
      if ! grep -qi "type.*pie\|pie.*type" "${FILE}" 2>/dev/null; then
        echo "No pie chart series found in chart_demo.cfm"
        exit 1
      fi
      echo "Pie chart series is present"

  verify_chart_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_pie_chart
    run: |
      BODY=$(curl -s http://localhost:8500/student/chart_demo.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "chart_demo.cfm is throwing an error"
        exit 1
      fi
      COUNT=$(echo "${BODY}" | grep -c "_cf_chart" || true)
      if [ "${COUNT}" -lt 2 ]; then
        echo "Expected 2 chart img tags, found ${COUNT} — not all charts rendered"
        exit 1
      fi
      echo "Both charts rendered successfully — ${COUNT} cfchart image tags confirmed"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_chart_page
    run: |
      echo "Lesson complete — well done!"

---
