---
kind: unit

title: CommandBox CLI & Server Management

name: commandbox-cli-server-management-unit-1
---

## What is CommandBox?

CommandBox is the **package manager, CLI, and embedded server** for the CFML ecosystem. Think of it as `npm` + `node` for ColdFusion — one tool that installs ForgeBox packages, manages Lucee/Adobe CF server instances, runs test suites, and provides a CFML REPL, all from the terminal.

::image-box
---
:src: __static__/commandbox-ecosystem-overview-v1.png
:alt: Diagram showing CommandBox at the centre of three connected roles — on the left "Package Manager" pointing to ForgeBox with label "install cbvalidation, testbox, coldbox"; on the right "Server Manager" pointing to Lucee and Adobe CF logos with label "box server start"; below "CLI and REPL" with a terminal icon and label "box run-script, box testbox run" — all three arrows meet at the central CommandBox logo
:max-width: 860px
---
_CommandBox is package manager + embedded server + CLI in one tool — the `npm` + `node` of the CFML world._
::

In this lab environment, `box` is already on the PATH and a Lucee 7 server is running on port **8888** via a systemd service. You do not need to install or start anything — CommandBox is ready to use.

---

## The `box` command

Everything in CommandBox goes through the `box` command. You can run single commands inline or drop into the interactive shell:

```bash
# Run a single command inline
box version
box server list

# Drop into the interactive CommandBox shell (exit with 'exit')
box
```

::hint-box
---
:summary: Running box commands — inline vs interactive shell
---

**Inline** (`box <command>`) — runs one command and returns to the system shell. Best for scripting and quick lookups.

**Interactive shell** (`box` with no arguments) — drops you into a persistent CommandBox prompt with tab-completion, command history, and coloured output. Type `exit` or press `Ctrl+D` to leave.

In this lesson all commands are shown in inline form so they work directly in the terminal without entering and exiting the shell.

::

---

## Server management

```bash
# Check the status of running servers
box server list

# Start a server (picks up server.json if present)
box server start

# Start with explicit options — engine, port, no browser
box server start cfengine=lucee@7.0.4.34 port=8888 openbrowser=false

# Stop a named server
box server stop name=hungry-minds-training

# Get detailed info about a running server
box server info
```

---

## `server.json` — server configuration file

Persist server settings in a `server.json` file at the project root so any developer starts an identical server with just `box server start`:

```json
{
  "name": "hungry-minds-training",
  "web": {
    "http": { "port": 8888 }
  },
  "app": {
    "cfengine": "lucee@7.0.4.34",
    "webroot": "/home/laborant/app"
  }
}
```

::image-box
---
:src: __static__/commandbox-server-json-anatomy-v1.png
:alt: Annotated JSON snippet of a server.json file — the "name" field is labelled "human-readable server label", "web.http.port" is labelled "port to listen on", "app.cfengine" is labelled "engine and version pin lucee@7.0.4.34", and "app.webroot" is labelled "path to serve files from" — each label connected to its JSON key by a coloured callout line
:max-width: 860px
---
_`server.json` pins the engine version and port — reproducible server config checked into source control._
::

---

## `box.json` — project package descriptor

`box.json` is CommandBox's equivalent of `package.json` — it describes your project and its dependencies:

```json
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "dependencies": {
    "testbox": "^5.0.0",
    "cbvalidation": "^4.0.0"
  }
}
```

Run `box install` to install all declared dependencies into `{webroot}/modules/`.

::details-box
---
:summary: ForgeBox — the CFML package registry
---

