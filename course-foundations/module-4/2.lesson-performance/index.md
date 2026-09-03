---
kind: lesson

title: Performance Tuning & JVM Configuration
description: |
  Tune ColdFusion 2025 and the JVM for production workloads.
  Configure heap size, garbage collection, connection pools,
  and use the built-in server monitor to spot bottlenecks.

name: performance-tuning-jvm
slug: performance-tuning-jvm

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- performance
- jvm

playground:
  name: cf-alex-edcdf975

tasks:
  verify_jvm_config:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/bin/jvm.config"
      if [ ! -f "${FILE}" ]; then
        echo "jvm.config not found at ${FILE}"
        exit 1
      fi
      echo "jvm.config found"

  verify_heap_set:
    machine: dev-machine
    user: laborant
    needs:
      - verify_jvm_config
    run: |
      FILE="/opt/coldfusion2025/cfusion/bin/jvm.config"
      if ! grep -q "\-Xmx" "${FILE}"; then
        echo "-Xmx heap setting not found in jvm.config"
        exit 1
      fi
      echo "JVM heap (-Xmx) is configured"

  verify_response_time:
    machine: dev-machine
    user: laborant
    needs:
      - verify_heap_set
    run: |
      START=$(date +%s%N)
      curl -s http://localhost:8500/index.cfm > /dev/null
      END=$(date +%s%N)
      MS=$(( (END - START) / 1000000 ))
      if [ "${MS}" -gt 2000 ]; then
        echo "Response time is ${MS}ms — exceeds 2000ms threshold"
        exit 1
      fi
      echo "Response time is ${MS}ms — within acceptable range"
---

## JVM heap settings

```bash
# /opt/coldfusion2025/cfusion/bin/jvm.config
java.args=-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

## Connection pool tuning

1. CF Admin → **Data & Services → Data Sources → training_db → Advanced Settings**
2. **Max Connections**: `50`
3. **Connection Timeout**: `120`
4. **Max Wait Time**: `5000` ms

## Enable GZIP (nginx)

```nginx
gzip on;
gzip_types text/html application/json application/javascript text/css;
```
