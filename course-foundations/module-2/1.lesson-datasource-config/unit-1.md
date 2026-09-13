---
kind: unit

title: Datasource Configuration

name: datasource-configuration-unit-1
---

## Datasources in the lab

::image-box
---
:src: __static__/cf-datasource-pool-diagram-v1.png
:alt: Architecture diagram showing the ColdFusion datasource pool — three concurrent browser requests on the left send cfquery calls into a central "Connection Pool (training_db)" box that contains 5 JDBC connection slots, which all point to a single database cylinder on the right labelled "H2 / MySQL / PostgreSQL" — the pool is labelled with "CF Admin or Application.cfc" above it to show where it is configured
:max-width: 860px
---
_A datasource is a named JDBC connection pool — pages reference it by name, the engine manages the connections._
::

The `training_db` datasource is pre-configured in CF Admin on first boot. It is an embedded H2 database pre-seeded with a **Help Desk schema**.

| Name | Type | Purpose |
|---|---|---|
| `training_db` | H2 embedded | All lab exercises |

### Help Desk schema

| Table | Rows | Contents |
|---|---|---|
| `hd_departments` | 4 | IT, Dev, HR, Finance |
| `hd_users` | 6 | Admin, agents, end users |
| `hd_tickets` | 10 | Mixed status, priority, category |
| `hd_comments` | 9 | Thread replies and internal notes |

Useful URLs in your environment:

```
http://localhost:8500/seed-db.cfm   ← re-seed the schema
http://localhost:8500/db-test.cfm   ← view raw table data
```

---

## What is a datasource?

::image-box
---
:src: __static__/cf-admin-datasource-screen-v1.png
:alt: Screenshot mock-up of the ColdFusion Administrator Data Sources page — a table with columns Name, Driver, Status, and Actions; one row shows "training_db" with driver "H2 Database Engine", status shown as a green checkmark "OK", and action buttons Verify and Edit — styled to match the flat CF Admin UI with a dark sidebar on the left listing menu items
:max-width: 860px
---
_CF Admin's Data Sources panel — click Verify to confirm the pool is healthy without writing any CFML._
::

A ColdFusion datasource is a **named JDBC connection pool**. Pages and components reference it by name — not by connection string. The pool is configured once (in CF Admin or `Application.cfc`) and shared across all requests.

---

## Configure in CF Admin

The `training_db` datasource is already set up — no manual steps needed. To inspect it:

1. Browse to `http://localhost:8500/CFIDE/administrator`
2. Log in with password: `admin`
3. Go to **Data & Services → Data Sources**
4. Click **Verify** next to `training_db`

You should see a green checkmark and "OK" status.

---

## Activity 1 — Verify the datasource with CFML

**Activity:** Click the **Terminal** tab in your lab. Copy and paste the script below to create `verify_ds.cfm` — a page that queries `training_db` and outputs a connection confirmation:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/verify_ds.cfm << 'EOF'
<cfquery name="test" datasource="training_db">
  SELECT COUNT(*) AS total FROM hd_tickets
</cfquery>
<cfoutput>Connection OK — #test.total# tickets found</cfoutput>
EOF
```

Verify the page responds correctly:

```bash
curl -s http://localhost:8500/verify_ds.cfm
# Expected: Connection OK — 10 tickets found
```

::image-box
---
:src: __static__/browser-verify-ds-output-v1.png
:alt: Browser window showing the rendered output of verify_ds.cfm — a single line reading "Connection OK — 10 tickets found" confirming the training_db datasource is reachable and the hd_tickets table contains rows
:max-width: 860px
---
_`verify_ds.cfm` confirms the `training_db` datasource is reachable and returns a row count._
::

::simple-task
---
:tasks: tasks
:name: verify_no_error
---
#active
Click the **Terminal** tab and run the `sudo tee` command above to create `verify_ds.cfm`. The page must output **Connection OK** with a ticket count and must not throw any error.

#completed
Datasource verified — `verify_ds.cfm` runs without errors. ✓
::

---

## Activity 2 — Inspect the datasource in CF Admin

**Activity:** Open the **ColdFusion 2025** browser tab and navigate to the CF Administrator to inspect `training_db`:

1. Browse to `http://localhost:8500/CFIDE/administrator`
2. Log in with password: `admin`
3. Go to **Data & Services → Data Sources**
4. Locate the `training_db` row and click **Verify**
5. Confirm the status column shows a green checkmark and **OK**

::image-box
---
:src: __static__/browser-cf-admin-datasource-v1.png
:alt: ColdFusion Administrator Data Sources page showing the training_db row with a green checkmark in the Status column and an OK label confirming the JDBC connection pool is healthy
:max-width: 860px
---
_CF Admin confirms `training_db` is healthy — no CFML required to check pool status._
::

::simple-task
---
:tasks: tasks
:name: verify_training_db
---
#active
Open CF Admin at `http://localhost:8500/CFIDE/administrator`, go to **Data & Services → Data Sources**, and click **Verify** next to `training_db`. Confirm the green OK status.

#completed
`training_db` datasource verified in CF Admin. ✓
::

---

## Activity 3 — Define the datasource in Application.cfc

**Activity:** Setting `this.datasource` in `Application.cfc` makes `training_db` the default for every `cfquery` call in your application — no need to repeat the `datasource` attribute on each tag.

In the **Terminal** tab, create `Application.cfc` in the web root:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/Application.cfc << 'EOF'
component {

  this.name       = "HelpdeskApp";
  this.datasource = "training_db";

}
EOF
```

Verify the file was written correctly:

```bash
grep "this.datasource" /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
# Expected: this.datasource = "training_db";
```

::image-box
---
:src: __static__/browser-app-cfc-datasource-v1.png
:alt: Terminal window showing the sudo tee command writing Application.cfc followed by the grep output confirming the line "this.datasource = training_db" is present in the file
:max-width: 860px
---
_`Application.cfc` with `this.datasource` set — all `cfquery` calls in this application now default to `training_db`._
::

::simple-task
---
:tasks: tasks
:name: verify_app_cfc
---
#active
Run the `sudo tee` command above to create `Application.cfc` in the web root with `this.datasource = "training_db"`.

#completed
`Application.cfc` created with `this.datasource` set. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All done? Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete. On to the next one!
::
