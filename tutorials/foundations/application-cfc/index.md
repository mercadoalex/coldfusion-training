---
kind: tutorial

title: Building Application.cfc from Scratch

description: |
  Create a complete Application.cfc with lifecycle methods,
  session management, and a global error handler.

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
---

## Steps

### 1. Create Application.cfc

Create `/opt/coldfusion2025/cfusion/wwwroot/Application.cfc`:

```cfml
component {
  this.name              = "HelpDeskApp";
  this.sessionManagement = true;
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);
  this.datasource        = "training_db";

  public boolean function onApplicationStart() {
    application.startTime = now();
    application.version   = "1.0.0";
    return true;
  }

  public boolean function onSessionStart() {
    session.userId   = 0;
    session.loggedIn = false;
    return true;
  }

  public boolean function onRequestStart(string targetPage) {
    // Global request setup — add auth checks here later
    return true;
  }

  public void function onError(any exception, string eventName) {
    cfheader(name="Content-Type", value="application/json");
    writeOutput(serializeJSON({
      error:   exception.message,
      detail:  exception.detail,
      event:   arguments.eventName
    }));
  }
}
```

### 2. Verify it loads

```bash
curl -s http://localhost:8500/index.cfm
```

A 200 response confirms Application.cfc was parsed without errors.

### 3. Check the application scope

Create a quick debug page to confirm `onApplicationStart` ran:

```cfml
<!--- debug_app.cfm --->
<cfoutput>
  Started: #application.startTime#<br>
  Version: #application.version#
</cfoutput>
```

```bash
curl -s http://localhost:8500/debug_app.cfm
```
