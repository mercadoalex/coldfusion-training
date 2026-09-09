---
kind: tutorial

title: Your First ORM Entity — Ticket.cfc

description: |
  Enable Hibernate ORM, define a persistent Ticket entity, and
  perform CRUD operations against the training_db datasource.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- orm
- hibernate

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Enable ORM in Application.cfc

Add these settings to your `Application.cfc`:

```cfml
component {
  this.name       = "HelpDeskApp";
  this.ormenabled = true;
  this.ormsettings = {
    datasource: "training_db",
    dbcreate:   "update",
    logsql:     false
  };
}
```

### 2. Create Ticket.cfc

Create `/opt/coldfusion2025/cfusion/wwwroot/Ticket.cfc`:

```cfml
component persistent="true" table="hd_tickets" {
  property name="id"          fieldtype="id" generator="native";
  property name="title"       ormtype="string";
  property name="description" ormtype="string";
  property name="status"      ormtype="string"  default="open";
  property name="priority"    ormtype="string"  default="medium";
}
```

### 3. Create orm_test.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/orm_test.cfm`:

```cfml
<cfscript>
  // READ all open tickets
  tickets = entityLoad("Ticket", {status: "open"});
  for (t in tickets) {
    writeOutput(t.getId() & " — " & t.getTitle() & "<br>");
  }

  // CREATE a new ticket
  newTicket = new Ticket();
  newTicket.setTitle("ORM tutorial test");
  newTicket.setDescription("Created by the ORM tutorial");
  newTicket.setStatus("open");
  newTicket.setPriority("low");
  entitySave(newTicket);
  writeOutput("<br>Created ticket ID: " & newTicket.getId());
</cfscript>
```

### 4. Verify

```bash
curl -s http://localhost:8500/orm_test.cfm | grep -vi "error\|exception"
```

Should list open tickets and show the newly created ID.
