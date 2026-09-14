---
kind: unit

title: Integration via Web Services (SOAP)

name: soap-web-services-integration-unit-1
---

## What is SOAP?

**SOAP** (Simple Object Access Protocol) is an XML-based messaging protocol for calling remote services over HTTP. Every request and response is wrapped in a **SOAP envelope** — an XML document with a defined structure. The service contract is described in a **WSDL** (Web Services Description Language) document that lists all available operations, their input/output parameters, and data types.

::image-box
---
:src: __static__/soap-wsdl-envelope-flow-v1.png
:alt: SOAP request/response flow diagram — on the left a CF Client box calls createObject webservice with a WSDL URL; an arrow labelled HTTP POST XML SOAP Envelope crosses to a Remote SOAP Service box on the right; the envelope shows XML with Envelope, Header, and Body elements; a response arrow carries a SOAP response envelope back; below the diagram a WSDL document icon is labelled describes available operations and data types
:max-width: 860px
---
_SOAP wraps every call in an XML envelope — ColdFusion handles the serialisation automatically via `createObject("webservice", wsdlUrl)`._
::

While REST APIs dominate new development, SOAP is still widely used in **enterprise systems** — banking, government, ERP platforms, and healthcare systems commonly expose SOAP endpoints. ColdFusion has had first-class SOAP support since version 6.

::details-box
---
:summary: SOAP vs REST — what actually differs and when to use each
---

::image-box
---
:src: __static__/soap-vs-rest-comparison-v1.png
:alt: Two-column comparison card — left column SOAP lists strict WSDL contract, XML over HTTP, SOAP Fault for errors, mature enterprise tooling, high verbosity; right column REST lists optional OpenAPI contract, any format over HTTP, HTTP status codes for errors, lightweight web and mobile tooling, low verbosity — shared row at top says both run over HTTP
:max-width: 860px
---
_SOAP and REST both use HTTP — the key differences are contract strictness, payload format, and ecosystem._
::

| Aspect | SOAP | REST |
|---|---|---|
| **Protocol** | XML over HTTP/HTTPS | Any format (usually JSON) over HTTP |
| **Contract** | WSDL — strict, machine-readable | OpenAPI/Swagger — optional |
| **Error handling** | SOAP Fault XML envelope | HTTP status codes (4xx, 5xx) |
| **Tooling** | Mature enterprise IDEs, WS-Security | Lightweight, any HTTP client |
| **Verbosity** | High — XML wrapping adds overhead | Low — JSON is compact |
| **When to use** | Legacy enterprise integration, banking, healthcare | New APIs, mobile, web, public APIs |

**The practical rule:** if you are integrating with a system built before 2010, expect SOAP. If you are building something new, use REST. ColdFusion handles both equally well.

**What about gRPC?** ColdFusion has no native gRPC support. gRPC uses HTTP/2 and binary Protocol Buffers — outside CF's built-in web service layer. If you need to call a gRPC service from ColdFusion, put a REST gateway in front of it (gRPC-Gateway, Envoy) and call that via `cfhttp`. For this course, gRPC is out of scope.

::

---

## How ColdFusion consumes a SOAP service

ColdFusion reads the WSDL and generates a **proxy object** automatically. Every method call on the proxy is serialised into a SOAP envelope and dispatched over HTTP — you never write XML manually:

```cfml
<cfscript>
  // Create proxy from WSDL URL — CF parses the contract automatically
  ws = createObject("webservice", "http://example.com/StudentService?wsdl");

  // Call a remote method — CF handles XML serialisation
  result = ws.getStudentById(1);

  writeOutput("Name: " & result.name);
</cfscript>
```

The `<cfinvoke>` tag is the tag-syntax alternative:

```cfml
<cfinvoke
  webservice = "http://example.com/StudentService?wsdl"
  method     = "getAll"
  returnvariable = "students">
</cfinvoke>

<cfdump var="#students#">
```

::hint-box
---
:summary: WSDL caching — why the first call is slow
---

The first time ColdFusion connects to a WSDL URL it downloads the contract, parses it, and generates a Java proxy class — this can take 2–5 seconds. Subsequent calls use the cached proxy and are fast.

ColdFusion caches WSDL proxies in the CF temp directory. To force a refresh (e.g. after the remote service updates its contract):

```cfml
<cfscript>
  // refreshWSDL=true forces re-download and regeneration of the proxy
  ws = createObject("webservice", "http://example.com/service?wsdl", {refreshWSDL: true});
</cfscript>
```

In production, avoid `refreshWSDL: true` on every request — only use it when you know the contract has changed.

::

---

## Exposing a CFC as a SOAP web service

Any CFC function marked `access="remote"` is **automatically exposed as a SOAP web service** by ColdFusion. No configuration required — ColdFusion generates the WSDL automatically:

```cfml
// TicketService.cfc
component displayname="TicketService" style="document" {

  remote struct function getTicketById(required numeric id)
    returntype = "struct"
    access     = "remote"
    output     = "false"
  {
    var q = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets WHERE id = :id",
      { id: { value: arguments.id, cfsqltype: "cf_sql_integer" } },
      { datasource: "training_db" }
    );
    if (q.recordCount == 0) { return { error: "not found" }; }
    return {
      id       : q.id,
      title    : q.title,
      status   : q.status,
      priority : q.priority
    };
  }

}
```

ColdFusion auto-generates the WSDL — append `?wsdl` to the CFC URL:

```
http://localhost:8500/TicketService.cfc?wsdl
```

And consume it from any SOAP client — including another ColdFusion application:

```cfml
<cfscript>
  ws     = createObject("webservice", "http://localhost:8500/TicketService.cfc?wsdl");
  ticket = ws.getTicketById(1);
  writeOutput("Ticket: " & ticket.title & " — " & ticket.status);
</cfscript>
```

