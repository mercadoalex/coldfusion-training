---
kind: unit

title: Building REST APIs with CFML

name: building-rest-apis-cfml-unit-1
---

## What is a REST API, and why does it matter?

A **REST API** (Representational State Transfer) is a way for two systems to talk to each other over HTTP. Instead of returning an HTML page, the server returns structured data — almost always JSON — that a client (a browser, a mobile app, another server) can consume programmatically.

Why does this matter for ColdFusion developers?

- Modern frontends (React, Vue, plain JavaScript) don't load full pages — they fetch JSON and update the UI
- Mobile apps need data, not markup
- Microservices and integrations call each other via HTTP APIs
- ColdFusion sits naturally in this model: it already handles HTTP requests, runs queries, and can serialise any struct or array to JSON with a single function call

In this lesson you will work with a fully functional REST API that is **already deployed** in your environment. The goal is to understand how it's built, explore it with `curl`, and internalise the patterns you'll use in your own projects.

::image-box
---
:src: __static__/rest-api-request-response-cycle-v1.png
:alt: HTTP request-response cycle diagram for a CFML REST API — client on the left sends GET /api/tickets.cfm with an Accept application/json header; the ColdFusion server in the middle shows cfheader setting Content-Type, queryExecute fetching from training_db, and serializeJSON serialising the result; the response arrow carries a JSON payload back to the client
:max-width: 860px
---
_A CFML REST endpoint is a plain `.cfm` file — set the Content-Type header, run a query, serialise the result._
::

### What's already running in your lab

Two files are pre-deployed on the ColdFusion server:

| File | Location | Purpose |
|---|---|---|
| `api/tickets.cfm` | `/opt/coldfusion2025/cfusion/wwwroot/api/tickets.cfm` | REST endpoint — GET list, GET by id, POST create, DELETE close |
| `TicketService.cfc` | `/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc` | CFC service layer used by the endpoint |
| `api-test.cfm` | `/opt/coldfusion2025/cfusion/wwwroot/api-test.cfm` | Browser-based API console |

To open the API console, right-click the **ColdFusion** tab in the lab panel and open it in a new browser tab, then navigate to `/api-test.cfm`.

::image-box
---
:src: __static__/cf-api-test-console-v1.png
:alt: Help Desk API Console running in the browser — dark-themed page titled Help Desk API Console with subtitle Live REST endpoint /api/tickets.cfm · Powered by Adobe ColdFusion 2025 — four endpoint cards are visible: GET /api/tickets.cfm with a Send button and equivalent curl command, GET /api/tickets.cfm?id={id}, POST /api/tickets.cfm, and DELETE /api/tickets.cfm?id={id}
:max-width: 860px
---
_`api-test.cfm` — a browser-based console showing all four endpoints. Click any card to expand it and send a live request._
::

---

## 1. The simplest JSON endpoint

A ColdFusion REST endpoint is just a `.cfm` file that:
1. Sets the `Content-Type` header to `application/json`
2. Writes serialised data to the response and exits

```cfml
<!--- /api/tickets.cfm (GET — list all tickets) --->
<cfscript>
  cfheader(name="Content-Type", value="application/json");
  cfheader(name="Access-Control-Allow-Origin", value="*");

  q = queryExecute(
    "SELECT t.id, t.title, t.status, t.priority, t.created_at, u.name AS submitter
     FROM   hd_tickets t
     JOIN   hd_users   u ON u.id = t.user_id
     ORDER  BY t.created_at DESC",
    {}, { datasource: "training_db" }
  );

  writeOutput(serializeJSON({ "total": q.recordCount, "tickets": queryToArray(q) }));
</cfscript>
```

No framework, no routing config, no annotations. Just headers, a query, and `serializeJSON`.

---

## 2. Reading URL parameters safely

Always use `val()` or explicit type checks before using URL values in queries.
Never concatenate URL params directly into SQL.

