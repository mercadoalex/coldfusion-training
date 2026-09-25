---
kind: unit

title: WebSockets — Live, Two-Way Connections Without the Request Overhead

name: real-time-websockets-unit-1
---

## WebSockets — Live, Two-Way Connections Without the Request Overhead

HTTP is a **request–response** protocol: the client sends a request, the server replies, and the connection closes. That works well for loading pages and calling APIs, but it is the wrong tool for anything that must push data from the server to the client without being asked — live chat messages, real-time notifications, live dashboards.

**WebSockets** solve this by upgrading an HTTP connection to a persistent, full-duplex channel. Once the handshake completes, both sides can send frames at any time without the overhead of a new HTTP request for every message.

Why does this matter for ColdFusion developers?

- ColdFusion 2025 ships with a **built-in WebSocket server** — no extra daemon, no third-party proxy
- The HTTP server runs on port **8500** in the lab, and in this lab the WebSocket server also runs on **port 8500** — because `startListenerOnNormalPort` is enabled in the CF config
- The server side is a plain **CFC** that extends `CFIDE.websocket.ChannelListener` — the same CFC model you already know
- You can push a message to every connected client from **any CFML page** with a single function call: `wsPublish`
- The browser connects using a `new WebSocket()` call pointed at the same host and port as the HTTP page

::hint-box
---
:summary: 💡 WebSocket port — 8585 by default, but 8500 in this lab
---
ColdFusion's WebSocket server defaults to port **8585**, separate from the HTTP port 8500. However this lab image has `startListenerOnNormalPort=true` in `neo-websocket.xml`, which tells CF to also accept WebSocket upgrade requests on the **same port as HTTP — 8500**. You can confirm this at any time:

```bash
cat /opt/coldfusion2025/cfusion/lib/neo-websocket.xml | grep -A2 "startListenerOnNormalPort"
```

Expected output:
```
<var name='startListenerOnNormalPort'>
    <boolean value='true'/>
```

This means the browser WebSocket URL is `ws://<host>:8500/cfusion/WS/<channel>` — the same port the page was served from, which is already proxied correctly by the lab platform.
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

Every handler CFC must start with this declaration — the `extends` is not optional:

```cfml
component extends="CFIDE.websocket.ChannelListener" {
    // your three lifecycle methods go here
}
```

ColdFusion calls `isInstanceOf("CFIDE.websocket.ChannelListener")` on your CFC at startup. If the `extends` is missing, every request to the application returns 500.

---

### `onWSMessage` — a message arrived

Called every time a client sends a frame to the channel. This is where you decide what to do with the message — in the simplest case, echo it back to everyone.

| Argument | Type | What it contains |
|---|---|---|
| `channel` | string | The channel the message was sent to — `"chat"`, `"notifications"`, etc. |
| `data` | any | The raw message payload — a string, or a JSON string you can deserialize |
| `client` | struct | Metadata about the sender — at minimum `client.clientid` |

```cfml
public void function onWSMessage(
    required string channel,
    required any    data,
    required struct client
) {
    // Echo the message back to every subscriber on the same channel
    wsPublish(channel, data);
}
```

`wsPublish(channel, data)` broadcasts `data` to **every client currently subscribed** to that channel — including the sender.

---

### `onWSOpen` — a client just connected

Called once per connection when a new client subscribes to any channel this CFC handles. Use it to log connections or send a welcome message.

| Argument | Type | What it contains |
|---|---|---|
| `client` | struct | The connecting client — `client.clientid` is the unique connection ID |

```cfml
public void function onWSOpen(required struct client) {
    writeLog(
        file = "websocket",
        text = "WS connection opened: #client.clientid#"
    );
}
```

---

### `onWSClose` — a client disconnected

Called when a connection drops — tab closed, network lost, or the client called `.close()` in JavaScript. Use it to clean up any per-client state you are tracking.

| Argument | Type | What it contains |
|---|---|---|
| `client` | struct | The disconnecting client — same `clientid` that was passed to `onWSOpen` |

```cfml
public void function onWSClose(required struct client) {
    writeLog(
        file = "websocket",
        text = "WS connection closed: #client.clientid#"
    );
}
```

---

### The complete handler CFC

Put it all together — this is the file you will create in Activity 1:

