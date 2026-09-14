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
| **Admin URL** | `/lucee/admin/` | `/CFIDE/administrator/` |
| **Config format** | JSON (`.CFConfig.json`) | XML (`neo-*.xml`) |
| **Cold start speed** | Fast (~5–10 s) | Moderate (~30 s) |
| **PDF generation** | Via extension | Native (`<cfdocument>`) |
| **Null support** | `isNull()` works natively | Requires `fullnullsupport` setting |
| **`systemOutput()`** | Built-in | Use `<cflog>` instead |
| **Managed by** | Lucee Association Switzerland | Adobe Inc. |

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

## Lucee admin console

Browse to the **Lucee Dev Server** tab (port 8888) and navigate to `/lucee/admin/server.cfm` — or go directly to `http://localhost:8888/lucee/admin/` — to access the Lucee Server Administrator. Default password: `training`.

Key sections in the admin:

| Section | What you do there |
|---|---|
| **Services → Datasource** | Add, edit, verify datasource connections |
| **Services → Mail** | Configure SMTP server for `<cfmail>` |
| **Settings → Performance** | Tune template cache size and request timeouts |
| **Extensions** | Install PDF, S3, image, and other optional extensions |
| **Debug & Log → Logs** | View server, application, and exception logs |

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
box cfconfig import from=.CFConfig.json to=default@lucee7
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

You should see **HTTP 200**. Then open the **Lucee Dev Server** browser tab to confirm the app loads.

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

Open `/lucee_info.cfm` in the **Lucee Dev Server** tab to confirm the version details appear. Also verify from the terminal:

```bash
curl -s http://localhost:8888/lucee_info.cfm | grep -i "lucee"
```

::image-box
---
:src: __static__/browser-lucee-info-v1.png
:alt: Browser showing lucee_info.cfm with a blue info box displaying Lucee version 7.x, Java version, OS name, and CFML engine name — all pulled from the server scope
:max-width: 860px
---
_`lucee_info.cfm` — the `server` scope exposes the engine version, Java version, and OS details at runtime._
::

::simple-task
---
:tasks: tasks
:name: verify_lucee_version
---
#active
Run the `sudo tee` command above to create `lucee_info.cfm`, then open `/lucee_info.cfm` in the Lucee Dev Server tab to confirm the Lucee version appears.

#completed
Lucee version info is accessible. ✓
::

---

## Activity 3 — Verify the datasource works on Lucee

**What you are doing:** The Help Desk app's `verify_ds.cfm` page queries `hd_tickets` through the `training_db` datasource. Running it on the Lucee server (port 8888) confirms that Lucee has the datasource configured and can reach the H2 database — the same database used by Adobe CF on port 8500.

In the **Terminal** tab, run:

```bash
curl -s http://localhost:8888/verify_ds.cfm
```

The response should contain **OK** or a ticket count — no errors or exceptions. Open `/verify_ds.cfm` in the **Lucee Dev Server** tab to see the full output.

::hint-box
---
:summary: Getting a datasource error on Lucee? The datasource may not be configured yet.
---

Lucee and Adobe CF each have their own datasource registry — a datasource defined in the Adobe CF admin is not automatically available in Lucee. If `verify_ds.cfm` throws a datasource error on port 8888, you need to add `training_db` in the Lucee admin.

Open the **Lucee Dev Server** tab, go to `/lucee/admin/server.cfm`, click **Services → Datasource**, and add a new H2 datasource named `training_db` pointing to `/opt/coldfusion2025/cfusion/db/training_db`.

Alternatively, if `Application.cfc` defines the datasource inline using `this.datasource` and a JDBC URL, Lucee will pick it up automatically without any admin configuration.

::

::image-box
---
:src: __static__/browser-lucee-verify-ds-v1.png
:alt: Browser showing verify_ds.cfm running on Lucee port 8888 — the page displays a success message confirming the training_db datasource is reachable and the hd_tickets table contains rows
:max-width: 860px
---
_`verify_ds.cfm` on Lucee port 8888 — the `training_db` datasource is configured and the H2 database is accessible from both engines._
::

::simple-task
---
:tasks: tasks
:name: verify_lucee_datasource
---
#active
Run `curl -s http://localhost:8888/verify_ds.cfm` in the Terminal. The response must not contain errors and must show a successful datasource connection.

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
