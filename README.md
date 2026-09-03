# ColdFusion Training — iximiuz Labs Rootfs

Custom OCI rootfs image for running an interactive ColdFusion training course on
[iximiuz Labs](https://labs.iximiuz.com). Boots as a microVM (not a container),
so students get a real Linux VM with ColdFusion and Lucee pre-installed — no
local setup required.

## What's Inside

| Component | Details |
|---|---|
| **Base OS** | Rocky Linux 9 (matches iximiuz microVM kernel ABI) |
| **ColdFusion 2025** | Developer Edition, pre-installed at `/opt/coldfusion2025`, port **8500** |
| **CommandBox + Lucee 5** | `box` CLI on PATH, Lucee dev server on port **8888** |
| **Init system** | systemd (PID 1), serial console on `ttyS0` |
| **Online IDE** | code-server (VS Code) with CFML syntax extension |
| **Datasources** | H2 embedded (`training_db`) + MySQL stub (`mysql_demo`) |
| **Task engine** | iximiuz `examiner` daemon for playground tasks |

## Repository Layout

```
.
├── Makefile                        # Build, push, local test targets
├── playground/
│   └── playground.yaml             # iximiuz playground manifest (edit registry URL)
└── rootfs/
    ├── Dockerfile                  # Multi-layer rootfs image
    ├── cf-config/
    │   ├── silent-install.properties   # CF silent installer config
    │   ├── instances.xml               # CF instance: port 8500, lean JVM args
    │   ├── neo-security.xml            # Admin creds: admin / training
    │   └── neo-datasource.xml          # Pre-configured datasources
    ├── app/
    │   ├── index.cfm               # CommandBox/Lucee starter app
    │   └── wwwroot/
    │       ├── index.cfm           # CF 2025 starter page (shows CF version, links)
    │       ├── api-test.cfm        # JSON endpoint demo
    │       └── db-test.cfm         # H2 datasource connectivity test
    ├── rootfs/
    │   └── welcome                 # Terminal welcome banner
    └── scripts/
        ├── install-coldfusion.sh       # CF silent install (real or stub)
        ├── install-commandbox.sh       # CommandBox + Lucee pre-bake
        ├── cf-server.service           # systemd unit: ColdFusion
        ├── lucee-server.service        # systemd unit: Lucee/CommandBox
        ├── cf-readiness-probe.service  # systemd unit: waits for ports 8500+8888
        ├── cf-readiness-probe.sh       # Readiness probe script
        ├── set-up-systemd-examiner-service.sh
        ├── add-lab-user.sh             # Creates user 'laborant' (uid 1001)
        ├── get-arkade.sh
        ├── get-common-tools.sh         # jq, yq, task, just
        ├── get-btop.sh
        ├── get-cfssl.sh
        ├── get-websocat.sh
        ├── get-code-server.sh
        ├── get-fzf.sh
        ├── customize-bashrc.sh         # Adds cf-* aliases to .bashrc
        ├── customize-git.sh
        └── customize-vimrc.sh
```

## Prerequisites

- Docker (BuildKit enabled — `DOCKER_BUILDKIT=1`)
- An OCI registry you can push to (e.g. [GitHub Container Registry](https://ghcr.io),
  Docker Hub, or your own)
- Adobe ColdFusion 2025 Developer Edition installer binary
  (`ColdFusion_2025_linux64.bin`) — see [Download Instructions](#download-cf-installer)

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/<your-org>/coldfusion_training.git
cd coldfusion_training
```

Set your registry (once, or export in your shell):

```bash
export REGISTRY=ghcr.io/<your-github-username>
```

### 2. Download the ColdFusion installer

```bash
make downloads   # prints instructions
```

Place the binary at `downloads/ColdFusion_2025_linux64.bin`.

> **Tip:** Adobe offers ColdFusion 2025 Developer Edition for free at
> https://www.adobe.com/products/coldfusion-family.html (no license key needed).

### 3. Build the image

```bash
# With real CF installer (production)
make build-with-cf REGISTRY=ghcr.io/<you>

# Without CF installer (stub mode — for CI / layout testing)
make build REGISTRY=ghcr.io/<you>
```

### 4. Push to your registry

```bash
make push REGISTRY=ghcr.io/<you>
```

### 5. Update playground.yaml

```bash
make update-playground REGISTRY=ghcr.io/<you>
# — or edit playground/playground.yaml manually:
#   rootfs: oci://ghcr.io/<you>/cf-training:v1
```

### 6. Publish on iximiuz Labs

Follow the [Content Authoring guide](https://labs.iximiuz.com/docs/content-authoring/how-to-publish-content)
to upload your course content referencing this playground.

---

## iximiuz OCI Rootfs Requirements

This image satisfies all platform requirements:

| Requirement | How it's met |
|---|---|
| Boots as a microVM (not a container) | systemd as PID 1, `udev`, `kmod` installed |
| Serial console (`ttyS0`) | `getty@ttyS0.service` symlinked in `getty.target.wants` |
| Valid OCI image | Standard `docker build` → pushed via `docker push` |
| `amd64` / `linux` | Rocky Linux 9 x86_64; `LABEL architecture=amd64` |
| Kernel-compatible userspace | Rocky Linux 9 glibc matches iximiuz microVM kernel |
| SSH access | `openssh-server` enabled, host keys generated at first VM boot |
| iximiuz task engine | `examiner` binary installed, `examiner.service` enabled |

---

## Service Details

### ColdFusion 2025 (`cf-server.service`)

- **Install path:** `/opt/coldfusion2025/`
- **HTTP port:** `8500` (exposed as *ColdFusion 2025* tab in playground UI)
- **Admin URL:** `http://<vm>:8500/CFIDE/administrator/`
- **Admin credentials:** `admin` / `training`
- **JVM args:** `-Xms256m -Xmx512m -XX:+UseG1GC` (lean footprint for microVMs)
- **Startup time:** ~30–60 s on first cold JVM boot; faster on subsequent starts

### Lucee / CommandBox (`lucee-server.service`)

- **HTTP port:** `8888` (exposed as *Lucee Dev Server* tab)
- **App root:** `/home/laborant/app/`
- **Started via:** `box server start` (CommandBox manages the Lucee WAR)
- **Engine:** Lucee 5.4.x (pre-baked into CommandBox module cache)

### Readiness Probe (`cf-readiness-probe.service`)

A one-shot systemd unit that polls ports 8500 and 8888 with `nc`, writes
`/run/cf-training-ready` when both are up, and exits. The playground's init
task (`wait_for_cf`) tests for this file before unlocking the student UI.

---

## CF Admin Credentials

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `training` |

These are pre-set in [`cf-config/neo-security.xml`](rootfs/cf-config/neo-security.xml).
Change them before running a public-facing course.

---

## Customising the Image

### Add a new starter exercise

Place `.cfm` files in `rootfs/app/wwwroot/` — they'll be served by CF 2025 at
`http://<vm>:8500/<file>.cfm`.

Place `.cfm` files in `rootfs/app/` — they'll be served by Lucee at
`http://<vm>:8888/<file>.cfm`.

### Change JVM heap size

Edit `instances.xml`:

```xml
<jvmargs>-server -Xms512m -Xmx1g -XX:+UseG1GC</jvmargs>
```

Then bump `ramSize` in `playground.yaml` accordingly.

### Add a MySQL machine

Add a second machine to `playground.yaml`:

```yaml
machines:
  - name: cf-server
    rootfs: oci://ghcr.io/<you>/cf-training:v1
    ...
  - name: db-server
    rootfs: oci://ghcr.io/iximiuz/labs/rootfs:ubuntu-24-04
    ...
```

Then update `neo-datasource.xml` to point `mysql_demo` at `db-server:3306`.

---

## Download CF Installer

Adobe ColdFusion 2025 Developer Edition is **free** (no license key, no expiry,
limited to 2 CPUs and 2 instances — perfect for training):

1. Go to https://www.adobe.com/products/coldfusion-family.html
2. Click **Download free trial** → select **ColdFusion 2025 Developer Edition**
3. Choose the **Linux 64-bit** binary installer
4. Place it at `downloads/ColdFusion_2025_linux64.bin`

> The file is ~900 MB. Add `downloads/` to `.gitignore` (already done) — do
> not commit it to the repository.

---

## Contributing

PRs welcome. Please test with `make build` (stub mode) before submitting.
For changes to CF configuration, test with the real installer via `make build-with-cf`.



## About Iximiuz Labs
Practice on real servers, solve challenges, and follow guided Linux, Docker, Kubernetes, and Networking learning paths — all from your browser or via SSH.

https://github.com/iximiuz

https://labs.iximiuz.com/docs


