---
kind: lesson

title: Datasource Configuration
description: |
  Configure and verify datasources in ColdFusion 2025. Work with the embedded
  H2 datasource (training_db), pre-seeded with the Help Desk schema.

name: datasource-configuration
slug: datasource-configuration

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- datasource
- h2

playground:
  name: cf-alex-edcdf975

tasks:
  verify_datasource_page:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s http://localhost:8500/verify_ds.cfm)
      if ! echo "${BODY}" | grep -qi "success\|connected\|ok"; then
        echo "verify_ds.cfm does not confirm a working datasource connection"
        exit 1
      fi
      echo "Datasource connection verified"

  verify_training_db:
    machine: dev-machine
    user: laborant
    needs:
      - verify_datasource_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/verify_ds.cfm"
      if ! grep -q "training_db" "${FILE}" 2>/dev/null; then
        echo "verify_ds.cfm does not reference the training_db datasource"
        exit 1
      fi
      echo "training_db datasource is referenced"

  verify_no_error:
    machine: dev-machine
    user: laborant
    needs:
      - verify_training_db
    run: |
      BODY=$(curl -s http://localhost:8500/verify_ds.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "verify_ds.cfm is throwing an error"
        exit 1
      fi
      echo "No errors on datasource verification page"
---

## Datasources in the lab

| Name | Type | Purpose |
|---|---|---|
| `training_db` | H2 embedded | All lab exercises — pre-seeded with Help Desk schema |

The `training_db` datasource is pre-configured and ready on first boot. It contains
a **Help Desk schema** with realistic sample data:

| Table | Rows | Contents |
|---|---|---|
| `hd_departments` | 4 | IT, Dev, HR, Finance |
| `hd_users` | 6 | Admin, agents, end users |
| `hd_tickets` | 10 | Mixed status, priority, category |
| `hd_comments` | 9 | Thread replies and internal notes |

Run the seed script to verify or re-seed: `http://localhost:8500/seed-db.cfm`

View the data: `http://localhost:8500/db-test.cfm`

## Verify via CFML

```cfml
<cfquery name="test" datasource="training_db">
  SELECT COUNT(*) AS total FROM hd_tickets
</cfquery>
<cfoutput>
  Tickets in training_db: #test.total#
</cfoutput>
```

## Configure in CF Admin

The datasource is pre-configured — no manual setup needed. To inspect it:

1. Browse to `http://localhost:8500/CFIDE/administrator`
2. Login with password: `admin`
3. Go to **Data & Services → Data Sources**
4. Click **Verify** next to `training_db`
