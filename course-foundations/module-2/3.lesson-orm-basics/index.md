---
kind: lesson

title: ORM Basics — ColdFusion Hibernate ORM
description: |
  Use ColdFusion's built-in Hibernate ORM to map CFCs to database tables.
  Learn entity definition, CRUD operations, and basic HQL queries.

name: orm-basics-hibernate
slug: orm-basics-hibernate

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

tasks:
  verify_orm_enabled:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if ! grep -q "ormenabled\|ormEnabled" "${FILE}" 2>/dev/null; then
        echo "ORM is not enabled in Application.cfc (missing ormenabled=true)"
        exit 1
      fi
      echo "ORM is enabled in Application.cfc"

  verify_entity_exists:
    machine: dev-machine
    user: laborant
    needs:
      - verify_orm_enabled
    run: |
      COUNT=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" | xargs grep -li "persistent.*=.*true\|persistent=\"true\"" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No persistent ORM entity CFC found"
        exit 1
      fi
      echo "Found ${COUNT} ORM entity CFC(s)"

  verify_orm_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_entity_exists
    run: |
      BODY=$(curl -s http://localhost:8500/orm_test.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "orm_test.cfm is throwing an error"
        exit 1
      fi
      echo "ORM test page runs without errors"
---

## Enable ORM in Application.cfc

```cfml
component {
  this.name = "MyApp";
  this.ormenabled = true;
  this.ormsettings = {
    datasource: "training_db",
    dbcreate: "update",
    logsql: false
  };
}
```

## Define an entity

```cfml
// Student.cfc
component persistent="true" table="students" {
  property name="id"    fieldtype="id" generator="native";
  property name="name"  ormtype="string";
  property name="email" ormtype="string";
}
```

## CRUD operations

```cfml
<cfscript>
  // CREATE
  s = new Student();
  s.setName("Alex");
  s.setEmail("alex@example.com");
  entitySave(s);

  // READ
  students = entityLoad("Student");

  // UPDATE
  s = entityLoadByPK("Student", 1);
  s.setName("Alex Updated");
  entitySave(s);

  // DELETE
  entityDelete(s);
</cfscript>
```
