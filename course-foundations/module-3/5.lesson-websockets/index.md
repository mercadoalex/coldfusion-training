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

## WebSocket handler CFC

```cfml
// WSHandler.cfc
component {
  public void function onWSMessage(string channel, any data, struct client) {
    // broadcast message to all subscribers on the channel
    wsPublish(channel, data);
  }

  public void function onWSOpen(struct client) {
    writeLog("WS opened: #client.clientid#");
  }

  public void function onWSClose(struct client) {
    writeLog("WS closed: #client.clientid#");
  }
}
```

## Register the WebSocket endpoint in Application.cfc

```cfml
component {
  this.name = "MyApp";
  this.wschannels = [
    {name: "chat",          cfclistener: "WSHandler"},
    {name: "notifications", cfclistener: "WSHandler"}
  ];
}
```

## JavaScript client

```javascript
const ws = new WebSocket("ws://localhost:8500/cfusion/WS/chat");

ws.onopen = () => {
  ws.send(JSON.stringify({type: "join", user: "Alex"}));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  document.getElementById("chat").insertAdjacentHTML(
    "beforeend", `<p><strong>${msg.user}</strong>: ${msg.text}</p>`
  );
};

function sendMessage(text) {
  ws.send(JSON.stringify({type: "message", user: "Alex", text}));
}
```

## Publish from server-side CFML

```cfml
<cfscript>
  wsPublish("notifications", serializeJSON({
    type: "alert",
    message: "New student registered",
    timestamp: now()
  }));
</cfscript>
```
