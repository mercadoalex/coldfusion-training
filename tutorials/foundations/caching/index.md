---
kind: tutorial

title: Query Caching and Application-Scope Cache

description: |
  Add cachedwithin to a cfquery, then implement a cacheGet/cachePut
  pattern and confirm repeated requests skip the database.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- caching
- performance

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Create cache_demo.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm`:

```cfml
<cfscript>
  // --- Method 1: query-level caching ---
  // Results are cached for 5 minutes automatically
</cfscript>

<cfquery name="cachedTickets" datasource="training_db"
         cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT id, title, status, priority FROM hd_tickets WHERE status = 'open'
</cfquery>

<cfscript>
  // --- Method 2: application-scope cache ---
  tickets = cacheGet("openTickets");
  if (isNull(tickets)) {
    tickets = queryExecute(
      "SELECT id, title FROM hd_tickets WHERE status = 'open'",
      {}, {datasource: "training_db"}
    );
    cachePut("openTickets", tickets, createTimeSpan(0,0,5,0));
    writeOutput("<p>Cache MISS — loaded from DB</p>");
  } else {
    writeOutput("<p>Cache HIT — served from cache</p>");
  }

  writeOutput("<p>Tickets: " & tickets.recordCount & "</p>");
</cfscript>
```

### 2. Test cache hit/miss

```bash
# First request — cache miss
curl -s http://localhost:8500/cache_demo.cfm

# Second request — cache hit
curl -s http://localhost:8500/cache_demo.cfm
```

The first response shows **Cache MISS**, subsequent ones show **Cache HIT**.

### 3. Manually invalidate

```bash
# Add this to a reset.cfm to clear the cache
```

```cfml
<cfscript>
  cacheRemove("openTickets");
  writeOutput("Cache cleared");
</cfscript>
```

```bash
curl -s http://localhost:8500/reset.cfm
curl -s http://localhost:8500/cache_demo.cfm  # miss again
```
