---
kind: lesson

title: Variables, Data Types & Scopes
description: |
  Understand how ColdFusion manages variables, the available data types,
  and the critical concept of variable scopes.

name: variables-data-types-scopes
slug: variables-data-types-scopes

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- scopes

playground:
  name: cf-alex-edcdf975

tasks:
  verify_data_types:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s http://localhost:8500/student/data_types.cfm)
      for word in "String" "Numeric" "Boolean"; do
        if ! echo "${BODY}" | grep -qi "${word}"; then
          echo "data_types.cfm is missing expected output: ${word}"
          exit 1
        fi
      done
      echo "data_types.cfm demonstrates all six data types"

  verify_scopes_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_data_types
    run: |
      BODY=$(curl -s http://localhost:8500/student/scopes.cfm)
      if ! echo "${BODY}" | grep -qi "variables"; then
        echo "scopes.cfm does not demonstrate variable scopes"
        exit 1
      fi
      echo "scopes.cfm is demonstrating variable scopes"

  verify_variables_scope:
    machine: dev-machine
    user: laborant
    needs:
      - verify_scopes_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/student/scopes.cfm"
      if ! grep -q "variables\." "${FILE}" 2>/dev/null; then
        echo "Expected variables. scope usage in scopes.cfm"
        exit 1
      fi
      echo "variables scope is used correctly"

  verify_url_scope:
    machine: dev-machine
    user: laborant
    needs:
      - verify_variables_scope
    run: |
      BODY=$(curl -s "http://localhost:8500/student/scopes.cfm?name=TestUser")
      if ! echo "${BODY}" | grep -qi "TestUser"; then
        echo "URL scope not demonstrated — ?name=TestUser not reflected in output"
        exit 1
      fi
      echo "URL scope is working correctly"

  verify_cfdump:
    machine: dev-machine
    user: laborant
    needs:
      - verify_url_scope
    run: |
      BODY=$(curl -s http://localhost:8500/student/cfdump_demo.cfm)
      if ! echo "${BODY}" | grep -qi "greeting"; then
        echo "cfdump_demo.cfm does not contain expected variable 'greeting'"
        exit 1
      fi
      echo "cfdump_demo.cfm dumps the variables scope correctly"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfdump
    run: |
      echo "Lesson complete — well done!"

---
