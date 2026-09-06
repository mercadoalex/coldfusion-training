---
kind: lesson

title: Building REST APIs with CFML
description: |
  Build JSON REST APIs using ColdFusion 2025. Learn cfheader, serializeJSON,
  deserializeJSON, cfqueryparam, and CFC service patterns — all against the
  live Help Desk database already running in your environment.

name: building-rest-apis-cfml
slug: building-rest-apis-cfml

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- rest
- api

playground:
  name: cf-alex-edcdf975

tasks:
  verify_api_list:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/api/tickets.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "GET /api/tickets.cfm returned HTTP ${STATUS}, expected 200"
        exit 1
      fi
      echo "GET /api/tickets.cfm → 200 OK"

  verify_json_content_type:
    machine: dev-machine
    user: laborant
    needs:
      - verify_api_list
    run: |
      CT=$(curl -s -I http://localhost:8500/api/tickets.cfm | grep -i "content-type")
      if ! echo "${CT}" | grep -qi "application/json"; then
        echo "Expected Content-Type: application/json, got: ${CT}"
        exit 1
      fi
      echo "Content-Type: application/json ✓"

  verify_json_valid:
    machine: dev-machine
    user: laborant
    needs:
      - verify_json_content_type
    run: |
      BODY=$(curl -s http://localhost:8500/api/tickets.cfm)
      if ! echo "${BODY}" | python3 -m json.tool > /dev/null 2>&1; then
        echo "Response is not valid JSON"
        exit 1
      fi
      echo "Valid JSON response ✓"

  verify_tickets_array:
    machine: dev-machine
    user: laborant
    needs:
      - verify_json_valid
    run: |
      COUNT=$(curl -s http://localhost:8500/api/tickets.cfm \
              | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total',0))")
      if [ "${COUNT}" -lt "1" ]; then
        echo "Expected at least 1 ticket in response, got ${COUNT}"
        exit 1
      fi
      echo "Response contains ${COUNT} ticket(s) ✓"

  verify_single_ticket:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tickets_array
    run: |
      BODY=$(curl -s "http://localhost:8500/api/tickets.cfm?id=1")
      if ! echo "${BODY}" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'title' in d" 2>/dev/null; then
        echo "GET ?id=1 did not return a ticket object with a 'title' field"
        exit 1
      fi
      echo "Single ticket fetch ✓"

  verify_post_ticket:
    machine: dev-machine
    user: laborant
    needs:
      - verify_single_ticket
    run: |
      BODY=$(curl -s -X POST http://localhost:8500/api/tickets.cfm \
              -H "Content-Type: application/json" \
              -d '{"title":"API test ticket","priority":"low","user_id":1}')
      if ! echo "${BODY}" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d.get('created') == True" 2>/dev/null; then
        echo "POST did not return {created: true}. Got: ${BODY}"
        exit 1
      fi
      echo "POST ticket created ✓"
---
