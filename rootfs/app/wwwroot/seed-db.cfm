<!---
  seed-db.cfm — Seed the training_db with a Help Desk / Ticketing schema.
  Safe to run multiple times — uses IF NOT EXISTS + skips inserts if data exists.
  Access: http://localhost:8500/seed-db.cfm
--->
<cfsilent>
<cfsetting requesttimeout="30">

<cfset errors = []>
<cfset steps  = []>

<!--- ── Schema ──────────────────────────────────────────────────────────── --->

<!--- departments --->
<cftry>
  <cfquery datasource="training_db">
    CREATE TABLE IF NOT EXISTS hd_departments (
      id          INT AUTO_INCREMENT PRIMARY KEY,
      name        VARCHAR(100) NOT NULL,
      email       VARCHAR(150)
    )
  </cfquery>
  <cfset arrayAppend(steps, "hd_departments table OK")>
  <cfcatch><cfset arrayAppend(errors, "hd_departments: " & cfcatch.message)></cfcatch>
</cftry>

<!--- users --->
<cftry>
  <cfquery datasource="training_db">
    CREATE TABLE IF NOT EXISTS hd_users (
      id            INT AUTO_INCREMENT PRIMARY KEY,
      username      VARCHAR(50)  NOT NULL UNIQUE,
      full_name     VARCHAR(150) NOT NULL,
      email         VARCHAR(150) NOT NULL,
      role          VARCHAR(20)  NOT NULL DEFAULT 'user',
      department_id INT,
      created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
    )
  </cfquery>
  <cfset arrayAppend(steps, "hd_users table OK")>
  <cfcatch><cfset arrayAppend(errors, "hd_users: " & cfcatch.message)></cfcatch>
</cftry>

<!--- tickets --->
<cftry>
  <cfquery datasource="training_db">
    CREATE TABLE IF NOT EXISTS hd_tickets (
      id            INT AUTO_INCREMENT PRIMARY KEY,
      title         VARCHAR(255) NOT NULL,
      description   CLOB,
      status        VARCHAR(20)  NOT NULL DEFAULT 'open',
      priority      VARCHAR(10)  NOT NULL DEFAULT 'medium',
      category      VARCHAR(50),
      requester_id  INT          NOT NULL,
      assignee_id   INT,
      department_id INT,
      created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
      updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
      resolved_at   TIMESTAMP
    )
  </cfquery>
  <cfset arrayAppend(steps, "hd_tickets table OK")>
  <cfcatch><cfset arrayAppend(errors, "hd_tickets: " & cfcatch.message)></cfcatch>
</cftry>

<!--- comments --->
<cftry>
  <cfquery datasource="training_db">
    CREATE TABLE IF NOT EXISTS hd_comments (
      id         INT AUTO_INCREMENT PRIMARY KEY,
      ticket_id  INT          NOT NULL,
      author_id  INT          NOT NULL,
      body       CLOB         NOT NULL,
      is_internal BOOLEAN     DEFAULT FALSE,
      created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
    )
  </cfquery>
  <cfset arrayAppend(steps, "hd_comments table OK")>
  <cfcatch><cfset arrayAppend(errors, "hd_comments: " & cfcatch.message)></cfcatch>
</cftry>

<!--- ── Seed data (skip if already present) ─────────────────────────────── --->

<cfquery datasource="training_db" name="checkDepts">
  SELECT COUNT(*) AS cnt FROM hd_departments
</cfquery>

