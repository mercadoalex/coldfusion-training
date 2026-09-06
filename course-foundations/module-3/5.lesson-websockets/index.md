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
    needs:
      - verify_ws_page
    run: |
      COUNT=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" | xargs grep -li "wsGetAllChannels\|wsPublish\|onWSMessage" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No WebSocket handler CFC found"
        exit 1
      fi
      echo "WebSocket handler CFC found"

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
---
