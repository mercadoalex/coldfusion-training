---
kind: unit

title: Lucee Server — Configuration & Administration

name: lucee-server-configuration-unit-1
---

## What is Lucee?

Lucee is a **free, open-source CFML engine** — it executes the same ColdFusion Markup Language that Adobe ColdFusion runs, but under a community-maintained open-source project licensed under LGPL. Most CFML code written for Adobe CF runs on Lucee without changes. The differences are in administration, configuration format, and a handful of engine-specific features.

In this lab: **Adobe CF 2025** runs on port **8500**, **Lucee 7** runs on port **8888**. You can switch between them by changing the port in your browser.

::image-box
---
:src: __static__/lucee-vs-adobe-cf-comparison-v1.png
:alt: Two-column comparison card — left column has the Lucee logo and lists open source LGPL, admin at /lucee/admin/, JSON-based CFConfig.json config, fast cold start 5 to 10 seconds, PDF via extension; right column has the Adobe ColdFusion 2025 logo and lists commercial license, admin at /CFIDE/administrator/, XML neo-*.xml config, moderate cold start 30 seconds, native PDF via cfdocument — both columns share a row saying "same CFML language core" highlighted in green at the top
:max-width: 860px
---
_Lucee and Adobe CF share the same CFML language core — the differences are in licensing, admin tooling, and some built-in features._
::

| Feature | Lucee 7 | Adobe CF 2025 |
|---|---|---|
| **License** | Open source (LGPL) — free forever | Commercial — requires paid license |
| **Admin** | CLI via `box cfconfig` — no web UI in Lucee 7 | Web UI at `/CFIDE/administrator/` |
| **Config format** | JSON (`.CFConfig.json`) | XML (`neo-*.xml`) |
| **Cold start speed** | Fast (~5–10 s) | Moderate (~30 s) |
| **PDF generation** | Via extension | Native (`<cfdocument>`) |
| **Null support** | `isNull()` works natively | Requires `fullnullsupport` setting |
| **`systemOutput()`** | Built-in | Use `<cflog>` instead |
| **Managed by** | Lucee Association Switzerland | Adobe Inc. |

::hint-box
---
:summary: What is a cold start — and why is Lucee faster at it?
---

A **cold start** is what happens the very first time a CFML engine boots from zero — loading the JVM, initialising the engine internals, compiling Application.cfc, and making the first request ready to serve. Everything after that is a **warm start** — the engine is already running and requests are handled quickly.

**Why cold start speed matters:**
In traditional always-on servers, cold start happens once and you forget about it. It matters a lot in modern deployments:
- **Containers (Docker/Kubernetes)** — new container instances spin up on demand; a slow cold start means slow scale-out
- **Serverless** — functions start fresh per request in some architectures; a 30-second cold start is unacceptable
- **Local development** — developers restart the server dozens of times a day; 5 seconds vs 30 seconds adds up fast

**Why Lucee is faster than Adobe CF:**

| Reason | Detail |
|---|---|
| **Lighter engine core** | Lucee loads fewer built-in subsystems at startup — no PDF engine, no Flash gateway, no legacy CORBA layer |
| **On-demand loading** | Lucee loads most optional features only when first used, not at startup |
| **Smaller footprint** | Lucee's core JAR is significantly smaller than Adobe CF's — less bytecode to initialise |
| **No setup wizard check** | Adobe CF checks for first-run wizard completion on every boot; Lucee skips this entirely |

In this playground, Lucee typically starts in **5–8 seconds**. Adobe CF 2025 takes **25–35 seconds**. You can observe this by restarting each service and timing how long until HTTP responses return.

::

::details-box
---
:summary: Lucee vs Adobe CF — which should you use?
---

Both engines are production-grade. The choice depends on your context:

**Use Lucee when:**
- You want zero licensing cost — Lucee is free, including for commercial use
- You are building on ColdBox / CommandBox ecosystem — Lucee is the primary target
- You need fast cold starts — important for containerised / serverless deployments
- Your team prefers JSON-based, version-controlled server configuration (`.CFConfig.json`)
- You are building a new project and want community-driven, actively developed engine

