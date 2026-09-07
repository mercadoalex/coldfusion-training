---
kind: unit

title: HTML5 & the Modern Browser Platform

name: html5-advanced-coldfusion-unit-1
---

## HTML5 + ColdFusion

HTML5 is not a dated technology — it is the **current living standard** for the web, maintained continuously by WHATWG. Every browser ships HTML5. There is no HTML6. When you write `<!DOCTYPE html>` today you are writing HTML5, and the platform keeps gaining capabilities (Web Components, View Transitions, Container Queries, WASM) without ever changing that doctype.

ColdFusion's role is always **server-side**: it queries databases, processes business logic, and renders HTML or JSON. The browser's HTML5 APIs — localStorage, canvas, geolocation, WebSockets, fetch — consume that output. CFML never runs in the browser.

::hint-box
---
:summary: What actually evolved since "HTML5 launched"?
---

The term "HTML5" entered common use around 2010 when browsers started shipping canvas, video, and localStorage. What has changed since then is not the standard itself but the richness of the platform built on top of it:

| Era | New capabilities |
|---|---|
| 2010–2014 | `<canvas>`, `<video>`, `<audio>`, localStorage, geolocation, WebSockets |
| 2015–2018 | ES6 modules, Fetch API, Service Workers, CSS Grid |
| 2019–2022 | Web Components, CSS custom properties, Intersection Observer |
| 2023–today | View Transitions API, Container Queries, CSS `@layer`, WASM threads |

All of this runs on the same `<!DOCTYPE html>` foundation. When this course says "HTML5", it means the full modern browser platform — not just the 2010 feature set.

::

::image-box
---
:src: __static__/cfml-server-browser-data-flow-v1.png
:alt: Data-flow diagram showing the server-browser boundary — on the left the ColdFusion server box contains CFML code and a database cylinder; a rightward arrow labelled "HTTP response (HTML + embedded JSON)" crosses the boundary; on the right a browser box shows the DOM tree and JavaScript code consuming the data with HTML5 APIs (localStorage.setItem, fetch(), canvas.getContext) — illustrating that CFML runs only on the server, never in the browser
:max-width: 860px
---
_ColdFusion generates the HTML and embeds JSON; all HTML5 API calls execute entirely in the browser._
::

---

## Basic HTML5 page with dynamic CFML

```cfml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CF + HTML5 — Help Desk</title>
</head>
<body>
<cfscript>
  tickets = queryExecute(
    "SELECT t.id, t.title, t.priority
     FROM   hd_tickets t
     WHERE  t.status = 'open'
     ORDER  BY t.created_at DESC",
    {},
    {datasource: "training_db"}
  );
</cfscript>

<ul id="ticket-list">
  <cfoutput query="tickets">
    <li data-id="#id#" data-priority="#priority#">#encodeForHTML(title)#</li>
  </cfoutput>
</ul>

<script>
  const items = document.querySelectorAll("#ticket-list li");
  items.forEach(li => {
    li.addEventListener("click", () => {
      localStorage.setItem("lastSelected", li.dataset.id);
    });
  });
</script>
</body>
</html>
```

Notice `encodeForHTML()` — always encode untrusted data before rendering it in HTML to prevent XSS.

---

## Two patterns for sending CFML data to JavaScript

There are two established approaches for getting server-side data into browser JavaScript. Which one you use depends on your architecture.

::hint-box
---
:summary: Embedded JSON (SSR) vs fetch — when to use each?
---

**Pattern 1 — Embedded JSON (Server-Side Rendering):**
The server renders the full page including the data baked in as a JavaScript variable. No second HTTP request needed.

```cfml
<cfscript>
  jsonData = serializeJSON(queryToArray(queryExecute(
    "SELECT id, title, status FROM hd_tickets", {}, {datasource:"training_db"}
  )));
</cfscript>
<script>
  const tickets = <cfoutput>#jsonData#</cfoutput>;
  renderTable(tickets);
</script>
```

✓ Fewer round-trips — data is available instantly on page load
✓ Better for SEO — content is in the initial HTML
✓ Simpler — no CORS headers, no loading states needed
✗ Page must fully reload to refresh data

---

**Pattern 2 — fetch() API (Client-Side Data Fetching):**
The page loads first, then JavaScript calls a CF JSON endpoint asynchronously.

```javascript
async function loadTickets() {
  const res  = await fetch('/api/tickets.cfm');
  const data = await res.json();
  renderTable(data.tickets);
}
loadTickets();
```

✓ Page stays interactive — data refreshes without full reload
✓ Works perfectly with React, Vue, Angular frontends
✓ Supports real-time updates (poll or WebSocket)
✗ Requires CORS headers on the CF endpoint
✗ Needs loading/error states in the UI

**The practical rule:** use embedded JSON for simple server-rendered pages; use `fetch()` when building a SPA or when data needs to refresh without a page reload.

::

## Passing CFML data to JavaScript (embedded JSON)

