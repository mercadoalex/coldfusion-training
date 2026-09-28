---
kind: lesson
---


# Caching Challenge — Review & Annotated Solution

This lesson unlocks after you pass the **Cache That Query** challenge. It walks through a complete, annotated solution and explains every design choice so you can apply these patterns confidently in your own code.

---

## What the checker was testing

| Task | What it checked |
|------|-----------------|
| `verify_cache_page` | `GET /cache_demo.cfm` returns HTTP 200 |
| `verify_caching_used` | File contains at least one of: `cachedwithin`, `cacheGet`, `cachePut`, `cfcache` (case-insensitive) |
| `verify_no_error_on_repeat` | Body of the second request contains neither `error` nor `exception` |

The file path the checker used was `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm` — **not** `wwwroot/student/`. This is the web root itself, so the URL is `http://localhost:8500/cache_demo.cfm`.

---

## Annotated solution — all three techniques in one file

```cfml
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ColdFusion Cache Demo — Review</title>
  <style>
    body  { font-family: sans-serif; max-width: 860px; margin: 2rem auto; }
    h2    { border-bottom: 2px solid #3b82d4; padding-bottom: .25rem; }
    .box  { padding: 1rem; background: #f0f4ff; border-left: 4px solid #3b82d4; margin: 1rem 0; }
    .hit  { border-left-color: #22c55e; background: #f0fff4; }
    .miss { border-left-color: #ef4444; background: #fff0f0; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th    { background: #3b82d4; color: #fff; padding: .5rem .75rem; text-align: left; }
    td    { padding: .45rem .75rem; border-bottom: 1px solid #e5e7eb; }
  </style>
</head>
<body>
<h1>ColdFusion Caching Demo</h1>

<!--- ──────────────────────────────────────────────────────────────────
  TECHNIQUE 1: cachedwithin on a cfquery
  ────────────────────────────────────────────────────────────────── --->

<h2>1. Query Cache — <code>cachedwithin</code></h2>

<!---
  cachedwithin tells ColdFusion to re-use the previous result
  if it is less than the specified timespan old.
  createTimeSpan(days, hours, minutes, seconds):
    (0,0,5,0) = 5 minutes
  On the FIRST request ColdFusion runs the SQL.
  On every request within the next 5 minutes it returns the cached result.
--->
<cfquery name="openTickets" datasource="training_db"
         cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT id, title, status, priority
  FROM   hd_tickets
  WHERE  status = 'open'
  ORDER  BY id DESC
</cfquery>

<div class="box">
  <strong>cachedwithin</strong> — returned
  <cfoutput>#openTickets.recordCount#</cfoutput> row(s).
  This result is cached for <strong>5 minutes</strong>.
  Reload the page immediately and the SQL will <em>not</em> re-run.
</div>

<table>
  <tr><th>ID</th><th>Title</th><th>Status</th><th>Priority</th></tr>
  <cfoutput query="openTickets">
    <tr>
      <td>#id#</td>
      <td>#encodeForHTML(title)#</td>
      <td>#encodeForHTML(status)#</td>
      <td>#encodeForHTML(priority)#</td>
    </tr>
  </cfoutput>
</table>

<!--- ──────────────────────────────────────────────────────────────────
  TECHNIQUE 2: cacheGet / cachePut (application-level cache)
  ────────────────────────────────────────────────────────────────── --->

<h2>2. Application Cache — <code>cacheGet</code> / <code>cachePut</code></h2>

<cfscript>
  // The cache key is just a string — pick something descriptive.
  cacheKey   = "highPriorityTickets";

  // cacheGet returns null if the key does not exist OR has expired.
  // ALWAYS check for null before using the value — skipping this is the
  // single most common source of errors on repeated requests.
  highTickets = cacheGet(cacheKey);
  cacheHit    = !isNull(highTickets);

  if (!cacheHit) {
    // Cache miss: run the query and store the result.
    highQuery = new Query();
    highQuery.setDatasource("training_db");
    highQuery.setSQL("
      SELECT id, title, status, priority
      FROM   hd_tickets
      WHERE  priority = 'high'
      ORDER  BY id DESC
    ");
    result = highQuery.execute().getResult();

    // Convert to an array-of-structs so we can cache it as a plain value.
    highTickets = [];
    for (row in result) {
      arrayAppend(highTickets, {
        id:       row.id,
        title:    row.title,
        status:   row.status,
        priority: row.priority
      });
    }

    // Store in cache for 5 minutes.
    // cachePut(key, value, timespan [, idleTime])
    cachePut(cacheKey, highTickets, createTimeSpan(0,0,5,0));
  }
</cfscript>

<div class="box #(cacheHit ? 'hit' : 'miss')#">
  <cfoutput>
    <strong>#(cacheHit ? "Cache HIT" : "Cache MISS")#</strong> —
    #arrayLen(highTickets)# high-priority ticket(s) from key
    <code>#cacheKey#</code>.
  </cfoutput>
</div>

<table>
  <tr><th>ID</th><th>Title</th><th>Status</th><th>Priority</th></tr>
  <cfoutput>
    <cfloop array="#highTickets#" item="t">
      <tr>
        <td>#t.id#</td>
        <td>#encodeForHTML(t.title)#</td>
        <td>#encodeForHTML(t.status)#</td>
        <td>#encodeForHTML(t.priority)#</td>
      </tr>
    </cfloop>
  </cfoutput>
</table>

<!--- ──────────────────────────────────────────────────────────────────
  TECHNIQUE 3: cfcache — full-page output cache
  ────────────────────────────────────────────────────────────────── --->

<h2>3. Page Cache — <code>&lt;cfcache&gt;</code></h2>

<!---
  cfcache with action="cache" stores the entire rendered HTML output.
  Subsequent requests within the timespan receive the cached HTML
  without executing any CFML — the fastest possible response.
  action="flush" clears the cache for this URL.
  action="optimal" lets ColdFusion decide based on client headers.
--->
<cfcache action="cache" timespan="#createTimeSpan(0,0,5,0)#">

<div class="box">
  This section is cached at the <strong>page-output level</strong>
  using <code>&lt;cfcache action="cache"&gt;</code>.
  Rendered at: <cfoutput>#now()#</cfoutput> — this timestamp
  will <em>not</em> change for 5 minutes after the first load.
</div>

</body>
</html>
```

