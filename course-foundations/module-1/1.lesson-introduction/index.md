---
kind: lesson

title: Introduction to ColdFusion
description: |
  What ColdFusion is, the problems it solves, and how its architecture works.
  Learn the history of CFML, the difference between Adobe ColdFusion and Lucee,
  and how to verify services in your lab environment.

name: introduction-to-coldfusion
slug: introduction-to-coldfusion

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- lucee

playground:
  name: cf-alex-edcdf975

tasks:
  verify_cf_running:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "ColdFusion 2025 is not responding on port 8500 (got ${STATUS})"
        exit 1
      fi
      echo "ColdFusion 2025 is running"

  verify_lucee_running:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cf_running
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "Lucee/CommandBox is not responding on port 8888 (got ${STATUS})"
        exit 1
      fi
      echo "Lucee via CommandBox is running"

  verify_hello_cfm:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cf_running
    run: |
      BODY=$(curl -s http://localhost:8500/hello.cfm)
      if ! echo "${BODY}" | grep -qi "hello"; then
        echo "hello.cfm does not exist or does not output a greeting"
        exit 1
      fi
      echo "hello.cfm is working correctly"
---

## What is ColdFusion?

ColdFusion is a rapid web-application development platform built around the CFML (ColdFusion Markup Language) scripting language. Originally created by Allaire in 1995, it is now maintained by Adobe (ColdFusion 2025) and available as an open-source alternative via **Lucee**.

## Lab environment

Your lab microVM includes:
- **ColdFusion 2025 Developer Edition** on port **8500**
- **CommandBox + Lucee 7.0.4.34** on port **8888**
- **code-server** (VS Code in browser) for editing CFML files

## Verify services

```bash
# check CF2025
curl -s http://localhost:8500/index.cfm

# check Lucee via CommandBox
curl -s http://localhost:8888/index.cfm

# check code-server
curl -s http://localhost:50061
```

## Key concepts

| Term | Meaning |
|---|---|
| CFML | ColdFusion Markup Language — tag + script hybrid |
| CFM | ColdFusion page file (.cfm) |
| CFC | ColdFusion Component (.cfc) — reusable class |
| Application.cfc | Framework entry point, lifecycle hooks |
| CF Admin | Web-based admin console at /CFIDE/administrator |
