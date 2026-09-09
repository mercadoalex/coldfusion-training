---
kind: challenge

title: Hello CFML

description: |
  Create a CFML page at /opt/coldfusion2025/cfusion/wwwroot/hello.cfm that outputs "Hello, ColdFusion!"
  and the current server date. The page must return HTTP 200 and contain
  the string "Hello, ColdFusion!".

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- linux

tagz:
- coldfusion
- cfml
- beginner

difficulty: easy

playground:
  name: cf-alex-edcdf975

tasks:
  verify_hello_cfm:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/hello.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "hello.cfm is not returning HTTP 200 (got ${STATUS})"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/hello.cfm)
      if ! echo "${BODY}" | grep -qi "Hello, ColdFusion!"; then
        echo "hello.cfm does not contain 'Hello, ColdFusion!'"
        exit 1
      fi
      echo "hello.cfm is working correctly"
---

## Your mission

Create `/opt/coldfusion2025/cfusion/wwwroot/hello.cfm` that:
- Outputs the text `Hello, ColdFusion!`
- Includes the current date using `dateFormat(now(), "long")`
- Returns HTTP 200

```bash
curl -s http://localhost:8500/hello.cfm | grep "Hello, ColdFusion!"
```
