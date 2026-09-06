---
kind: unit

title: CommandBox CLI & Server Management

name: commandbox-cli-server-management-unit-1
---

## What is CommandBox?

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
