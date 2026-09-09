---
kind: challenge

title: Media Upload Handler

description: |
  Create media_demo.cfm with an HTML5 video or audio element, and
  upload_media.cfm that accepts a file upload using cffile. Both pages
  must return HTTP 200.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cffile
- multimedia

playground:
  name: cf-alex-edcdf975

tasks:
  verify_media_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/media_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "media_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "media_demo.cfm accessible"

  verify_html5_media_element:
    machine: dev-machine
    user: laborant
    needs:
      - verify_media_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/media_demo.cfm"
      if ! grep -qi "<video\|<audio" "${FILE}" 2>/dev/null; then
        echo "No HTML5 video or audio element found"
        exit 1
      fi
      echo "HTML5 media element present"

  verify_upload_handler:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_media_element
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "upload_media.cfm not found"
        exit 1
      fi
      echo "upload_media.cfm exists"
---

## Your mission

**media_demo.cfm** — an HTML page with at least one `<video>` or `<audio>` element.

**upload_media.cfm** — a handler that uses `cffile action="upload"` to accept a file.

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/media_demo.cfm
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/upload_media.cfm
```

Both must return **200**.
