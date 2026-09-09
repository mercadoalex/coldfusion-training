---
kind: tutorial

title: Build a Simple JSON API Endpoint
description: |
  Create a JSON-returning CFML page, test it with curl and confirm
  the Content-Type header is set correctly.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- rest
- json

playground:
  name: cf-alex-edcdf975
---

## Steps

```cfml
<!--- /opt/coldfusion2025/cfusion/wwwroot/api/ping.cfm --->
<cfscript>
  cfheader(name="Content-Type", value="application/json");
  writeOutput(serializeJSON({
    status  : "ok",
    message : "pong",
    ts      : now()
  }));
</cfscript>
```

```bash
# test
curl -i http://localhost:8500/api/ping.cfm
```

Expected output:
```
HTTP/1.1 200 OK
Content-Type: application/json
{"STATUS":"ok","MESSAGE":"pong","TS":"..."}
```