**Use Adobe CF when:**
- Your organisation already has Adobe CF licenses and existing applications
- You need native `<cfdocument>` PDF generation without an extension
- You rely on Adobe-specific tags or functions not available in Lucee
- Your client or compliance requirement mandates Adobe support
- You need Adobe's official enterprise support contract

**The practical reality:**
Most modern CFML development targets both. The ColdBox framework and TestBox run identically on both engines. If you write standard CFML without engine-specific features, your code will run on either. Many teams run Lucee in development (free, fast) and Adobe CF in production (for client requirements or legacy reasons).

In this lab you have both — port 8500 for Adobe CF, port 8888 for Lucee. The core CFML exercises work on both.

::

---

## Lucee administration

::hint-box
---
:summary: No web admin UI in Lucee 7 — use the CLI instead
---

Lucee 7 **removed the web-based admin console** (`/lucee/admin/server.cfm`) from its default distribution. This was a deliberate decision — the web UI is a security risk (an admin panel exposed on every server), and modern infrastructure practice treats server config as code, not as something clicked through a browser.

**The correct way to administer Lucee 7 is via the CommandBox CLI:**

```bash
# Show all current server settings
box cfconfig show

# Set a specific value
box cfconfig set adminPassword=training

# Export current config to a portable JSON file
box cfconfig export to=.CFConfig.json

# Apply config from file (use on every environment, in CI/CD)
box cfconfig import from=.CFConfig.json
```

Commit `.CFConfig.json` to git alongside your application code — any developer or pipeline runs `box cfconfig import` and gets an identical server configuration. This is the same "infrastructure as code" principle that Terraform applies to cloud resources, applied to your CFML engine.

::

---

## CFConfig — JSON-based server configuration

::image-box
---
:src: __static__/cfconfig-json-workflow-v1.png
:alt: Three-step workflow diagram — step 1 Author .CFConfig.json shows a code editor with JSON datasources configuration; step 2 Commit to git shows a git commit icon labelled version-controlled server config; step 3 box cfconfig import shows the CommandBox CLI command applying the config to a running Lucee server with a green confirmation message
:max-width: 860px
---
_CFConfig makes server configuration reproducible — commit `.CFConfig.json` to git and import it on every environment._
::

CommandBox ships with the `cfconfig` module that reads and writes Lucee settings as a single JSON file. Instead of clicking through the admin UI, you define your datasources, mail servers, and settings in `.CFConfig.json` and apply it with one command — making server configuration repeatable and version-controlled:

```json
{
  "datasources": {
    "training_db": {
      "type": "H2",
      "database": "/opt/lucee/db/training",
      "username": "sa",
      "password": ""
    }
  },
  "mailServers": [
    {
      "host": "smtp.example.com",
      "port": 587,
      "username": "user@example.com"
    }
  ]
}
```

Apply it to a running server:

```bash
box cfconfig import from=.CFConfig.json
```

::hint-box
---
:summary: Why CFConfig matters — config as code
---

Without CFConfig, Lucee server settings live in XML/JSON files deep inside the engine directory — files you cannot easily diff, review, or reproduce. The first time a new developer sets up the environment they manually recreate datasources through the admin UI and inevitably forget something.

With CFConfig, you commit `.CFConfig.json` to your repository alongside your application code. Any developer — or any CI/CD pipeline — runs `box cfconfig import` and gets an identical server configuration. This is the same "infrastructure as code" principle that Terraform and Ansible apply to servers, applied to your CFML engine settings.

::

---

## Activity 1 — Verify Lucee is running on port 8888

