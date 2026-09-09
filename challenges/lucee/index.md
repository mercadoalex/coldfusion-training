---
kind: challenge

title: Lucee Version Info Page

description: |
  Create lucee_info.cfm on the Lucee web root that outputs the Lucee
  version string. The page must return HTTP 200 and contain the word "lucee"
  in the response body.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- lucee
- coldfusion

playground:
  name: cf-alex-edcdf975

tasks:
  verify_lucee_running:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "Lucee not running on port 8888 (got ${STATUS})"
        exit 1
      fi
      echo "Lucee is running"

  verify_lucee_info_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_lucee_running
    run: |
      BODY=$(curl -s http://localhost:8888/lucee_info.cfm)
      if ! echo "${BODY}" | grep -qi "lucee"; then
        echo "lucee_info.cfm does not output Lucee version info"
        exit 1
      fi
      echo "Lucee version info accessible"

  verify_lucee_datasource:
    machine: dev-machine
    user: laborant
    needs:
      - verify_lucee_info_page
    run: |
      BODY=$(curl -s http://localhost:8888/verify_ds.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "Lucee datasource check failed"
        exit 1
      fi
      echo "Lucee datasource OK"
---

## Your mission

Create `/home/laborant/app/lucee_info.cfm`:

```cfml
<cfscript>
  writeOutput("Lucee version: " & server.lucee.version & "<br>");
  writeOutput("Java version: "  & server.java.version  & "<br>");
</cfscript>
```

Verify on port 8888:

```bash
curl -s http://localhost:8888/lucee_info.cfm
```

Also ensure `verify_ds.cfm` exists on the Lucee root and returns no errors.
