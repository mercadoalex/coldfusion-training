---
kind: unit

title: Integration via Web Services (SOAP)

name: soap-web-services-integration-unit-1
---

## What is SOAP?

::image-box
---
:src: __static__/soap-wsdl-envelope-flow-v1.png
:alt: SOAP request/response flow diagram — on the left a "CF Client" box calls createObject("webservice", WSDL URL); an arrow labelled "HTTP POST (XML SOAP Envelope)" crosses to a "Remote SOAP Service" box on the right; the envelope shows XML with Envelope, Header, and Body elements; the response arrow carries a SOAP response envelope back; below the diagram a WSDL document icon is labelled "describes available operations and data types"
:max-width: 860px
---
_SOAP wraps every call in an XML envelope — ColdFusion handles the serialisation automatically via `createObject("webservice", wsdlUrl)`._
::

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

::image-box
---
:src: __static__/soap-vs-rest-comparison-v1.png
:alt: Two-column visual comparison card — left column "SOAP" has XML badge and lists: strict WSDL contract, XML over HTTP, SOAP Fault for errors, mature enterprise tooling, high verbosity; right column "REST" has JSON badge and lists: optional OpenAPI contract, any format over HTTP, HTTP status codes for errors, lightweight web/mobile tooling, low verbosity — shared row at top labelled "both run over HTTP"
:max-width: 860px
---
_SOAP and REST both use HTTP — the key differences are contract strictness, payload format, and ecosystem maturity._
::


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


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.soap-webservices-013fbc6a
---
::
