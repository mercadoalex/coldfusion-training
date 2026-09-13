---
kind: unit

title: Caching Strategies in ColdFusion

name: caching-strategies-coldfusion-unit-1
---

## Why cache?

ColdFusion applications spend most of their time waiting for database queries and expensive computations. Caching stores a computed result so subsequent requests skip the work entirely — the database is never hit again until the cache expires.

::image-box
---
:src: __static__/cf-cache-hit-miss-flow-v1.png
:alt: Flowchart showing two parallel paths for a page request — the "Cache Miss" path (red) goes: Request → cacheGet returns null → run cfquery → cachePut with TTL → render response; the "Cache Hit" path (green) goes: Request → cacheGet returns data → render response, skipping the database entirely — the two paths merge at "render response" at the bottom
:max-width: 760px
---
_Cache hit/miss pattern — on a miss the engine queries the DB and warms the cache; on a hit it skips the DB entirely._
::

ColdFusion provides **four caching tiers** you can combine in the same application:

| Tier | API / Tag | Scope | Best for |
|---|---|---|---|
| **Query cache** | `cachedwithin` on `<cfquery>` | Per-query | Repeated identical SQL queries |
| **Application cache** | `cacheGet` / `cachePut` | Application-wide | Any computed value — queries, structs, arrays |
| **Function cache** | `cachedWithin` on `<cffunction>` | Per function call | CFC methods that return the same result for the same inputs |
| **Page cache** | `<cfcache>` | Full page output | Static or near-static pages |

::image-box
---
:src: __static__/cf-caching-tiers-overview-v1.png
:alt: Layered diagram showing four caching tiers stacked vertically from fastest top to slowest bottom — tier 1 "Page cache cfcache" at the top, tier 2 "Function-level cache cachedWithin attribute", tier 3 "Application cache cacheGet/cachePut via ehcache", tier 4 "Query cache cachedwithin on cfquery" — each tier shows its scope label and a typical TTL example
:max-width: 760px
---
_ColdFusion's four caching tiers — use the highest applicable tier to maximise cache hit rate._
::

---

## 1. Query caching — `cachedwithin`

Add `cachedwithin` to any `<cfquery>` to cache its result for a time span. The second call within the window returns the cached recordset without touching the database:

```cfml
<cfquery name="openTickets" datasource="training_db"
         cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT id, title, status, priority
  FROM   hd_tickets
  WHERE  status = 'open'
  ORDER  BY id DESC
</cfquery>
```

`createTimeSpan(days, hours, minutes, seconds)` — `(0,0,5,0)` = 5 minutes.

::hint-box
---
:summary: When does query caching NOT help?
---

Query caching caches the **exact SQL string** as the cache key. If anything in the query changes between calls — a different parameter, a different `WHERE` clause — ColdFusion treats it as a cache miss and re-runs the query. For parameterised queries with changing values, use `cacheGet`/`cachePut` with a computed key instead (e.g. `"tickets_open_dept_" & deptId`).

Also note: `cachedwithin` only works on `<cfquery>` — it does **not** apply to `queryExecute()`. Use `cacheGet`/`cachePut` around `queryExecute()` calls.

::

---

## 2. Application cache — `cacheGet` / `cachePut`

ColdFusion's built-in **ehcache** layer lets you store any value — a query result, a struct, an array — under a string key with a TTL:

::hint-box
---
:summary: What is TTL (Time-To-Live)?
---

**TTL** stands for **Time-To-Live** — it is the maximum age a cached value is allowed to reach before ColdFusion automatically discards it.

You set a TTL using `createTimeSpan(days, hours, minutes, seconds)`:

```cfml
createTimeSpan(0, 0, 5, 0)   // 5 minutes
createTimeSpan(0, 1, 0, 0)   // 1 hour
createTimeSpan(1, 0, 0, 0)   // 1 day
```

Once the TTL expires, the next request finds nothing in the cache (a **cache miss**), re-runs the original work, and stores a fresh value with a new TTL. Until then, every request gets the cached copy without touching the database.

A related concept you will see in the ehcache section is **TTI (Time-To-Idle)** — that clock resets every time the cached value is accessed, so a frequently-read entry can stay in cache indefinitely as long as it keeps getting hit.

