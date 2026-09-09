---
kind: tutorial

title: Safe SQL — INSERT and UPDATE with cfqueryparam

description: |
  Write a ticket creation form that uses cfqueryparam for every
  bound parameter and verify the record is saved to training_db.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- sql
- cfqueryparam

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Create tickets.cfm (list + form)

Create `/opt/coldfusion2025/cfusion/wwwroot/tickets.cfm`:

```cfml
<!--- Handle POST --->
<cfif cgi.REQUEST_METHOD eq "POST">
  <cfquery datasource="training_db">
    INSERT INTO hd_tickets (title, description, status, priority, user_id, created_at)
    VALUES (
      <cfqueryparam value="#form.title#"       cfsqltype="cf_sql_varchar">,
      <cfqueryparam value="#form.description#" cfsqltype="cf_sql_varchar">,
      'open',
      <cfqueryparam value="#form.priority#"    cfsqltype="cf_sql_varchar">,
      <cfqueryparam value="1"                  cfsqltype="cf_sql_integer">,
      <cfqueryparam value="#now()#"            cfsqltype="cf_sql_timestamp">
    )
  </cfquery>
</cfif>

<!--- List tickets --->
<cfquery name="tickets" datasource="training_db">
  SELECT t.id, t.title, t.status, t.priority, u.name AS submitter
  FROM   hd_tickets t
  JOIN   hd_users   u ON u.id = t.user_id
  ORDER  BY t.created_at DESC
</cfquery>

<!DOCTYPE html>
<html>
<body>
<form method="post">
  Title: <input type="text" name="title" required><br>
  Description: <textarea name="description"></textarea><br>
  Priority:
  <select name="priority">
    <option>low</option><option selected>medium</option>
    <option>high</option><option>critical</option>
  </select><br>
  <button type="submit">Create Ticket</button>
</form>

<hr>
<cfoutput query="tickets">
  <p><strong>#tickets.id#</strong> — #encodeForHTML(title)# [#status# / #priority#]</p>
</cfoutput>
</body>
</html>
```

### 2. Test the form

```bash
curl -s -X POST http://localhost:8500/tickets.cfm \
  -d "title=Tutorial+test+ticket&description=Created+via+curl&priority=low"
```

### 3. Verify cfqueryparam is present

```bash
grep -i "cfqueryparam" /opt/coldfusion2025/cfusion/wwwroot/tickets.cfm
```
