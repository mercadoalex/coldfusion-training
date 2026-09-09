---
kind: challenge

title: Application.cfc Lifecycle

description: |
  Create Application.cfc with this.name set, an onApplicationStart method
  that stores the start time in the application scope, and an onSessionStart
  method that initialises session.userId to 0.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- application-cfc

playground:
  name: cf-alex-edcdf975

tasks:
  verify_application_cfc_exists:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "Application.cfc not found"
        exit 1
      fi
      echo "Application.cfc exists"

  verify_this_name:
    machine: dev-machine
    user: laborant
    needs:
      - verify_application_cfc_exists
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if ! grep -q "this.name" "${FILE}"; then
        echo "this.name not set in Application.cfc"
        exit 1
      fi
      echo "this.name is set"

  verify_onapplicationstart:
    machine: dev-machine
    user: laborant
    needs:
      - verify_this_name
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if ! grep -q "onApplicationStart" "${FILE}"; then
        echo "onApplicationStart not found"
        exit 1
      fi
      echo "onApplicationStart is defined"

  verify_onsessionstart:
    machine: dev-machine
    user: laborant
    needs:
      - verify_onapplicationstart
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if ! grep -q "onSessionStart" "${FILE}"; then
        echo "onSessionStart not found"
        exit 1
      fi
      echo "onSessionStart is defined"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/Application.cfc` with:

1. `this.name` set to any non-empty string
2. `this.sessionManagement = true`
3. An `onApplicationStart()` method that stores something in the `application` scope
4. An `onSessionStart()` method that sets `session.userId = 0`

```bash
# Verify it loads cleanly
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/index.cfm
```