::image-box
---
:src: __static__/cfml-serializejson-to-js-v1.png
:alt: Side-by-side comparison of two data patterns — left panel "Embedded JSON (SSR)" shows CFML serializeJSON() output baked into a script tag as a const variable, labelled "one request, data ready on load"; right panel "fetch() pattern" shows a browser fetch call to /api/tickets.cfm returning JSON asynchronously, labelled "second request, works with React/Vue"
:max-width: 860px
---
_Two patterns for sending CF data to the browser — embedded JSON (SSR) for simple pages, `fetch()` for SPAs and dynamic updates._
::


Inject server-side data as a JSON literal into a JavaScript variable:

```cfml
<cfscript>
  data = queryExecute(
    "SELECT id, title, priority, status FROM hd_tickets",
    {}, {datasource: "training_db"}
  );
  jsonData = serializeJSON(queryToArray(data));
</cfscript>
<script>
  const tickets = <cfoutput>#jsonData#</cfoutput>;
  console.log(tickets);
</script>
```

`queryToArray()` converts a CF query object to an array of structs, which `serializeJSON()` then renders as a JSON array.

---

::hint-box
---
:summary: What is CORS and why does fetch() need it?
---

**CORS — Cross-Origin Resource Sharing** is a browser security mechanism that controls which domains are allowed to read responses from a server. It was introduced as a W3C standard in **2014** (implemented in all major browsers by 2015) to replace the older, less flexible JSONP workaround.

**The Same-Origin Policy (the problem CORS solves):**
Browsers enforce a rule called the Same-Origin Policy — a page at `https://app.example.com` cannot read responses from `https://api.other.com` unless the server explicitly permits it. This prevents malicious scripts on one site from silently reading data from another (e.g. your bank).

**How CORS works:**
When JavaScript calls `fetch('https://api.other.com/data')`, the browser automatically adds an `Origin` header. The server must respond with `Access-Control-Allow-Origin` — if it doesn't, the browser blocks the response (the request still happens on the server, but JavaScript never sees the result).

**In ColdFusion you add CORS headers in two places:**

```cfml
<!--- Option 1: per-endpoint in your .cfm file --->
<cfheader name="Access-Control-Allow-Origin" value="*">
<cfheader name="Access-Control-Allow-Methods" value="GET, POST, DELETE, OPTIONS">
<cfheader name="Access-Control-Allow-Headers" value="Content-Type, Authorization">
```

```cfml
<!--- Option 2: globally in Application.cfc onRequestStart — preferred --->
public boolean function onRequestStart(string targetPage) {
  cfheader(name="Access-Control-Allow-Origin",  value="https://your-frontend.com");
  cfheader(name="Access-Control-Allow-Methods", value="GET, POST, DELETE, OPTIONS");
  cfheader(name="Access-Control-Allow-Headers", value="Content-Type, Authorization");
  if (cgi.REQUEST_METHOD == "OPTIONS") { abort; }  // handle preflight
  return true;
}
```

**`*` vs specific origin:**
- `Access-Control-Allow-Origin: *` — allows any domain (fine for public APIs, dangerous for authenticated APIs)
- `Access-Control-Allow-Origin: https://app.example.com` — allows only your specific frontend (correct for authenticated APIs)

**Why embedded JSON doesn't need CORS:**
When you use `serializeJSON()` to bake data into the page, the browser sees it as part of the same HTML document — no cross-origin request is made, so no CORS header is needed.

**The practical rule:** if your CF endpoint is called by `fetch()` from a different domain (or a different port on the same domain), add CORS headers. If CF renders the page and data together, CORS is irrelevant.

::

## HTML5 Form validation + CFML processing

HTML5 provides built-in client-side validation via attributes like `required`, `minlength`, `type="email"`. ColdFusion handles the server-side processing when the form submits.

```cfml
<!DOCTYPE html>
<html>
<body>
<form method="post" action="create_ticket.cfm">
  <input type="text"   name="title"       required minlength="5" maxlength="255">
  <textarea            name="description" required></textarea>
  <select              name="priority">
    <option>low</option><option selected>medium</option>
    <option>high</option><option>critical</option>
  </select>
  <button type="submit">Submit Ticket</button>
</form>
</body>
</html>
```

> **Never rely on client-side validation alone.** Always re-validate on the server inside your `.cfm` handler.

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm` with a proper `<!DOCTYPE html>` and at least one `<cfoutput>` or `writeOutput()` call.
2. Verify:

```bash
curl -s http://localhost:8500/html5_demo.cfm | grep -i "DOCTYPE"
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_html5_page
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm` — must return HTTP 200.

#completed
`html5_demo.cfm` is accessible. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_html5_doctype
---
#active
Add `<!DOCTYPE html>` to `html5_demo.cfm`.

#completed
HTML5 doctype is present. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_dynamic_output
---
#active
Add at least one `<cfoutput>` or `writeOutput()` call to `html5_demo.cfm`.

#completed
Dynamic CFML output is present in the page. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.html5-page-12951dc7
---
::