**ForgeBox** ([forgebox.io](https://forgebox.io)) is the public package registry for the CFML ecosystem — the equivalent of npm for JavaScript or Packagist for PHP. CommandBox is the client that installs packages from ForgeBox.

**What lives on ForgeBox:**

| Category | Examples |
|---|---|
| Testing | TestBox, MockBox |
| Validation | cbvalidation |
| MVC frameworks | ColdBox, FW/1 |
| ORM / data | cborm, Quick ORM |
| Security | cbsecurity, BCrypt |
| Utilities | cfcollection, Hyper (HTTP client) |

**Installing packages:**

```bash
# Install latest version
box install testbox

# Install specific version
box install coldbox@6.9.0

# Install and save to box.json dependencies
box install cbvalidation --saveDev

# List installed packages
box list
```

Packages install into `{webroot}/modules/` by default. The `box.json` file tracks what is installed so teammates can run `box install` to reproduce the same environment.

**ForgeBox vs Maven/npm:**
ForgeBox is smaller than npm (thousands of packages vs millions) but covers the CFML ecosystem well. Adobe ColdFusion does not use ForgeBox directly — it is primarily the Lucee/ColdBox community ecosystem. However, CommandBox can also manage Adobe CF server installs using the `adobe` engine identifier (`cfengine=adobe@2025`).

::

::hint-box
---
:summary: Most commonly used ForgeBox packages — what they do
---

| Package | What it does |
|---|---|
| **TestBox** | BDD/TDD testing framework — the standard way to write unit and integration tests in CFML |
| **MockBox** | Mocking library — creates mock objects and stubs for testing |
| **ColdBox** | The most popular MVC framework for ColdFusion/Lucee — routing, interceptors, DI container |
| **cbvalidation** | Validates structs, forms, and model objects with declarative rules |
| **cbsecurity** | Authentication and authorisation framework |
| **cborm** | Enhanced ORM layer on top of ColdFusion's built-in Hibernate ORM |
| **Quick ORM** | ActiveRecord-style ORM — simpler alternative to native CF ORM |
| **Hyper** | HTTP client — makes REST API calls cleanly from CFML |
| **BCrypt** | Password hashing — industry-standard bcrypt implementation for CFML |
| **cfcollection** | Functional collection helpers — `map`, `filter`, `reduce` for queries and arrays |

They install into `{webroot}/modules/` and your app loads them via `Application.cfc` or the ColdBox module system. All are one `box install <name>` away.

::

---

## Activity 1 — Verify CommandBox is installed and check the version

**What you are doing:** Confirm `box` is on the PATH and check its version. In the **Terminal** tab, run:

```bash
box version
```

You should see output like `CommandBox CLI v6.x.x` — the exact version installed in this environment.

Also check what servers CommandBox knows about:

```bash
box server list
```

::image-box
---
:src: __static__/terminal-box-version-v1.png
:alt: Terminal showing the box version command returning CommandBox CLI version number, followed by box server list showing the running Lucee server entry with its name, status, and port
:max-width: 860px
---
_`box version` confirms CommandBox is installed — `box server list` shows the Lucee server already running in this environment._
::

::simple-task
---
:tasks: tasks
:name: verify_box_installed
---
#active
Run `box version` in the Terminal to confirm CommandBox is installed and on the PATH.

#completed
CommandBox (`box`) is installed. ✓
::

---

## Activity 2 — Confirm the Lucee server is running on port 8888

**What you are doing:** The Lucee 7 server started by CommandBox is already running on port **8888** via a systemd service. Confirm it is responding correctly.

In the **Terminal** tab, run:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8888/index.cfm
```

You should see **HTTP 200**. Then open the **Lucee Dev Server** browser tab to see the running application.

Also check the server status from CommandBox:

```bash
box server info
```

::image-box
---
:src: __static__/terminal-lucee-server-running-v1.png
:alt: Terminal showing the curl command returning HTTP 200 for localhost port 8888, followed by box server info output showing the server name, engine version, port, and status as running
:max-width: 860px
---
_HTTP 200 on port 8888 confirms the Lucee server is up — `box server info` shows the engine version and webroot._
::

::simple-task
---
:tasks: tasks
:name: verify_server_running
---
#active
Run `curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8888/index.cfm` in the Terminal. Confirm it returns HTTP 200.

#completed
Lucee server is running on port 8888. ✓
::

---

## Activity 3 — Initialise the project with `box.json`

**What you are doing:** Create a `box.json` file in the app directory to register it as a CommandBox project. This is the equivalent of `npm init` — it records the project name, version, and any dependencies.

**File to create:** `/home/laborant/app/box.json`

In the **Terminal** tab, run:

```bash
sudo tee /home/laborant/app/box.json << 'EOF'
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "author": "Hungry Minds Training",
  "description": "ColdFusion 2025 Foundations — Help Desk training application",
  "dependencies": {}
}
EOF
```

Verify the file was created:

```bash
cat /home/laborant/app/box.json
```

::image-box
---
:src: __static__/terminal-box-json-created-v1.png
:alt: Terminal showing the sudo tee command writing box.json, followed by cat displaying its contents — name helpdesk-app, version 1.0.0, author Hungry Minds Training, description, and empty dependencies object
:max-width: 860px
---
_`box.json` initialised — the project is now a CommandBox-managed package with a name, version, and dependency manifest._
::

::simple-task
---
:tasks: tasks
:name: verify_box_json
---
#active
Run the `sudo tee` command above to create `/home/laborant/app/box.json`, then run `cat /home/laborant/app/box.json` to confirm the file exists.

#completed
`box.json` found — CommandBox project is initialised. ✓
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
