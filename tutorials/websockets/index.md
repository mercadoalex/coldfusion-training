---
kind: tutorial

title: Real-Time Notifications with WebSockets

description: |
  Build a WebSocket handler CFC, register a notifications channel,
  and write a JavaScript client that displays server push events.

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
---

## Steps

### 1. Create WSHandler.cfc

Create `/opt/coldfusion2025/cfusion/wwwroot/WSHandler.cfc`:

```cfml
component {
  public void function onWSMessage(string channel, any data, struct client) {
    wsPublish(channel, data);
  }

  public void function onWSOpen(struct client) {
    writeLog(file="websocket", text="Client connected: #client.clientid#");
  }

  public void function onWSClose(struct client) {
    writeLog(file="websocket", text="Client disconnected: #client.clientid#");
  }
}
```

### 2. Register the channel in Application.cfc

Add to your `Application.cfc` component block:

```cfml
this.wschannels = [
  {name: "notifications", cfclistener: "WSHandler"}
];
```

### 3. Create ws_demo.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/ws_demo.cfm`:

```cfml
<!DOCTYPE html>
<html>
<head><title>WS Demo</title></head>
<body>
  <h1>Live Notifications</h1>
  <ul id="messages"></ul>
  <button onclick="sendPing()">Send Ping</button>

  <script>
    const ws = new WebSocket("ws://localhost:8500/cfusion/WS/notifications");
    const list = document.getElementById("messages");

    ws.onopen = () => {
      const li = document.createElement("li");
      li.textContent = "Connected";
      list.appendChild(li);
    };

    ws.onmessage = (event) => {
      const li = document.createElement("li");
      li.textContent = JSON.stringify(JSON.parse(event.data));
      list.appendChild(li);
    };

    function sendPing() {
      ws.send(JSON.stringify({type: "ping", ts: Date.now()}));
    }
  </script>
</body>
</html>
```

### 4. Verify the page loads

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/ws_demo.cfm
```

Open the **ColdFusion** browser tab and navigate to `/ws_demo.cfm` to see the live WebSocket connection.
