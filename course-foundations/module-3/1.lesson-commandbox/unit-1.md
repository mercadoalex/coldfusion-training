---
kind: unit

title: CommandBox CLI & Server Management

name: commandbox-cli-server-management-unit-1
---

## What is CommandBox?

::image-box
---
:src: __static__/commandbox-ecosystem-overview-v1.png
:alt: Diagram showing CommandBox at the centre of three connected roles — on the left "Package Manager" with an arrow to ForgeBox logo and label "install cbvalidation, testbox, coldbox from forgebox.io"; on the right "Server Manager" with an arrow to Lucee and Adobe CF engine logos and label "box server start"; below "CLI & REPL" with a terminal icon and label "box run-script, box testbox run" — all three arrows meet at the central CommandBox logo
:max-width: 860px
---
_CommandBox is package manager + embedded server + CLI in one tool — the `npm` + `node` of the CFML world._
::

CommandBox is the **package manager, CLI, and embedded server** for the CFML ecosystem. Think of it as `npm` + `node` for ColdFusion. It manages Lucee server instances, installs ForgeBox packages, and runs TestBox test suites — all from the terminal.

In your lab environment, `box` is already on the PATH and Lucee is running on port **8888** via a systemd service.

---

## Basic commands

```bash
# Start the default Lucee server on port 8888
box server start

# Start with a specific engine and port
box server start cfengine=lucee@7.0.4.34 port=8888 openbrowser=false

# Check status
box server info

# Stop server
box server stop

# List running servers
box server list
```

---

## server.json — server configuration file

Persist your server settings in `server.json` at the project root:

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

When `server.json` exists, running `box server start` picks up all settings automatically.

---

## box.json — project metadata

::image-box
---
:src: __static__/commandbox-server-json-anatomy-v1.png
:alt: Annotated JSON snippet showing a server.json file — the "name" field is labelled "human-readable server label", "web.http.port" is labelled "port to listen on", "app.cfengine" is labelled "engine + version pin (e.g. lucee@7.0.4.34)", and "app.webroot" is labelled "path to serve files from" — each label is connected to its JSON key by a coloured callout line
:max-width: 860px
---
_`server.json` pins the engine version and port so any developer or CI environment starts identical servers._
::


`box.json` is the package descriptor (like `package.json` for Node):

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

Run `box install` to install all declared dependencies into the project.

---

## Install packages

```bash
# Install a single package from ForgeBox
box install cbvalidation

# Install a specific version
box install coldbox@6.9.0

# List installed packages
box list
```

Packages land in `{webroot}/modules/` by default.

---

## Useful shortcuts

```bash
# Open the CommandBox REPL
box

# Check CommandBox version
box version

# Update CommandBox itself
box update --system

# Run a one-liner
box "server list --running"
```

---

## Exercises

1. Verify CommandBox is installed:

```bash
box version
```

2. Confirm the Lucee server is running on port 8888:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm
```

3. Check that `box.json` exists at `/home/laborant/app/box.json`:

```bash
cat /home/laborant/app/box.json
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_box_installed
---
#active
Confirm CommandBox is on the PATH: `box version`

#completed
CommandBox (`box`) is installed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_server_running
---
#active
The CommandBox Lucee server must be responding on port 8888.

#completed
CommandBox server is running on port 8888. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_box_json
---
#active
Create `/home/laborant/app/box.json` to initialise the CommandBox project.

#completed
`box.json` found — CommandBox project is initialised. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.commandbox-server-1b054ad4
---
::
