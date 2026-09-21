# Connect Your Local VS Code to the Playground (Remote-SSH)

> **Optional — Power User Setup**
> The playground has a built-in browser IDE that works for everyone.
> If you find it slow or prefer your own VS Code setup, this guide connects
> your local VS Code directly to the playground VM over SSH.
> Estimated setup time: **10–15 minutes (one-time)**.

---

## What You Get

- Full native VS Code speed — no browser rendering lag
- Your own theme, keybindings, and local extensions
- Real terminal directly on the VM
- File explorer shows `/home/laborant/app/` and CF wwwroot side by side
- Changes you save are served by ColdFusion/Lucee instantly

> **Remember:** playground VMs are ephemeral. Files you create on the VM
> are lost when the session ends. Use the playground for exercises only —
> keep your notes and personal files on your local machine.

---

## Prerequisites

- [VS Code](https://code.visualstudio.com/) installed on your local machine
- The **Remote - SSH** extension (Microsoft) — install it once, use it forever

### Install the Remote - SSH Extension

1. Open VS Code
2. Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (Mac) to open Extensions
3. Search for `Remote - SSH`
4. Click **Install** on the one published by **Microsoft**

After installing, a small green **`><`** icon appears in the very bottom-left
corner of your VS Code window. That's your connection button.

---

## Step 1 — Generate an SSH Key (skip if you already have one)

Open a terminal on your local machine and run:

```bash
ssh-keygen -t ed25519 -C "cf-training"
```

Press Enter three times to accept defaults (no passphrase is fine for training).

This creates two files:
- `~/.ssh/id_ed25519` — your **private key** (never share this)
- `~/.ssh/id_ed25519.pub` — your **public key** (this goes on the server)

---

## Step 2 — Start Your Playground Session

1. Open the course on [iximiuz Labs](https://labs.iximiuz.com)
2. Click **Start Playground** and wait for the VM to boot (~30–60 seconds)
3. Click the **Terminal** tab — you should see the ColdFusion welcome banner

---

## Step 3 — Find the VM's SSH Address

In the **Terminal** tab of your playground, run:

```bash
hostname -I | awk '{print $1}'
```

This prints the VM's IP address. Copy it — you'll need it in the next step.

> **Tip:** iximiuz may also show an SSH connection string directly in the
> playground UI. Look for a "Connect via SSH" or similar button near the
> playground header.

---

## Step 4 — Add the VM to Your SSH Config

On your **local machine**, open (or create) `~/.ssh/config` in any text editor
and add these lines — replacing `<VM-IP>` with the address from Step 3:

```
Host cf-training
    HostName     <VM-IP>
    User         laborant
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

Save the file. You only need to update `HostName` each time you start a new
playground session — everything else stays the same.

---

## Step 5 — Copy Your Public Key to the VM

In the **Terminal** tab of your playground, run the following command — replacing
the key content with your own (get it by running `cat ~/.ssh/id_ed25519.pub`
in your local terminal):

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA...your-public-key-here... cf-training" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

---

## Step 6 — Connect from VS Code

1. Click the green **`><`** button in the bottom-left corner of VS Code
2. Select **Connect to Host…**
3. Pick **`cf-training`** from the dropdown (the name you set in Step 4)
4. A new VS Code window opens — the bottom-left changes to **`>< SSH: cf-training`**

That's it. You're in.

---

## Step 7 — Open the Course Workspace

Once connected, open the course workspace file so the Explorer shows the right folders:

1. Press `Ctrl+K Ctrl+O` (or `File → Open Folder`)
2. Navigate to `/home/laborant/app`
3. Click **OK**

The Explorer now shows your student app folder. The integrated terminal opens
directly in `/home/laborant/app` and runs on the VM.

---

## Every New Session (30 seconds)

When you start a new playground session the VM IP changes. The one-time setup
(SSH key, extension) never needs repeating. You only need to:

1. Start the playground, wait for boot
2. Get the new IP: `hostname -I | awk '{print $1}'`
3. Update `HostName` in `~/.ssh/config`
4. Click `><` → **Connect to Host** → `cf-training`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `Permission denied (publickey)` | Your public key wasn't added to the VM. Redo Step 5. |
| `Connection timed out` | VM IP changed. Get the new IP (Step 3) and update `~/.ssh/config`. |
| VS Code hangs on "Setting up SSH Host" | First connect downloads `vscode-server` (~60 MB). Wait ~30s on first connect. |
| Terminal shows wrong folder | Run `cd ~/app` or re-open the folder via `File → Open Folder`. |
| Session disconnects during lesson | `ServerAliveInterval 30` in your config keeps it alive. If it still drops, the VM session may have hit the 8-hour limit. |
