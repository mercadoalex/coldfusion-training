---
kind: challenge

title: Hello CFML
description: |
  Create a CFML page at /opt/coldfusion2025/cfusion/wwwroot/hello.cfm that outputs "Hello, ColdFusion!"
  and the current server date. The page must return HTTP 200 and contain
  the string "Hello, ColdFusion!".


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- beginner

playground:
  name: cf-alex-edcdf975
---

## Task

Create `/opt/coldfusion2025/cfusion/wwwroot/hello.cfm` that:
- Outputs the text `Hello, ColdFusion!`
- Includes the current date using `dateFormat(now(), "long")`
- Returns HTTP 200

## Verify

```bash
curl -s http://localhost:8500/hello.cfm | grep "Hello, ColdFusion!"
```