```cfml
<cfscript>
  id = structKeyExists(url, "id") ? val(url.id) : 0;
  if (id LTE 0) {
    cfheader(statuscode="400", statustext="Bad Request");
    writeOutput(serializeJSON({ "error": "id must be a positive integer" }));
    abort;
  }

  q = queryExecute(
    "SELECT id, title, status, priority, description FROM hd_tickets WHERE id = :id",
    { id: { value: id, cfsqltype: "cf_sql_integer" } },
    { datasource: "training_db" }
  );

  if (q.recordCount == 0) {
    cfheader(statuscode="404", statustext="Not Found");
    writeOutput(serializeJSON({ "error": "Ticket not found" }));
    abort;
  }

  writeOutput(serializeJSON(queryToArray(q)[1]));
</cfscript>
```

The `:id` named binding in `queryExecute` is a `cfqueryparam` equivalent — it escapes the value and prevents SQL injection.

---

## 3. Accepting a JSON POST body

POST requests carry their payload in the request body, not the URL. ColdFusion exposes it via `getHttpRequestData().content`:

```cfml
<cfscript>
  rawBody = toString(getHttpRequestData().content);

  if (!isJSON(rawBody)) {
    cfheader(statuscode="400", statustext="Bad Request");
    writeOutput(serializeJSON({ "error": "Request body must be valid JSON" }));
    abort;
  }

  data = deserializeJSON(rawBody);

  if (!structKeyExists(data, "title") || !len(trim(data.title))) {
    cfheader(statuscode="400", statustext="Bad Request");
    writeOutput(serializeJSON({ "error": "title is required" }));
    abort;
  }

  queryExecute(
    "INSERT INTO hd_tickets (title, description, status, priority, user_id, created_at)
     VALUES (:title, :desc, 'open', :priority, :user_id, CURRENT_TIMESTAMP)",
    {
      title:    { value: left(trim(data.title), 255), cfsqltype: "cf_sql_varchar" },
      desc:     { value: data.description ?: "",       cfsqltype: "cf_sql_varchar" },
      priority: { value: data.priority    ?: "medium", cfsqltype: "cf_sql_varchar" },
      user_id:  { value: data.user_id     ?: 1,        cfsqltype: "cf_sql_integer" }
    },
    { datasource: "training_db" }
  );

  cfheader(statuscode="201", statustext="Created");
  writeOutput(serializeJSON({ "created": true }));
</cfscript>
```

---

## 4. Routing on HTTP method

::image-box
---
:src: __static__/cfml-http-method-routing-v1.png
:alt: Decision tree showing cgi.REQUEST_METHOD at the root — three branches lead to GET returning ticket list or single ticket, POST creating a new ticket returning 201 Created, and DELETE closing a ticket returning 200 OK — a fourth branch labelled other leads to a 405 Method Not Allowed response
:max-width: 760px
---
_Route on `cgi.REQUEST_METHOD` to handle GET, POST, and DELETE in a single `.cfm` file._
::

ColdFusion exposes the HTTP verb via `cgi.REQUEST_METHOD`. A single file can handle all methods:

```cfml
<cfscript>
  cfheader(name="Content-Type", value="application/json");
  method = cgi.REQUEST_METHOD;

  if (method == "GET")    { /* list or fetch */ }
  if (method == "POST")   { /* create */        }
  if (method == "DELETE") { /* close ticket */  }

  cfheader(statuscode="405", statustext="Method Not Allowed");
  writeOutput(serializeJSON({ "error": "Method not allowed" }));
  abort;
</cfscript>
```

---

## 5. CFC Service pattern

Large APIs benefit from separating the HTTP layer (request/response handling) from the data layer (queries and business logic). `TicketService.cfc` is already deployed and provides a clean interface:

```cfml
<cfscript>
  svc     = createObject("component", "TicketService");
  tickets = svc.getAll();           // array of structs
  ticket  = svc.getById(1);         // struct + comments array
  newId   = svc.create("My ticket", "Details here", 1, "high");
  svc.close(newId);
</cfscript>
```

