---
kind: lesson

title: HTML5 and Advanced ColdFusion Features
description: |
  Integrate HTML5 capabilities with ColdFusion applications.
  Learn how to combine CFML with modern HTML5 APIs, dynamic components,
  and considerations for modern web applications.

name: html5-advanced-coldfusion
slug: html5-advanced-coldfusion

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- html5
- cfml

playground:
  name: cf-alex-edcdf975

tasks:
  verify_html5_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/html5_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "html5_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "html5_demo.cfm is accessible"

  verify_html5_doctype:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_page
    run: |
      BODY=$(curl -s http://localhost:8500/html5_demo.cfm)
      if ! echo "${BODY}" | grep -qi "<!DOCTYPE html>"; then
        echo "html5_demo.cfm is missing HTML5 doctype"
        exit 1
      fi
      echo "HTML5 doctype is present"

  verify_dynamic_output:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_doctype
    run: |
      BODY=$(curl -s http://localhost:8500/html5_demo.cfm)
      if ! echo "${BODY}" | grep -qi "cfoutput\|#"; then
        FILE="/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm"
        if ! grep -q "cfoutput\|writeOutput" "${FILE}" 2>/dev/null; then
          echo "No dynamic CFML output found in html5_demo.cfm"
          exit 1
        fi
      fi
      echo "Dynamic CFML output is present"
---

## HTML5 + ColdFusion

ColdFusion renders server-side content that feeds into HTML5 features like
local storage, canvas, geolocation, and web workers.

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
  // read server data into JS
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

## Passing CFML data to JavaScript

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

## HTML5 Form validation + CFML processing

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
