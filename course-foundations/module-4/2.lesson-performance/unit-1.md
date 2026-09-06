---
kind: unit

title: Performance Tuning & JVM Configuration

name: performance-tuning-jvm-unit-1
---

## JVM heap settings

ColdFusion runs on the JVM. The heap size directly controls how much memory CF can use before triggering garbage collection pauses.

Edit `/opt/coldfusion2025/cfusion/bin/jvm.config`:

```bash
java.args=-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

| Flag | Meaning |
|---|---|
| `-Xms512m` | Initial (minimum) heap — 512 MB |
| `-Xmx1024m` | Maximum heap — 1 GB |
| `-XX:+UseG1GC` | Use Garbage First GC (best for low-latency) |
| `-XX:MaxGCPauseMillis=200` | Target GC pause ≤ 200 ms |

After editing, restart ColdFusion:

```bash
sudo systemctl restart cf-server
```

---

## Connection pool tuning

Database connection pools let ColdFusion reuse JDBC connections instead of opening a new one for every request.

1. CF Admin → **Data & Services → Data Sources → training_db → Advanced Settings**
2. Set **Max Connections**: `50`
3. Set **Connection Timeout**: `120` seconds
4. Set **Max Wait Time**: `5000` ms

In high-traffic environments, undersized pools cause requests to queue waiting for a connection, which appears as slow page loads.

---

## Template cache

ColdFusion compiles `.cfm`/`.cfc` files to Java bytecode on first request and caches the bytecode. Once warm, repeated requests run from cache with no recompilation.

Increase the template cache size if you have many templates:

1. CF Admin → **Server Settings → Caching**
2. **Maximum Number of Cached Templates**: increase to `1024` or more

---

## Enable GZIP (nginx front-end)

If you run nginx as a reverse proxy in front of CF, enable GZIP compression:

```nginx
gzip on;
gzip_types text/html application/json application/javascript text/css;
gzip_min_length 1024;
```

GZIP typically reduces HTML/JSON response size by 60–80%.

---

## Measuring response time

```bash
# Time a single request
time curl -s http://localhost:8500/index.cfm > /dev/null

# Or use curl's timing output
curl -s -w "\nTotal: %{time_total}s\n" -o /dev/null http://localhost:8500/index.cfm
```

The task checks that the response is under **2000 ms**.

---

## Exercises

1. Confirm `jvm.config` exists and contains `-Xmx`:

```bash
grep -i "xmx" /opt/coldfusion2025/cfusion/bin/jvm.config
```

2. Measure the CF response time:

```bash
curl -s -w "\nHTTP %{http_code} — %{time_total}s\n" -o /dev/null http://localhost:8500/index.cfm
```

3. Adjust the heap if needed and restart: `sudo systemctl restart cf-server`

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_jvm_config
---
#active
`/opt/coldfusion2025/cfusion/bin/jvm.config` must exist.

#completed
`jvm.config` found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_heap_set
---
#active
`jvm.config` must contain a `-Xmx` heap setting.

#completed
JVM heap (`-Xmx`) is configured. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_response_time
---
#active
ColdFusion must respond to a request on port 8500 in under 2000 ms.

#completed
Response time is within the 2000 ms threshold. ✓
::