```cfml
// WSHandler.cfc — place in the CF wwwroot
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

ColdFusion provides the **`<cfwebsocket>`** tag to create WebSocket connections from a CFM page. The tag handles the subscription handshake automatically and wraps the connection in a named JavaScript object.

> **`<cfwebsocket>` vs `new WebSocket()` — which to use in this lab**
>
> `<cfwebsocket>` is the standard CF approach — it handles the subscription handshake automatically. However, it hardcodes `localhost` in the JavaScript it emits, which only works when the browser and server are on the same machine. In this lab the browser connects through the iximiuz platform proxy with a generated hostname — `localhost` resolves to the student's own laptop rather than the VM.
>
> For this reason **the activity uses a raw `new WebSocket()` call** built from `window.location.host`, which the browser already knows correctly regardless of the proxy. The WebSocket connects on port 8500 — the same port as HTTP, because `startListenerOnNormalPort=true` in the lab's CF config. `<cfwebsocket>` remains the right choice for any deployment where the browser hits the server directly.

---

### Step 1 — The `<cfwebsocket>` tag

This single CFML tag replaces several lines of JavaScript boilerplate. Drop it anywhere in your CFM page — ColdFusion emits the connection script automatically.

| Attribute | Required | What it does |
|---|---|---|
| `name` | Yes | The JavaScript variable name for this connection — use it to call `.publish()` later |
| `onMessage` | Yes | Your JS function that runs every time the server sends a frame |
| `onOpen` | No | Your JS function that runs when the connection is established |
| `onClose` | No | Your JS function that runs when the connection drops |
| `subscribeTo` | No | Channel(s) to join immediately on connect — comma-separated |

```cfml
<cfwebsocket
    name        = "chatWS"
    onMessage   = "handleMessage"
    onOpen      = "handleOpen"
    onClose     = "handleClose"
    subscribeTo = "chat"
>
```

`name="chatWS"` means you will call `chatWS.publish(...)` from JavaScript — it is the handle for this connection.

---

### Step 2 — `handleOpen` and `handleClose`

These two functions mirror `onWSOpen` / `onWSClose` on the server — they fire when the connection state changes on the **browser** side.

```javascript
function handleOpen() {
    // Connection is live — safe to publish now
    document.getElementById("status").textContent = "Connected";
}

function handleClose() {
    // Connection dropped — warn the user
    document.getElementById("status").textContent = "Disconnected";
}
```

---

### Step 3 — `handleMessage`

Every frame the server sends — including system responses like subscribe confirmations — arrives here. Check `msg.type === "data"` to filter out system messages and only render real chat payloads.

| `msg` field | What it contains |
|---|---|
| `msg.type` | `"data"` for real messages; `"response"` for system acknowledgements |
| `msg.data` | The payload — present when `type` is `"data"` |
| `msg.publisherID` | Client ID of the sender; `0` means it came from a server-side `wsPublish` call |

```javascript
function handleMessage(msg) {
    if (msg.type === "data") {
        document.getElementById("chat-log").insertAdjacentHTML(
            "beforeend",
            `<p><strong>${msg.publisherID}</strong>: ${msg.data}</p>`
        );
    }
}
```

---

### Step 4 — sending a message

The JavaScript object created by `<cfwebsocket name="chatWS">` exposes a `.publish()` method. Call it from any JS function to send a message to a channel:

```javascript
function sendMessage(text) {
    chatWS.publish("chat", text);
}
```

The object also exposes `.subscribe(channel)`, `.unsubscribe(channel)`, `.getSubscriberCount(channel)`, and `.isConnectionOpen()` — useful for more advanced interactions.

---

### The complete browser client

All four pieces together — this is what goes in `ws_demo.cfm`:

```cfml
<cfwebsocket
    name        = "chatWS"
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

function sendMessage(text) {
    chatWS.publish("chat", text);
}
</script>
```

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
:summary: ⚠️ Always use wss:// when the page is served over HTTPS
---

`ws://` and `wss://` mirror `http://` and `https://` exactly — `wss://` is the TLS-encrypted WebSocket protocol. Browsers enforce a hard rule: **a page loaded over HTTPS may not open an unencrypted `ws://` connection**. Attempting it produces a Mixed Content error in the browser console and the connection is blocked before it reaches the server:

::image-box
---
:src: __static__/wss-required-v1.png
:alt: Browser DevTools console showing a Mixed Content error — the page was loaded over HTTPS but attempted to connect to an insecure ws:// WebSocket endpoint, which was blocked by the browser
:max-width: 860px
---
_Mixed Content error — the browser blocks `ws://` from an HTTPS page. Switch to `wss://` to fix it._
::

The lab is served over HTTPS, so `wss://` is required. Rather than hardcoding either protocol, derive it from the page:

```javascript
const wsProto = window.location.protocol === "https:" ? "wss://" : "ws://";
const ws = new WebSocket(wsProto + window.location.host + "/cfusion/WS/chat");
```

