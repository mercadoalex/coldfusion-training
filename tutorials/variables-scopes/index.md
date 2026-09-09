---
kind: tutorial

title: Exploring Variable Scopes

description: |
  Build a single CFML page that reads and writes the variables, url,
  session and application scopes and displays all values on screen.

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
---

## Steps

### 1. Create scopes.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/scopes.cfm`:

```cfml
<cfscript>
  // variables scope — request-local
  variables.greeting = "Hello from variables scope";

  // url scope — read query string
  variables.urlName = url.name ?: "nobody";

  // session scope — persist across requests
  session.visitCount = (session.visitCount ?: 0) + 1;

  // application scope — shared across all requests
  application.siteName = application.siteName ?: "CF Training";
</cfscript>

<cfoutput>
  <p>#variables.greeting#</p>
  <p>URL name param: #encodeForHTML(urlName)#</p>
  <p>Session visits: #session.visitCount#</p>
  <p>App name: #application.siteName#</p>
</cfoutput>
```

### 2. Test with a URL parameter

```bash
curl -s "http://localhost:8500/scopes.cfm?name=TestUser"
```

The output should contain **TestUser**. Hit it again — `visitCount` increments each request.

### 3. Try without the parameter

```bash
curl -s "http://localhost:8500/scopes.cfm"
```

The `urlName` falls back to **nobody** via the Elvis operator `?:`.
