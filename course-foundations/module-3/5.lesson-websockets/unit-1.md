---
kind: unit

title: Real-Time Communication with WebSockets

name: real-time-websockets-unit-1
---

## Understanding WebSockets and Their Role in Modern Applications

HTTP is a **request–response** protocol: the client sends a request, the server replies, and the connection closes. That works well for loading pages and calling APIs, but it is the wrong tool for anything that must push data from the server to the client without being asked — live chat messages, real-time notifications, live dashboards.

**WebSockets** solve this by upgrading an HTTP connection to a persistent, full-duplex channel. Once the handshake completes, both sides can send frames at any time without the overhead of a new HTTP request for every message.

Why does this matter for ColdFusion developers?

- ColdFusion 2025 ships with a **built-in WebSocket server** — no extra daemon, no third-party proxy
- The HTTP server runs on port **8500** in the lab, but the WebSocket server runs on a **separate port — 8585 by default**
- The server side is a plain **CFC** that extends `CFIDE.websocket.ChannelListener` — the same CFC model you already know
- You can push a message to every connected client from **any CFML page** with a single function call: `wsPublish`
- The browser connects using the **`<cfwebsocket>`** CFML tag — not a raw `new WebSocket()` call

::hint-box
---
:summary: 💡 Two ports — HTTP on 8500, WebSocket on 8585
---
This is one of the most common sources of confusion in CF WebSocket setup. The HTTP server (where you open `.cfm` pages) runs on port 8500. The WebSocket server runs on a **different port — 8585 by default**. You can confirm the WebSocket port at any time:

```bash
curl -s http://localhost:8500/CFIDE/administrator/index.cfm | grep websocket_port
```
::

::image-box
---
:src: __static__/cf-websocket-architecture-v1.png
:alt: Architecture diagram showing the ColdFusion WebSocket flow — on the left a blue browser box contains two items: a JavaScript block with new WebSocket("ws://localhost:8500/cfusion/WS/chat") and a ws.onmessage handler that inserts incoming text into the page; a bidirectional dark arrow labelled WebSocket upgrade same port 8500 crosses to the right where a green Adobe ColdFusion 2025 server box contains two inner cards: Application.cfc with this.wschannels array registering the chat channel mapped to WSHandler, and WSHandler.cfc with onWSMessage calling wsPublish to broadcast back to all subscribers; a small grey channel bubble labelled chat sits between the two boxes on the arrow
:max-width: 860px
---
_ColdFusion's built-in WebSocket server: register channels in `Application.cfc`, implement a handler CFC, connect from the browser — all on the same port._
::

---

## 1. The WebSocket handler CFC

The server side of a WebSocket channel is a CFC with three lifecycle methods. ColdFusion calls them automatically as connections open, receive messages, and close.

::image-box
---
:src: __static__/websocket-handler-lifecycle-v1.png
:alt: Three-column lifecycle diagram for WSHandler.cfc — left column is a grey connection box labelled Client connects, an arrow labelled onWSOpen points right into the middle ColdFusion column which shows the onWSOpen method logging the client ID; a second arrow from the browser box labelled Client sends message points to onWSMessage which calls wsPublish back to all subscribers; a third arrow labelled Client disconnects points to onWSClose which logs the closed client ID; the right column is the same browser box labelled All subscribers receive the broadcast message
:max-width: 860px
---
_Three lifecycle methods: `onWSOpen` when a client connects, `onWSMessage` when a frame arrives, `onWSClose` when the connection drops._
::

```cfml
// WSHandler.cfc — place in the CF wwwroot
component extends="CFIDE.websocket.ChannelListener" {

    /**
     * Called when a message arrives on this channel.
     * channel  — name of the channel the message was sent to
     * data     — the raw message string (often JSON)
     * client   — struct with clientid, subscribed channels, etc.
     */
    public void function onWSMessage(
        required string channel,
        required any    data,
        required struct client
    ) {
        // Echo the message back to every subscriber on the same channel
        wsPublish(channel, data);
    }

    /**
     * Called when a new client subscribes to any channel
     * handled by this CFC.
     */
    public void function onWSOpen(required struct client) {
        writeLog(
            file = "websocket",
            text = "WS connection opened: #client.clientid#"
        );
    }

    /**
     * Called when a client disconnects (tab closed, network drop, etc.).
     */
    public void function onWSClose(required struct client) {
        writeLog(
            file = "websocket",
            text = "WS connection closed: #client.clientid#"
        );
    }

}
```

