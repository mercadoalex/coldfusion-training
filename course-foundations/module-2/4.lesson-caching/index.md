---
kind: lesson

title: Caching Strategies in ColdFusion
description: |
  Use cfcache, application-scope caching, query caching, and
  function-level caching to dramatically improve application performance.

name: caching-strategies-coldfusion
slug: caching-strategies-coldfusion

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
      echo "cache_demo.cfm is accessible"

  verify_cache_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cache_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm"
      if ! grep -qi "cfcache\|cacheput\|cacheget\|cachedwithin" "${FILE}" 2>/dev/null; then
        echo "No caching directives found in cache_demo.cfm"
        exit 1
      fi
      echo "Caching directives are present"

  verify_cache_no_error:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cache_used
    run: |
      curl -s http://localhost:8500/cache_demo.cfm > /dev/null
      BODY=$(curl -s http://localhost:8500/cache_demo.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "cache_demo.cfm throwing error on second request"
        exit 1
      fi
      echo "Cache demo page returns clean on repeated requests"
---

## Query caching

```cfml
<cfquery name="students" datasource="training_db" cachedwithin="#createTimeSpan(0,0,5,0)#">
  SELECT id, name FROM students
</cfquery>
```

## Application-scope caching

```cfml
<cfscript>
  students = cacheGet("allStudents");
  if (isNull(students)) {
    students = queryExecute("SELECT * FROM students", {}, {datasource:"training_db"});
    cachePut("allStudents", students, createTimeSpan(0,0,5,0));
  }
</cfscript>
```

## Page caching with cfcache

```cfml
<cfcache action="cache" timespan="#createTimeSpan(0,0,5,0)#">
  <!--- expensive page content here --->
</cfcache>
```
