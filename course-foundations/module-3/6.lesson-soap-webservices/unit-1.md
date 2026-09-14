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

> **What does "serialised" mean?**
> Think of it like packing a suitcase. Your ColdFusion variables — strings, numbers, structs — exist in memory in a form only your server understands. *Serialising* means converting them into a standardised text format (XML, in SOAP's case) that any other system on any platform can read and unpack. The remote server receives that XML, unpacks it back into its own variables, runs the function, then serialises its response back to you the same way. You write normal ColdFusion; the serialisation/deserialisation happens invisibly in between.

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

::details-box
---
:summary: WSDL deep dive — what the contract file actually contains
---

**WSDL** (Web Services Description Language) is an XML document that fully describes a SOAP web service — every operation, every parameter, every data type, and every endpoint URL. It is the machine-readable contract that allows any SOAP client (Java, .NET, Python, ColdFusion) to auto-generate a proxy without you writing a single line of binding code.

**The five key sections of a WSDL document:**

| Section | XML element | What it defines |
|---|---|---|
| **Types** | `<types>` | XML Schema (XSD) definitions of all input/output data structures |
| **Messages** | `<message>` | Named sets of typed parameters — one per operation input/output |
| **Port Type** | `<portType>` | The interface — lists all available operations and their messages |
| **Binding** | `<binding>` | How operations are transmitted — SOAP encoding style, HTTP verb |
| **Service** | `<service>` | The actual endpoint URL where the service is reachable |

**A minimal WSDL for `getTicketById` looks like this:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions
  name="TicketService"
  targetNamespace="http://localhost:8500/TicketService.cfc"
  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema">

  <!-- 1. Types — data structure definitions -->
  <wsdl:types>
    <xsd:schema>
      <xsd:element name="getTicketByIdRequest">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element name="id" type="xsd:int"/>
          </xsd:sequence>
        </xsd:complexType>
      </xsd:element>
    </xsd:schema>
  </wsdl:types>

  <!-- 2. Messages — named parameter sets -->
  <wsdl:message name="getTicketByIdRequest">
    <wsdl:part name="parameters" element="tns:getTicketByIdRequest"/>
  </wsdl:message>
  <wsdl:message name="getTicketByIdResponse">
    <wsdl:part name="return" type="xsd:anyType"/>
  </wsdl:message>

  <!-- 3. Port Type — the interface (list of operations) -->
  <wsdl:portType name="TicketServicePortType">
    <wsdl:operation name="getTicketById">
      <wsdl:input  message="tns:getTicketByIdRequest"/>
      <wsdl:output message="tns:getTicketByIdResponse"/>
    </wsdl:operation>
  </wsdl:portType>

  <!-- 4. Binding — SOAP transport details -->
  <wsdl:binding name="TicketServiceBinding" type="tns:TicketServicePortType">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="getTicketById">
      <soap:operation soapAction="getTicketById"/>
    </wsdl:operation>
  </wsdl:binding>

  <!-- 5. Service — endpoint URL -->
  <wsdl:service name="TicketService">
    <wsdl:port name="TicketServicePort" binding="tns:TicketServiceBinding">
      <soap:address location="http://localhost:8500/TicketService.cfc"/>
    </wsdl:port>
  </wsdl:service>

</wsdl:definitions>
```

**WSDL 1.1 vs WSDL 2.0:**
ColdFusion generates **WSDL 1.1** — the version used by virtually all enterprise SOAP systems. WSDL 2.0 was published in 2007 but never widely adopted. If you see a WSDL in the wild, it is almost certainly 1.1.

**How ColdFusion generates it:**
When you append `?wsdl` to a CFC URL, ColdFusion inspects all `remote` functions using Java reflection, maps CFML types to XSD types (`numeric` → `xsd:int`, `string` → `xsd:string`, `struct` → `xsd:anyType`), and assembles the five sections above automatically. You never write WSDL by hand — ColdFusion owns it.

**Practical tip — reading a WSDL:**
When integrating with a third-party SOAP service, always read the `<wsdl:portType>` section first — it lists every available operation. Then check `<wsdl:types>` to understand the input/output structures. The `<wsdl:service>` section gives you the endpoint URL to pass to `createObject("webservice", ...)`.

::

::details-box
---
:summary: Can you create a WSDL from scratch — and should you?
---

**Yes, but you almost never should.** WSDL is verbose, strict XML with interdependent sections — a single typo in a namespace or a mismatched message name breaks the entire contract. Every major platform generates it automatically:

- **ColdFusion** — append `?wsdl` to any CFC with `remote` functions
- **Java (JAX-WS)** — `wsgen` generates WSDL from annotated classes
- **.NET (WCF)** — generates WSDL from `[ServiceContract]` interfaces

**The only valid reason to write WSDL by hand** is **contract-first design** — defining the interface before any implementation exists so multiple teams (Java backend, CF consumer, .NET client) can build against a shared contract simultaneously. Even then, use a tool like SoapUI or Apache CXF that validates as you type.

**Code-first vs contract-first:**

| Approach | When to use | Risk |
|---|---|---|
| **Code-first** (CF generates WSDL) | Internal services, quick integrations | WSDL changes silently when you rename a function |
| **Contract-first** (WSDL written first) | Multi-team enterprise integration, public APIs | More upfront work, but the contract is stable |

For ColdFusion and most CF projects — **code-first is the right default**. Let CF generate it.

::

::details-box
---
:summary: WSDL security risks and how to harden your SOAP services
---

A public `?wsdl` URL is an **attack map** — it tells anyone every operation name, parameter name, and data type your service exposes. Key risks:

| Risk | What it means |
|---|---|
| **Service enumeration** | Attackers see your entire API surface — every function and its parameter types |
| **XXE (XML External Entity)** | Malicious `<!DOCTYPE>` in a SOAP envelope tricks the XML parser into reading local files (`/etc/passwd`) or making internal HTTP requests |
| **WSDL injection** | A cached or proxied WSDL is tampered with to redirect operations to a malicious endpoint |
| **Verbose SOAP Faults** | Default error responses include Java stack traces, class names, and server paths |
| **Unauthenticated WSDL** | The contract is publicly accessible even when operations require auth — exposing your API design to anyone |
| **Accidental remote exposure** | Any CFC with `access="remote"` in wwwroot becomes a SOAP endpoint — a forgotten annotation exposes internal logic |

**Hardening checklist for CF SOAP services:**

```
✅ Restrict ?wsdl to internal IPs only — via CF Admin or web server (nginx/Apache) rules
✅ Require authentication before serving operations — use Application.cfc onRequestStart
✅ Only mark functions access="remote" that genuinely need to be public
✅ Never return raw exception detail in SOAP Fault — catch errors and return a generic message
✅ Use HTTPS — SOAP envelopes carry all data as plaintext XML over HTTP
✅ Disable XXE in the CF JVM — add -Djavax.xml.parsers.SAXParserFactory to jvm.config
```

**Tools to validate and test SOAP services:**

| Tool | What it does |
|---|---|
| **SoapUI** | Industry standard — imports WSDL, fires test requests, inspects raw envelopes |
| **Postman** | Imports WSDL and generates a full test collection |
| **Burp Suite** | Intercepts and modifies SOAP envelopes in transit — has a built-in WSDL parser |
| **WSFuzzer** | Fuzzes SOAP operations with malformed inputs to find parser and injection bugs |
| **Apache CXF `wsdlvalidator`** | CLI tool — validates WSDL against WS-I Basic Profile |

::

---

::hint-box
---
:summary: Which engine are we using in this lesson — Adobe CF or Lucee?
---

**This lesson uses Adobe ColdFusion 2025 (port 8500).** SOAP web service support (`createObject("webservice", ...)`, auto-generated WSDL, `<cfinvoke webservice=...>`) is a mature, well-tested feature of Adobe CF and is the recommended engine for SOAP work.

Lucee 7 also supports SOAP but its implementation is less complete — some edge cases in WSDL generation and complex type mapping behave differently. For enterprise SOAP integration, Adobe CF is the safer choice.

**Quick reference — which port is which:**

| Engine | Port | Use for |
|---|---|---|
| Adobe ColdFusion 2025 | **8500** | This lesson — SOAP services |
| Lucee 7 / CommandBox | **8888** | Previous lesson — CFConfig, CLI admin |

All files in this lesson go into `/opt/coldfusion2025/cfusion/wwwroot/` and are accessed via the **ColdFusion 2025** browser tab.

::

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
