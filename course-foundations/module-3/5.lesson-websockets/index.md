---
kind: lesson

title: Real-Time Communication with WebSockets
description: |
  Implement real-time bidirectional communication using WebSockets in ColdFusion.
  Learn the WebSocket lifecycle, event handling, and how to build
  live features like notifications and chat.

name: real-time-websockets
slug: real-time-websockets

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- websockets
- real-time

playground:
  name: cf-alex-edcdf975

tasks:
  verify_ws_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/ws_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "ws_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "ws_demo.cfm is accessible"

  verify_ws_handler:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/WSHandler.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "WSHandler.cfc not found"
        exit 1
      fi
      if ! grep -q "wsPublish" "${FILE}"; then
        echo "WSHandler.cfc exists but does not call wsPublish"
        exit 1
      fi
      if ! grep -q "onWSMessage" "${FILE}"; then
        echo "WSHandler.cfc exists but is missing onWSMessage"
        exit 1
      fi
      echo "WebSocket handler CFC found: ${FILE}"

  verify_ws_channels:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/Application.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "Application.cfc not found"
        exit 1
      fi
      if ! grep -q "wschannels" "${FILE}"; then
        echo "Application.cfc exists but this.wschannels is not defined"
        exit 1
      fi
      if ! grep -q "WSHandler" "${FILE}"; then
        echo "Application.cfc exists but WSHandler is not referenced in wschannels"
        exit 1
      fi
      echo "Application.cfc has wschannels registered"

  verify_ws_js_client:
    machine: dev-machine
    user: laborant
    needs:
      - verify_ws_handler
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/ws_demo.cfm"
      if ! grep -qi "new WebSocket\|WebSocket(" "${FILE}" 2>/dev/null; then
        echo "No JavaScript WebSocket client found in ws_demo.cfm"
        exit 1
      fi
      echo "JavaScript WebSocket client is present"


  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    run: |
      echo "Lesson complete — well done!"

challenges:
  websockets_6e5e8d19: {}

---
