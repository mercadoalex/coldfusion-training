---
kind: unit

title: Integration via Web Services (SOAP)

name: soap-web-services-integration-unit-1
---

## What is SOAP?

SOAP (Simple Object Access Protocol) is an XML-based messaging protocol for calling remote services over HTTP. The service contract is described in a **WSDL** (Web Services Description Language) document that lists available operations and their data types.

While REST APIs dominate new development, many enterprise systems (banking, government, ERP) still expose SOAP endpoints.

---

## Consuming a SOAP web service

ColdFusion creates a proxy object from a WSDL URL. Method calls on the proxy are dispatched as SOAP requests.

```cfml
<cfscript>
  ws     = createObject("webservice", "http://example.com/service?wsdl");
  result = ws.getStudentById(1);
  writeOutput("Name: " & result.name);
</cfscript>
```

---

## Using cfinvoke

The `<cfinvoke>` tag is the tag-syntax alternative for calling a web service method:

```cfml
<cfinvoke
  webservice="http://example.com/StudentService?wsdl"
  method="getAll"
  returnvariable="students">
</cfinvoke>

<cfdump var="#students#">
```

---

## Exposing a CFC as a SOAP web service

Any `remote` CFC function is automatically exposed as a SOAP web service. Add `access="remote"` to the function declaration:

```cfml
// TicketService.cfc — expose getById as a remote SOAP method
component displayname="TicketService" style="document" {

  remote struct function getTicketById(required numeric id)
    returntype="struct"
    access="remote"
    output="false"
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

ColdFusion auto-generates the WSDL — append `?wsdl` to the CFC URL:

```
http://localhost:8500/TicketService.cfc?wsdl
```

---

## SOAP vs REST comparison

| Aspect | SOAP | REST |
|---|---|---|
| Protocol | XML over HTTP | Any format over HTTP |
| Contract | WSDL (strict) | OpenAPI/Swagger (optional) |
| Tooling | Mature (enterprise) | Lightweight (web, mobile) |
| Error handling | SOAP Fault envelopes | HTTP status codes |
| Verbosity | High (XML overhead) | Low (JSON) |

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm` that calls a SOAP service using `createObject("webservice", ...)` or `<cfinvoke>`.
2. Verify that `TicketService.cfc` exposes a remote function and the WSDL is accessible:

```bash
curl -s -o /dev/null -w "%{http_code}" "http://localhost:8500/TicketService.cfc?wsdl"
# Should return 200
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_ws_consumer
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm`.

#completed
`soap_consumer.cfm` exists. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cfinvoke_used
---
#active
Use `<cfinvoke>` or `createObject("webservice", ...)` in `soap_consumer.cfm`.

#completed
Web service invocation found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_exposed_service
---
#active
`TicketService.cfc` must have a `remote` function — verify at `?wsdl`.

#completed
SOAP WSDL is accessible at `TicketService.cfc?wsdl`. ✓
::
