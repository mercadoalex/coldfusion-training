---
kind: challenge

title: Cache That Query

description: |
  Create cache_demo.cfm that uses at least one of: cachedwithin on a cfquery,
  cacheGet/cachePut, or cfcache. The page must return HTTP 200 on the first
  and second request without throwing errors.

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

Create `/opt/coldfusion2025/cfusion/wwwroot/cache_demo.cfm` using **at least one** caching technique:

- `cachedwithin="#createTimeSpan(0,0,5,0)#"` on a `<cfquery>`
- `cacheGet("key")` / `cachePut("key", data, ttl)`
- `<cfcache action="cache" timespan="...">`

Hit it twice — the second request must return cleanly.

```bash
curl -s http://localhost:8500/cache_demo.cfm
curl -s http://localhost:8500/cache_demo.cfm
```
