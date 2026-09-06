---
kind: unit

title: Building REST APIs with CFML

name: building-rest-apis-cfml-unit-1
---

## Overview

Your environment has a live Help Desk database (`training_db`) with four tables:
`hd_departments`, `hd_users`, `hd_tickets`, and `hd_comments`. A fully working
REST endpoint is already deployed at `/api/tickets.cfm`.

Open the **API Console** tab to interact with it visually, then study the code below to understand how it works.

```
http://localhost:8500/api-test.cfm    ← interactive API console
http://localhost:8500/api/tickets.cfm ← raw JSON endpoint
```

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

Test it:
```bash
curl -s http://localhost:8500/api/tickets.cfm | python3 -m json.tool
```

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

```bash
curl -s "http://localhost:8500/api/tickets.cfm?id=3" | python3 -m json.tool
curl -s "http://localhost:8500/api/tickets.cfm?id=999"   # → 404
```

---

## 3. Accepting a JSON POST body

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

```bash
curl -s -X POST http://localhost:8500/api/tickets.cfm \
  -H "Content-Type: application/json" \
  -d '{"title":"Keyboard missing","priority":"low","user_id":2}' \
  | python3 -m json.tool
```

---

## 4. Routing on HTTP method

ColdFusion exposes the request method via `cgi.REQUEST_METHOD`:

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

Large APIs benefit from separating the HTTP layer from the data layer.
`TicketService.cfc` (already deployed in the webroot) provides a reusable component:

```cfml
<cfscript>
  svc     = createObject("component", "TicketService");
  tickets = svc.getAll();           // array of structs
  ticket  = svc.getById(1);         // struct + comments array
  newId   = svc.create("My ticket", "Details here", 1, "high");
  svc.close(newId);
</cfscript>
```

---

## 6. Try it — curl exercises

```bash
# List all tickets
curl -s http://localhost:8500/api/tickets.cfm | python3 -m json.tool

# Get ticket #2 with its comments
curl -s "http://localhost:8500/api/tickets.cfm?id=2" | python3 -m json.tool

# Create a new ticket
curl -s -X POST http://localhost:8500/api/tickets.cfm \
  -H "Content-Type: application/json" \
  -d '{"title":"Monitor flickering","description":"Display flickers","priority":"high","user_id":3}' \
  | python3 -m json.tool

# Close a ticket
curl -s -X DELETE "http://localhost:8500/api/tickets.cfm?id=1" | python3 -m json.tool
```

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

## Hands-on checks

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