---

## Why each technique matters

### `cachedwithin` — query-result cache

Best for: **read-heavy queries whose data changes slowly** (lookup tables, reference data, aggregated reports).

- ColdFusion stores the query object in memory.
- If the same SQL (same datasource + same query text) is requested within the timespan, the cached object is returned directly — no database round-trip.
- The cache is **per server instance** and not shared across a cluster by default.

### `cacheGet` / `cachePut` — application-level cache

Best for: **computed values, API responses, or any serialisable data** you want to reuse across requests.

- More flexible than `cachedwithin` — you can cache arrays, structs, strings, anything serialisable.
- The `isNull()` guard is **mandatory**. `cacheGet` returns `null` on a miss; using a null value without checking causes a runtime error on the first request.
- Supports an optional `idleTime` parameter: `cachePut(key, value, ttl, idleTime)` — the cache entry is also evicted if it has not been accessed for `idleTime`.

### `<cfcache>` — page-output cache

Best for: **mostly static pages** or expensive pages that rarely change.

- ColdFusion intercepts the request before executing any CFML and returns the cached HTML directly.
- `action="cache"` — stores and serves cached output.
- `action="flush"` — clears the cached output for the current URL (useful on a refresh button).
- `action="optimal"` — respects HTTP cache-control headers from the browser.

---

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| File in `wwwroot/student/` instead of `wwwroot/` | HTTP 404, checker fails Step 1 | Use `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm` |
| `cacheGet` result used without `isNull()` guard | Runtime error on first load, checker fails Step 3 | Always wrap: `if (isNull(result)) { ... }` |
| Typo: `cachewithin` instead of `cachedwithin` | Directive not recognised, query runs every time (no error but Step 2 fails) | Double-check spelling with `d` |
| `<cfcache>` without `action` attribute | Tag has no effect | Always include `action="cache"` |
| Wrong datasource name | SQL error thrown, Step 3 fails | Use `datasource="training_db"` |

---

## Quick reference — `createTimeSpan` values

| Expression | Duration |
|------------|----------|
| `createTimeSpan(0,0,1,0)` | 1 minute |
| `createTimeSpan(0,0,5,0)` | 5 minutes |
| `createTimeSpan(0,1,0,0)` | 1 hour |
| `createTimeSpan(1,0,0,0)` | 1 day |
| `createTimeSpan(0,0,0,30)` | 30 seconds |
