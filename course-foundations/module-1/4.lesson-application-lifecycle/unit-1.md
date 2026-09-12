---
kind: unit

title: Application.cfc & Request Lifecycle

name: application-cfc-lifecycle-unit-1
---

## What is Application.cfc?

`Application.cfc` is the framework entry point for every ColdFusion web application. Drop it in the web root and ColdFusion automatically invokes its lifecycle methods at the right moment — no configuration file, no XML, no registration step.

It replaces the older `Application.cfm` approach and gives you a clean OO structure: one component, one place to configure your entire application.

::image-box
---
:src: __static__/application-cfc-request-lifecycle-v1.png
:alt: Vertical swimlane diagram with two lanes — left lane "First request" shows boxes for onApplicationStart then onSessionStart then onRequestStart then page execution then onRequestEnd; right lane "Subsequent requests" shows only onRequestStart then page execution then onRequestEnd — dashed arrows show onSessionEnd firing when the session timer expires, and onApplicationEnd firing when the server shuts down
:max-width: 860px
---
_Application.cfc lifecycle: first-request path (left) triggers all startup hooks; subsequent requests skip them._
::

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

## Activity 1 — Create Application.cfc

**Activity:** Click the **Terminal** tab in your lab. Copy and paste the script below to create a minimal `Application.cfc` in the web root:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/Application.cfc << 'EOF'
component {

  this.name              = "CFTraining";
  this.sessionManagement = true;
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);  // 30 minutes

  public boolean function onApplicationStart() {
    application.startTime = now();
    writeLog(text="Application started at #now()#", file="application");
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
    writeOutput("An error occurred: #exception.message#");
  }

}
EOF
```

Verify it was created:

```bash
ls -lh /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

::image-box
---
:src: __static__/terminal-application-cfc-created-v1.png
:alt: Terminal window showing the sudo tee command output confirming Application.cfc was written, followed by the ls -lh command output showing the file with its size and timestamp in the wwwroot directory
:max-width: 860px
---
_Terminal confirming `Application.cfc` was created in the web root._
::

::simple-task
---
:tasks: tasks
:name: verify_application_cfc_exists
---
#active
Click the **Terminal** tab and run the `sudo tee` command above to create `Application.cfc` in the web root.

#completed
`Application.cfc` exists in the web root. ✓
::

---

## Activity 2 — Verify onApplicationStart fires

The `onApplicationStart` method you just added writes to the application scope and logs to the CF log file. Trigger it by making any request to the engine:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8500/index.cfm
# Expected: 200
```

Now confirm `onApplicationStart` is defined in the file:

```bash
grep "onApplicationStart" /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

::image-box
---
:src: __static__/terminal-onapplicationstart-grep-v1.png
:alt: Terminal window showing the grep command output — one matching line from Application.cfc with the onApplicationStart function signature highlighted, confirming the method is present in the file
:max-width: 860px
---
_`grep` confirms `onApplicationStart` is defined in `Application.cfc`._
::

::simple-task
---
:tasks: tasks
:name: verify_onapplicationstart
---
#active
Confirm `onApplicationStart()` is defined in `Application.cfc` — the file must contain the string `onApplicationStart`.

#completed
`onApplicationStart` is defined. ✓
::

---

## Key `this.*` settings

The `this.*` block at the top of `Application.cfc` configures the entire application before any request is processed:

```cfml
component {
  this.name              = "HelpDesk";             // required — unique app identifier
  this.sessionManagement = true;                   // enable session scope
  this.sessionTimeout    = createTimeSpan(0,1,0,0);  // 1 hour
  this.clientManagement  = false;
  this.datasource        = "training_db";          // default datasource for cfquery

  // ORM settings (covered in the ORM lesson)
  this.ormenabled        = false;
}
```

| Setting | Purpose |
|---|---|
| `this.name` | Unique app identifier — required, determines application scope boundary |
| `this.sessionManagement` | Enables `session.*` scope |
| `this.sessionTimeout` | How long before an idle session expires |
| `this.datasource` | Default datasource — pages can omit `datasource` in `<cfquery>` |
| `this.ormenabled` | Enables Hibernate ORM (covered later) |

