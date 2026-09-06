---
kind: unit

title: Introduction to ColdFusion

name: introduction-to-coldfusion-unit-1
---

## What is ColdFusion?

ColdFusion is a **rapid web-application development platform** built around CFML (ColdFusion Markup Language). It lets you query databases, send email, consume web services, and render HTML responses with far less ceremony than most general-purpose languages. A single CFML tag can replace dozens of lines of boilerplate in other languages.

The platform has two layers:

- **CFML** — the language itself: a hybrid of HTML-like tags (`<cfquery>`, `<cfloop>`) and a modern ECMAScript-style scripting block (`<cfscript>`).
- **The CFML engine** — the Java-based runtime that compiles `.cfm`/`.cfc` files to bytecode and executes them inside a servlet container (historically JRun, today Apache Tomcat).

---

## A brief history of CFML

| Year | Milestone |
|------|-----------|
| 1995 | Allaire Corporation ships ColdFusion 1.0 — one of the first server-side web scripting platforms |
| 1999 | Allaire merges with Macromedia; CF gains Flash/Flex integration |
| 2005 | Adobe acquires Macromedia; ColdFusion becomes an Adobe product |
| 2012 | **Railo** (open-source CFML engine) forks into **Lucee** |
| 2016 | Lucee Association Switzerland established; Lucee 5 released |
| 2018 | ColdFusion 2018 ships API Manager and enhanced REST support |
| 2021 | ColdFusion 2021 introduces `cfThread` improvements and PDF services overhaul |
| 2023 | ColdFusion 2023 ships with JVM 21 baseline and enhanced security headers |
| 2025 | **ColdFusion 2025** — current release; Lucee **7.0.x** in parallel |

CFML was one of the web's original "batteries included" platforms. While other stacks require composing separate libraries for database access, file I/O, and HTTP clients, ColdFusion ships all of that in the core runtime. This philosophy still defines it today.

---

## Problems ColdFusion solves

### 1. Database access without boilerplate

In most languages you open a connection, prepare a statement, bind parameters, iterate a result set, and close the connection. In CFML:

```cfml
<cfquery name="users" datasource="myDB">
  SELECT id, name, email FROM users WHERE active = 1
</cfquery>

<cfoutput query="users">
  #users.name# — #users.email#<br>
</cfoutput>
```

The engine manages the connection pool, parameterises the query, and returns a strongly-typed `query` object you can iterate with a single tag.

### 2. File and email operations in one line

```cfml
<!--- Send email --->
<cfmail to="user@example.com" from="app@example.com" subject="Welcome" type="html">
  <p>Your account is ready.</p>
</cfmail>

<!--- Upload a file --->
<cffile action="upload" fileField="myFile" destination="/var/uploads" nameConflict="makeUnique">
```

### 3. HTTP and web-service consumption

```cfml
<cfhttp url="https://api.example.com/data.json" method="GET" result="resp">
  <cfhttpparam type="header" name="Authorization" value="Bearer #token#">
</cfhttp>

<cfset data = deserializeJSON(resp.fileContent)>
```

### 4. Rapid page rendering

ColdFusion pages are compiled to Java bytecode on first request and cached. Subsequent requests hit the bytecode cache directly, giving competitive throughput without a separate compile step during development.

---

## How ColdFusion's architecture works

```
Browser / API client
        │  HTTP
        ▼
  Apache / IIS / Nginx          ← optional reverse proxy
        │  AJP or mod_cfml
        ▼
  Apache Tomcat (servlet container)
        │
        ▼
  CFML Engine (ColdFusion 2025 or Lucee)
  ┌─────────────────────────────────────────┐
  │  Request lifecycle                      │
  │  1. Parse .cfm / .cfc                   │
  │  2. Compile → Java bytecode (cached)    │
  │  3. Execute in sandbox                  │
  │  4. Datasource pool  ──► JDBC ──► DB    │
  │  5. Cache tier (ehcache / Redis)        │
  │  6. Write response buffer               │
  └─────────────────────────────────────────┘
        │
        ▼
  HTML / JSON / binary response
```

Key architectural points:

- **Everything runs on the JVM.** You can call any Java class from CFML, use Java libraries on the classpath, and read JVM metrics with standard tools.
- **Datasources** are named connection pools configured in the CF Admin or via `Application.cfc`. Pages reference them by name, not by connection string.
- **Application scope** is shared across all requests within one application context, making in-memory caching trivial.
- **The web root** is a folder watched by the engine; dropping a `.cfm` file there makes it immediately accessible with no restart or deploy step.