The `client` struct is provided by ColdFusion and contains at minimum `clientid` — a unique identifier for that connection. You can use it to send targeted messages or track online users.

::hint-box
---
:summary: ⚠️ Your handler CFC must extend CFIDE.websocket.ChannelListener
---
This is non-negotiable and not obvious from the ColdFusion documentation. ColdFusion validates the handler CFC at startup by calling `isInstanceOf("CFIDE.websocket.ChannelListener")` on it. If the component does not extend that base, the entire application throws a 500 error on every request.

The base CFC already exists at `/opt/coldfusion2025/cfusion/wwwroot/CFIDE/websocket/ChannelListener.cfc` and provides default pass-through implementations of all six listener methods (`allowSubscribe`, `allowPublish`, `beforePublish`, `canSendMessage`, `beforeSendMessage`, `afterUnsubscribe`). Your handler only needs to override the ones it cares about.

```cfml
// ✗ Wrong — CF throws InvalidListenerException at startup
component {
    public void function onWSMessage(...) { ... }
}

// ✓ Correct
component extends="CFIDE.websocket.ChannelListener" {
    public void function onWSMessage(...) { ... }
}
```

If you edit `WSHandler.cfc` and the error persists after restarting CF, delete the compiled class cache — CF may be loading a stale compiled version:

```bash
rm -f /opt/coldfusion2025/cfusion/wwwroot/WEB-INF/cfclasses/cfWSHandler* && \
sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart
```
::

::details-box
---
:summary: 📖 What else is in the client struct?
---

ColdFusion populates the `client` struct with metadata about the WebSocket connection. The most useful keys:

| Key | Type | Description |
|---|---|---|
| `clientid` | string | Unique ID for this connection — generated by CF |
| `subscriptions` | array | List of channel names this client is subscribed to |
| `cfid` | string | ColdFusion session ID, if the user has an active session |
| `cftoken` | string | ColdFusion session token, if applicable |

You can use `clientid` with `wsSendMessage(clientid, data)` to push a message to one specific client instead of broadcasting to everyone. This is useful for targeted notifications (e.g., "Your export is ready") where you do not want to broadcast to every connected user.
::

---

## 2. Register channels in Application.cfc

Channels must be declared in `Application.cfc` before the WebSocket server will accept connections to them. Use the `this.wschannels` array — each entry is a struct with a `name` and a `cfclistener`:

::image-box
---
:src: __static__/websocket-channel-registration-v1.png
:alt: Code card showing Application.cfc with this.wschannels assigned an array of two structs — first struct has name chat and cfclistener WSHandler, second struct has name notifications and cfclistener WSHandler — an annotation arrow on the right labels cfclistener as the CFC that handles onWSMessage onWSOpen onWSClose for this channel and another annotation labels name as the string used in new WebSocket wsPublish and wsGetAllChannels
:max-width: 860px
---
_Both channels point to the same handler CFC. Multiple channels can share a handler — they are distinguished by the `channel` argument in `onWSMessage`._
::

```cfml
// Application.cfc
component {

    this.name = "MyApp";

    // Declare WebSocket channels.
    // Each channel needs: name (string) and cfclistener (CFC name).
    this.wschannels = [
        { name="chat",          cfclistener="WSHandler" },
        { name="notifications", cfclistener="WSHandler" }
    ];

}
```

