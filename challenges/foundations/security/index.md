---
kind: challenge

title: Harden the Application

description: |
  Create input_demo.cfm that encodes URL parameters with encodeForHTML.
  Restrict the CF Admin via nginx config or Application.cfc redirect.
  Ensure cfqueryparam is used in at least one file in the web root.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- security

tagz:
- coldfusion
- security
- xss

playground:
  name: cf-alex-edcdf975

tasks:
  verify_admin_restricted:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        http://localhost:8500/CFIDE/administrator/index.cfm)
      if [ "${STATUS}" = "200" ]; then
        echo "CF Admin is publicly accessible — must be restricted"
        exit 1
      fi
      echo "CF Admin restricted (got ${STATUS})"

  verify_xss_encoded:
    machine: dev-machine
    user: laborant
    needs:
      - verify_admin_restricted
    run: |
      BODY=$(curl -s \
        "http://localhost:8500/input_demo.cfm?name=<script>alert(1)</script>")
      if echo "${BODY}" | grep -q "<script>alert(1)</script>"; then
        echo "XSS vulnerability — raw script tag in response"
        exit 1
      fi
      echo "Input encoded — no XSS"

  verify_queryparam_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_xss_encoded
    run: |
      COUNT=$(grep -r "cfqueryparam\|queryParam" \
        /opt/coldfusion2025/cfusion/wwwroot/ 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No cfqueryparam found anywhere in web root"
        exit 1
      fi
      echo "cfqueryparam used in ${COUNT} location(s)"
---

## Your mission

1. Create `input_demo.cfm` — take `url.name` and output it with `encodeForHTML()`
2. Restrict the CF Admin (return non-200 for `/CFIDE/administrator/index.cfm`)
3. Ensure `cfqueryparam` is used somewhere in the web root

Test XSS protection:

```bash
curl -s "http://localhost:8500/input_demo.cfm?name=<script>alert(1)</script>"
# Must NOT contain the raw <script> tag
```
