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
  setup_directory:
    machine: dev-machine
    user: laborant
    run: |
      sudo mkdir -p /opt/coldfusion2025/cfusion/wwwroot/unit1challenge
      sudo chmod 755 /opt/coldfusion2025/cfusion/wwwroot/unit1challenge
      echo "unit1challenge directory ready"

  verify_app_cfc:
    machine: dev-machine
    user: laborant
    needs:
      - setup_directory
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

Build a self-contained ColdFusion application in `/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/` that combines the lifecycle, OOP, scopes, HTML5, and Java interop you have practised across all seven lessons. You need three files: `Application.cfc`, `PortfolioService.cfc`, and `index.cfm`.

Try each step on your own first. Each step has three levels of help — open them only if you need them.

---

### Step 1 — Open the working directory

The folder `/opt/coldfusion2025/cfusion/wwwroot/unit1challenge/` is created automatically when the challenge loads.

**Terminal tab** — confirm it exists:

```bash
ls -ld /opt/coldfusion2025/cfusion/wwwroot/unit1challenge
```

**IDE tab** — click **File → Open Folder…**, type `/opt/coldfusion2025/cfusion/wwwroot/unit1challenge` and press **Enter**.

---

### Step 2 — Create `Application.cfc`

`Application.cfc` is the lifecycle controller for your app. It must set the application name, enable sessions, and define two lifecycle hooks.

Requirements:
- `this.name` set to any non-empty string
- `this.sessionManagement = true`
- `onApplicationStart()` — store the current timestamp in the `application` scope
- `onSessionStart()` — initialise a visit counter in the `session` scope

::details-box
---
:summary: 👉 Hint — not sure where to start?
---
Revisit **Lesson 4 — Application Lifecycle**. The key things you need:

- `this.name`, `this.sessionManagement`, `this.sessionTimeout` go inside the `component { }` block directly (not inside a function)
- `onApplicationStart()` fires once when the app boots — use `now()` to capture the time
- `onSessionStart()` fires once per new visitor session — initialise `session.visitCount = 0`
- Return type for lifecycle hooks is `void`
::

::details-box
---
:summary: 👉 Skeleton — need the structure?
---
Fill in the blanks:

```cfml
component {
  this.name              = "______";
  this.sessionManagement = ______;
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);

  public void function onApplicationStart() {
    application.______ = ______();   // store current timestamp
  }

  public void function onSessionStart() {
    session.______ = ______;         // initialise counter to zero
  }
}
```
::

::details-box
---
:summary: 👉 Full solution — only open if truly stuck
---
**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/unit1challenge/Application.cfc << 'EOF'
component {
  this.name              = "Unit1Challenge";
  this.sessionManagement = true;
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);

  public void function onApplicationStart() {
    application.launchTime = now();
  }

  public void function onSessionStart() {
    session.visitCount = 0;
  }
}
EOF
```

**IDE tab** — right-click → **New File** → `Application.cfc`:

```cfml
component {
  this.name              = "Unit1Challenge";
  this.sessionManagement = true;
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);

  public void function onApplicationStart() {
    application.launchTime = now();
  }

  public void function onSessionStart() {
    session.visitCount = 0;
  }
}
```
::

---

### Step 3 — Create `PortfolioService.cfc`

A CFC that encapsulates your portfolio data and summary logic.

Requirements:
- Constructor `init(required string authorName)` — stores the author name in `variables` scope
- `getProjects()` — returns an array of at least 2 structs, each with `title`, `description`, and `type` keys (hardcoded data, no database)
- `getSummary()` — returns a string built using Java's `StringBuilder` via `createObject("java", "java.lang.StringBuilder")`

::details-box
---
:summary: 👉 Hint — not sure where to start?
---
Revisit **Lesson 5 — OOP with CFCs** and **the Java interop section**.

- The constructor is always named `init()` in ColdFusion — it must `return this`
- Store constructor arguments in `variables.*` so all methods can access them
- `getProjects()` returns a CFML array literal: `[ {title: "...", ...}, {title: "...", ...} ]`
- For `getSummary()`, call `createObject("java", "java.lang.StringBuilder").init("")` then use `.append()` and `.toString()`
::

::details-box
---
:summary: 👉 Skeleton — need the structure?
---
Fill in the blanks:

```cfml
component {

  public PortfolioService function init(required string authorName) {
    variables.______ = arguments.______;
    return this;
  }

  public array function getProjects() {
    return [
      { title: "______", description: "______", type: "______" },
      { title: "______", description: "______", type: "______" }
    ];
  }

  public string function getSummary() {
    var sb = createObject("java", "______").init("");
    sb.append("Portfolio by ");
    sb.append(variables.______);
    sb.append(" — ");
    sb.append(arrayLen(______()));
    sb.append(" projects");
    return sb.______();
  }

}
```
::

::details-box
---
:summary: 👉 Full solution — only open if truly stuck
---
**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/unit1challenge/PortfolioService.cfc << 'EOF'
component {

  public PortfolioService function init(required string authorName) {
    variables.authorName = arguments.authorName;
    return this;
  }

  public array function getProjects() {
    return [
      { title: "Help Desk App",   description: "Ticket management system in CFML", type: "web"  },
      { title: "REST API",        description: "JSON REST API with cfhttp",         type: "api"  },
      { title: "ORM Entity Demo", description: "Hibernate ORM with Ticket.cfc",     type: "data" }
    ];
  }

  public string function getSummary() {
    var sb = createObject("java", "java.lang.StringBuilder").init("");
    sb.append("Portfolio by ");
    sb.append(variables.authorName);
    sb.append(" — ");
    sb.append(arrayLen(getProjects()));
    sb.append(" projects");
    return sb.toString();
  }

}
EOF
```