A few rules:
- The `cfclistener` value is the **CFC name without `.cfc`**, resolved relative to the webroot (or via the component path)
- The handler CFC **must be in the same directory or a subdirectory** of the application — CF will not find it otherwise
- Channel names must be **unique** across the application
- Use `name="channelName"` syntax (equals sign, not colon) — the JSON colon syntax `{"name": "chat"}` is not supported in `this.wschannels`
- You must **restart the CF application** (or touch `Application.cfc`) after changing `this.wschannels`
- If no `cfclistener` is specified, ColdFusion uses the default `CFIDE/websocket/ChannelListener.cfc` which allows everything through

::hint-box
---
:summary: ⚠️ Use name= syntax, not JSON colon syntax
---
ColdFusion struct literals in `this.wschannels` must use the **equals sign** syntax, not quoted JSON-style keys:

```cfml
// ✓ Correct
this.wschannels = [{ name="chat", cfclistener="WSHandler" }];

// ✗ Wrong — CF silently misreads this
this.wschannels = [{ "name": "chat", "cfclistener": "WSHandler" }];
```
::

---

## 3. The browser client

ColdFusion provides the **`<cfwebsocket>`** tag to create WebSocket connections from a CFM page. The tag handles the subscription handshake automatically and wraps the connection in a named JavaScript object you can call from your own code:

```cfml
<!-- Creates a JavaScript object named "ws" subscribed to the chat channel -->
<cfwebsocket
    name        = "ws"
    onMessage   = "handleMessage"
    onOpen      = "handleOpen"
    onClose     = "handleClose"
    subscribeTo = "chat"
>

<script>
function handleOpen() {
    document.getElementById("status").textContent = "Connected";
}

function handleMessage(msg) {
    // msg.data contains the payload; msg.type is "data" for real messages
    if (msg.type === "data") {
        document.getElementById("chat-log").insertAdjacentHTML(
            "beforeend",
            `<p><strong>${msg.publisherID}</strong>: ${msg.data}</p>`
        );
    }
}

function handleClose() {
    document.getElementById("status").textContent = "Disconnected";
}

// Publish a message to the chat channel
function sendMessage(text) {
    ws.publish("chat", text);
}
</script>
```

The `<cfwebsocket>` tag sends a CF-specific subscription handshake after the TCP connection opens — this is what registers the client with `wsGetSubscribers`. A plain `new WebSocket()` call opens the TCP socket but skips the handshake, so CF never sees the client as subscribed.

::details-box
---
:summary: 📖 cfwebsocket tag attributes
---

| Attribute | Required | Description |
|---|---|---|
| `name` | Yes | Name of the JavaScript object created in the page. Use it to call `.publish()`, `.subscribe()`, `.unsubscribe()`, etc. |
| `onMessage` | Yes | JavaScript function called every time the server sends a frame |
| `onOpen` | No | JavaScript function called when the connection is established |
| `onClose` | No | JavaScript function called when the connection drops |
| `onError` | No | JavaScript function called on error — receives codes `-1` (channel error) and `4001` (application error) |
| `subscribeTo` | No | Comma-separated list of channels to subscribe to automatically on connect |
| `useCFAuth` | No | If `true` (default), uses the ColdFusion session for authentication — no separate login needed |

The JavaScript object created by `name` exposes these methods: `.publish(channel, message)`, `.subscribe(channel)`, `.unsubscribe(channel)`, `.getSubscriberCount(channel)`, `.isConnectionOpen()`.
::

::details-box
---
:summary: 📖 What does the message object look like in onMessage?
---

Every message your `onMessage` function receives is a JavaScript object with these keys:

| Key | Description |
|---|---|
| `type` | `"data"` for real messages, `"response"` for system acknowledgements (subscribe, unsubscribe, etc.) |
| `code` | `0` = success, `-1` = channel error, `4001` = application error |
| `reqType` | The request type: `"subscribe"`, `"publish"`, `"data"`, etc. |
| `data` | The message payload — present when `type` is `"data"` |
| `clientid` | Unique ID of the connected client |
| `publisherID` | Client ID of who published. `0` means it came from a server-side `wsPublish` call |
| `channelname` | The channel the message arrived on |
| `msg` | Human-readable status — `"ok"` on success, error description on failure |

