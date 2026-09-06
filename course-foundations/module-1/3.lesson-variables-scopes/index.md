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
  verify_scopes_page:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s http://localhost:8500/scopes.cfm)
      if ! echo "${BODY}" | grep -qi "variables\|session\|application"; then
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
      FILE="/opt/coldfusion2025/cfusion/wwwroot/scopes.cfm"
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
      BODY=$(curl -s "http://localhost:8500/scopes.cfm?name=TestUser")
      if ! echo "${BODY}" | grep -qi "TestUser"; then
        echo "URL scope not demonstrated — ?name=TestUser not reflected in output"
        exit 1
      fi
      echo "URL scope is working correctly"
---
