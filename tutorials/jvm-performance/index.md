---
kind: tutorial

title: JVM Tuning and Response-Time Benchmarking

description: |
  Adjust JVM heap settings in jvm.config, restart ColdFusion,
  and benchmark response time with curl to confirm performance is acceptable.

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
---

## Steps

### 1. View current JVM settings

```bash
cat /opt/coldfusion2025/cfusion/bin/jvm.config | grep "java.args"
```

### 2. Update the heap

Edit `/opt/coldfusion2025/cfusion/bin/jvm.config` — find the `java.args` line and set:

```bash
sed -i 's/java\.args=.*/java.args=-Xms512m -Xmx1024m -XX:+UseG1GC -XX:MaxGCPauseMillis=200/' \
  /opt/coldfusion2025/cfusion/bin/jvm.config
```

Verify:

```bash
grep "java.args" /opt/coldfusion2025/cfusion/bin/jvm.config
```

### 3. Restart ColdFusion

```bash
sudo systemctl restart cf-server
sleep 30  # wait for CF to come back up
```

### 4. Benchmark response time

```bash
# Single request timing
curl -s -w "\nTime: %{time_total}s  HTTP: %{http_code}\n" \
  -o /dev/null http://localhost:8500/index.cfm
```

Target: under **2 seconds**. The lesson task checks for < 2000 ms.

### 5. Run 5 requests and see average

```bash
for i in 1 2 3 4 5; do
  curl -s -w "%{time_total}\n" -o /dev/null http://localhost:8500/index.cfm
done
```

### 6. Check the connection pool

1. Browse to `http://localhost:8500/CFIDE/administrator`
2. Log in: password `admin`
3. **Data & Services → Data Sources → training_db → Edit**
4. Check **Advanced Settings** — confirm Max Connections is set
