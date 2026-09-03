---
kind: lesson

title: CommandBox CLI & Server Management
description: |
  Master the CommandBox CLI to start, stop, configure and package
  ColdFusion/Lucee applications without the Adobe CF Administrator.

name: commandbox-cli-server-management
slug: commandbox-cli-server-management

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- commandbox
- lucee

playground:
  name: cf-alex-edcdf975

tasks:
  verify_box_installed:
    machine: dev-machine
    user: laborant
    run: |
      if ! command -v box &>/dev/null; then
        echo "CommandBox (box) is not installed or not in PATH"
        exit 1
      fi
      echo "CommandBox is installed: $(box version)"

  verify_server_running:
    machine: dev-machine
    user: laborant
    needs:
      - verify_box_installed
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "CommandBox server is not running on port 8888 (got ${STATUS})"
        exit 1
      fi
      echo "CommandBox server is running on port 8888"

  verify_box_json:
    machine: dev-machine
    user: laborant
    needs:
      - verify_server_running
    run: |
      if [ ! -f "/home/laborant/app/box.json" ] && [ ! -f "/home/laborant/app/box.json" ]; then
        echo "box.json not found — project not initialized with CommandBox"
        exit 1
      fi
      echo "box.json found — CommandBox project is initialized"
---

## Basic commands

```bash
# start the default Lucee server on port 8888
box server start

# start with specific engine and port
box server start cfengine=lucee@7.0.4.34 port=8888 openbrowser=false

# check status
box server info

# stop server
box server stop

# list running servers
box server list
```

## server.json — server configuration file

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

## Install packages

```bash
box install cbvalidation
box install coldbox@6.9.0
box list
```
