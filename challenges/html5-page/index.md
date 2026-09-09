---
kind: challenge

title: HTML5 Dynamic Page

description: |
  Create html5_demo.cfm with a proper HTML5 DOCTYPE, at least one dynamic
  CFML output (cfoutput or writeOutput), and data-* attributes on list items
  populated from a database query.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- html5

playground:
  name: cf-alex-edcdf975

tasks:
  verify_html5_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/html5_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "html5_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "html5_demo.cfm is accessible"

  verify_doctype:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_page
    run: |
      BODY=$(curl -s http://localhost:8500/html5_demo.cfm)
      if ! echo "${BODY}" | grep -qi "<!DOCTYPE html>"; then
        echo "HTML5 DOCTYPE missing"
        exit 1
      fi
      echo "HTML5 DOCTYPE present"

  verify_dynamic_output:
    machine: dev-machine
    user: laborant
    needs:
      - verify_doctype
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm"
      if ! grep -q "cfoutput\|writeOutput" "${FILE}" 2>/dev/null; then
        echo "No dynamic CFML output in html5_demo.cfm"
        exit 1
      fi
      echo "Dynamic output present"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm` that:

1. Has a proper `<!DOCTYPE html>` declaration
2. Uses `<cfoutput>` or `writeOutput()` to render dynamic data
3. Queries `hd_tickets` and renders each ticket in a `<li>` with `data-id` and `data-priority` attributes

```bash
curl -s http://localhost:8500/html5_demo.cfm | grep -i "DOCTYPE"
curl -s http://localhost:8500/html5_demo.cfm | grep "data-id"
```
