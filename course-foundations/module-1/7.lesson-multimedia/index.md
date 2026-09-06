---
kind: lesson

title: Multimedia Content Integration
description: |
  Embed and manage video, audio and other multimedia in ColdFusion applications.
  Use HTML5 media elements, manage uploads, and handle compatibility
  and performance considerations.

name: multimedia-content-integration
slug: multimedia-content-integration

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- html5
- multimedia
- video

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
      echo "media_demo.cfm is accessible"

  verify_html5_video:
    machine: dev-machine
    user: laborant
    needs:
      - verify_media_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/media_demo.cfm"
      if ! grep -qi "<video\|<audio" "${FILE}" 2>/dev/null; then
        echo "No HTML5 video or audio element found in media_demo.cfm"
        exit 1
      fi
      echo "HTML5 media element is present"

  verify_upload_handler:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_video
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "upload_media.cfm not found"
        exit 1
      fi
      echo "Upload handler exists"
---
