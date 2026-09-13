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

::hint-box
---
:summary: What is an embedded H2 database?
---

**H2** is a relational database engine written entirely in Java. "Embedded" means it runs **inside the same JVM process as ColdFusion** — there is no separate database server to install, start, or connect to over a network. The database file lives on disk alongside the application.

**Why H2 for training?**

| Property | H2 (embedded) | MySQL / PostgreSQL (external) |
|---|---|---|
| Setup | Zero — ships with ColdFusion | Requires a separate install and service |
| Network | None — in-process | TCP connection to a server |
| Performance | Fast for small datasets | Optimised for production workloads |
| Persistence | File on disk | Dedicated server storage |
| Use case | Development, testing, training | Production applications |

H2 supports a large subset of standard SQL — `SELECT`, `INSERT`, `UPDATE`, `DELETE`, joins, indexes, transactions — so everything you learn querying `training_db` transfers directly to MySQL or PostgreSQL.

**How ColdFusion connects to it:**
ColdFusion uses a JDBC driver (`h2-*.jar`, bundled in the CF installation) to open the embedded database file. The datasource definition in CF Admin points to that file path. When CF starts, H2 opens the file and keeps it ready for queries — no separate `service start` command needed.

**In production you would use an external database.** H2 is not recommended for production because it does not support the same level of concurrent write throughput, replication, or operational tooling as MySQL, PostgreSQL, or Microsoft SQL Server. But for learning CFML and SQL, it is ideal — it is always on, always fast, and requires zero administration.

::

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

::hint-box
---
:summary: What else is under Data & Services in CF Admin?
---

The **Data & Services** section of CF Admin is the central hub for configuring every type of external data connection and service integration ColdFusion supports. This course focuses on **Data Sources** — the others are covered in depth in the Advanced ColdFusion courses.

| Option | What it configures | Used with |
|---|---|---|
| **Data Sources** | Named JDBC connection pools to relational databases (H2, MySQL, PostgreSQL, MSSQL, Oracle) | `cfquery`, `queryExecute()`, ORM |
| **NoSQL Sources** | Connections to MongoDB document stores | `cfmongodb`, custom Java integration |
| **ColdFusion Collections** | Verity full-text search indexes — collections of documents indexed for keyword search | `cfindex`, `cfsearch` |
| **Solr Server** | Connection to an Apache Solr search server for enterprise full-text search | `cfindex`, `cfsearch` with Solr engine |
| **Web Services** | Registered WSDL endpoints for SOAP web service consumption | `cfinvoke`, `cfobject` |
| **REST Services** | Registered ColdFusion REST applications — maps URL paths to CFC-based REST endpoints | `cfrestregistry`, REST CFCs with `restpath` |
| **PDF Service** | Connection to a remote ColdFusion PDF generation service for offloading heavy PDF rendering | `cfdocument`, `cfpdf` with remote engine |
| **Cloud Credentials** | Stored credentials for AWS, Azure, and Google Cloud services (S3, SES, Rekognition, etc.) | `cffile` S3 storage, `cfmail` SES, AI/ML tags |
| **Cloud Configuration** | Named cloud storage and service configurations that reference a Cloud Credential | `cffile action="copy"` to S3, cloud functions |
| **GraphQL** | Schema registration and endpoint configuration for ColdFusion's built-in GraphQL support | GraphQL query execution via ColdFusion endpoints |

**A note on scope:** this lesson covers Data Sources only, because relational databases are the backbone of almost every ColdFusion application. The other integrations — Solr, SOAP, REST, PDF, cloud services, and GraphQL — each have their own dedicated lessons in the **Advanced ColdFusion** course track where they are explored hands-on with real examples.

::

---

## Seed the Help Desk database

Before running any queries, make sure the Help Desk schema is populated. Open the **ColdFusion 2025** browser tab and click the **DB Test** button.

1. Click **Run Seed Script**

::image-box
---
:src: __static__/browser-db-test-seed-option-v1.png
:alt: The DB Test page in the lab showing the Run Seed Script button
:max-width: 860px
---
_DB Test page — click **Run Seed Script** to create and populate the Help Desk schema._
::

2. A confirmation screen confirms the seed completed successfully

::image-box
---
:src: __static__/browser-db-test-seed-confirmed-v1.png
:alt: Confirmation screen after running the seed script showing the schema was created and rows inserted successfully
:max-width: 860px
---
_Seed confirmation — all four tables created and sample rows inserted._
::

3. Click **← Back to DB Test** to see all the records

::image-box
---
:src: __static__/browser-db-test-records-v1.png
:alt: DB Test page showing all records from the Help Desk tables — hd_departments, hd_users, hd_tickets, and hd_comments — after the seed script ran successfully
:max-width: 860px
---
_DB Test showing all Help Desk records — the database is seeded and ready._
::

Alternatively, seed from the terminal:

```bash
curl -s http://localhost:8500/seed-db.cfm
```

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

::hint-box
---
:summary: Troubleshooting — "Table HD_TICKETS not found (this database is empty)"
---

If you forgot to seed first, you will see this error:

::image-box
---
:src: __static__/error-table-not-found-seed-db-v1.png
:alt: ColdFusion error page showing "Error Executing Database Query — Table HD_TICKETS not found (this database is empty)" with the SQL statement and H2 error code 42104
:max-width: 860px
---
_H2 error 42104 — the Help Desk schema has not been seeded yet._
::

Go back to the **DB Test** page, click **Run Seed Script**, then reload `verify_ds.cfm`.

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
