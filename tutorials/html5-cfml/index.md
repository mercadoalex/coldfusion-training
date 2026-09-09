---
kind: tutorial

title: HTML5 Media Page with Dynamic CFML Data

description: |
  Build an HTML5 page that reads ticket data from the database and
  renders it with HTML5 semantic elements and data attributes.

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
---

## Steps

### 1. Create html5_demo.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm`:

```cfml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Help Desk — Open Tickets</title>
</head>
<body>
  <header><h1>Open Tickets</h1></header>
  <main>
<cfscript>
  tickets = queryExecute(
    "SELECT id, title, priority FROM hd_tickets WHERE status = 'open' ORDER BY created_at DESC",
    {}, {datasource: "training_db"}
  );
</cfscript>
  <ul id="ticket-list">
    <cfoutput query="tickets">
      <li data-id="#id#" data-priority="#priority#">
        #encodeForHTML(title)#
      </li>
    </cfoutput>
  </ul>
  </main>
</body>
</html>
```

### 2. Verify

```bash
curl -s http://localhost:8500/html5_demo.cfm | grep -i "DOCTYPE"
curl -s http://localhost:8500/html5_demo.cfm | grep "data-id"
```

### 3. Pass data to JavaScript

Add this script block before `</body>`:

```cfml
<cfscript>
  jsonData = serializeJSON(queryToArray(tickets));
</cfscript>
<script>
  const tickets = <cfoutput>#jsonData#</cfoutput>;
  console.log("Loaded", tickets.length, "tickets");
</script>
```

Open the browser console on the CF tab to see the ticket array logged.