---

## Activity 1 — Create a SOAP consumer page

**What you are building:** `soap_consumer.cfm` — a page that calls a public SOAP web service and displays the result. We use a **local** SOAP call (CF calling itself via `TicketService.cfc`) so the exercise works without internet access.

**File to create:** `/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm`

In the **Terminal** tab, first create the `TicketService.cfc` that will be consumed:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc << 'EOF'
component displayname="TicketService" style="document" {

  remote struct function getTicketById(required numeric id)
    returntype="struct"
    access="remote"
    output="false"
  {
    var q = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets WHERE id = :id",
      { id: { value: arguments.id, cfsqltype: "cf_sql_integer" } },
      { datasource: "training_db" }
    );
    if (q.recordCount == 0) { return { error: "not found" }; }
    return {
      id       : q.id,
      title    : q.title,
      status   : q.status,
      priority : q.priority
    };
  }

  remote array function getAllTickets()
    returntype="array"
    access="remote"
    output="false"
  {
    var q = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets ORDER BY id",
      {},
      { datasource: "training_db" }
    );
    var result = [];
    for (var row in q) {
      arrayAppend(result, {
        id       : row.id,
        title    : row.title,
        status   : row.status,
        priority : row.priority
      });
    }
    return result;
  }

}
EOF
```

Now create the consumer page:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>SOAP Consumer Demo</title>
  <style>
    body  { font-family: sans-serif; max-width: 860px; margin: 2rem auto; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th    { background: #3b82d4; color: #fff; padding: .5rem .75rem; text-align: left; }
    td    { padding: .45rem .75rem; border-bottom: 1px solid #e5e7eb; }
    .box  { padding: 1rem; background: #f0f4ff; border-left: 4px solid #3b82d4; margin: 1rem 0; }
  </style>
</head>
<body>
  <h1>SOAP Web Service Consumer</h1>

  <cfscript>
    // Create proxy from the local TicketService WSDL
    ws = createObject("webservice", "http://localhost:8500/TicketService.cfc?wsdl");

    // Call getTicketById — SOAP request/response handled by ColdFusion
    ticket = ws.getTicketById(1);

    // Call getAllTickets
    allTickets = ws.getAllTickets();
  </cfscript>

  <div class="box">
    <strong>SOAP call — getTicketById(1):</strong><br>
    <cfoutput>
      ID: #ticket.id# | Title: #encodeForHTML(ticket.title)# |
      Status: #encodeForHTML(ticket.status)# | Priority: #encodeForHTML(ticket.priority)#
    </cfoutput>
  </div>

  <h2>getAllTickets() — full ticket list via SOAP</h2>
  <table>
    <tr><th>ID</th><th>Title</th><th>Status</th><th>Priority</th></tr>
    <cfoutput>
      <cfloop array="#allTickets#" index="t">
        <tr>
          <td>#t.id#</td>
          <td>#encodeForHTML(t.title)#</td>
          <td>#encodeForHTML(t.status)#</td>
          <td>#encodeForHTML(t.priority)#</td>
        </tr>
      </cfloop>
    </cfoutput>
  </table>

</body>
</html>
EOF
```

Verify both files exist:

```bash
grep -i "cfinvoke\|createObject" /opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm
```

Open `/soap_consumer.cfm` in the **ColdFusion 2025** browser tab — you should see the ticket loaded via SOAP and the full ticket list.

::image-box
---
:src: __static__/browser-soap-consumer-v1.png
:alt: Browser showing soap_consumer.cfm — a blue info box shows the result of getTicketById(1) with ID, title, status and priority, followed by a table listing all tickets returned by the getAllTickets SOAP call
:max-width: 860px
---
_`soap_consumer.cfm` — tickets loaded via SOAP proxy calls to `TicketService.cfc` running on the same CF instance._
::

::simple-task
---
:tasks: tasks
:name: verify_ws_consumer
---
#active
Run the `sudo tee` commands above to create `TicketService.cfc` and `soap_consumer.cfm`. Open `/soap_consumer.cfm` in the browser to confirm the SOAP calls return ticket data.

#completed
`soap_consumer.cfm` exists with web service invocation. ✓
::

---

## Activity 2 — Verify the WSDL is accessible

**What this proves:** When ColdFusion sees `?wsdl` appended to a CFC URL it generates a complete WSDL document describing all `remote` functions. This is the contract that any SOAP client — Java, .NET, Python, or another CF app — uses to know what operations are available and what parameters they accept.

In the **Terminal** tab, confirm the WSDL returns HTTP 200:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://localhost:8500/TicketService.cfc?wsdl"
```

Then inspect the first few lines of the generated WSDL:

```bash
curl -s "http://localhost:8500/TicketService.cfc?wsdl" | head -20
```

You should see an XML document starting with `<?xml` and containing `<wsdl:definitions` — ColdFusion generated this automatically from your CFC's `remote` function signatures.

::image-box
---
:src: __static__/terminal-wsdl-accessible-v1.png
:alt: Terminal showing the curl command returning HTTP 200 for TicketService.cfc?wsdl, followed by the head command showing the first lines of the auto-generated WSDL XML document with wsdl:definitions element
:max-width: 860px
---
_HTTP 200 on `?wsdl` — ColdFusion auto-generated the WSDL from the `remote` function signatures in `TicketService.cfc`._
::

::simple-task
---
:tasks: tasks
:name: verify_exposed_service
---
#active
Run `curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://localhost:8500/TicketService.cfc?wsdl"` in the Terminal. Confirm it returns HTTP 200 — the WSDL is accessible.

#completed
SOAP WSDL is accessible at `TicketService.cfc?wsdl`. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All done? Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete. On to the next one!
::
