---
kind: lesson

title: ORM Relationships — One-to-Many, Many-to-One, and Beyond
description: |
  Learn how to define relationships between persistent CFCs using ColdFusion
  Hibernate ORM. Covers one-to-one, one-to-many, many-to-one, many-to-many,
  cascade options, inverse, and link tables.

name: orm-relationships
slug: orm-relationships

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- orm
- hibernate
- relationships

playground:
  name: cf-alex-edcdf975

tasks:
  verify_orm_relationship_cfcs:
    machine: dev-machine
    user: laborant
    run: |
      WWWROOT="/opt/coldfusion2025/cfusion/wwwroot"
      COUNT=$(grep -rl "fieldtype.*one-to-many\|fieldtype.*many-to-one\|fieldtype.*one-to-one\|fieldtype.*many-to-many" "${WWWROOT}" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No CFC with a relationship fieldtype found in ${WWWROOT}"
        exit 1
      fi
      echo "Found ${COUNT} CFC(s) with ORM relationship mappings"

  verify_relationship_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_orm_relationship_cfcs
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/orm_rel_test.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "orm_rel_test.cfm not found (got ${STATUS})"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/orm_rel_test.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "orm_rel_test.cfm is throwing an error"
        exit 1
      fi
      echo "Relationship test page runs without errors"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_relationship_page
    run: |
      echo "Lesson complete — well done!"

---
