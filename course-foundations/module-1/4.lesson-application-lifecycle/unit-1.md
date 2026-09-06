---
kind: unit

title: Application.cfc & Request Lifecycle

name: application-cfc-lifecycle-unit-1
---

## What is Application.cfc?

`Application.cfc` is the framework entry point for every ColdFusion web application. Drop it in the web root and ColdFusion automatically invokes its lifecycle methods at the right moment.

It replaces the older `Application.cfm` approach and gives you a clean OO structure.

::image-box
---
:src: __static__/application-cfc-request-lifecycle-v1.png
:alt: Vertical swimlane diagram with two lanes — left lane "First request" shows boxes for onApplicationStart then onSessionStart then onRequestStart then page execution then onRequestEnd; right lane "Subsequent requests" shows only onRequestStart then page execution then onRequestEnd — dashed arrows show onSessionEnd firing when the session timer expires, and onApplicationEnd firing when the server shuts down
:max-width: 860px
---
_Application.cfc lifecycle: first-request path (left) triggers all startup hooks; subsequent requests skip them._
::

---

## Minimal Application.cfc

```cfml
component {
  this.name              = "MyApp";
  this.sessionManagement = true;
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);  // 30 minutes

  public boolean function onApplicationStart() {
    application.startTime = now();
    return true;
  }

  public boolean function onSessionStart() {
    session.userId = 0;
    return true;
  }

  public boolean function onRequestStart(string targetPage) {
    return true;  // return false to abort the request
  }

  public void function onError(any exception, string eventName) {
    writeOutput("Error: #exception.message#");
  }
}
```

---

## Lifecycle order

Each request triggers a predictable sequence of method calls:

| Step | Method | Fires |
|---|---|---|
| 1 | `onApplicationStart` | Once per application start/restart |
| 2 | `onSessionStart` | Once per new user session |
| 3 | `onRequestStart` | Before every page request |
| 4 | `onRequest` | The actual page (if defined; otherwise CF runs the `.cfm` directly) |
| 5 | `onRequestEnd` | After every page request |
| 6 | `onSessionEnd` | When a session times out |
| 7 | `onApplicationEnd` | When the application shuts down |

::image-box
---
:src: __static__/application-cfc-this-settings-v1.png
:alt: Two-column reference card showing the most important Application.cfc this.* settings — left column shows the setting name (this.name, this.sessionManagement, this.sessionTimeout, this.datasource, this.ormenabled, this.secureJSON) and right column shows a short description and example value for each, laid out as a clean flat table with alternating row shading
:max-width: 860px
---
_Key `this.*` settings in Application.cfc — configure once, effective for every request in the application._
::

---

## Key `this.*` settings

```cfml
component {
  this.name              = "HelpDesk";        // required — unique app identifier
  this.sessionManagement = true;              // enable session scope
  this.sessionTimeout    = createTimeSpan(0,1,0,0);  // 1 hour
  this.clientManagement  = false;
  this.datasource        = "training_db";     // default datasource for cfquery

  // ORM settings (covered in the ORM lesson)
  this.ormenabled        = false;
}
```

---

## onRequestStart as a gatekeeper

A common pattern is to enforce authentication in `onRequestStart`:

```cfml
public boolean function onRequestStart(string targetPage) {
  var publicPages = ["/login.cfm", "/register.cfm"];
  if (!session.userId && !arrayFind(publicPages, arguments.targetPage)) {
    location(url="/login.cfm", addtoken=false);
    return false;
  }
  return true;
}
```

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/Application.cfc` with:
   - `this.name` set to any string
   - an `onApplicationStart` method that writes to the application scope
2. Verify:

```bash
curl -s http://localhost:8500/index.cfm
```

3. Check that `onApplicationStart` fires by inspecting `application.startTime`:

```bash
curl -s http://localhost:8500/debug_app.cfm
# or check with cfdump: <cfdump var="#application#">
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_application_cfc_exists
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/Application.cfc`.

#completed
`Application.cfc` exists in the web root. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_onapplicationstart
---
#active
Add an `onApplicationStart()` method to `Application.cfc`.

#completed
`onApplicationStart` is defined. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_app_name
---
#active
Set `this.name` to a non-empty string in `Application.cfc`.

#completed
Application name (`this.name`) is configured. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.application-lifecycle-a2a4b96b
---
::
