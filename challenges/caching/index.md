---
kind: challenge

title: Cache That Query

description: |
  Create cache_demo.cfm that uses at least one of: cachedwithin on a cfquery,
  cacheGet/cachePut, or cfcache. The page must return HTTP 200 on the first
  and second request without throwing errors.

difficulty: medium

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- caching

playground:
  name: cf-alex-edcdf975

tasks:
  verify_cache_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/cache_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "cache_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "cache_demo.cfm accessible"

  verify_caching_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cache_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm"
      if ! grep -qi "cfcache\|cacheput\|cacheget\|cachedwithin" "${FILE}" 2>/dev/null; then
        echo "No caching directive found in cache_demo.cfm"
        exit 1
      fi
      echo "Caching directive present"

  verify_no_error_on_repeat:
    machine: dev-machine
    user: laborant
    needs:
      - verify_caching_used
    run: |
      curl -s http://localhost:8500/cache_demo.cfm > /dev/null
      BODY=$(curl -s http://localhost:8500/cache_demo.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "cache_demo.cfm throws an error on repeated requests"
        exit 1
      fi
      echo "No error on repeated requests"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm` that demonstrates at least **one** of the following caching techniques:

- `cachedwithin="#createTimeSpan(0,0,5,0)#"` on a `<cfquery>` — caches query results for 5 minutes
- `cacheGet("key")` / `cachePut("key", data, ttl)` — stores arbitrary data in the application cache
- `<cfcache action="cache" timespan="#createTimeSpan(0,0,5,0)#">` — caches the full page output

The page must return **HTTP 200** on both the first and second request, with no ColdFusion error output.

**Requirements checklist:**
- [ ] File lives at `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm` (note: `wwwroot/`, **not** `wwwroot/student/`)
- [ ] Contains at least one of `cachedwithin`, `cacheGet`, `cachePut`, or `<cfcache>`
- [ ] Returns HTTP 200 on repeated requests with no error or exception text in the body

---

### Step 1 — Create `cache_demo.cfm` with a caching directive

::details-box
---
:summary: 💡 Hint — which technique should I use?
---
Any of the three techniques passes the checker. The simplest one to start with is `cachedwithin` on a `<cfquery>`:

```cfml
<cfquery name="myQuery" datasource="training_db"
         cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT 1 AS alive
</cfquery>
```

Review **Module 2 → Lesson 6 (Caching)**, Activity 1 for the full pattern.

Key points:
- `createTimeSpan(days, hours, minutes, seconds)` — `(0,0,5,0)` = 5 minutes
- The `datasource` attribute must match an existing datasource (`training_db`)
- If you use `cacheGet`/`cachePut`, check for `isNull()` before using the cached value
::

::details-box
---
:summary: 👉 Skeleton — need the structure?
---
Fill in the blanks:

```cfml
<cfquery name="______" datasource="______"
         cachedwithin="#createTimeSpan(0,0,______,0)#">
  SELECT 1 AS alive
</cfquery>
<cfoutput>
  Rows returned: #______.recordCount# (cached for 5 min)
</cfoutput>
```

Or using application cache:

```cfml
<cfscript>
  key    = "______";
  result = cacheGet(______);
  if (isNull(______)) {
    result = "computed at " & now();
    cachePut(______, result, createTimeSpan(0,0,5,0));
  }
  writeOutput(result);
</cfscript>
```
::

::remark-box
---
kind: info
---
No full solution is provided — use the hint and the skeleton above. The productive struggle of working out the last step is exactly what makes caching concepts stick. A fully annotated walkthrough unlocks in the **Caching Review** lesson after you pass.
::

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm << 'EOF'
<cfquery name="ping" datasource="training_db"
         cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT 1 AS alive
</cfquery>
<cfoutput>
  <p>cache_demo — rows: #ping.recordCount# (cached 5 min)</p>
</cfoutput>
EOF
```

::simple-task
---
:tasks: tasks
:name: verify_cache_page
---
#active
Waiting for `cache_demo.cfm` to return HTTP 200...

#completed
`cache_demo.cfm` is accessible. ✓
::

---

### Step 2 — Confirm a caching directive is present

The checker greps `cache_demo.cfm` for any of: `cachedwithin`, `cacheGet`, `cachePut`, `cfcache`.

::details-box
---
:summary: 💡 Hint — directive not detected?
---
The grep is **case-insensitive**, so `CachedWithin`, `CACHEDWITHIN`, and `cachedwithin` all match.

Common mistakes:
- Putting the file in `wwwroot/student/` instead of `wwwroot/` — the checker path is `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm`
- Misspelling `cachedwithin` as `cachewithin` (missing the `d`)
- Using `<cfcache>` but forgetting `action="cache"` — the tag must have the attribute to be meaningful

Verify the file exists and contains the directive:

```bash
grep -i "cachedwithin\|cacheput\|cacheget\|cfcache" \
  /opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm
```
::

::details-box
---
:summary: 👉 Skeleton — cfcache alternative
---
If you prefer page-level caching instead of a query:

```cfml
<cfcache action="______" timespan="#createTimeSpan(0,0,______,0)#">
<cfoutput>
  Page cached at: #now()#
</cfoutput>
```

The `action` value that caches output is `"______"`.
::

::simple-task
---
:tasks: tasks
:name: verify_caching_used
---
#active
Checking for a caching directive in `cache_demo.cfm`...

#completed
Caching directive found. ✓
::

---

### Step 3 — No error on repeated requests

The checker hits `cache_demo.cfm` twice and scans the second response body for `error` or `exception`.

::details-box
---
:summary: 💡 Hint — what causes errors on repeated requests?
---
The most common cause is a `cacheGet` result that is `null` on the first call but the code tries to use it directly without an `isNull()` guard:

```cfml
<!--- ❌ This throws on first load: null has no .len() --->
result = cacheGet("myKey");
writeOutput(result.len());
```

```cfml
<!--- ✅ Safe pattern --->
result = cacheGet("myKey");
if (isNull(result)) {
  result = "freshly computed";
  cachePut("myKey", result, createTimeSpan(0,0,5,0));
}
writeOutput(result);
```

If you are using `cachedwithin` on a `cfquery`, there is no null-guard needed — ColdFusion handles the cache miss internally and always returns a query object.
::

Verify yourself before submitting:

```bash
curl -s http://localhost:8500/cache_demo.cfm
curl -s http://localhost:8500/cache_demo.cfm
```

::simple-task
---
:tasks: tasks
:name: verify_no_error_on_repeat
---
#active
Confirming no error on repeated requests...

#completed
No error on repeated requests — challenge complete! ✓
::
