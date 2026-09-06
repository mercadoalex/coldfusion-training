---
kind: unit

title: HTML5 and Advanced ColdFusion Features

name: html5-advanced-coldfusion-unit-1
---

## HTML5 + ColdFusion

ColdFusion renders server-side content that feeds into HTML5 features like local storage, canvas, geolocation, and web workers. The pattern is always the same: CFML runs on the server, produces HTML/JSON, and the browser's HTML5 APIs consume it.

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

## Passing CFML data to JavaScript

::image-box
---
:src: __static__/cfml-serializejson-to-js-v1.png
:alt: Split-view diagram showing CFML on the left with a queryExecute() call and serializeJSON() producing a JSON string, and on the right the rendered HTML source with a JavaScript const tickets = [...] variable containing the serialised data — an arrow spans the middle labelled "serializeJSON() bridges the server/client boundary"
:max-width: 860px
---
_`serializeJSON()` is the standard bridge — converts any CF variable to a JSON literal you can embed directly in a `<script>` block._
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
