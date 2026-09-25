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

        // Derive protocol and host from the page — works on HTTP and HTTPS,
        // through any reverse proxy, without hardcoding any address or port.
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
