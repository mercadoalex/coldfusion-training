---
kind: challenge

title: Start a CommandBox Server
description: |
  Use CommandBox to start a Lucee server on port 8888 and verify it responds
  to HTTP requests. The server must serve a CFML page from /home/laborant/app.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- commandbox
- lucee
- coldfusion

playground:
  name: cf-alex-edcdf975
---

## Task

1. Start a CommandBox Lucee server on port 8888
2. Create `/home/laborant/app/index.cfm` returning "Lucee OK"
3. Verify HTTP 200 on port 8888

## Verify

```bash
box server list
curl -s http://localhost:8888/ | grep "Lucee OK"
```