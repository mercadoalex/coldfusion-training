---
kind: challenge

title: Scope Inspector
description: |
  Create a CFML page that displays all available URL, FORM and SESSION
  scope variables as a JSON object. The page must return HTTP 200 and
  valid JSON.


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

## Task

Create `/opt/coldfusion2025/cfusion/wwwroot/scope-inspector.cfm` that:
- Returns `Content-Type: application/json`
- Outputs a JSON object with keys `url`, `form`, `session`
- Returns HTTP 200

## Verify

```bash
curl -s http://localhost:8500/scope-inspector.cfm | python3 -m json.tool
```