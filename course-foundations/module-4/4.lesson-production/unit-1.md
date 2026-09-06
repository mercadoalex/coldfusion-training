---
kind: unit

title: Production Readiness & Monitoring

name: production-readiness-monitoring-unit-1
---

## Health check endpoint

::image-box
---
:src: __static__/cf-health-endpoint-flow-v1.png
:alt: Flowchart for the health.cfm endpoint — starting box "GET /health.cfm"; two branches: left "try queryExecute('SELECT 1')" succeeds → status='ok', HTTP 200 → JSON {"status":"ok","timestamp":"..."}; right "catch (any e)" fires → status='degraded', HTTP 503 → JSON {"status":"degraded","timestamp":"..."} — both branches end at "write JSON response" box labelled "Content-Type: application/json"
:max-width: 760px
---
_health.cfm tests the DB on every request and returns 200/503 — used by load balancers and container probes._
::

Every production ColdFusion application should expose a `/health.cfm` endpoint that:
1. Tests the database connection
2. Returns JSON with a `status` field (`"ok"` or `"degraded"`)
3. Returns HTTP 200 when healthy, 503 when degraded

```cfml
<!--- health.cfm --->
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

Test it:

```bash
curl -s -w "\nHTTP: %{http_code}\n" http://localhost:8500/health.cfm
```

---

## Log aggregation

ColdFusion writes logs to `/opt/coldfusion2025/cfusion/logs/`. Tail the application log:

```bash
tail -f /opt/coldfusion2025/cfusion/logs/app.log
```

Key log files:

| File | Contents |
|---|---|
| `application.log` | Unhandled CF errors |
| `scheduler.log` | cfschedule task results |
| `exception.log` | Java-level exceptions |
| `mail.log` | cfmail send/fail events |
| `server.log` | CF server start/stop events |

---

## Monitoring with CF Server Monitor

Browse to `http://localhost:8500/CFIDE/administrator` and go to **Server Monitor**:

- **Active requests** — see currently executing pages
- **Memory usage** — heap, non-heap
- **Datasource connections** — pool utilisation
- **Average response time** — per-template breakdown

---

## Readiness vs liveness probes

::image-box
---
:src: __static__/blue-green-deployment-v1.png
:alt: Blue/green deployment diagram showing five numbered steps — 1. Build new image tagged :green; 2. Start :green container alongside running :blue container; 3. Run health checks on :green (GET /health.cfm → 200); 4. Switch load balancer from :blue to :green; 5. Drain and stop :blue — a load balancer rectangle sits between two server boxes (:blue on the left fading out, :green on the right becoming active) with a traffic arrow switching from blue to green
:max-width: 860px
---
_Blue/green deployment: run both versions simultaneously, flip traffic only after health checks pass, then retire the old version._
::


In container environments (Docker, Kubernetes):

| Probe | Purpose | Check |
|---|---|---|
| **Liveness** | Is the process alive? | HTTP 200 from `/health.cfm` |
| **Readiness** | Is the app ready to serve? | DB connection + cache warm |

---

## Blue/green deployment pattern

1. Build new image → tag as `:green`
2. Start a `:green` container alongside `:blue`
3. Run health checks on `:green`
4. Switch the load balancer to `:green`
5. Drain and stop `:blue`

This gives zero-downtime deploys with instant rollback.

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/health.cfm` using the template above.
2. Verify it returns valid JSON:

```bash
curl -s http://localhost:8500/health.cfm | python3 -m json.tool
```

3. Confirm the `status` field is `"ok"`:

```bash
curl -s http://localhost:8500/health.cfm \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])"
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_health_endpoint
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/health.cfm` — must return valid JSON.

#completed
`health.cfm` returns valid JSON. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_health_status
---
#active
The JSON response must contain a `status` field set to `"ok"` or `"degraded"`.

#completed
Health status is `ok` or `degraded`. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_health_http_code
---
#active
`health.cfm` must return HTTP 200 (healthy) or HTTP 503 (degraded).

#completed
Health endpoint returns the correct HTTP status code. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.health-endpoint-f082760a
---
::
