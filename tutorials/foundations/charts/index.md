---
kind: tutorial

title: Generating Charts with cfchart

description: |
  Query ticket data from training_db and render bar and pie charts
  using the cfchart and cfchartseries tags.

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
---

## Steps

### 1. Create chart_demo.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm`:

```cfml
<!DOCTYPE html>
<html>
<body>
  <h1>Ticket Dashboard</h1>

  <!--- Query 1: tickets by priority --->
  <cfquery name="byPriority" datasource="training_db">
    SELECT priority, COUNT(*) AS total
    FROM   hd_tickets
    WHERE  status = 'open'
    GROUP  BY priority
    ORDER  BY total DESC
  </cfquery>

  <h2>Open Tickets by Priority</h2>
  <cfchart format="png" chartwidth="600" chartheight="350"
           title="Open Tickets by Priority" show3d="false">
    <cfchartseries type="bar" query="byPriority"
                   itemcolumn="priority" valuecolumn="total"
                   seriescolor="##4A90D9">
    </cfchartseries>
  </cfchart>

  <!--- Query 2: tickets by status --->
  <cfquery name="byStatus" datasource="training_db">
    SELECT status, COUNT(*) AS total FROM hd_tickets GROUP BY status
  </cfquery>

  <h2>All Tickets by Status</h2>
  <cfchart format="png" chartwidth="500" chartheight="350"
           title="Tickets by Status">
    <cfchartseries type="pie" query="byStatus"
                   itemcolumn="status" valuecolumn="total">
    </cfchartseries>
  </cfchart>
</body>
</html>
```

### 2. Verify

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/chart_demo.cfm
```

Should return **200**. Open the **ColdFusion** tab in the browser and navigate to `/chart_demo.cfm` to see the rendered charts.

### 3. Save a chart to disk

```cfml
<cfchart format="png" name="myChart">
  <cfchartseries type="line" query="byPriority"
                 itemcolumn="priority" valuecolumn="total">
  </cfchartseries>
</cfchart>

<cffile action="write"
        file="#expandPath('/charts/tickets.png')#"
        output="#myChart#">
<p>Chart saved to /charts/tickets.png</p>
```
