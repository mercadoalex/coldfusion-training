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
      echo "CF Admin returned HTTP ${STATUS}"
      echo "In production this must be 403 (nginx blocked) — never 200"

  verify_no_xss:
    machine: dev-machine
    user: laborant
    needs:
      - verify_admin_restricted
    run: |
      BODY=$(curl -s "http://localhost:8500/input_demo.cfm?name=%3Cscript%3Ealert(1)%3C%2Fscript%3E")
      if ! curl -s -o /dev/null -w "%{http_code}" "http://localhost:8500/input_demo.cfm" | grep -q "200"; then
        echo "input_demo.cfm not found or not returning 200"
        exit 1
      fi
      if echo "${BODY}" | grep -qi "<script>"; then
        echo "XSS vulnerability detected — raw script tag in output"
        exit 1
      fi
      echo "Input is properly handled — no raw script tag in output"

  verify_queryparam_sql:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_xss
    run: |
      COUNT=$(grep -rl "cfqueryparam" /opt/coldfusion2025/cfusion/wwwroot/ \
        --exclude-dir=CFIDE --exclude-dir=WEB-INF 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No cfqueryparam usage found in student files — SQL injection risk"
        exit 1
      fi
      echo "cfqueryparam found in ${COUNT} file(s)"


  verify_security_headers:
    machine: dev-machine
    user: laborant
    needs:
      - verify_queryparam_sql
    run: |
      HEADERS=$(curl -s -I http://localhost:8500/index.cfm)
      if ! echo "${HEADERS}" | grep -qi "x-frame-options"; then
        echo "X-Frame-Options header missing"
        exit 1
      fi
      if ! echo "${HEADERS}" | grep -qi "content-security-policy"; then
        echo "Content-Security-Policy header missing"
        exit 1
      fi
      if ! echo "${HEADERS}" | grep -qi "x-content-type-options"; then
        echo "X-Content-Type-Options header missing"
        exit 1
      fi
      echo "Security headers present"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_security_headers
    run: |
      echo "Lesson complete — well done!"

---
