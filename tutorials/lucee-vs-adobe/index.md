---
kind: tutorial

title: Lucee vs Adobe CF — Run the Same Code on Both Engines

description: |
  Deploy identical CFML files to both CF 2025 (port 8500) and Lucee 7
  (port 8888) and compare the output to understand engine differences.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- lucee
- coldfusion
- cfml

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Create lucee_info.cfm on the Lucee web root

```bash
cat > /home/laborant/app/lucee_info.cfm << 'EOF'
<cfscript>
  writeOutput("Engine: " & server.coldfusion.productname & "<br>");
  writeOutput("Version: " & server.coldfusion.productversion & "<br>");
  if (structKeyExists(server, "lucee")) {
    writeOutput("Lucee: " & server.lucee.version & "<br>");
  }
  writeOutput("Java: " & server.java.version & "<br>");
</cfscript>
EOF
```

### 2. Create the same file for CF 2025

```bash
cp /home/laborant/app/lucee_info.cfm \
   /opt/coldfusion2025/cfusion/wwwroot/lucee_info.cfm
```

### 3. Compare output from both engines

```bash
echo "=== Adobe CF 2025 (port 8500) ==="
curl -s http://localhost:8500/lucee_info.cfm

echo ""
echo "=== Lucee 7 (port 8888) ==="
curl -s http://localhost:8888/lucee_info.cfm
```

### 4. Create verify_ds.cfm on Lucee

```bash
cat > /home/laborant/app/verify_ds.cfm << 'EOF'
<cfscript>
  try {
    q = queryExecute("SELECT COUNT(*) AS total FROM hd_tickets", {}, {datasource: "training_db"});
    writeOutput("Lucee DB OK — tickets: " & q.total);
  } catch (any e) {
    writeOutput("Error: " & e.message);
  }
</cfscript>
EOF
```

```bash
curl -s http://localhost:8888/verify_ds.cfm
```
