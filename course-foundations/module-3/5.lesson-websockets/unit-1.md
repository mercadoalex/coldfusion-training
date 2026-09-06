---
kind: unit

title: Real-Time Communication with WebSockets

name: real-time-websockets-unit-1
---

## How ColdFusion WebSockets work

ColdFusion 2025 ships with a built-in WebSocket server running on the same port as the HTTP server. Clients connect via JavaScript's `WebSocket` API; the server-side handler is a CFC with lifecycle methods.

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

---

## Register channels in Application.cfc

```cfml
component {
  this.name = "MyApp";
  this.wschannels = [
    {name: "chat",          cfclistener: "WSHandler"},
    {name: "notifications", cfclistener: "WSHandler"}
  ];
}
```

Each channel name maps to a handler CFC. Multiple channels can share the same handler.

---

## JavaScript client

```javascript
const ws = new WebSocket("ws://localhost:8500/cfusion/WS/chat");

ws.onopen = () => {
  ws.send(JSON.stringify({type: "join", user: "Alex"}));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  document.getElementById("chat").insertAdjacentHTML(
    "beforeend",
    `<p><strong>${msg.user}</strong>: ${msg.text}</p>`
  );
};

function sendMessage(text) {
  ws.send(JSON.stringify({type: "message", user: "Alex", text}));
}
```

---

## Publish from server-side CFML

Use `wsPublish` to push a message from any CFML page to all connected clients on a channel:

```cfml
<cfscript>
  wsPublish("notifications", serializeJSON({
    type:      "alert",
    message:   "New student registered",
    timestamp: now()
  }));
</cfscript>
```

This is useful for real-time dashboard updates triggered by background jobs or scheduled tasks.

---

## Common use cases

| Use case | Channel | Pattern |
|---|---|---|
| Live chat | `chat` | Broadcast every message to all subscribers |
| Notifications | `notifications` | Server pushes events to connected users |
| Live dashboard | `dashboard` | Backend pushes metric updates every N seconds |
| Collaborative editing | `doc-{id}` | Per-document channels with targeted routing |

---

## Exercises

1. Create `WSHandler.cfc` in the webroot with `onWSMessage`, `onWSOpen`, and `onWSClose`.
2. Register a `chat` channel in `Application.cfc`.
3. Create `ws_demo.cfm` with a `new WebSocket(...)` JavaScript client.
4. Verify:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/ws_demo.cfm
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_ws_page
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/ws_demo.cfm` — must return HTTP 200.

#completed
`ws_demo.cfm` is accessible. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_ws_handler
---
#active
Create `WSHandler.cfc` with `onWSMessage`, `wsPublish`, or `wsGetAllChannels`.

#completed
WebSocket handler CFC found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_ws_js_client
---
#active
Add `new WebSocket(...)` JavaScript client code to `ws_demo.cfm`.

#completed
JavaScript WebSocket client is present. ✓
::