## Activity 3 — Verify this.name is set

Your `Application.cfc` already has `this.name = "CFTraining"`. Confirm it:

```bash
grep "this.name" /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
# Expected: this.name = "CFTraining";
```

Then make a request and confirm the app responds without errors:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8500/index.cfm
# Expected: 200
```

Open the **ColdFusion 2025** tab (right-click → Open in New Tab) and browse to your lab root — CF Admin login page appearing means the engine is running with your `Application.cfc` active.

::image-box
---
:src: __static__/browser-cf-admin-app-running-v1.png
:alt: Browser window showing the ColdFusion Administrator login page at the lab root URL, confirming the CF engine is running and Application.cfc is active — the dark login form is centered on the page with a password field and Login button
:max-width: 860px
---
_CF Admin login page confirming the engine is running with `Application.cfc` active._
::

::simple-task
---
:tasks: tasks
:name: verify_app_name
---
#active
Confirm `this.name` is set in `Application.cfc` — the file must contain `this.name`.

#completed
Application name (`this.name`) is configured. ✓
::

---

## onRequestStart as a gatekeeper

A common pattern is to enforce authentication in `onRequestStart`. It runs before every page — making it the ideal place to check whether the user is logged in:

```cfml
public boolean function onRequestStart(string targetPage) {
  var publicPages = ["/login.cfm", "/register.cfm"];
  if (!session.userId && !arrayFind(publicPages, arguments.targetPage)) {
    location(url="/login.cfm", addtoken=false);
    return false;  // abort the request — page will not execute
  }
  return true;
}
```

Returning `false` from `onRequestStart` stops the request entirely — the target page never runs. This is how CF apps enforce login gates without touching every individual page.

::hint-box
---
:summary: How do I restart the application to re-trigger onApplicationStart?
---

`onApplicationStart` only fires once — on the very first request after the engine starts or after the application is explicitly restarted. To force it to re-run during development:

**Option 1 — From CF Admin:**
1. Open CF Admin (right-click the ColdFusion 2025 tab → Open in New Tab)
2. Log in with password `admin`
3. Go to **Server Settings → Memory Variables**
4. Click **Clear Application Scope** next to your app name

**Option 2 — From the Terminal:**
```bash
sudo systemctl restart coldfusion
# Wait ~15 seconds, then:
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8500/index.cfm
```

::

::hint-box
---
:summary: Need to edit Application.cfc? Use vi
---

```bash
vi /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

| Key | What it does |
|---|---|
| `i` | Enter insert mode |
| `Esc` | Back to normal mode |
| `:wq` + Enter | Save and quit |
| `:q!` + Enter | Quit without saving |

::

---

::hint-box
---
:summary: Going further — ColdFusion as a backend for React, Vue, or Angular
---

Once you are comfortable with `Application.cfc` you may wonder how it fits into a modern frontend stack. The short answer: **React owns the UI, ColdFusion owns the data and business logic, and they meet at a JSON API boundary.**

```
Browser (React)                    Server (ColdFusion)
───────────────────                ──────────────────────────────
Components / State                 Application.cfc (session, auth, CORS)
     │                                      │
     │  fetch("/api/tickets")  ────────────►│  TicketService.cfc → cfquery → DB
     │◄────────────────────────  JSON       │  serializeJSON(result)
     │
  renders UI
```

`Application.cfc` becomes your API gateway — handling CORS headers, JWT token validation, and authentication before any endpoint runs. React never touches the database; ColdFusion never touches the DOM.

| Concern | Owner |
|---|---|
| Routes / UI components | React |
| Business rules & validation | ColdFusion CFC |
| Database access | ColdFusion (`cfquery` / ORM) |
| Auth / sessions / CORS | ColdFusion `Application.cfc` |

> **This topic is outside the scope of this Foundations course.** It is covered in depth — including JWT auth, CORS configuration, REST endpoint design, and ColdBox MVC — in the **ColdFusion Advanced Course**.

::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All done? Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete. On to the next one!
::
