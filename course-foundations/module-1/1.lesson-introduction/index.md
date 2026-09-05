---
kind: lesson

title: Introduction to ColdFusion
description: |
  What ColdFusion is, the problems it solves, and how its architecture works.
  Learn the history of CFML, the difference between Adobe ColdFusion and Lucee,
  and how to verify services in your lab environment.

name: introduction-to-coldfusion
slug: introduction-to-coldfusion

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- lucee

playground:
  name: cf-alex-edcdf975

tasks:
  verify_cf_running:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "ColdFusion 2025 is not responding on port 8500 (got ${STATUS})"
        exit 1
      fi
      echo "ColdFusion 2025 is running"

  verify_lucee_running:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cf_running
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "Lucee/CommandBox is not responding on port 8888 (got ${STATUS})"
        exit 1
      fi
      echo "Lucee via CommandBox is running"

  verify_hello_cfm:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cf_running
    run: |
      BODY=$(curl -s http://localhost:8500/hello.cfm)
      if ! echo "${BODY}" | grep -qi "hello"; then
        echo "hello.cfm does not exist or does not output a greeting"
        exit 1
      fi
      echo "hello.cfm is working correctly"
---