This works in the lab (HTTPS → `wss://`), in local development (HTTP → `ws://`), and in any production deployment — no changes needed when moving between environments.
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

**Step 1 — Open a Terminal tab**

Click the **Terminal** tab in the lab panel. You should see a prompt like:

```
laborant@dev-machine:~$
```

**Step 2 — Create `WSHandler.cfc` in the ColdFusion webroot**

The ColdFusion webroot is `/opt/coldfusion2025/cfusion/wwwroot/`. Run the following command — it creates the file and writes the full handler CFC in one step:

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

The command returns silently with no output — that means it succeeded.

**Step 3 — Verify the file was created correctly**

```bash
grep -l "wsPublish\|onWSMessage" /opt/coldfusion2025/cfusion/wwwroot/*.cfc
```

Expected output:

```
/opt/coldfusion2025/cfusion/wwwroot/WSHandler.cfc
```

If you see that path, the file is in place and contains both required methods. If nothing is returned, the file is missing or the command in Step 2 did not run fully — try Step 2 again.

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

### Step 1 — Create `Application.cfc` in the ColdFusion webroot

`Application.cfc` is ColdFusion's application configuration file — it sits in the webroot and is loaded automatically on the first request. This is where you register WebSocket channels: without a `this.wschannels` entry here, ColdFusion has no record of the `chat` channel and any browser that tries to subscribe will be rejected before `WSHandler.cfc` is ever called.

**Still in your Terminal tab** — run the following command to create `Application.cfc` in the ColdFusion webroot:

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

The command returns silently — that means it succeeded.

**Verify `Application.cfc` was created with the channel registered:**

```bash
grep -A3 "wschannels" /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

Expected output:

```
    this.wschannels = [
        { name="chat", cfclistener="WSHandler" }
    ];
```

If you see those three lines, the channel is registered. If nothing is returned, the file is missing or the `cat` command did not complete — run it again.

**Force ColdFusion to reload `Application.cfc` now:**

```bash
touch /opt/coldfusion2025/cfusion/wwwroot/Application.cfc && \
curl -s -o /dev/null http://localhost:8500/index.cfm
```

The `touch` updates the file's timestamp — CF detects the change and reinitialises the application on the very next request. The `curl` triggers that request immediately so the channel is live before you open the browser. Without this step, CF may still be running an older cached application with no channels registered.

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

::hint-box
---
:summary: 💡 Open CF Admin in a new window — don't lose your workspace
---

::image-box
---
:src: __static__/open-new-window-v1.png
:alt: Browser showing the CF Admin link being right-clicked with the context menu option Open link in new window highlighted
:max-width: 640px
---
::

When you need to check something in the CF Admin panel, right-click the link and choose **Open in new window** (or **new tab**). Opening it in the same window will navigate away from your current workspace and you will lose your place in the lab.
::

**Step 2** — Create `ws_demo.cfm` with a chat UI:

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

    <script>
        const log    = document.getElementById("chat-log");
        const status = document.getElementById("status");

        // Derive the WebSocket protocol from the page protocol:
        //   https → wss://  (required — browsers block ws:// from HTTPS pages)
        //   http  → ws://
        // Using window.location.host (hostname + port) ensures the connection
        // routes correctly through the lab proxy without hardcoding any address.
        const wsProto = window.location.protocol === "https:" ? "wss://" : "ws://";
        const ws = new WebSocket(wsProto + window.location.host + "/cfusion/WS/chat");

        ws.onopen = function() {
            status.textContent = "Connected";
        };

        ws.onmessage = function(event) {
            const msg = JSON.parse(event.data);
            if (msg.type === "data") {
                log.insertAdjacentHTML("beforeend",
                    `<p><strong>user</strong>: ${msg.data}</p>`);
                log.scrollTop = log.scrollHeight;
            }
        };

        ws.onclose = function() {
            status.textContent = "Disconnected";
        };

        function sendMsg() {
            const input = document.getElementById("msg-input");
            if (!input.value.trim()) return;
            ws.send(JSON.stringify({ type: "publish", channel: "chat", data: input.value }));
            input.value = "";
        }
    </script>
</body>
</html>
EOF
```

**Step 3 — Verify the page loads and the WebSocket port is open**

**Back in your Terminal tab** — run both checks below. Do not run these in the browser address bar.

First confirm the page itself returns HTTP 200:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/ws_demo.cfm
```

Expected output: `200`

Then confirm ColdFusion's WebSocket service is running. In this lab WebSocket connections are handled on port **8500** (same as HTTP) because `startListenerOnNormalPort=true`. Confirm the WebSocket service is active:

```bash
cat /opt/coldfusion2025/cfusion/lib/neo-websocket.xml | grep -A2 "startWebSocketService"
```

Expected output:
```
<var name='startWebSocketService'>
    <boolean value='true'/>
