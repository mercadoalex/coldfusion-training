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
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/upload_media.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "upload_media.cfm not found (got ${STATUS})"
        exit 1
      fi
      FILE="/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm"
      if ! grep -q "cffile\|action.*upload" "${FILE}" 2>/dev/null; then
        echo "No cffile upload handler found in upload_media.cfm"
        exit 1
      fi
      echo "Upload handler exists and contains cffile"

  verify_image_thumb:
    machine: dev-machine
    user: laborant
    needs:
      - verify_upload_handler
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/image_thumb.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "image_thumb.cfm not found (got ${STATUS})"
        exit 1
      fi
      FILE="/opt/coldfusion2025/cfusion/wwwroot/image_thumb.cfm"
      if ! grep -q "cfimage\|imageNew\|imageWrite" "${FILE}" 2>/dev/null; then
        echo "No cfimage usage found in image_thumb.cfm"
        exit 1
      fi
      echo "image_thumb.cfm exists and uses cfimage"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_image_thumb
    run: |
      echo "Lesson complete — well done!"

---
