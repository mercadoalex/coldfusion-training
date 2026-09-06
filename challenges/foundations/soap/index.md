---
kind: challenge

title: Expose and Consume a SOAP Service

description: |
  Ensure TicketService.cfc has a remote function accessible via WSDL,
  and create soap_consumer.cfm that calls it using createObject or cfinvoke.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- soap

playground:
  name: cf-alex-edcdf975

tasks:
  verify_soap_consumer:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "soap_consumer.cfm not found"
        exit 1
      fi
      echo "soap_consumer.cfm exists"

  verify_cfinvoke_or_createobject:
    machine: dev-machine
    user: laborant
    needs:
      - verify_soap_consumer
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm"
      if ! grep -qi "cfinvoke\|createObject.*webservice" "${FILE}" 2>/dev/null; then
        echo "No cfinvoke or createObject webservice call found"
        exit 1
      fi
      echo "Web service call found"

  verify_wsdl_accessible:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfinvoke_or_createobject
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://localhost:8500/TicketService.cfc?wsdl")
      if [ "${STATUS}" != "200" ]; then
        echo "WSDL not accessible (got ${STATUS})"
        exit 1
      fi
      echo "WSDL accessible"
---

## Your mission

1. Make sure `TicketService.cfc` has a function with `access="remote"` so CF auto-generates the WSDL:

```bash
curl -s -o /dev/null -w "%{http_code}" "http://localhost:8500/TicketService.cfc?wsdl"
```

2. Create `soap_consumer.cfm` that calls it:

```cfml
<cfscript>
  ws = createObject("webservice", "http://localhost:8500/TicketService.cfc?wsdl");
  result = ws.getTicketById(1);
  writeOutput(result.title);
</cfscript>
```
