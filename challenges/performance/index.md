---
kind: challenge

title: JVM Heap and Response Time

description: |
  Verify jvm.config exists and contains an -Xmx setting, then confirm
  ColdFusion responds to a request within 2000 milliseconds.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- jvm
- performance

playground:
  name: cf-alex-edcdf975

tasks:
  verify_jvm_config:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/bin/jvm.config"
      if [ ! -f "${FILE}" ]; then
        echo "jvm.config not found"
        exit 1
      fi
      echo "jvm.config found"

  verify_xmx_set:
    machine: dev-machine
    user: laborant
    needs:
      - verify_jvm_config
    run: |
      if ! grep -q "\-Xmx" /opt/coldfusion2025/cfusion/bin/jvm.config; then
        echo "-Xmx not set in jvm.config"
        exit 1
      fi
      echo "-Xmx is configured"

  verify_response_time:
    machine: dev-machine
    user: laborant
    needs:
      - verify_xmx_set
    run: |
      START=$(date +%s%N)
      curl -s http://localhost:8500/index.cfm > /dev/null
      END=$(date +%s%N)
      MS=$(( (END - START) / 1000000 ))
      if [ "${MS}" -gt 2000 ]; then
        echo "Response time ${MS}ms exceeds 2000ms threshold"
        exit 1
      fi
      echo "Response time ${MS}ms — OK"
---

## Your mission

1. Confirm `-Xmx` is set in `/opt/coldfusion2025/cfusion/bin/jvm.config`:

```bash
grep "Xmx" /opt/coldfusion2025/cfusion/bin/jvm.config
```

2. If not set, update it:

```bash
sed -i 's/java\.args=.*/java.args=-Xms512m -Xmx1024m -XX:+UseG1GC/' \
  /opt/coldfusion2025/cfusion/bin/jvm.config
sudo systemctl restart cf-server && sleep 30
```

3. Benchmark:

```bash
curl -s -w "\nTime: %{time_total}s\n" -o /dev/null http://localhost:8500/index.cfm
```

Must be under **2 seconds**.
