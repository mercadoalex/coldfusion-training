---
kind: tutorial

title: Consuming and Exposing a SOAP Web Service

description: |
  Call an external SOAP service from CFML using createObject,
  then expose TicketService.cfc as a remote web service and verify the WSDL.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- soap
- web-services

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Expose TicketService.cfc as a SOAP service

Ensure `TicketService.cfc` has at least one `remote` function:

```cfml
component displayname="TicketService" {
  remote struct function getTicketById(required numeric id)
    returntype="struct" access="remote" output="false"
  {
    var q = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets WHERE id = :id",
      {id: {value: arguments.id, cfsqltype: "cf_sql_integer"}},
      {datasource: "training_db"}
    );
    if (q.recordCount == 0) { return {error: "not found"}; }
    return {id: q.id, title: q.title, status: q.status, priority: q.priority};
  }
}
```

### 2. Verify the WSDL is generated

```bash
curl -s -o /dev/null -w "%{http_code}" \
  "http://localhost:8500/TicketService.cfc?wsdl"
```

Should return **200**. To see the full WSDL XML:

```bash
curl -s "http://localhost:8500/TicketService.cfc?wsdl" | head -20
```

### 3. Create soap_consumer.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm`:

```cfml
<cfscript>
  try {
    ws     = createObject("webservice", "http://localhost:8500/TicketService.cfc?wsdl");
    result = ws.getTicketById(1);
    writeOutput("Title: " & result.title & "<br>");
    writeOutput("Status: " & result.status);
  } catch (any e) {
    writeOutput("SOAP call failed: " & e.message);
  }
</cfscript>
```

### 4. Verify the consumer

```bash
curl -s http://localhost:8500/soap_consumer.cfm
```

Should output the title and status of ticket #1.