The endpoint file stays thin — it validates input, calls the service, and writes the response. The service holds all the SQL. This separation makes both easier to test and maintain.

---

## Activity 1 — Explore the live API

The endpoint is already running. Use `curl` to inspect it:

```bash
# List all tickets
curl -s http://localhost:8500/api/tickets.cfm | python3 -m json.tool

# Confirm Content-Type header
curl -s -I http://localhost:8500/api/tickets.cfm | grep -i content-type
```

You should see a JSON response with a `total` count and a `tickets` array. The `Content-Type` header must be `application/json`.

::hint-box
---
:summary: 💡 What does python3 -m json.tool do?
---
It pretty-prints raw JSON with indentation. Without it, `curl` returns the JSON as a single compact line. Use it any time you want to read the response clearly in the terminal.
::

::simple-task
---
:tasks: tasks
:name: verify_api_list
---
#active
`GET /api/tickets.cfm` must return HTTP 200.

#completed
`GET /api/tickets.cfm` → 200 OK. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_json_content_type
---
#active
The response must include `Content-Type: application/json`.

#completed
`Content-Type: application/json` confirmed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_json_valid
---
#active
The response body must be valid JSON.

#completed
Valid JSON response. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_tickets_array
---
#active
The JSON response must contain at least 1 ticket (`total` > 0).

#completed
Response contains tickets. ✓
::

---

## Activity 2 — Fetch a single ticket

Add the `?id=` parameter to fetch one specific ticket:

```bash
# Fetch ticket #1
curl -s "http://localhost:8500/api/tickets.cfm?id=1" | python3 -m json.tool

# Test a 404 — ticket 999 does not exist
curl -s -w "\nHTTP %{http_code}\n" "http://localhost:8500/api/tickets.cfm?id=999"
```

The first command should return a single ticket object with a `title` field. The second should return HTTP 404 and `{"error":"Ticket not found"}`.

::simple-task
---
:tasks: tasks
:name: verify_single_ticket
---
#active
`GET /api/tickets.cfm?id=1` must return a ticket object with a `title` field.

#completed
Single ticket fetch works. ✓
::

---

## Activity 3 — Create a ticket via POST

Send a JSON body to create a new ticket:

```bash
curl -s -X POST http://localhost:8500/api/tickets.cfm \
  -H "Content-Type: application/json" \
  -d '{"title":"Monitor flickering","description":"Display flickers on login","priority":"high","user_id":3}' \
  | python3 -m json.tool
```

A successful response returns HTTP 201 and `{"created": true}`. Verify the ticket was actually saved by listing again:

```bash
curl -s http://localhost:8500/api/tickets.cfm | python3 -m json.tool | grep -A3 "Monitor flickering"
```

::hint-box
---
:summary: 💡 Why 201 and not 200?
---
HTTP **201 Created** is the correct status code when a new resource has been successfully created. Using `200 OK` for a POST that creates data is technically incorrect — it makes it harder for clients to distinguish between "I retrieved data" and "I created something new".
::

::simple-task
---
:tasks: tasks
:name: verify_post_ticket
---
#active
`POST /api/tickets.cfm` with a JSON body must return `{"created": true}`.

#completed
POST creates a new ticket. ✓
::

---

## Key takeaways

| Concept | ColdFusion approach |
|---|---|
| Set response type | `cfheader(name="Content-Type", value="application/json")` |
| Serialize data | `serializeJSON(struct_or_array)` |
| Parse JSON input | `deserializeJSON(toString(getHttpRequestData().content))` |
| HTTP status codes | `cfheader(statuscode="404", statustext="Not Found")` |
| Route on verb | `cgi.REQUEST_METHOD` — `"GET"`, `"POST"`, `"DELETE"` |
| Safe SQL params | `cfqueryparam` / `queryExecute` named bindings |
| Halt execution | `abort` after writing the response |

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

::remark-box
Found a bug or an issue with this lesson? Please reach out — your feedback helps improve the course for everyone.

📧 Alex — mercadoalex[at]gmail.com
::