**IDE tab** — right-click → **New File** → `PortfolioService.cfc`:

```cfml
component {

  public PortfolioService function init(required string authorName) {
    variables.authorName = arguments.authorName;
    return this;
  }

  public array function getProjects() {
    return [
      { title: "Help Desk App",   description: "Ticket management system in CFML", type: "web"  },
      { title: "REST API",        description: "JSON REST API with cfhttp",         type: "api"  },
      { title: "ORM Entity Demo", description: "Hibernate ORM with Ticket.cfc",     type: "data" }
    ];
  }

  public string function getSummary() {
    var sb = createObject("java", "java.lang.StringBuilder").init("");
    sb.append("Portfolio by ");
    sb.append(variables.authorName);
    sb.append(" — ");
    sb.append(arrayLen(getProjects()));
    sb.append(" projects");
    return sb.toString();
  }

}
```
::

---

### Step 4 — Create `index.cfm`

The main HTML5 page that wires everything together.

Requirements:
- `<!DOCTYPE html>` declaration
- Instantiate `PortfolioService` and call both `getProjects()` and `getSummary()`
- Render the projects list dynamically using `<cfoutput>` and `encodeForHTML()`
- Embed the projects array as JSON into a JavaScript variable using `serializeJSON()`
- Display `application.launchTime` and `session.visitCount` from their scopes
- Include at least one HTML5 element — a `<video>`, `<audio>`, or a form with `type="email"` or `type="date"`

::details-box
---
:summary: 👉 Hint — not sure where to start?
---
Revisit **Lesson 6 — HTML5** and **Lesson 3 — Variables & Scopes**.

- Start with `<!DOCTYPE html>` — the check verifies this exact string
- Instantiate with `new PortfolioService("Your Name")` — pass the author name to the constructor
- Loop over the array with `<cfloop array="#projects#" index="p">` inside a `<cfoutput>` block
- Always wrap dynamic output in `encodeForHTML()` to prevent XSS
- `serializeJSON(projects)` converts the CF array to a JSON string for JavaScript
- Access session/application scopes directly: `session.visitCount`, `application.launchTime`
::

::details-box
---
:summary: 👉 Skeleton — need the structure?
---
Fill in the blanks:

```cfml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>______</title>
</head>
<body>
<cfscript>
  session.visitCount = (structKeyExists(session, "visitCount") ? session.visitCount : 0) + 1;
  svc      = new ______("ColdFusion Student");
  projects = svc.______();
  summary  = svc.______();
</cfscript>

<h1>ColdFusion Portfolio</h1>
<p>
  <cfoutput>
    Summary: #encodeForHTML(______)# &nbsp;·&nbsp;
    Launched: #dateTimeFormat(application.______, "dd-mmm-yyyy HH:nn")# &nbsp;·&nbsp;
    Visits: #session.______#
  </cfoutput>
</p>

<cfoutput>
  <cfloop array="#______#" index="p">
    <div>
      <strong>#encodeForHTML(p.______)#</strong> — #encodeForHTML(p.______)#
    </div>
  </cfloop>
</cfoutput>

<script>
  var projects = <cfoutput>#serializeJSON(______)#</cfoutput>;
</script>

<!-- HTML5 element: <audio>, <video>, or a form with type="email" or type="date" -->
______

</body>
</html>
```
::