---

## Adobe ColdFusion vs. Lucee

Both engines execute the same CFML language core, but they differ in licensing, extension model, and some built-in capabilities.

| Feature | Adobe ColdFusion 2025 | Lucee 7 |
|---|---|---|
| **License** | Commercial (Developer Edition free, production licensed) | Open source (LGPL) |
| **Servlet container** | Bundled Tomcat | Any container; CommandBox bundles its own |
| **Admin console** | `/CFIDE/administrator` | `/lucee/admin/` |
| **PDF generation** | Native (`<cfdocument>`) | Via extension (PDF extension required) |
| **ORM** | Hibernate (built-in) | Hibernate (built-in) |
| **Language extensions** | Adobe-only tags (e.g., `<cfpresentation>`) | Lucee-only features (e.g., `systemOutput()`) |
| **Script-first style** | Both tag and script equally supported | Script-first recommended |
| **Cold start speed** | Moderate (~30 s typical) | Fast (~5–10 s with CommandBox) |
| **Community** | Adobe forums, Adobe docs | Lucee community, CommandBox ecosystem |

- **Greenfield projects** can use either. Lucee + CommandBox is popular for local development because of fast cold starts and zero licensing cost.
- **Enterprise Adobe shops** use CF for support contracts, CF Admin policies, and built-in PDF/Office features.
- **This course** uses both: Adobe ColdFusion 2025 on port **8500** is the primary engine; Lucee 7 on port **8888** lets you verify cross-engine compatibility.

---

## Your lab environment

Your lab microVM is pre-configured with both engines running:

| Service | Port | Web root |
|---|---|---|
| Adobe ColdFusion 2025 | `8500` | `/opt/coldfusion2025/cfusion/wwwroot/` |
| CommandBox + Lucee 7.0 | `8888` | `/home/laborant/app/` |
| VS Code (code-server) | IDE tab | Opens the webroot of ColdFusion 2025 |

> **Tip:** Files you create in VS Code land directly in the CF 2025 webroot. Open a Terminal inside VS Code to also write to the Lucee webroot.

---

## Verify services

Open the **Terminal** tab in your lab and run each command. A `200` status code confirms the service is ready.

```bash
# Verify Adobe ColdFusion 2025 (should return HTTP 200)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8500/index.cfm

# Verify Lucee via CommandBox (should return HTTP 200)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8888/index.cfm
```

### Create and test your first ColdFusion page

1. In VS Code, create a file called `hello.cfm` in the webroot.
2. Add this content:

```cfml
<cfset greeting = "Hello from ColdFusion 2025!">
<cfoutput>#greeting#</cfoutput>
```

3. Verify it through the engine:

```bash
curl -s http://localhost:8500/hello.cfm
# Expected output: Hello from ColdFusion 2025!
```

If you see the greeting text (not the raw CFML source), the engine compiled and executed your file correctly.

---

## Key concepts reference

| Term | Meaning |
|---|---|
| **CFML** | ColdFusion Markup Language — tag + script hybrid |
| **CFM** | ColdFusion page file (`.cfm`) — renders a response |
| **CFC** | ColdFusion Component (`.cfc`) — reusable class or service |
| **Application.cfc** | Framework entry point; defines app name, scope timeouts, lifecycle hooks |
| **Datasource** | Named JDBC connection pool configured in CF Admin or `Application.cfc` |
| **CF Admin** | Web-based admin console at `/CFIDE/administrator` (Adobe) |
| **CommandBox** | CLI + embedded server tool for Lucee; analogous to Node's `npm` + `node` |
| **cfscript** | Block tag (`<cfscript>...</cfscript>`) that enables ECMAScript-style syntax |
| **Scope** | Named variable namespace (e.g., `variables`, `session`, `application`, `request`) |

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_cf_running
---
#active
Waiting for Adobe ColdFusion 2025 to respond on port 8500...

#completed
ColdFusion 2025 is running on port 8500. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_lucee_running
---
#active
Waiting for Lucee / CommandBox to respond on port 8888...

#completed
Lucee is running on port 8888. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_hello_cfm
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/hello.cfm` that outputs a greeting containing the word **hello**.

#completed
`hello.cfm` exists and returns a greeting. ✓
::
