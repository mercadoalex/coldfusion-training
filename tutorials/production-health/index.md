---
kind: tutorial

title: Build a Production Health Check Endpoint

description: |
  Create health.cfm that checks the database connection and returns
  JSON with status "ok" or "degraded" and the correct HTTP status code.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- observability

tagz:
- coldfusion
- monitoring
- production

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Create health.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/health.cfm`:

```cfml
<cfscript>
  status   = "ok";
  httpCode = 200;

  try {
    queryExecute("SELECT 1", {}, {datasource: "training_db"});
  } catch (any e) {
    status   = "degraded";
    httpCode = 503;
  }

  cfheader(statuscode=httpCode,
           statustext=(status == "ok" ? "OK" : "Service Unavailable"));
  cfheader(name="Content-Type", value="application/json");

  writeOutput(serializeJSON({
    status:    status,
    timestamp: dateTimeFormat(now(), "iso8601"),
    version:   "1.0.0"
  }));
</cfscript>
```

### 2. Test — healthy state

```bash
curl -s -w "\nHTTP: %{http_code}\n" http://localhost:8500/health.cfm
```

Expected output:
```json
{"STATUS":"ok","TIMESTAMP":"2026-09-03T...","VERSION":"1.0.0"}
```
HTTP: **200**

### 3. Verify JSON is valid

```bash
curl -s http://localhost:8500/health.cfm | python3 -m json.tool
```

### 4. Check the status field

```bash
curl -s http://localhost:8500/health.cfm \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])"
```

Should print **ok**.

### 5. Tail the CF logs

```bash
tail -f /opt/coldfusion2025/cfusion/logs/application.log &
# trigger a few requests
curl -s http://localhost:8500/health.cfm > /dev/null
curl -s http://localhost:8500/health.cfm > /dev/null
```
