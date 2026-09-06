---
kind: lesson

title: Security Hardening ColdFusion
description: |
  Harden a ColdFusion 2025 installation: secure the admin console,
  configure neo-security.xml, enforce HTTPS, validate input,
  and prevent XSS and SQL injection.

name: security-hardening-coldfusion
slug: security-hardening-coldfusion

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- security

tagz:
- coldfusion
- cfml
- hardening
- xss

playground:
  name: cf-alex-edcdf975

tasks:
  verify_admin_restricted:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/CFIDE/administrator/index.cfm)
      if [ "${STATUS}" = "200" ]; then
        echo "CF Admin is publicly accessible — should be restricted"
        exit 1
      fi
      echo "CF Admin is restricted (got ${STATUS})"

  verify_no_xss:
    machine: dev-machine
    user: laborant
    needs:
      - verify_admin_restricted
    run: |
      BODY=$(curl -s "http://localhost:8500/input_demo.cfm?name=<script>alert(1)</script>")
      if echo "${BODY}" | grep -q "<script>alert(1)</script>"; then
        echo "XSS vulnerability detected — input is not encoded"
        exit 1
      fi
      echo "Input is properly HTML-encoded — no XSS"

  verify_queryparam_sql:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_xss
    run: |
      COUNT=$(grep -r "cfqueryparam\|queryParam" /opt/coldfusion2025/cfusion/wwwroot/ 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No cfqueryparam usage found — SQL injection risk"
        exit 1
      fi
      echo "cfqueryparam is used in ${COUNT} location(s)"
---
