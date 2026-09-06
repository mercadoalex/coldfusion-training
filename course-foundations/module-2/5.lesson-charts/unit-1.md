---
kind: unit

title: Chart Generation and Management

name: chart-generation-management-unit-1
---

## cfchart overview

ColdFusion's `<cfchart>` tag generates charts as PNG images (or Flash, SVG) directly from query data. No JavaScript charting library required.

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

---

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

---

## Chart to file (save as image)

Use the `name` attribute to capture the chart into a variable, then write it to disk:

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

Then serve it with a normal `<img>` tag: `<img src="/charts/tickets.png">`.

---

## Chart types available

| Type | Use case |
|---|---|
| `bar` | Compare values across categories |
| `line` | Show trends over time |
| `pie` | Show proportions |
| `area` | Cumulative trends |
| `scatter` | Correlation between two variables |

---

## Key cfchart attributes

| Attribute | Purpose |
|---|---|
| `format` | `png` (default), `flash`, `jpg` |
| `chartwidth` / `chartheight` | Dimensions in pixels |
| `title` | Chart heading |
| `show3d` | `true` / `false` |
| `name` | Capture to variable instead of outputting inline |

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm`.
2. Run a `cfquery` against `hd_tickets` and render a `<cfchart>` from the result.
3. Verify:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/chart_demo.cfm
# Should return 200
```
