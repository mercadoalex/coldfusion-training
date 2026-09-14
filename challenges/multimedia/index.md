---
kind: challenge

title: Unit 1 Challenge — ColdFusion Foundations

description: |
  Put everything from Unit 1 together. Build a self-contained ColdFusion
  application that combines CFML syntax, variables and scopes, the application
  lifecycle, OOP with CFCs, HTML5 integration, and multimedia handling.

categories:
- programming

tagz:
- coldfusion
- cfml
- oop
- html5
- multimedia

difficulty: medium

createdAt: 2026-09-03
updatedAt: 2026-09-03

playground:
  name: cf-alex-edcdf975

tasks:
  verify_app_cfc:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/Application.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "Application.cfc not found in unit1challenge/"
        exit 1
      fi
      if ! grep -qi "this.name" "${FILE}" 2>/dev/null; then
        echo "Application.cfc is missing this.name"
        exit 1
      fi
      echo "Application.cfc found with this.name set"

  verify_portfolio_cfc:
    machine: dev-machine
    user: laborant
    needs:
      - verify_app_cfc
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/PortfolioService.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "PortfolioService.cfc not found"
        exit 1
      fi
      if ! grep -qi "component" "${FILE}" 2>/dev/null; then
        echo "PortfolioService.cfc is missing component declaration"
        exit 1
      fi
      COUNT=$(grep -ci "function" "${FILE}")
      if [ "${COUNT}" -lt 2 ]; then
        echo "PortfolioService.cfc needs at least 2 functions (got ${COUNT})"
        exit 1
      fi
      echo "PortfolioService.cfc found with ${COUNT} functions"

  verify_index_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_portfolio_cfc
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/unit1challenge/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "unit1challenge/index.cfm not accessible (got ${STATUS})"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/unit1challenge/index.cfm)
      if ! echo "${BODY}" | grep -qi "<!DOCTYPE html>"; then
        echo "index.cfm is missing HTML5 doctype"
        exit 1
      fi
      echo "index.cfm is accessible and has HTML5 doctype"

  verify_dynamic_output:
    machine: dev-machine
    user: laborant
    needs:
      - verify_index_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/index.cfm"
      if ! grep -qi "cfoutput\|writeOutput\|new PortfolioService\|createObject" "${FILE}" 2>/dev/null; then
        echo "index.cfm does not use PortfolioService or produce dynamic output"
        exit 1
      fi
      echo "index.cfm uses dynamic CFML output"

  verify_html5_media:
    machine: dev-machine
    user: laborant
    needs:
      - verify_dynamic_output
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/index.cfm"
      if ! grep -qi "<video\|<audio\|type=\"email\"\|type=\"date\"" "${FILE}" 2>/dev/null; then
        echo "index.cfm is missing an HTML5 media element or form input type"
        exit 1
      fi
      echo "HTML5 media or form input type found"

  verify_session_or_application_scope:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_media
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/Application.cfc"
      if ! grep -qi "session\|application\|onSessionStart\|onApplicationStart" "${FILE}" 2>/dev/null; then
        echo "Application.cfc does not use session or application scope"
        exit 1
      fi
      echo "Application lifecycle scope usage confirmed"

---

## Unit 1 Challenge — Build a ColdFusion Portfolio Page

You have completed all seven lessons of Unit 1. Now bring it all together.

### Your mission

Build a small self-contained ColdFusion application inside the directory `/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/`. It must include all of the following:

---

### 1. Application lifecycle — `Application.cfc`

Create `Application.cfc` that:
- Sets `this.name` to `"Unit1Challenge"`
- Uses `onApplicationStart()` to store a launch timestamp in the `application` scope
- Uses `onSessionStart()` to initialise a visit counter in the `session` scope

---

### 2. OOP — `PortfolioService.cfc`

Create a CFC with at least:
- A constructor `init()` that stores your name in `variables` scope
- A `getProjects()` method that returns an array of structs, each with `title`, `description`, and `type` keys (use hardcoded data — no database needed)
- A `getSummary()` method that returns a one-line string using Java's `StringBuilder` via `createObject("java", "java.lang.StringBuilder")`

---

### 3. Main page — `index.cfm`

Create an HTML5 page (`<!DOCTYPE html>`) that:
- Instantiates `PortfolioService` and calls both methods
- Renders the projects list dynamically with `<cfoutput>` and `encodeForHTML()`
- Embeds the projects array as JSON into a JavaScript variable using `serializeJSON()`
- Includes at least one HTML5 element — either a `<video>` or `<audio>` player, or a form with `type="email"` or `type="date"` inputs
- Displays the application launch time and session visit count from their respective scopes

---

### Verify your work

```bash
curl -s http://localhost:8500/unit1challenge/index.cfm | head -30
```

::simple-task
---
:tasks: tasks
:name: verify_app_cfc
---
#active
Waiting for `Application.cfc` with `this.name` set in `unit1challenge/`...

#completed
`Application.cfc` exists with `this.name`. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_portfolio_cfc
---
#active
Waiting for `PortfolioService.cfc` with at least 2 functions...

#completed
`PortfolioService.cfc` exists with the required functions. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_index_page
---
#active
Waiting for `index.cfm` to return HTTP 200 with an HTML5 doctype...

#completed
`index.cfm` is accessible and has an HTML5 doctype. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_dynamic_output
---
#active
Checking that `index.cfm` uses `PortfolioService` for dynamic output...

#completed
`index.cfm` uses dynamic CFML output. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_html5_media
---
#active
Checking for an HTML5 media element or form input type in `index.cfm`...

#completed
HTML5 media or form input type found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_session_or_application_scope
---
#active
Checking that `Application.cfc` uses session or application scope...

#completed
Application lifecycle scope usage confirmed. All six checks passed — challenge complete! ✓
::
