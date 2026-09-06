---
kind: unit

title: ORM Basics — ColdFusion Hibernate ORM

name: orm-basics-hibernate-unit-1
---

## What is ColdFusion ORM?

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
