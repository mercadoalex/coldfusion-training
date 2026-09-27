---
kind: unit

title: Dynamic Chart Challenge — Solution Review

name: charts-challenge-review-unit-1
---

Read this only after you have made a genuine attempt at the challenge. The explanations are most useful when you have already wrestled with the problem yourself.

---

## What the checker verifies

Three things must be true for the challenge to pass:

| Check | What it tests |
|---|---|
| `verify_chart_page` | `http://localhost:8500/chart_demo.cfm` returns HTTP 200 |
| `verify_cfchart_tag` | The file contains the string `cfchart` |
| `verify_query_data` | The file contains `cfquery` or `queryExecute` |

The file must live at `/opt/coldfusion2025/cfusion/wwwroot/chart_demo.cfm` — not inside `student/`. The checker calls `http://localhost:8500/chart_demo.cfm` directly.

---

## The complete solution — annotated

```cfml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Chart Demo</title>
</head>
<body>

  <h2>Bar Chart — Open Tickets by Priority</h2>

  <cfquery name="byPriority" datasource="training_db">  <!--- (1) --->
    SELECT priority, COUNT(*) AS total
    FROM   hd_tickets
    WHERE  status = 'open'
    GROUP  BY priority
    ORDER  BY total DESC
  </cfquery>

  <cfchart format="png"             <!--- (2) --->
           chartwidth="600"
           chartheight="380"
           title="Open Tickets by Priority"
           show3d="false"
           backgroundColor="##ffffff">  <!--- (3) --->
    <cfchartseries
      type        = "bar"           <!--- (4) --->
      query       = "byPriority"    <!--- (5) --->
      itemcolumn  = "priority"      <!--- (6) --->
      valuecolumn = "total"         <!--- (7) --->
      seriescolor = "##3b82d4"      <!--- (3) --->
      serieslabel = "Open tickets">
    </cfchartseries>
  </cfchart>

  <h2>Pie Chart — All Tickets by Status</h2>

  <cfquery name="byStatus" datasource="training_db">
    SELECT status, COUNT(*) AS total
    FROM   hd_tickets
    GROUP  BY status
    ORDER  BY total DESC
  </cfquery>

  <cfchart format="png" chartwidth="500" chartheight="400"
           title="All Tickets by Status" show3d="false"
           backgroundColor="##ffffff">
    <cfchartseries type="pie" query="byStatus"
                   itemcolumn="status" valuecolumn="total">
    </cfchartseries>
  </cfchart>

</body>
</html>
```

---

## Annotation key

**(1) `cfquery` with `datasource="training_db"`** — always query first, before the `cfchart` tag. `cfchart` reads from a named query object that must already exist in memory. The query name (`byPriority`) is what you pass to `cfchartseries query="byPriority"`.

**(2) `cfchart` attributes** — `format="png"` is the default and the right choice for web pages. `show3d="false"` keeps the chart clean — 3D adds visual noise without adding information. `chartwidth` and `chartheight` are in pixels.

**(3) `##` colour escaping** — in CFML, `#` is the expression delimiter. A literal `#` inside a tag attribute must be escaped as `##`. So `backgroundColor="##ffffff"` means the colour `#ffffff`, not a variable. Forgetting this causes a CFML parse error. This is the most common mistake on this challenge.

**(4) `type="bar"`** — the chart type is on `cfchartseries`, not on `cfchart`. One `cfchart` can contain multiple `cfchartseries` of different types — useful for combination charts. The challenge accepts `bar`, `pie`, or `line`.

**(5) `query="byPriority"`** — must exactly match the `name` attribute on your `cfquery`. Case-insensitive in practice, but match it exactly to be safe.

**(6) `itemcolumn="priority"`** — the query column used for the x-axis labels (bar/line) or slice labels (pie). Must be a column that exists in the query result set.

**(7) `valuecolumn="total"`** — the query column used for the y-axis values (bar/line) or slice sizes (pie). Must be numeric. The alias `COUNT(*) AS total` in the SQL is what makes this column available.

---

## Why the file goes in `wwwroot/` not `wwwroot/student/`

The task checker calls `http://localhost:8500/chart_demo.cfm` — no `student/` path prefix. ColdFusion's web root is `/opt/coldfusion2025/cfusion/wwwroot/`, so the file must live directly there. In the lesson activities `student/` is used to keep practice files organised, but a challenge that defines its own URL path overrides that convention.

---

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| File in `wwwroot/student/` instead of `wwwroot/` | `verify_chart_page` fails with 404 | Move the file: `sudo mv /opt/coldfusion2025/cfusion/wwwroot/student/chart_demo.cfm /opt/coldfusion2025/cfusion/wwwroot/` |
| `#ffffff` instead of `##ffffff` | CFML parse error, HTTP 500 | Double the `#`: `##ffffff` |
| `cfchartseries` outside `cfchart` | Chart renders blank or throws error | `cfchartseries` must be nested inside `cfchart` |
| `itemcolumn` points to a non-existent column | Blank chart, no error | Check the column name matches exactly what the query `SELECT`s |
| Chart package not installed | "The chart package is not installed" | `sudo /opt/coldfusion2025/cfusion/bin/cfpm.sh install chart && sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart` |

---

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
Read through the review and hit **Check** when you are done.

#completed
Review complete — on to the next lesson!
::
