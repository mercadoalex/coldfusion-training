---
kind: challenge

title: WebSocket Demo Page

description: |
  Create WSHandler.cfc with onWSMessage, register a WebSocket channel in
  Application.cfc, and create ws_demo.cfm with a JavaScript WebSocket client.
  The page must return HTTP 200 and contain a WebSocket constructor call.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- websockets

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
      echo "ws_demo.cfm accessible"

  verify_ws_handler:
    machine: dev-machine
    user: laborant
    needs:
      - verify_ws_page
    run: |
      COUNT=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" \
        | xargs grep -li "onWSMessage\|wsPublish\|wsGetAllChannels" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No WebSocket handler CFC found"
        exit 1
      fi
      echo "WebSocket handler CFC present"

  verify_js_client:
    machine: dev-machine
    user: laborant
    needs:
      - verify_ws_handler
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/ws_demo.cfm"
      if ! grep -qi "new WebSocket\|WebSocket(" "${FILE}" 2>/dev/null; then
        echo "No JavaScript WebSocket client in ws_demo.cfm"
        exit 1
      fi
      echo "JavaScript WebSocket client present"
---

## Your mission

1. Create `WSHandler.cfc` with at least `onWSMessage` (calls `wsPublish`)
2. Add `this.wschannels` to `Application.cfc` registering the handler
3. Create `ws_demo.cfm` with a `new WebSocket(...)` JavaScript client

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/ws_demo.cfm
```