**What you are doing:** Confirm the Lucee server is responding. In the **Terminal** tab, run:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8888/index.cfm
```

You should see:

```
HTTP 200
```

::image-box
---
:src: __static__/terminal-lucee-200-v1.png
:alt: Terminal showing the curl command returning HTTP 200 for localhost port 8888 confirming Lucee is running and serving the application
:max-width: 860px
---
_HTTP 200 on port 8888 — Lucee is running and serving the Help Desk application._
::


::simple-task
---
:tasks: tasks
:name: verify_lucee_running
---
#active
Run `curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8888/index.cfm` in the Terminal. Confirm it returns HTTP 200.

#completed
Lucee is running on port 8888. ✓
::

---

## Activity 2 — Create `lucee_info.cfm` and check the version

**What you are doing:** Create a small CFML page that outputs the Lucee engine version and Java version using the `server` scope — a built-in struct available in every CFML request.

**File to create:** `/home/laborant/app/lucee_info.cfm`

In the **Terminal** tab, run:

```bash
sudo tee /home/laborant/app/lucee_info.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Lucee Info</title>
  <style>
    body { font-family: sans-serif; max-width: 600px; margin: 2rem auto; }
    .box { padding: 1rem; background: #f0f4ff; border-left: 4px solid #3b82d4; margin: 1rem 0; }
  </style>
</head>
<body>
  <h1>Lucee Server Info</h1>
  <cfscript>
    info = {
      luceeVersion : server.lucee.version,
      javaVersion  : server.java.version,
      osName       : server.os.name,
      cfmlEngine   : server.coldfusion.productname
    };
  </cfscript>
  <div class="box">
    <cfoutput>
      <strong>Lucee version:</strong> #info.luceeVersion#<br>
      <strong>Java version:</strong> #info.javaVersion#<br>
      <strong>OS:</strong> #info.osName#<br>
      <strong>CFML engine:</strong> #info.cfmlEngine#
    </cfoutput>
  </div>
</body>
</html>
EOF
```

Verify it from the terminal — this also confirms the CFML was executed (not just served as plain text):

```bash
curl -s http://localhost:8888/lucee_info.cfm | grep -i "lucee\|java\|os"
```

You should see output like:

```
<strong>Lucee version:</strong> 7.0.0.x<br>
<strong>Java version:</strong> 21.0.x<br>
<strong>OS:</strong> Linux<br>
```

::simple-task
---
:tasks: tasks
:name: verify_lucee_version
---
#active
Run the `sudo tee` command above to create `lucee_info.cfm`, then run the `curl` command to confirm the Lucee version appears in the response.

#completed
Lucee version info is accessible. ✓
::

---

## Activity 3 — Register the datasource on Lucee and verify it

**What you are doing:** Lucee and Adobe CF each have their own datasource registry. The cleanest way to make `training_db` available on Lucee — without touching server config files or restarting — is to declare it in `Application.cfc` using `this.datasources`. Lucee reads this on every request, so no restart is needed.

**Step 1 — Add the datasource to `Application.cfc`:**

```bash
sudo tee /home/laborant/app/Application.cfc << 'EOF'
component {
  this.name        = "HelpdeskApp";
  this.datasource  = "training_db";
  this.datasources = {
    "training_db": {
      type:     "H2",
      database: "/opt/coldfusion2025/cfusion/db/training_db",
      username: "sa",
      password: ""
    }
  };
}
EOF
```

**Step 2 — Create a test file and verify the datasource:**

```bash
sudo tee /home/laborant/app/lucee_ds_check.cfm << 'EOF'
<cfscript>
  try {
    q = queryExecute("SELECT COUNT(*) AS total FROM hd_tickets", {}, {datasource: "training_db"});
    writeOutput("OK — hd_tickets row count: " & q.total);
  } catch (any e) {
    writeOutput("ERROR — " & e.message);
  }
</cfscript>
EOF

curl -s http://localhost:8888/lucee_ds_check.cfm
```

You should see:

```
OK — hd_tickets row count: 10
```

::hint-box
---
:summary: 💡 Why does this work without a restart?
---

`Application.cfc` is evaluated on every request — Lucee reads `this.datasources` before executing any page in the application. The datasource exists for the lifetime of that request and any subsequent request in the same application scope. No server-level config file needs to change, and no restart is required.

This is also the recommended pattern for **portable applications**: the datasource definition travels with the code, so any Lucee instance that runs the app automatically has the connection — no manual admin setup on each server.

::

::simple-task
---
:tasks: tasks
:name: verify_lucee_datasource
---
#active
Complete all three steps above. The final `curl` response must start with **OK**.

#completed
Lucee datasource is configured correctly. ✓
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
