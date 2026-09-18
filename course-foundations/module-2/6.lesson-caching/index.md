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

challenges:
  caching-10837ff1: {}

tasks:
  verify_query_cache:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "cache_demo.cfm not found"
        exit 1
      fi
      if ! grep -qi "cachedwithin" "${FILE}" 2>/dev/null; then
        echo "No cachedwithin query caching found in cache_demo.cfm"
        exit 1
      fi
      echo "Query caching with cachedwithin is present"

  verify_app_cache:
    machine: dev-machine
    user: laborant
    needs:
      - verify_query_cache
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm"
      if ! grep -qi "cacheput\|cacheget" "${FILE}" 2>/dev/null; then
        echo "No cacheGet/cachePut application caching found in cache_demo.cfm"
        exit 1
      fi
      echo "Application caching with cacheGet/cachePut is present"

  verify_cache_page:
    machine: dev-machine
    user: laborant
    needs:
      - verify_app_cache
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/cache_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "cache_demo.cfm not accessible (got ${STATUS})"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/cache_demo.cfm)
      if echo "${BODY}" | grep -qi "error\|exception"; then
        echo "cache_demo.cfm is throwing an error"
        exit 1
      fi
      echo "cache_demo.cfm runs cleanly and returns HTTP 200"

  verify_cache_invalidation:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cache_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm"
      if ! grep -qi "cacheremove\|cacheremoveall" "${FILE}" 2>/dev/null; then
        echo "No cacheRemove or cacheRemoveAll found in cache_demo.cfm"
        exit 1
      fi
      echo "Cache invalidation with cacheRemove is present"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cache_invalidation
    run: |
      echo "Lesson complete — well done!"

---