<cfif checkDepts.cnt EQ 0>

  <!--- Departments --->
  <cftry>
    <cfquery datasource="training_db">
      INSERT INTO hd_departments (name, email) VALUES
        ('IT Infrastructure', 'it@company.local'),
        ('Software Development', 'dev@company.local'),
        ('Human Resources', 'hr@company.local'),
        ('Finance', 'finance@company.local')
    </cfquery>
    <cfset arrayAppend(steps, "Departments seeded")>
    <cfcatch><cfset arrayAppend(errors, "dept seed: " & cfcatch.message)></cfcatch>
  </cftry>

  <!--- Users --->
  <cftry>
    <cfquery datasource="training_db">
      INSERT INTO hd_users (username, full_name, email, role, department_id) VALUES
        ('jsmith',   'John Smith',    'jsmith@company.local',   'admin',  1),
        ('mgarcia',  'Maria Garcia',  'mgarcia@company.local',  'agent',  1),
        ('twilson',  'Tom Wilson',    'twilson@company.local',  'agent',  2),
        ('alee',     'Amy Lee',       'alee@company.local',     'user',   2),
        ('rjones',   'Robert Jones',  'rjones@company.local',   'user',   3),
        ('scarroll', 'Sue Carroll',   'scarroll@company.local', 'user',   4)
    </cfquery>
    <cfset arrayAppend(steps, "Users seeded")>
    <cfcatch><cfset arrayAppend(errors, "user seed: " & cfcatch.message)></cfcatch>
  </cftry>

  <!--- Tickets --->
  <cftry>
    <cfquery datasource="training_db">
      INSERT INTO hd_tickets (title, description, status, priority, category, requester_id, assignee_id, department_id) VALUES
        ('Cannot connect to VPN',         'Getting error 619 when connecting from home.',              'open',        'high',   'Network',  4, 2, 1),
        ('New laptop setup request',      'Need MacBook Pro configured for new hire starting Monday.', 'in_progress', 'medium', 'Hardware', 5, 2, 1),
        ('Email not syncing on mobile',   'Outlook on iPhone stopped syncing after iOS update.',       'open',        'low',    'Email',    6, 3, 1),
        ('Deploy staging environment',    'Need a staging server for Q4 release branch.',              'in_progress', 'high',   'DevOps',   4, 3, 2),
        ('Password reset request',        'Locked out after too many failed attempts.',                'resolved',    'medium', 'Access',   5, 2, 3),
        ('Software license renewal',      'Adobe CC licenses expire end of month.',                    'open',        'medium', 'Software', 6, 1, 4),
        ('Printer offline in room 204',   'HP LaserJet shows offline, restarting does not help.',      'open',        'low',    'Hardware', 4, 2, 1),
        ('DB query running slow',         'SELECT on orders table taking 30s+, started after migration.', 'in_progress', 'high', 'Database', 3, 3, 2),
        ('Onboarding checklist missing',  'New hire portal shows 404 for onboarding docs.',            'resolved',    'low',    'HR Portal',5, 3, 3),
        ('Payroll export failing',        'CSV export from payroll system throws NullPointerException.','open',        'high',  'Finance',  6, 1, 4)
    </cfquery>
    <cfset arrayAppend(steps, "Tickets seeded (10 rows)")>
    <cfcatch><cfset arrayAppend(errors, "ticket seed: " & cfcatch.message)></cfcatch>
  </cftry>

  <!--- Comments --->
  <cftry>
    <cfquery datasource="training_db">
      INSERT INTO hd_comments (ticket_id, author_id, body, is_internal) VALUES
        (1, 2, 'Checked firewall rules — looks like port 1194 is blocked on the new router. Escalating to network team.', true),
        (1, 4, 'Any update on this? Working from home today is critical.', false),
        (2, 2, 'Ordered device from Apple Business. ETA 2 days.', true),
        (2, 5, 'Please also install Slack and Zoom.', false),
        (4, 3, 'Provisioned EC2 t3.medium. Waiting for DNS propagation.', true),
        (5, 2, 'Reset completed. User advised to use password manager.', false),
        (8, 3, 'Missing index on customer_id column. Added index, re-running query tests.', true),
        (8, 4, 'Index helped but still seeing 8s on large datasets.', true),
        (9, 3, 'Restored onboarding docs from backup. Link is working now.', false)
    </cfquery>
    <cfset arrayAppend(steps, "Comments seeded (9 rows)")>
    <cfcatch><cfset arrayAppend(errors, "comment seed: " & cfcatch.message)></cfcatch>
  </cftry>

<cfelse>
  <cfset arrayAppend(steps, "Data already present — skipped inserts")>
</cfif>

</cfsilent>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>DB Seed — Help Desk Schema</title>
  <style>
    body { font-family: monospace; background: #0f172a; color: #e2e8f0; padding: 2rem; max-width: 700px; }
    h2 { color: #38bdf8; }
    .ok  { color: #4ade80; }
    .err { color: #f87171; }
    li   { margin: .25rem 0; }
  </style>
</head>
<body>
<h2>Help Desk Schema — Seed Results</h2>
<ul>
  <cfloop array="#steps#" index="s">
    <li class="ok">✅ <cfoutput>#s#</cfoutput></li>
  </cfloop>
  <cfloop array="#errors#" index="e">
    <li class="err">❌ <cfoutput>#e#</cfoutput></li>
  </cfloop>
</ul>
<cfif arrayLen(errors) EQ 0>
  <p class="ok"><strong>All done.</strong> Tables: hd_departments, hd_users, hd_tickets, hd_comments</p>
  <p><a href="/db-test.cfm" style="color:#38bdf8">← Back to DB Test</a></p>
<cfelse>
  <p class="err"><strong>#arrayLen(errors)# error(s) occurred.</strong></p>
</cfif>
</body>
</html>
