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

## Verify via CFML

```cfml
<cfquery name="test" datasource="training_db">
  SELECT COUNT(*) AS total FROM hd_tickets
</cfquery>
<cfoutput>
  Tickets in training_db: #test.total#
</cfoutput>
```

Create this as `verify_ds.cfm` in the web root. The page must output something containing **success**, **connected**, or **ok** for the lesson task to pass.

---

## Configure in CF Admin

The datasource is already set up — no manual steps needed. To inspect it:

1. Browse to `http://localhost:8500/CFIDE/administrator`
2. Log in with password: `admin`
3. Go to **Data & Services → Data Sources**
4. Click **Verify** next to `training_db`

You should see a green checkmark and "OK" status.

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

```cfml
// Inline datasource definition in Application.cfc (alternative to CF Admin)
component {
  this.datasource = "training_db";  // sets the default for all cfquery calls
}
```

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/verify_ds.cfm`.
2. Query `hd_tickets` and output a confirmation containing the word **ok** or **connected**.
3. Verify:

```bash
curl -s http://localhost:8500/verify_ds.cfm
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_datasource_page
---
#active
Create `verify_ds.cfm` — the response must contain **success**, **connected**, or **ok**.

#completed
Datasource connection verified. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_training_db
---
#active
Reference the `training_db` datasource in `verify_ds.cfm`.

#completed
`training_db` datasource is referenced. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_no_error
---
#active
`verify_ds.cfm` must not output any **error** or **exception** text.

#completed
No errors on the datasource verification page. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.datasource-verify-ee68f4ff
---
::
