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
  verify_no_error:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s http://localhost:8500/verify_ds.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "verify_ds.cfm is throwing an error"
        exit 1
      fi
      if ! echo "${BODY}" | grep -qi "ok"; then
        echo "verify_ds.cfm does not output a connection confirmation"
        exit 1
      fi
      echo "No errors on datasource verification page"

  verify_training_db:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_error
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/verify_ds.cfm"
      if ! grep -q "training_db" "${FILE}" 2>/dev/null; then
        echo "verify_ds.cfm does not reference the training_db datasource"
        exit 1
      fi
      echo "training_db datasource is referenced"

  verify_app_cfc:
    machine: dev-machine
    user: laborant
    needs:
      - verify_training_db
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "Application.cfc not found in the web root"
        exit 1
      fi
      if ! grep -q "this.datasource" "${FILE}"; then
        echo "Application.cfc does not define this.datasource"
        exit 1
      fi
      echo "Application.cfc found with this.datasource defined"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_app_cfc
    run: |
      echo "Lesson complete — well done!"

---
