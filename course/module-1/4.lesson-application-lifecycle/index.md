---
kind: lesson

title: Application.cfc & Request Lifecycle
description: |
  Master the Application.cfc framework entry point. Learn lifecycle methods
  onApplicationStart, onSessionStart, onRequestStart, onRequest, onError.

name: application-cfc-lifecycle
slug: application-cfc-lifecycle

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
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
        echo "Application.cfc not found at ${FILE}"
        exit 1
      fi
      echo "Application.cfc exists"

  verify_onapplicationstart:
    machine: dev-machine
    user: laborant
    needs:
      - verify_application_cfc_exists
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if ! grep -q "onApplicationStart" "${FILE}"; then
        echo "onApplicationStart method not found in Application.cfc"
        exit 1
      fi
      echo "onApplicationStart is defined"

  verify_app_name:
    machine: dev-machine
    user: laborant
    needs:
      - verify_onapplicationstart
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if ! grep -q "this.name" "${FILE}"; then
        echo "this.name is not set in Application.cfc"
        exit 1
      fi
      echo "Application name is configured"
---

## Application.cfc skeleton

```cfml
component {
  this.name = "MyApp";
  this.sessionManagement = true;
  this.sessionTimeout = createTimeSpan(0, 0, 30, 0);

  public boolean function onApplicationStart() {
    application.startTime = now();
    return true;
  }

  public boolean function onSessionStart() {
    session.userId = 0;
    return true;
  }

  public boolean function onRequestStart(string targetPage) {
    return true;
  }

  public void function onError(any exception, string eventName) {
    writeOutput("Error: #exception.message#");
  }
}
```

## Lifecycle order

1. `onApplicationStart` — once per app restart
2. `onSessionStart` — once per new user session
3. `onRequestStart` — before every page request
4. `onRequest` — the actual page
5. `onRequestEnd` — after every page request
6. `onSessionEnd` — when session expires
7. `onApplicationEnd` — when app shuts down
