---
kind: unit

title: Performance Tuning & JVM Configuration

name: performance-tuning-jvm-unit-1
---

## JVM heap settings

::image-box
---
:src: __static__/jvm-heap-configuration-v1.png
:alt: Annotated jvm.config file snippet — the line "java.args=-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200" has four callout labels: -Xms512m labelled "Initial heap (minimum)", -Xmx1024m labelled "Maximum heap", -XX:+UseG1GC labelled "Garbage First GC (low latency)", -XX:MaxGCPauseMillis=200 labelled "Target GC pause ≤ 200 ms" — each label is a blue arrow pointing to its flag
:max-width: 860px
---
_`jvm.config` is the single file that controls all JVM tuning for Adobe ColdFusion — restart required after any change._
::

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

::image-box
---
:src: __static__/cf-template-cache-warm-cold-v1.png
:alt: Two-path diagram for template execution — left path labelled "Cold request (first hit)" shows browser request → CFML file on disk → CFML compiler → Java bytecode → JVM execution → response, with a side arrow "bytecode cached"; right path labelled "Warm request (cached)" shows browser request → bytecode cache → JVM execution → response, skipping the compiler entirely — warm path is highlighted in green with "⚡ faster" annotation
:max-width: 860px
---
_ColdFusion's template cache eliminates recompilation on repeated requests — the JVM runs bytecode, not source._
::

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

## Activity 1 — Inspect jvm.config

ColdFusion's JVM settings live in a single file. Check that it exists and see its current heap settings:

```bash
# Confirm the file exists
ls /opt/coldfusion2025/cfusion/bin/jvm.config

# Show the current heap flags
grep -i "xms\|xmx\|GC" /opt/coldfusion2025/cfusion/bin/jvm.config
```

::hint-box
---
:summary: 💡 Can I change the heap size in this lab?
---

Yes — but restart is required and the lab VM has limited RAM (~512 MB RSS in use). Do not set `-Xmx` higher than `512m` in this environment or ColdFusion will fail to restart.

On a production server with 8–16 GB RAM, a typical setting is:

```bash
java.args=-Xms512m -Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

Edit the file with: `sudo nano /opt/coldfusion2025/cfusion/bin/jvm.config`
::

::simple-task
---
:tasks: tasks
:name: verify_jvm_config
---
#active
Confirm `/opt/coldfusion2025/cfusion/bin/jvm.config` exists.

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

---

## Activity 2 — Measure response time

Measure how long ColdFusion takes to respond to a request — it must be under 2000 ms:

```bash
curl -s -w "\nHTTP %{http_code} — Total: %{time_total}s\n" -o /dev/null http://localhost:8500/index.cfm
```

Run it a few times — the first request is always slower (template compilation). Subsequent requests run from the bytecode cache and should be significantly faster.

::hint-box
---
:summary: 💡 Why is the first request always slower?
---

ColdFusion compiles `.cfm` files to Java bytecode on the **first request** — this takes extra time. The bytecode is then cached so subsequent requests skip the compilation step entirely and run much faster.

This is the **template cache** in action. In production you warm the cache at deploy time (by hitting all your key pages) so real users never see the compilation delay.

You can increase the cache size in CF Admin → **Server Settings → Caching → Maximum Number of Cached Templates**.
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

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete — on to CI/CD! 🚀
::

::remark-box
Found a bug or an issue with this lesson? Please reach out — your feedback helps improve the course for everyone.

📧 Alex — mercadoalex[at]gmail.com
::
