---
kind: challenge

title: ORM Persistent Entity

description: |
  Enable Hibernate ORM in Application.cfc, define a persistent Ticket.cfc
  entity mapped to hd_tickets, and create orm_test.cfm that loads entities
  without throwing an error.

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
      if ! grep -qi "ormenabled" "${FILE}" 2>/dev/null; then
        echo "ORM not enabled in Application.cfc"
        exit 1
      fi
      echo "ORM enabled"

  verify_entity_cfc:
    machine: dev-machine
    user: laborant
    needs:
      - verify_orm_enabled
    run: |
      COUNT=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" \
        | xargs grep -li "persistent.*=.*true\|persistent=\"true\"" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No persistent ORM entity found"
        exit 1
      fi
      echo "Found ${COUNT} ORM entity CFC(s)"

  verify_orm_test_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_entity_cfc
    run: |
      BODY=$(curl -s http://localhost:8500/orm_test.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "orm_test.cfm threw an error"
        exit 1
      fi
      echo "ORM test page runs cleanly"
---

## Your mission

1. Add `this.ormenabled = true` and `this.ormsettings` to `Application.cfc`
2. Create `Ticket.cfc` with `persistent="true"` and `table="hd_tickets"`
3. Create `orm_test.cfm` that calls `entityLoad("Ticket")` and outputs results

```bash
curl -s http://localhost:8500/orm_test.cfm | grep -vi "error\|exception"
```
