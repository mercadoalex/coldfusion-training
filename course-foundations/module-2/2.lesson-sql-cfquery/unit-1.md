---
kind: unit

title: SQL with cfquery & queryParam

name: sql-cfquery-queryparam-unit-1
---

## SELECT

::image-box
---
:src: __static__/cfquery-object-structure-v1.png
:alt: Diagram showing a cfquery tag on the left producing a "Query Object" on the right — the query object box contains labelled fields: recordCount (integer), columnList (comma-separated string), and a grid showing rows with columns id, title, status, priority matching the SELECT columns; arrows from cfoutput query="tickets" and cfloop query="tickets" below show the two ways to iterate the object
:max-width: 860px
---
_A `cfquery` returns a Query object — iterate it with `cfoutput query=` or `cfloop query=`._
::

```cfml
<cfquery name="tickets" datasource="training_db">
  SELECT t.id, t.title, t.status, t.priority, u.name AS submitter
  FROM   hd_tickets t
  JOIN   hd_users   u ON u.id = t.user_id
  ORDER  BY t.created_at DESC
</cfquery>

<cfoutput query="tickets">
  #tickets.id# — #encodeForHTML(title)# [#status# / #priority#]<br>
</cfoutput>
```

The `cfquery` tag returns a **query object**. Iterate it with `<cfoutput query="...">` or `cfloop query="..."`.

---

## INSERT with cfqueryparam

Always bind parameters with `<cfqueryparam>` — never concatenate user input directly into SQL.

```cfml
<cfquery datasource="training_db">
  INSERT INTO hd_tickets (title, description, status, priority, user_id, created_at)
  VALUES (
    <cfqueryparam value="#form.title#"       cfsqltype="cf_sql_varchar">,
    <cfqueryparam value="#form.description#" cfsqltype="cf_sql_varchar">,
    'open',
    <cfqueryparam value="#form.priority#"    cfsqltype="cf_sql_varchar">,
    <cfqueryparam value="#session.userId#"   cfsqltype="cf_sql_integer">,
    <cfqueryparam value="#now()#"            cfsqltype="cf_sql_timestamp">
  )
</cfquery>
```

---

## Why cfqueryparam?

::image-box
---
:src: __static__/cfqueryparam-sql-injection-v1.png
:alt: Split comparison diagram showing two code boxes stacked vertically — top box labelled "Without cfqueryparam (UNSAFE)" shows WHERE id = #url.id# with a red banner showing the injection payload 1 OR 1=1; DROP TABLE hd_tickets; bottom box labelled "With cfqueryparam (SAFE)" shows the same clause using cfqueryparam with cfsqltype="cf_sql_integer" and an green banner saying "Bind parameter — injection blocked, query plan cached"
:max-width: 860px
---
_`cfqueryparam` is the single most important SQL security practice in CFML — never interpolate user input directly._
::

Without it — **dangerous** (SQL injection risk):

```cfml
WHERE id = #url.id#
```

With it — **safe** (parameterised query):

```cfml
WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
```

`cfqueryparam` does three things:
1. Sends the value as a **typed bind parameter** (never interpolated into the SQL string)
2. Validates the type (`cf_sql_integer` rejects `"'; DROP TABLE --"`)
3. Lets the database cache the query plan across calls

---

## Common cfsqltype values

| CFML type | SQL equivalent |
|---|---|
| `cf_sql_varchar` | `VARCHAR` / `TEXT` |
| `cf_sql_integer` | `INT` |
| `cf_sql_bigint` | `BIGINT` |
| `cf_sql_double` | `DOUBLE` / `FLOAT` |
| `cf_sql_timestamp` | `DATETIME` / `TIMESTAMP` |
| `cf_sql_boolean` | `BOOLEAN` |

---

## Modern queryExecute()

In cfscript, use the function form instead of the tag:

```cfml
<cfscript>
  tickets = queryExecute(
    "SELECT id, title, status FROM hd_tickets WHERE status = :status",
    { status: { value: "open", cfsqltype: "cf_sql_varchar" } },
    { datasource: "training_db" }
  );
</cfscript>
```

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/tickets.cfm` that SELECTs from `hd_tickets` and outputs ticket data.
2. Make sure you use `cfqueryparam` (or named bindings in `queryExecute`) for any parameterised value.
3. Verify:

```bash
curl -s http://localhost:8500/tickets.cfm | grep -i "ticket\|title\|id"
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_query_page
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/tickets.cfm` — must return HTTP 200.

#completed
`tickets.cfm` is accessible. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_queryparam_used
---
#active
Use `<cfqueryparam>` or named bindings in `queryExecute` in `tickets.cfm`.

#completed
`cfqueryparam` is used — safe parameterised SQL. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_select_results
---
#active
`tickets.cfm` must display ticket data (ID, title, or similar).

#completed
Query results are displayed correctly. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.sql-query-90f5ae15
---
::