::details-box
---
:summary: 👉 Full solution — only open if truly stuck
---
**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/unit1challenge/index.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Unit 1 Challenge — Portfolio</title>
  <style>
    body  { font-family: sans-serif; max-width: 760px; margin: 2rem auto; background: #f8fafc; }
    h1    { color: #1d4ed8; }
    .card { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1rem 1.25rem; margin: .75rem 0; }
    .meta { color: #64748b; font-size: .85rem; margin-bottom: 1.5rem; }
  </style>
</head>
<body>
<cfscript>
  session.visitCount = (structKeyExists(session, "visitCount") ? session.visitCount : 0) + 1;
  svc      = new PortfolioService("ColdFusion Student");
  projects = svc.getProjects();
  summary  = svc.getSummary();
</cfscript>

<h1>ColdFusion Portfolio</h1>
<p class="meta">
  <cfoutput>
    Summary: #encodeForHTML(summary)# &nbsp;·&nbsp;
    Launched: #dateTimeFormat(application.launchTime, "dd-mmm-yyyy HH:nn")# &nbsp;·&nbsp;
    Visits this session: #session.visitCount#
  </cfoutput>
</p>

<cfoutput>
  <cfloop array="#projects#" index="p">
    <div class="card">
      <strong>#encodeForHTML(p.title)#</strong> — #encodeForHTML(p.description)#
      <span style="color:#64748b;font-size:.8rem">[#encodeForHTML(p.type)#]</span>
    </div>
  </cfloop>
</cfoutput>

<script>
  var projects = <cfoutput>#serializeJSON(projects)#</cfoutput>;
  console.log("Projects loaded:", projects);
</script>

<audio controls style="margin-top:1.5rem">
  <source src="https://www.w3schools.com/html/horse.mp3" type="audio/mpeg">
  Your browser does not support the audio element.
</audio>

</body>
</html>
EOF
```

**IDE tab** — right-click → **New File** → `index.cfm`:

```cfml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Unit 1 Challenge — Portfolio</title>
  <style>
    body  { font-family: sans-serif; max-width: 760px; margin: 2rem auto; background: #f8fafc; }
    h1    { color: #1d4ed8; }
    .card { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1rem 1.25rem; margin: .75rem 0; }
    .meta { color: #64748b; font-size: .85rem; margin-bottom: 1.5rem; }
  </style>
</head>
<body>
<cfscript>
  session.visitCount = (structKeyExists(session, "visitCount") ? session.visitCount : 0) + 1;
  svc      = new PortfolioService("ColdFusion Student");
  projects = svc.getProjects();
  summary  = svc.getSummary();
</cfscript>

<h1>ColdFusion Portfolio</h1>
<p class="meta">
  <cfoutput>
    Summary: #encodeForHTML(summary)# &nbsp;·&nbsp;
    Launched: #dateTimeFormat(application.launchTime, "dd-mmm-yyyy HH:nn")# &nbsp;·&nbsp;
    Visits this session: #session.visitCount#
  </cfoutput>
</p>

<cfoutput>
  <cfloop array="#projects#" index="p">
    <div class="card">
      <strong>#encodeForHTML(p.title)#</strong> — #encodeForHTML(p.description)#
      <span style="color:#64748b;font-size:.8rem">[#encodeForHTML(p.type)#]</span>
    </div>
  </cfloop>
</cfoutput>

<script>
  var projects = <cfoutput>#serializeJSON(projects)#</cfoutput>;
  console.log("Projects loaded:", projects);
</script>

<audio controls style="margin-top:1.5rem">
  <source src="https://www.w3schools.com/html/horse.mp3" type="audio/mpeg">
  Your browser does not support the audio element.
</audio>

</body>
</html>
```
::

---

### Verify your work

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/unit1challenge/index.cfm
# Expected: 200
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
