---
kind: unit

title: Caching Strategies in ColdFusion

name: caching-strategies-coldfusion-unit-1
---

## Why cache?

ColdFusion applications often spend most of their time waiting for database queries. Caching stores computed results so that subsequent requests skip the work entirely.

---

## 1. Query caching — `cachedwithin`

Add `cachedwithin` to any `<cfquery>` to cache the result for a time span:

```cfml
<cfquery name="tickets" datasource="training_db"
         cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT t.id, t.title, t.status, t.priority, u.name AS submitter
  FROM   hd_tickets t
  JOIN   hd_users   u ON u.id = t.user_id
  WHERE  t.status = 'open'
</cfquery>
```

`createTimeSpan(days, hours, minutes, seconds)` — here `(0,0,5,0)` = 5 minutes.

The second call within 5 minutes returns the cached result without hitting the database.

---

## 2. Application-scope caching — `cacheGet` / `cachePut`

ColdFusion's built-in ehcache layer lets you store any value:

```cfml
<cfscript>
  tickets = cacheGet("openTickets");
  if (isNull(tickets)) {
    tickets = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets WHERE status = 'open'",
      {}, {datasource: "training_db"}
    );
    cachePut("openTickets", tickets, createTimeSpan(0,0,5,0));
  }
</cfscript>
```

**Cache hit/miss pattern:**
1. Try `cacheGet` — if not null, use it.
2. On miss: run the expensive operation, then `cachePut` with a TTL.

---

## 3. Page caching — `<cfcache>`

Caches the entire rendered output of a page for a time span:

```cfml
<cfcache action="cache" timespan="#createTimeSpan(0,0,5,0)#">
  <!--- expensive page content here --->
</cfcache>
```

Use sparingly — page caching bypasses all per-request logic inside the cached block.

---

## 4. Function-level caching — `cachedWithin` attribute

Cache the return value of a CFC function for a period:

```cfml
<cffunction name="getOpenTickets" returntype="query"
            cachedWithin="#createTimeSpan(0,0,5,0)#">
  <cfquery name="q" datasource="training_db">
    SELECT id, title FROM hd_tickets WHERE status = 'open'
  </cfquery>
  <cfreturn q>
</cffunction>
```

---

## Invalidating cache

```cfml
// Remove a specific key
cacheRemove("openTickets");

// Clear all application cache
cacheRemoveAll();
```

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm`.
2. Use at least one of: `cfcache`, `cacheGet`/`cachePut`, or `cachedwithin`.
3. Verify (hit it twice — the second request should serve from cache):

```bash
curl -s http://localhost:8500/cache_demo.cfm
curl -s http://localhost:8500/cache_demo.cfm
```
