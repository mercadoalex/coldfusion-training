---
kind: unit

title: ORM Basics — ColdFusion Hibernate ORM

name: orm-basics-hibernate-unit-1
---

## What is ColdFusion ORM?

::image-box
---
:src: __static__/orm-entity-to-table-mapping-v1.png
:alt: Two-column mapping diagram — on the left a Ticket.cfc component box shows property declarations with persistent="true", property name="id" fieldtype="id", property name="title" ormtype="string", and property name="status" ormtype="string"; on the right a database table box shows the corresponding hd_tickets table with columns id (PK), title (VARCHAR), status (VARCHAR) — a bidirectional arrow labelled "Hibernate ORM" bridges the two sides
:max-width: 860px
---
_ColdFusion ORM maps persistent CFC properties directly to database columns via Hibernate — no SQL DDL required._
::

ColdFusion ships with **Hibernate** as its built-in ORM layer. Mark a CFC as `persistent="true"` and ColdFusion automatically maps it to a database table, generates the schema, and provides CRUD functions.

---

## 1. Enable ORM in Application.cfc

```cfml
component {
  this.name = "MyApp";
  this.ormenabled = true;
  this.ormsettings = {
    datasource: "training_db",
    dbcreate:   "update",   // "none" | "create" | "update" | "dropcreate"
    logsql:     false
  };
}
```

`dbcreate: "update"` tells Hibernate to alter the schema to match your entities without dropping existing data.

---

## 2. Define an entity

```cfml
// Ticket.cfc
component persistent="true" table="hd_tickets" {
  property name="id"          fieldtype="id" generator="native";
  property name="title"       ormtype="string";
  property name="description" ormtype="string";
  property name="status"      ormtype="string";
  property name="priority"    ormtype="string";
}
```

Each `property` maps to a column. `fieldtype="id"` marks the primary key; `generator="native"` uses the database's auto-increment.

---

## 3. CRUD operations

```cfml
<cfscript>
  // CREATE
  t = new Ticket();
  t.setTitle("Keyboard not working");
  t.setDescription("Keys are unresponsive on laptop");
  t.setStatus("open");
  t.setPriority("medium");
  entitySave(t);

  // READ — all open tickets
  tickets = entityLoad("Ticket", {status: "open"});

  // READ — single by PK
  t = entityLoadByPK("Ticket", 1);

  // UPDATE
  t.setStatus("closed");
  entitySave(t);

  // DELETE
  entityDelete(t);
</cfscript>
```

ColdFusion generates getter/setter methods automatically from the `property` declarations.

---

## 4. HQL queries

Hibernate Query Language is SQL-like but operates on entity names, not table names:

```cfml
<cfscript>
  // HQL query
  openTickets = ORMExecuteQuery(
    "FROM Ticket WHERE status = :status ORDER BY id DESC",
    { status: "open" }
  );

  // Or count
  total = ORMExecuteQuery(
    "SELECT COUNT(*) FROM Ticket WHERE priority = :p",
    { p: "high" },
    true   // unique = true returns scalar
  );
</cfscript>
```

---

## When to use ORM vs cfquery

::image-box
---
:src: __static__/orm-vs-cfquery-decision-v1.png
:alt: Decision flowchart — starting from "Do you need a query?" with two branches: left branch "Simple CRUD on one entity" points to "Use ORM (entityLoad / entitySave)" green box; right branch "Complex JOIN, report, or aggregate" points to "Use cfquery / queryExecute" blue box — a note at the bottom says "Both can be mixed within the same application"
:max-width: 760px
---
_Use ORM for domain-model CRUD, `cfquery` for reporting and complex JOINs — they coexist naturally._
::


| Scenario | Recommendation |
|---|---|
| Simple CRUD on one table | ORM — less boilerplate |
| Complex multi-table JOIN | `cfquery` / `queryExecute` — more control |
| Reporting queries | `cfquery` — easier to optimise |
| Domain model with relationships | ORM — handles lazy loading |

---

## Exercises

1. Enable ORM in your `Application.cfc` (`this.ormenabled = true`).
2. Create `Ticket.cfc` with `persistent="true"` mapped to `hd_tickets`.
3. Create `orm_test.cfm` that loads all open tickets with `entityLoad`.
4. Verify:

```bash
curl -s http://localhost:8500/orm_test.cfm | grep -vi "error\|exception"
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_orm_enabled
---
#active
Add `this.ormenabled = true` to `Application.cfc`.

#completed
ORM is enabled in `Application.cfc`. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_entity_exists
---
#active
Create a CFC with `persistent="true"` mapped to `hd_tickets`.

#completed
At least one persistent ORM entity CFC found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_orm_page
---
#active
Create `orm_test.cfm` that calls `entityLoad` — must return no errors.

#completed
`orm_test.cfm` runs without errors. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.orm-entity-eadcb3b1
---
::
