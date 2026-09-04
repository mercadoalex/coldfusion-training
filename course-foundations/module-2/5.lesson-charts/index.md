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

## Basic bar chart — tickets by priority

```cfml
<cfquery name="byPriority" datasource="training_db">
  SELECT priority, COUNT(*) AS total
  FROM   hd_tickets
  WHERE  status = 'open'
  GROUP  BY priority
  ORDER  BY total DESC
</cfquery>

<cfchart format="png" chartwidth="600" chartheight="400"
         title="Open Tickets by Priority" show3d="false">
  <cfchartseries type="bar" query="byPriority"
                 itemcolumn="priority" valuecolumn="total"
                 seriescolor="##4A90D9">
  </cfchartseries>
</cfchart>
```

## Pie chart — tickets by status

```cfml
<cfquery name="byStatus" datasource="training_db">
  SELECT status, COUNT(*) AS total FROM hd_tickets GROUP BY status
</cfquery>

<cfchart format="png" chartwidth="500" chartheight="400" title="Tickets by Status">
  <cfchartseries type="pie" query="byStatus"
                 itemcolumn="status" valuecolumn="total">
  </cfchartseries>
</cfchart>
```

## Chart to file (save as image)

```cfml
<cfchart format="png" name="myChart">
  <cfchartseries type="line" query="byPriority"
                 itemcolumn="priority" valuecolumn="total">
  </cfchartseries>
</cfchart>

<cffile action="write"
        file="#expandPath('/charts/tickets.png')#"
        output="#myChart#">
```

## Chart types available

| Type | Use case |
|---|---|
| `bar` | Compare values across categories |
| `line` | Show trends over time |
| `pie` | Show proportions |
| `area` | Cumulative trends |
| `scatter` | Correlation between variables |
