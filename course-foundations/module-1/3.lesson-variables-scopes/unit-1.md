---
kind: unit

title: Variables, Data Types & Scopes

name: variables-data-types-scopes-unit-1
---

## Data types

ColdFusion is dynamically typed. Variables are created on assignment and their type is inferred at runtime.

| Type | Example |
|---|---|
| String | `"Hello"` |
| Numeric | `42`, `3.14` |
| Boolean | `true`, `false`, `yes`, `no` |
| Date | `now()`, `"2026-09-03"` |
| Array | `[1, 2, 3]` |
| Struct | `{name: "Alex", age: 30}` |
| Query | result of `cfquery` / `queryExecute()` |

::image-box
---
:src: __static__/cfml-data-types-overview-v1.png
:alt: Six labelled boxes arranged in a 2×3 grid on a white background — String (orange border, example "Hello World"), Numeric (blue, example 42 and 3.14), Boolean (green, example true/false/yes/no), Array (purple, bracket notation [1,2,3]), Struct (teal, curly-brace notation {key: value}), and Query (grey, table icon with rows and columns) — each box shows the type name and a short CFML literal example
:max-width: 860px
---
_CFML's six core data types — dynamically inferred at runtime, no explicit type declarations needed._
::

---

## Variable scopes

ColdFusion organises variables into named scopes. Every scope has a different lifetime and visibility.

| Scope | Prefix | Lifetime | Typical use |
|---|---|---|---|
| `variables` | `variables.` | Single request | Default local scope for a page/CFC |
| `url` | `url.` | Single request | Query-string parameters |
| `form` | `form.` | Single request | POST form fields |
| `request` | `request.` | Single request | Pass data between included files |
| `session` | `session.` | User session | Per-user state (cart, login) |
| `application` | `application.` | App lifetime | Shared config, counters |
| `server` | `server.` | Server lifetime | Rarely written; read CF/Lucee version |

The `variables` scope is the default when you omit a prefix. Always prefix `session.*` and `application.*` explicitly.

::image-box
---
:src: __static__/cfml-scope-lifetimes-v1.png
:alt: Horizontal bar chart showing CFML scope lifetimes from shortest to longest — from top: url/form/request (single request, narrow bar), variables (single request, same width), local/arguments (function call duration, shortest), session (user session lifetime, medium bar), application (application lifetime, long bar), server (server process lifetime, longest bar) — bars are colour-coded from short (red) to long (green)
:max-width: 860px
---
_Scope lifetimes compared — request-scoped variables are cheapest; application-scoped variables persist for the life of the process._
::

---

## Code example

```cfml
<cfscript>
  // variables scope (default — page only)
  variables.name = "Alex";

  // url scope (query string params)
  writeOutput(url.name ?: "no name in URL");

  // session scope (per user session)
  session.userId = 42;

  // application scope (shared across all requests)
  application.siteName = "CF Training";
</cfscript>
```

---

## Scope resolution order

::image-box
---
:src: __static__/cfml-scope-resolution-order-v1.png
:alt: Numbered vertical flowchart showing ColdFusion's unqualified variable lookup order — step 1: local (inside CFC function), step 2: arguments, step 3: thread, step 4: query (inside cfloop query), step 5: variables, step 6: cgi/file/url/form/cookie/client — each step is a rounded rectangle, connected by downward arrows, with a "found → stop" branch on the right side of each box
:max-width: 640px
---
_When you omit a scope prefix, CF walks this resolution chain top-to-bottom — always prefix to be explicit._
::

When you write just `name` without a prefix, ColdFusion checks scopes in this order:

1. `local` (inside a CFC function)
2. `arguments`
3. `thread`
4. `query` (inside a `<cfloop query="...">`)
5. `variables`
6. `cgi`, `file`, `url`, `form`, `cookie`, `client`

Always prefix to be explicit and avoid scope-bleed bugs.

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/scopes.cfm`.
2. Output `variables.name`, a value from `url.name` (passed as query string), and set `session.userId`.
3. Verify:

```bash
curl -s "http://localhost:8500/scopes.cfm?name=TestUser"
```

The response should contain **TestUser** and show scope usage for `variables.` somewhere in the output.

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_scopes_page
---
#active
Create `scopes.cfm` — the response must contain the words **variables**, **session**, or **application**.

#completed
`scopes.cfm` demonstrates variable scopes. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_variables_scope
---
#active
Use the `variables.` prefix explicitly in `scopes.cfm`.

#completed
The `variables` scope is explicitly used. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_url_scope
---
#active
Visit `scopes.cfm?name=TestUser` — the response must echo back **TestUser** from the URL scope.

#completed
URL scope is working — `?name=TestUser` is reflected in the output. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.scope-inspector-3260417b
---
::