```

If the value is `false`, the WebSocket service is disabled and the browser will show "Connecting…" forever — like this:

::image-box
---
:src: __static__/connecting-v1.png
:alt: Browser screenshot of the WebSocket Chat Demo page showing the status line stuck on Connecting… in grey text, indicating the WebSocket handshake has not completed
:max-width: 640px
---
_Status stuck on "Connecting…" — the WebSocket port is not reachable. Fix it with the restart command below before opening the browser._
::

In that case restart ColdFusion:

```bash
sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart
```

Wait ~20 seconds, then repeat both checks before opening the browser.

Once both ports respond, open `http://localhost:8500/ws_demo.cfm` in the lab browser:

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
The most common cause is a syntax error in `Application.cfc`. Check that the `this.wschannels` line is inside the `component { }` block and that all curly braces are balanced.

> **Note:** You cannot open `Application.cfc` directly in the browser — ColdFusion will always block it with an "Invalid request" error because it is a reserved framework file. To check for syntax errors, trigger any normal request (e.g. `curl http://localhost:8500/index.cfm`) and CF will surface the parse error in the response, or check the CF error log:

```bash
tail -20 /opt/coldfusion2025/cfusion/logs/exception.log
```
::

::hint-box
---
:summary: ⚠️ Still showing "Connecting…" after restarting ColdFusion?
---

A CF restart confirms the server is up but does not by itself fix a broken channel. Work through these checks in order — each one is a separate root cause.

**Check 1 — Confirm the channel name matches exactly**

The channel name passed to `new WebSocket(...)` path (`/cfusion/WS/chat`) must match the `name=` in `this.wschannels`. A mismatch means CF never registers the subscription:

```bash
grep -i "cfusion/WS\|wschannels" \
  /opt/coldfusion2025/cfusion/wwwroot/ws_demo.cfm \
  /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

Both lines must show the same channel name — `chat`. If they differ, edit the file that is wrong and reload the page.

---

**Check 2 — Confirm `Application.cfc` was loaded after it was created**

CF caches the application on the first request. If `Application.cfc` was created *after* a request already hit the app, the old channelless application is still in memory. Force a reload:

```bash
touch /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

Then refresh `ws_demo.cfm` in the browser. If the status changes to **Connected**, this was the cause.

---

**Check 3 — Confirm `WSHandler.cfc` has the required `extends`**

```bash
head -2 /opt/coldfusion2025/cfusion/wwwroot/WSHandler.cfc
```

The second line must read:

```
component extends="CFIDE.websocket.ChannelListener" {
```

If it does not, recreate the file:

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

---

**Check 4 — Clear the compiled class cache and restart**

CF caches compiled CFC classes in `WEB-INF/cfclasses/`. Even with the correct `WSHandler.cfc` on disk, CF may load a stale cached version. Clear it and do a full restart:

```bash
rm -f /opt/coldfusion2025/cfusion/wwwroot/WEB-INF/cfclasses/cfWSHandler* && \
sudo /opt/coldfusion2025/cfusion/bin/coldfusion restart
```

Wait ~20 seconds for CF to come back up, then refresh `ws_demo.cfm`. The status should change to **Connected**.
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
Add a `new WebSocket(...)` JavaScript client to `ws_demo.cfm` connected to the `chat` channel.

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
Check that `ws_push_test.cfm` returned `Published` (not a CF error). If it did but the message still didn't appear, open the browser DevTools console — look for WebSocket errors or a Mixed Content block (`ws://` on an HTTPS page), and confirm `ws.onmessage` is defined in `ws_demo.cfm`.
::

---

## Key takeaways

| Concept | ColdFusion approach |
|---|---|
| Declare a channel | `this.wschannels = [{name="chat", cfclistener="WSHandler"}]` in `Application.cfc` |
| Handler CFC | Must `extends="CFIDE.websocket.ChannelListener"` — bare `component {}` is rejected |
| Channel struct syntax | Use `name="chat"` (equals), not `"name": "chat"` (colon) |
| Browser client | Derive protocol + host from the page: `wss://` on HTTPS, `ws://` on HTTP — never hardcode |
| Handle incoming messages | `onWSMessage(channel, data, client)` in the handler CFC |
| Broadcast to all subscribers | `wsPublish(channelName, message)` |
| Send to one client | `wsSendMessage(client.clientid, message)` |
| WebSocket port | **8500** in this lab (`startListenerOnNormalPort=true`) — defaults to 8585 in standard CF installs |
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
