---
kind: lesson

title: Lucee Server — Configuration & Administration
description: |
  Explore Lucee Server administration, configure datasources and mail servers,
  understand the differences between Lucee and Adobe ColdFusion 2025.

name: lucee-server-configuration
slug: lucee-server-configuration

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- lucee
- coldfusion
- cfml

playground:
  name: cf-alex-edcdf975

challenges:
  lucee_5db89516: {}

tasks:
  verify_lucee_running:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "Lucee is not running on port 8888 (got ${STATUS})"
        exit 1
      fi
      echo "Lucee is running on port 8888"

  verify_lucee_version:
    machine: dev-machine
    user: laborant
    needs:
      - verify_lucee_running
    run: |
      FILE="/home/laborant/app/lucee_info.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "lucee_info.cfm not found at ${FILE}"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8888/lucee_info.cfm)
      if ! echo "${BODY}" | grep -qi "lucee"; then
        echo "lucee_info.cfm does not output Lucee version info"
        exit 1
      fi
      echo "Lucee version info is accessible"

  verify_lucee_datasource:
    machine: dev-machine
    user: laborant
    needs:
      - verify_lucee_version
    run: |
      BODY=$(curl -s http://localhost:8888/verify_ds.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "Lucee datasource verification failed"
        exit 1
      fi
      if ! echo "${BODY}" | grep -qi "OK\|found\|ticket"; then
        echo "verify_ds.cfm did not return expected success output"
        exit 1
      fi
      echo "Lucee datasource is configured correctly"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_lucee_datasource
    run: |
      echo "Lesson complete — well done!"

---