Always check `msg.type === "data"` before rendering — system responses (`type: "response"`) will also arrive in your `onMessage` handler.
::

::hint-box
---
:summary: 💡 Why ws:// and not wss://?
---
`ws://` is the unencrypted WebSocket protocol, analogous to `http://`. `wss://` is the TLS-encrypted equivalent, analogous to `https://`. In the lab the CF server runs without TLS, so `ws://` is correct. In production, traffic should always use `wss://` — configure TLS on CF or terminate it at a load balancer/reverse proxy and forward as `ws://` internally.

To enable a secure `wss://` connection you need a TLS certificate issued by a Certificate Authority (CA) — either a trusted public CA (such as Let's Encrypt) or your organisation's internal CA.
::

---

## 4. Push messages from server-side CFML

`wsPublish` broadcasts a message to **every client currently subscribed** to a channel. You can call it from any CFML page, scheduled task, or CFC — not just from inside the handler:

```cfml
<cfscript>
    // Broadcast a notification to all connected users
    wsPublish("notifications", serializeJSON({
        type:      "alert",
        message:   "New ticket assigned to you",
        timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
    }));
</cfscript>
```

This is the pattern for **server-initiated pushes**: a background job detects an event (new ticket, completed export, price change) and calls `wsPublish` — all connected clients receive the update without polling.

| Function | Signature | What it does |
|---|---|---|
| `wsPublish` | `wsPublish(channel, message)` | Broadcast to all subscribers on a channel |
| `wsSendMessage` | `wsSendMessage(clientid, message)` | Send to one specific connected client |
| `wsGetAllChannels` | `wsGetAllChannels()` | Returns array of all registered channel names |
| `wsGetSubscribers` | `wsGetSubscribers(channel)` | Returns array of client structs subscribed to a channel |

---

## 5. Common use cases

::image-box
---
:src: __static__/websocket-use-cases-grid-v1.png
:alt: Four-cell grid of WebSocket use cases — top-left cell has a dark-blue left border, title Live Chat, and description wsPublish broadcasts every message to all subscribers on the chat channel; top-right cell has a teal left border, title Push Notifications, and description server pushes events to connected users without polling, triggered from any CFML page or scheduled task; bottom-left cell has an indigo left border, title Live Dashboard, and description backend pushes metric or status updates on an interval using cfschedule or a loop, clients render without refreshing; bottom-right cell has a purple left border, title Collaborative Editing, and description per-document channels using a dynamic name like doc-{id} with wsSendMessage for targeted routing to specific users
:max-width: 860px
---
_Four common WebSocket patterns — all supported natively with ColdFusion's built-in WS server and `wsPublish`._
::

| Use case | Channel strategy | Pattern |
|---|---|---|
| Live chat | Single `chat` channel | `onWSMessage` calls `wsPublish(channel, data)` — every subscriber gets every message |
| Push notifications | Single `notifications` channel | Server-side CFML calls `wsPublish` when an event fires |
| Live dashboard | `dashboard` channel | Scheduled task or loop calls `wsPublish` every N seconds with fresh metrics |
| Collaborative editing | `doc-{id}` per document | Dynamic channel per resource; use `wsSendMessage` for targeted routing |

---

## Activity 1 — Create the WebSocket handler CFC

Create `WSHandler.cfc` in the ColdFusion webroot:

```bash
cat > /opt/coldfusion2025/cfusion/wwwroot/WSHandler.cfc << 'EOF'
component extends="CFIDE.websocket.ChannelListener" {

    public void function onWSMessage(
        required string channel,
        required any    data,
        required struct client
    ) {
        wsPublish(channel, data);
    }

    public void function onWSOpen(required struct client) {
        writeLog(file="websocket", text="WS opened: #client.clientid#");
    }

    public void function onWSClose(required struct client) {
        writeLog(file="websocket", text="WS closed: #client.clientid#");
    }

}
EOF
```

Verify the file was created:

```bash
grep -l "wsPublish\|onWSMessage" /opt/coldfusion2025/cfusion/wwwroot/*.cfc
```

::simple-task
---
:tasks: tasks
:name: verify_ws_handler
---
#active
Create `WSHandler.cfc` in the CF wwwroot with `onWSMessage` calling `wsPublish`.

#completed
WebSocket handler CFC found. ✓
::

---

## Activity 2 — Create ws_demo.cfm and register the channel

**Step 1** — Create `Application.cfc` in the webroot with the `chat` channel registered:

```bash
cat > /opt/coldfusion2025/cfusion/wwwroot/Application.cfc << 'EOF'
component {

    this.name = "MyApp";

    this.wschannels = [
        { name="chat", cfclistener="WSHandler" }
    ];

}
EOF
```

Verify it was created correctly:

```bash
grep -A3 "wschannels" /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

::simple-task
---
:tasks: tasks
:name: verify_ws_channels
---
#active
Create `Application.cfc` in the CF wwwroot with `this.wschannels` registering the `chat` channel pointing to `WSHandler`.

#completed
`Application.cfc` has `wschannels` registered. ✓
::

**Step 2** — Create `ws_demo.cfm` with a chat UI using the `<cfwebsocket>` tag:

```bash
cat > /opt/coldfusion2025/cfusion/wwwroot/ws_demo.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CF WebSocket Demo</title>
    <style>
        body { font-family: sans-serif; max-width: 600px; margin: 2rem auto; }
        #chat-log { border: 1px solid #ccc; height: 200px; overflow-y: auto; padding: 0.5rem; margin-bottom: 0.5rem; }
        #msg-input { width: 75%; padding: 0.4rem; }
        button { padding: 0.4rem 1rem; }
    </style>
</head>
<body>
    <h2>WebSocket Chat Demo</h2>
    <div id="chat-log"></div>
    <input id="msg-input" type="text" placeholder="Type a message…">
    <button onclick="sendMsg()">Send</button>
    <p id="status">Connecting…</p>

    <cfwebsocket
        name        = "chatWS"
        onMessage   = "handleMessage"
        onOpen      = "handleOpen"
        onClose     = "handleClose"
        subscribeTo = "chat"
    >

    <script>
        const log    = document.getElementById("chat-log");
        const status = document.getElementById("status");

        function handleOpen() {
            status.textContent = "Connected";
        }

        function handleMessage(msg) {
            if (msg.type === "data") {
                log.insertAdjacentHTML("beforeend",
                    `<p><strong>user</strong>: ${msg.data}</p>`);
                log.scrollTop = log.scrollHeight;
            }
        }

        function handleClose() {
            status.textContent = "Disconnected";
        }

        function sendMsg() {
            const input = document.getElementById("msg-input");
            if (!input.value.trim()) return;
            chatWS.publish("chat", input.value);
            input.value = "";
        }
    </script>
</body>
</html>
EOF
```

**Step 3** — Verify the page returns HTTP 200:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/ws_demo.cfm
```

You should see `200`. Open `http://localhost:8500/ws_demo.cfm` in the lab browser to see the chat UI:

::image-box
---
:src: __static__/browser-ws-demo-chat-ui-v1.png
:alt: Browser screenshot of the WebSocket Chat Demo page — a white page with the heading WebSocket Chat Demo, below it a bordered chat log area, an input field labelled Type a message… next to a Send button, and a status line reading Connected in green
:max-width: 860px
---
_The chat demo page — once the WebSocket handshake completes the status line changes from "Connecting…" to "Connected"._
::

::hint-box
---
:summary: ⚠️ Page returns 500 or blank?
---
The most common cause is a syntax error in `Application.cfc`. Check that the `this.wschannels` line is inside the `component { }` block and that all curly braces are balanced. You can also hit `http://localhost:8500/Application.cfc` in the CF admin browser tab to trigger a parse error message.
::

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
:name: verify_ws_js_client
---
#active
Add `new WebSocket(...)` JavaScript client code to `ws_demo.cfm`.

#completed
JavaScript WebSocket client is present. ✓
::

---

## Activity 3 — Test end-to-end with a server push

ColdFusion's WebSocket subscription protocol requires a specific handshake message that only the `<cfwebsocket>` tag sends automatically. Command-line tools like `websocat` open a raw TCP connection but never send this handshake, so CF never registers them as subscribers. The correct end-to-end test uses the **browser** and a **server-side push**.

This activity needs **two terminal tabs open at the same time**. Click the **+** button at the top of the terminal panel to open a second tab:

::image-box
---
:src: __static__/second-terminal-v1.png
:alt: Lab terminal panel showing the + button at the top right of the terminal tab bar used to open a new terminal tab
:max-width: 860px
---
_Click **+** to open a second terminal tab. Click each tab to switch between them._
::

**Step 1 — In Terminal 1**, create the server-side push script:

```bash
cat > /opt/coldfusion2025/cfusion/wwwroot/ws_push_test.cfm << 'EOF'
<cfscript>
    wsPublish("chat", "Hello from wsPublish — " & timeFormat(now(), "HH:mm:ss"));
    writeOutput("Published");
</cfscript>
EOF
```

**Step 2** — Open `http://localhost:8500/ws_demo.cfm` in the lab browser. Wait until the status line shows **Connected**.

**Step 3 — In Terminal 2**, trigger the server-side push:

```bash
curl -s http://localhost:8500/ws_push_test.cfm
```

You should see `Published` in Terminal 2 and the message appear in the chat log in the browser instantly.

::hint-box
---
:summary: ⚠️ Browser shows "Connected" but no message appears after the push?
---
Check that `ws_push_test.cfm` returned `Published` (not a CF error). If it did but the message still didn't appear, open the browser DevTools console — look for WebSocket errors or check that the `handleMessage` function is correctly wired to the `<cfwebsocket>` tag's `onMessage` attribute.
::

---

## Troubleshooting WebSockets in ColdFusion

Real-world WebSocket setup surfaces a few gotchas that are not obvious from the documentation. Here is what to check when things do not work.

**Raw `new WebSocket()` connects but `wsGetSubscribers` returns 0**

ColdFusion WebSockets use a proprietary subscription handshake on top of the standard WebSocket protocol. A plain `new WebSocket()` in JavaScript (or tools like `websocat`) only opens the TCP connection — it never sends the CF subscription message, so the server never registers the client as a subscriber and `wsPublish` delivers nothing.

Always use the **`<cfwebsocket>`** tag in your CFM pages. The tag sends the subscription handshake automatically and wraps the connection in a named JavaScript object (`chatWS.publish()`, `chatWS.subscribe()`, etc.):

```cfml
<cfwebsocket name="chatWS" onMessage="handleMessage" subscribeTo="chat">
```

**`WSHandler is not a valid ChannelListener` in the exception log**

The handler CFC must **extend** `CFIDE.websocket.ChannelListener`, not just declare the methods bare. ColdFusion calls `isInstanceOf("CFIDE.websocket.ChannelListener")` on the CFC at startup — if the component does not extend that base, the channel fails to initialise and every request to the app returns 500.

```cfml
// ✗ Wrong — CF rejects this
component {
    public void function onWSMessage(...) { ... }
}

// ✓ Correct
component extends="CFIDE.websocket.ChannelListener" {
    public void function onWSMessage(...) { ... }
}
```

The base CFC lives at `/opt/coldfusion2025/cfusion/wwwroot/CFIDE/websocket/ChannelListener.cfc` and already provides default implementations of `allowSubscribe`, `allowPublish`, `beforePublish`, `canSendMessage`, `beforeSendMessage`, and `afterUnsubscribe` — your handler only needs to override the methods it cares about.

**WebSocket port is not 8500**

The CF HTTP server runs on port 8500, but the WebSocket server runs on a **separate port — 8585 by default**. Always connect `websocat` and browser clients to port 8585:

```bash
# ✗ Wrong port
websocat ws://localhost:8500/cfusion/WS/chat

# ✓ Correct
websocat ws://localhost:8585/cfusion/WS/chat
```

You can confirm the WebSocket port at any time:

```bash
curl -s http://localhost:8500/CFIDE/administrator/index.cfm | grep websocket_port
```

**Browser WebSocket connects to the wrong host**

If `ws_demo.cfm` is accessed via an IP address (e.g. `172.16.0.2`) but the JavaScript hardcodes `ws://localhost:8585`, the browser will try to connect to its own `localhost` — not the server. Always use ColdFusion's `cgi` scope to build the URL dynamically:

```cfml
// ColdFusion evaluates this server-side before sending HTML to the browser
const ws = new WebSocket("ws://#cgi.server_name#:8585/cfusion/WS/chat");
```

**Channel initialisation error on every request**

If `application.log` shows `Channel chat Initialization Exception` repeating every second, it means CF is retrying the channel setup on every request because it keeps failing. Fix `WSHandler.cfc` (add `extends="CFIDE.websocket.ChannelListener"`), then do a full CF restart — a `touch Application.cfc` reload is not enough once the channel is in a failed state:

```bash
sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart
```

**Edited the CFC but the error persists after restart**

ColdFusion caches compiled CFC classes in `wwwroot/WEB-INF/cfclasses/`. If you edit `WSHandler.cfc` but the error keeps happening, CF may have reused the old cached `.class` file instead of recompiling. Delete the cache and restart:

```bash
rm -f /opt/coldfusion2025/cfusion/wwwroot/WEB-INF/cfclasses/cfWSHandler* && \
sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart
```

This forces CF to recompile `WSHandler.cfc` from source on the next request.

**Understanding WebSocket response codes**

Every server response includes a `code` field. Use it in your `ws.onmessage` handler to detect errors:

| Code | Category | Meaning |
|---|---|---|
| `0` | Success | Request completed successfully |
| `-1` | Channel error | Channel not found, or client already subscribed |
| `4001` | Application error | Runtime error while invoking a CFC method |

If you have defined a `ws.onerror` handler it receives codes `-1` and `4001`. If not, they arrive in `ws.onmessage` — check `event.data.code` to distinguish errors from normal messages:

```javascript
ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (msg.code === -1)  { console.error("Channel error:", msg.msg); return; }
    if (msg.code === 4001) { console.error("Application error:", msg.msg); return; }
    // normal message — msg.data contains the payload
};
```

---

## Key takeaways

| Concept | ColdFusion approach |
|---|---|
| Declare a channel | `this.wschannels = [{name="chat", cfclistener="WSHandler"}]` in `Application.cfc` |
| Handler CFC | Must `extends="CFIDE.websocket.ChannelListener"` — bare `component {}` is rejected |
| Channel struct syntax | Use `name="chat"` (equals), not `"name": "chat"` (colon) |
| Browser client | Use `<cfwebsocket>` tag — not raw `new WebSocket()` |
| Handle incoming messages | `onWSMessage(channel, data, client)` in the handler CFC |
| Broadcast to all subscribers | `wsPublish(channelName, message)` |
| Send to one client | `wsSendMessage(client.clientid, message)` |
| WebSocket port | Port **8585** (not 8500) — confirm with `grep websocket_port` in CF admin page |
| Server-initiated push | Call `wsPublish` from any CFML page, scheduled task, or CFC |
| Stale class cache | Delete `WEB-INF/cfclasses/cfWSHandler*` and restart CF if edits don't take effect |

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All done? Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete. On to the next one!
::

::remark-box
Found a bug or an issue with this lesson? Please reach out — your feedback helps improve the course for everyone.

📧 Alex — mercadoalex[at]gmail.com
::

---

## Further reading

- [Adobe ColdFusion documentation — Using WebSocket to broadcast messages](https://guides.adobe.com/coldfusion/en/docs/develop-coldfusion-applications/using-websocket-to-broadcast-messages.html)
