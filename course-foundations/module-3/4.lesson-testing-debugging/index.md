---
kind: lesson

title: Testing & Debugging CFML
description: |
  Debug CFML applications using cfdump, cflog, and the CF Admin debugger.
  Write unit tests with TestBox and run them via CommandBox against the
  live TicketService already running in your lab.

name: testing-debugging-cfml
slug: testing-debugging-cfml

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- testbox
- debugging

playground:
  name: cf-alex-edcdf975

tasks:
  verify_cfdump_file:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/student/debug-demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "debug-demo.cfm returned HTTP ${STATUS}, expected 200"
        exit 1
      fi
      echo "debug-demo.cfm → 200 OK ✓"

  verify_cflog_entry:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfdump_file
    run: |
      if [ ! -f "/opt/coldfusion2025/cfusion/logs/training.log" ]; then
        echo "training.log not found — visit /debug-demo.cfm to trigger cflog"
        exit 1
      fi
      echo "training.log exists ✓"

  verify_testbox_installed:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cflog_entry
    run: |
      if [ ! -d "/home/laborant/app/testbox" ]; then
        echo "TestBox not found — run: cd ~/app && box install testbox"
        exit 1
      fi
      echo "TestBox is installed ✓"

  verify_test_exists:
    machine: dev-machine
    user: laborant
    needs:
      - verify_testbox_installed
    run: |
      COUNT=$(find /home/laborant/app/tests -name "*Test*.cfc" -o -name "*Spec*.cfc" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No TestBox test or spec CFC found in ~/app/tests/"
        exit 1
      fi
      echo "Found ${COUNT} test/spec file(s) ✓"

  verify_tests_pass:
    machine: dev-machine
    user: laborant
    needs:
      - verify_test_exists
    run: |
      BODY=$(curl -s "http://localhost:8888/testbox/system/runners/StreamingRunner.cfm?directory=tests" 2>/dev/null)
      FAILURES=$(echo "${BODY}" | grep -oP 'Failed:\s*\K[0-9]+'  || echo "0")
      ERRORS=$(echo "${BODY}"   | grep -oP 'Errors:\s*\K[0-9]+'  || echo "0")
      PASSED=$(echo "${BODY}"   | grep -oP 'Passed:\s*\K[0-9]+'  || echo "")
      if [ -z "${PASSED}" ]; then
        echo "TestBox runner returned no results — check http://localhost:8888/testbox/system/runners/StreamingRunner.cfm?directory=tests"
        exit 1
      fi
      if [ "${FAILURES}" != "0" ] || [ "${ERRORS}" != "0" ]; then
        echo "TestBox: ${FAILURES} failure(s), ${ERRORS} error(s)"
        exit 1
      fi
      echo "TestBox tests pass — 0 failures, 0 errors ✓"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    run: |
      echo "Lesson complete — well done!"

---
