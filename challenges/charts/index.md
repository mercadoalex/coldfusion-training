---
kind: challenge

title: Dynamic Chart from Live Data

description: |
  Create chart_demo.cfm that queries hd_tickets and renders a cfchart.
  The page must return HTTP 200, use cfchart, and pull data from a cfquery
  or queryExecute call.

difficulty: medium

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
3. Returns HTTP 200 with no errors

Try it on your own first — then use the hints below if you need them.

---

::details-box
---
:summary: 👉 Hint — not sure where to start?
---
Revisit **Module 2 Lesson 7 — Chart Generation and Management**.

Key things you need:
- The file goes in `/opt/coldfusion2025/cfusion/wwwroot/` (the web root, **not** `student/`) so the checker finds it at `http://localhost:8500/chart_demo.cfm`
- Query `hd_tickets` first with `cfquery` or `queryExecute` — group by any column (priority, status, category)
- Use `<cfchart>` to wrap the chart and `<cfchartseries>` inside it with `type="bar"`, `type="pie"`, or `type="line"`
- Point `cfchartseries` at your query: `query="yourQueryName"`, `itemcolumn="priority"`, `valuecolumn="total"`
- Colour values need `##` not `#` — e.g. `seriescolor="##3b82d4"`
- If you see "chart package not installed": run `sudo /opt/coldfusion2025/cfusion/bin/cfpm.sh install chart && sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart`
::

::details-box
---
:summary: 👉 Skeleton — need the structure?
---
Fill in the blanks:

```cfml
<cfquery name="______" datasource="training_db">
  SELECT ______, COUNT(*) AS total
  FROM   hd_tickets
  GROUP  BY ______
  ORDER  BY total DESC
</cfquery>

<cfchart format="png" chartwidth="600" chartheight="380"
         title="______" show3d="false">
  <cfchartseries type="______"
                 query="______"
                 itemcolumn="______"
                 valuecolumn="total">
  </cfchartseries>
</cfchart>
```
::

::remark-box
---
kind: info
---
No full solution is provided here — use the hint and the skeleton. Once you pass all the checks, a **post-challenge review lesson** unlocks with the full annotated solution.
::

---

### Verify your work

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/chart_demo.cfm
# Expected: 200
```

Open the **ColdFusion** browser tab to see the rendered chart.

::simple-task
---
:tasks: tasks
:name: verify_chart_page
---
#active
Waiting for `chart_demo.cfm` to return HTTP 200...

#completed
`chart_demo.cfm` is accessible. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cfchart_tag
---
#active
Checking for `cfchart` in `chart_demo.cfm`...

#completed
`cfchart` tag found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_query_data
---
#active
Checking that the chart uses live query data...

#completed
Chart powered by query data — challenge complete! ✓
::