::

```cfml
<cfscript>
  data = cacheGet("openTickets");

  if (isNull(data)) {
    // Cache miss — run the query
    data = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets WHERE status = 'open'",
      {},
      { datasource: "training_db" }
    );
    // Warm the cache for 5 minutes
    cachePut("openTickets", data, createTimeSpan(0,0,5,0));
  }
</cfscript>
```

The pattern is always the same:
1. `cacheGet(key)` — if not null, use it and skip the work
2. On null (cache miss): do the work, then `cachePut(key, value, ttl)`

::details-box
---
:summary: ehcache — the engine behind ColdFusion's application cache
---

**ehcache** (now **Terracotta ehcache**) is an open-source, in-process Java caching library originally created by Greg Luck in 2003. ColdFusion has bundled ehcache since ColdFusion 9 as the engine behind `cacheGet`, `cachePut`, and `cachedWithin`.

**What ehcache provides:**
- **In-memory storage** — all cached values live in JVM heap memory (fast, but limited by your server's RAM)
- **TTL (time-to-live)** — entries expire automatically after the duration you pass to `cachePut`
- **TTI (time-to-idle)** — optional: entries expire if not accessed for a set period, regardless of TTL
- **LRU eviction** — when the cache reaches its size limit, the least-recently-used entries are evicted first
- **Named caches** — ColdFusion exposes a default cache region; advanced config in `ehcache.xml` lets you define multiple named regions with different policies

**Useful functions beyond the basics:**

| Function | What it does |
|---|---|
| `cacheGet(key)` | Returns the cached value, or null if not found / expired |
| `cachePut(key, value, ttl)` | Stores a value with a TTL (`createTimeSpan`) |
| `cachePut(key, value, ttl, tti)` | Stores with both TTL and TTI |
| `cacheRemove(key)` | Removes a single key |
| `cacheRemoveAll()` | Clears the entire application cache |
| `cacheGetAllIds()` | Returns an array of all current cache keys |
| `cacheGetMetadata(key)` | Returns hit count, last accessed time, TTL remaining |

**Where the cache lives:**
By default, ehcache is configured in `/opt/coldfusion2025/cfusion/lib/ehcache.xml`. The default region stores up to 10,000 objects in memory. You can tune this for high-traffic applications, but the defaults work well for learning and moderate production load.

**Important:** the cache is scoped to the **ColdFusion application** (the `this.name` in `Application.cfc`). Two applications on the same CF server have separate cache regions. Restarting ColdFusion clears all cached values.

::

---

## 3. Function-level caching — `cachedWithin` on a CFC method

Add `cachedWithin` to a `<cffunction>` declaration to cache its return value. ColdFusion uses the **function name + argument values** as the cache key — the same call with the same arguments returns the cached result:

```cfml
component {

  public query function getOpenTickets() cachedWithin="#createTimeSpan(0,0,5,0)#" {
    return queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets WHERE status = 'open'",
      {},
      { datasource: "training_db" }
    );
  }

}
```

::hint-box
---
:summary: Function cache vs application cache — which to use?
---

Both `cachedWithin` on a function and `cacheGet`/`cachePut` use the same ehcache layer under the hood. The difference is **where the cache key is managed**:

- **`cachedWithin` on a function** — ColdFusion auto-generates the key from function name + argument signature. Zero boilerplate. Use this when the function is always called with the same arguments, or when each unique argument set should get its own cached result.
- **`cacheGet`/`cachePut`** — you control the key. Use this when you need a shared key across multiple pages/CFCs, when you want to invalidate specific keys on a write (`cacheRemove("openTickets")` after an INSERT), or when caching non-function results like complex structs.

::

---

## 4. Invalidating the cache

Cache invalidation — knowing when to throw away a cached value — is one of the genuinely hard problems in caching. ColdFusion gives you three options:

```cfml
<cfscript>
  // Remove a specific key (e.g. after a write operation)
  cacheRemove("openTickets");

  // Remove multiple keys matching a pattern (CF 2016+)
  cacheRemove("tickets_dept_*", false);

  // Clear everything in the application cache
  cacheRemoveAll();
</cfscript>
```

**The write-through pattern** — always invalidate on writes:

```cfml
<cfscript>
  // INSERT a new ticket
  queryExecute(
    "INSERT INTO hd_tickets (title, status, priority) VALUES (:t, 'open', 'medium')",
    { t: { value: form.title, cfsqltype: "cf_sql_varchar" } },
    { datasource: "training_db" }
  );

  // Immediately invalidate the stale cache key
  cacheRemove("openTickets");
</cfscript>
```

::hint-box
---
:summary: TTL vs explicit invalidation — which strategy?
---

| Strategy | When to use |
|---|---|
| **TTL only** (let it expire) | Data that can tolerate being stale for a few minutes — dashboards, ticket lists, statistics |
| **Explicit invalidation** (`cacheRemove` on write) | Data that must be fresh immediately after a change — user profile, ticket status shown to the owner |
| **Both** | Cache with a safety-net TTL (e.g. 10 min) AND invalidate explicitly on write — belt-and-suspenders for critical data |

For this training environment, TTL-only is fine. In production, always invalidate explicitly after writes to high-visibility data.

::

---

## Activity 1 — Query caching with `cachedwithin`

You are going to create a new file called `cache_demo.cfm` in the ColdFusion web root. This file does not exist yet — the command below creates it for you.

**File to create:** `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm`

In the **Terminal** tab, run the `sudo tee` command below. It writes the full file in one step — no editor needed:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ColdFusion Cache Demo</title>
  <style>
    body  { font-family: sans-serif; max-width: 860px; margin: 2rem auto; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th    { background: #3b82d4; color: #fff; padding: .5rem .75rem; text-align: left; }
    td    { padding: .45rem .75rem; border-bottom: 1px solid #e5e7eb; }
    tr:hover td { background: #f7f8fa; }
    .box  { padding: 1rem; background: #f0f4ff; border-left: 4px solid #3b82d4; margin: 1rem 0; }
  </style>
</head>
<body>
  <h1>ColdFusion Caching Demo</h1>

  <h2>1. Query Cache — cachedwithin</h2>

  <cfquery name="openTickets" datasource="training_db"
           cachedwithin="#createTimeSpan(0,0,5,0)#">
    SELECT id, title, status, priority
    FROM   hd_tickets
    WHERE  status = 'open'
    ORDER  BY id DESC
  </cfquery>

  <div class="box">
    <strong>cachedwithin query:</strong>
    <cfoutput>#openTickets.recordCount#</cfoutput> open ticket(s) — cached for 5 minutes
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

</body>
</html>
EOF
```

Verify `cachedwithin` is in the file:

```bash
grep -i "cachedwithin" /opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm
```

::image-box
---
:src: __static__/terminal-cachedwithin-created-v1.png
:alt: Terminal showing the sudo tee command writing cache_demo.cfm, followed by grep confirming the cachedwithin line is present in the file
:max-width: 860px
---
_`cachedwithin` on `<cfquery>` — ColdFusion caches the result set for 5 minutes after the first execution._
::

::simple-task
---
:tasks: tasks
:name: verify_query_cache
---
#active
Run the `sudo tee` command above to create `cache_demo.cfm` with a `cachedwithin` query that caches the open-ticket list for 5 minutes.

#completed
Query caching with `cachedwithin` is present. ✓
::

---

## Activity 2 — Application cache with `cacheGet` / `cachePut`

You are going to **replace** the `cache_demo.cfm` file you created in Activity 1 with an extended version that adds a second section using `cacheGet` / `cachePut`. The `sudo tee` command overwrites the file completely — that is intentional.

**File to overwrite:** `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm`

In the **Terminal** tab, run:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ColdFusion Cache Demo</title>
  <style>
    body  { font-family: sans-serif; max-width: 860px; margin: 2rem auto; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th    { background: #3b82d4; color: #fff; padding: .5rem .75rem; text-align: left; }
    td    { padding: .45rem .75rem; border-bottom: 1px solid #e5e7eb; }
    tr:hover td { background: #f7f8fa; }
    .box  { padding: 1rem; background: #f0f4ff; border-left: 4px solid #3b82d4; margin: 1rem 0; }
    .miss { border-left-color: #ef4444; background: #fff0f0; }
    .hit  { border-left-color: #22c55e; background: #f0fff4; }
  </style>
</head>
<body>
  <h1>ColdFusion Caching Demo</h1>

  <h2>1. Query Cache — cachedwithin</h2>

  <cfquery name="openTickets" datasource="training_db"
           cachedwithin="#createTimeSpan(0,0,5,0)#">
    SELECT id, title, status, priority
    FROM   hd_tickets
    WHERE  status = 'open'
    ORDER  BY id DESC
  </cfquery>

  <div class="box">
    <strong>cachedwithin query:</strong>
    <cfoutput>#openTickets.recordCount#</cfoutput> open ticket(s) — cached for 5 minutes
  </div>

  <h2>2. Application Cache — cacheGet / cachePut</h2>

  <cfscript>
    cacheKey = "highPriorityTickets";
    highTickets = cacheGet(cacheKey);
    cacheHit = !isNull(highTickets);

    if (!cacheHit) {
      highTickets = queryExecute(
        "SELECT id, title, priority, category FROM hd_tickets WHERE priority = 'high' ORDER BY id DESC",
        {},
        { datasource: "training_db" }
      );
      cachePut(cacheKey, highTickets, createTimeSpan(0,0,5,0));
    }
  </cfscript>

  <cfoutput>
  <div class="box #cacheHit ? 'hit' : 'miss'#">
    <strong>Cache #cacheHit ? 'HIT' : 'MISS'#:</strong>
    #highTickets.recordCount# high-priority ticket(s) from #cacheHit ? 'cache' : 'database'#
  </div>
  </cfoutput>

  <table>
    <tr><th>ID</th><th>Title</th><th>Priority</th><th>Category</th></tr>
    <cfoutput query="highTickets">
      <tr>
        <td>#id#</td>
        <td>#encodeForHTML(title)#</td>
        <td>#encodeForHTML(priority)#</td>
        <td>#encodeForHTML(category)#</td>
      </tr>
    </cfoutput>
  </table>

</body>
</html>
EOF
```

Open `/cache_demo.cfm` in the **ColdFusion 2025** browser tab. The first load will show **Cache MISS** (red); refresh and it switches to **Cache HIT** (green).

```bash
curl -s http://localhost:8500/cache_demo.cfm | grep -i "cache"
```

::image-box
---
:src: __static__/browser-cache-hit-miss-v1.png
:alt: Browser showing cache_demo.cfm with section 1 displaying the cachedwithin query result count in a blue box, and section 2 showing a green "Cache HIT" box indicating high-priority tickets were served from ehcache, with the tickets table below
:max-width: 860px
---
_First request shows Cache MISS (red) as data is fetched from the DB and stored; refresh shows Cache HIT (green) — DB skipped._
::

::simple-task
---
:tasks: tasks
:name: verify_app_cache
---
#active
Update `cache_demo.cfm` with the `cacheGet`/`cachePut` section above, then reload in the browser to see the cache hit/miss indicator switch from red to green on the second request.

#completed
Application caching with `cacheGet`/`cachePut` is present. ✓
::

---

## Activity 3 — Verify the cache page runs cleanly

**Activity:** Confirm `cache_demo.cfm` returns HTTP 200 with no errors on repeated requests:

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8500/cache_demo.cfm
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:8500/cache_demo.cfm
```

Both requests should return **HTTP 200**. Check for any error output:

```bash
curl -s http://localhost:8500/cache_demo.cfm | grep -i "error\|exception" || echo "No errors found"
```

::image-box
---
:src: __static__/terminal-cache-demo-200-v1.png
:alt: Terminal showing two curl commands each returning HTTP 200, followed by the grep command returning "No errors found" — confirming cache_demo.cfm serves cleanly on repeated requests
:max-width: 860px
---
_Two clean HTTP 200 responses — the second request is served entirely from cache._
::

::simple-task
---
:tasks: tasks
:name: verify_cache_page
---
#active
Run the two `curl` commands above to confirm `cache_demo.cfm` returns HTTP 200 with no errors on both the first and second request.

#completed
`cache_demo.cfm` runs cleanly on repeated requests. ✓
::

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

::card
---
:challenge: challenges.caching_10837ff1
---
::
