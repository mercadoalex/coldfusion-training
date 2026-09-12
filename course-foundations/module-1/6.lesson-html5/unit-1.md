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

## Activity 1 — Create a basic HTML5 page with dynamic CFML

**Activity:** In the **Terminal** tab, create `html5_demo.cfm` — an HTML5 page that uses the correct doctype and renders a dynamic timestamp with CFML:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CF + HTML5 Demo</title>
</head>
<body>
  <h1>ColdFusion + HTML5</h1>
  <cfoutput>
    <p>Server time: <strong>#timeFormat(now(), "HH:mm:ss")#</strong></p>
    <p>Today is: <strong>#dateFormat(now(), "dddd, mmmm d, yyyy")#</strong></p>
  </cfoutput>
</body>
</html>
EOF
```

Verify the file is served:

```bash
curl -s http://localhost:8500/html5_demo.cfm | head -20
```

::image-box
---
:src: __static__/browser-html5-demo-v1.png
:alt: Browser showing html5_demo.cfm output with the H1 heading "ColdFusion + HTML5" and the server time and date rendered dynamically by CFML
:max-width: 860px
---
_`html5_demo.cfm` served with a live timestamp rendered by ColdFusion._
::

::simple-task
---
:tasks: tasks
:name: verify_html5_page
---
#active
Click the **Terminal** tab and run the `sudo tee` command above to create `html5_demo.cfm`, then open `/html5_demo.cfm` in the browser tab to confirm it loads.

#completed
`html5_demo.cfm` is accessible and returns HTTP 200. ✓
::

---

## HTML5 doctype and page structure

The `<!DOCTYPE html>` declaration on line 1 is the only doctype you need for HTML5. It tells the browser to use the modern standards-mode parser — without it, browsers fall back to quirks mode with inconsistent layout behaviour.

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

## Activity 2 — Add the HTML5 doctype and verify

**Activity:** Confirm that `html5_demo.cfm` contains the HTML5 doctype. If you used the `tee` command in Activity 1 it is already there. Check with:

```bash
curl -s http://localhost:8500/html5_demo.cfm | grep -i "DOCTYPE"
```

You should see `<!DOCTYPE html>` in the output.

::image-box
---
:src: __static__/terminal-html5-doctype-check-v1.png
:alt: Terminal showing the curl command output with DOCTYPE html visible at the top of the response
:max-width: 860px
---
_Terminal confirming the HTML5 doctype is present in the page source._
::

::simple-task
---
:tasks: tasks
:name: verify_html5_doctype
---
#active
Run the `curl` command above and confirm `<!DOCTYPE html>` appears in the response.

#completed
HTML5 doctype is present in `html5_demo.cfm`. ✓
::

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

---

## Activity 3 — Add dynamic CFML output to the page

**Activity:** Update `html5_demo.cfm` to include a `writeOutput()` or `<cfoutput>` call that renders something dynamic. The file already has this from Activity 1 — this task simply confirms it. You can also extend it by embedding a JSON array of items:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CF + HTML5 Demo</title>
</head>
<body>
  <h1>ColdFusion + HTML5</h1>

  <cfoutput>
    <p>Server time: <strong>#timeFormat(now(), "HH:mm:ss")#</strong></p>
    <p>Today is: <strong>#dateFormat(now(), "dddd, mmmm d, yyyy")#</strong></p>
  </cfoutput>

  <cfscript>
    items = ["Apples", "Bananas", "Cherries"];
    jsonItems = serializeJSON(items);
  </cfscript>

  <ul id="fruit-list"></ul>

  <script>
    const fruits = <cfoutput>#jsonItems#</cfoutput>;
    const ul = document.getElementById("fruit-list");
    fruits.forEach(f => {
      const li = document.createElement("li");
      li.textContent = f;
      ul.appendChild(li);
    });
  </script>
</body>
</html>
EOF
```

Open `/html5_demo.cfm` in the **ColdFusion 2025** browser tab to verify the fruit list renders.

```bash
curl -s http://localhost:8500/html5_demo.cfm | grep -i "writeOutput\|cfoutput\|serializeJSON"
```

::image-box
---
:src: __static__/browser-html5-dynamic-output-v1.png
:alt: Browser showing html5_demo.cfm with the server time, today's date, and a bulleted fruit list rendered by JavaScript consuming the CFML-embedded JSON array
:max-width: 860px
---
_`html5_demo.cfm` showing dynamic CFML output and a JavaScript-rendered list populated from embedded JSON._
::

::simple-task
---
:tasks: tasks
:name: verify_dynamic_output
---
#active
Update `html5_demo.cfm` with `<cfoutput>` or `writeOutput()` and reload the page to confirm dynamic content appears.

#completed
Dynamic CFML output is present in the page. ✓
::

---

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
