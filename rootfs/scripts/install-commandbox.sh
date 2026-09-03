#!/usr/bin/env bash
# =============================================================================
# install-commandbox.sh
# Installs CommandBox CLI via the official Ortus APT repository (Ubuntu/Debian).
# Pre-bakes a Lucee 5 server configuration for the student app at ~/app/
# =============================================================================
set -euo pipefail

CB_VERSION="${COMMANDBOX_VERSION:-6.3.4}"
CB_HOME="${COMMANDBOX_HOME:-/opt/commandbox}"
LUCEE_VERSION="${LUCEE_VERSION:-7.0.4.34}"
APP_DIR="/home/${LAB_USER:-laborant}/app"

# ─── Java check ──────────────────────────────────────────────────────────────
# CF's bundled JRE is at /opt/coldfusion2025/jre (on PATH via Dockerfile ENV).
if ! command -v java >/dev/null 2>&1; then
  echo "[BOX] WARNING: java not found on PATH. Will proceed anyway."
fi

# ─── Install CommandBox via Ortus APT repo ───────────────────────────────────
echo "[BOX] Installing CommandBox via APT..."

# 1. Add Ortus GPG key
curl -fsSL https://downloads.ortussolutions.com/debs/gpg \
  | gpg --dearmor -o /usr/share/keyrings/ortus-commandbox.gpg

# 2. Add the stable APT source
echo "deb [signed-by=/usr/share/keyrings/ortus-commandbox.gpg] \
https://downloads.ortussolutions.com/debs/noarch /" \
  > /etc/apt/sources.list.d/commandbox.list

# 3. Install
apt-get update -qq
apt-get install -y commandbox
apt-get clean
rm -rf /var/lib/apt/lists/*

# 4. Verify
box version || { echo "[BOX] ERROR: box CLI not functional"; exit 1; }
echo "[BOX] CommandBox installed: $(box version 2>/dev/null)"

# ─── Pre-bake the student app scaffold ───────────────────────────────────────
echo "[BOX] Creating student app scaffold at ${APP_DIR}..."
mkdir -p "${APP_DIR}"

cat > "${APP_DIR}/.box.json" <<EOF
{
  "name": "cf-training-app",
  "version": "1.0.0",
  "description": "ColdFusion Training Starter App",
  "cfengine": "lucee@${LUCEE_VERSION}"
}
EOF

cat > "${APP_DIR}/server.json" <<EOF
{
  "name": "training-app",
  "app": {
    "cfengine": "lucee@${LUCEE_VERSION}",
    "webroot": "."
  },
  "web": {
    "http": {
      "port": 8888,
      "enable": true
    },
    "host": "0.0.0.0",
    "ssl": {
      "enable": false
    }
  },
  "jvm": {
    "heapSize": "256m",
    "minHeapSize": "128m"
  },
  "openbrowser": false
}
EOF

# ─── Pre-bake Lucee engine cache ─────────────────────────────────────────────
# If lucee-engine-${LUCEE_VERSION}.zip is present in /tmp/cf-downloads/ (copied
# from downloads/ in the build context), we manually place it into the
# CommandBox engine cache so students get instant first-start with no download.
#
# Cache path: /root/.CommandBox/engine/cfml/server/lucee_<version>/
#             CommandBox looks for cf-engine-<version>.zip here on startup.
LUCEE_ZIP="/tmp/cf-downloads/lucee-engine-${LUCEE_VERSION}.zip"
CB_ENGINE_CACHE="/root/.CommandBox/engine/cfml/server/lucee_${LUCEE_VERSION}"

if [ -f "${LUCEE_ZIP}" ]; then
  echo "[BOX] Pre-baking Lucee ${LUCEE_VERSION} engine cache from local ZIP..."
  mkdir -p "${CB_ENGINE_CACHE}"
  cp "${LUCEE_ZIP}" "${CB_ENGINE_CACHE}/cf-engine-${LUCEE_VERSION}.zip"
  echo "[BOX] Lucee engine cached at ${CB_ENGINE_CACHE}"
else
  echo "[BOX] NOTE: lucee-engine-${LUCEE_VERSION}.zip not found in downloads/."
  echo "[BOX] Lucee will download on first 'box server start' inside the VM (~30s)."
  echo "[BOX] To pre-bake: curl -L -o downloads/lucee-engine-${LUCEE_VERSION}.zip \\"
  echo "[BOX]   https://downloads.ortussolutions.com/lucee/lucee/${LUCEE_VERSION}/cf-engine-${LUCEE_VERSION}.zip"
fi

# ─── PATH entry for all users ────────────────────────────────────────────────
cat > /etc/profile.d/commandbox.sh <<'PROFILE'
# CommandBox CLI — added by cf-training rootfs
export PATH="$PATH:/usr/bin"
PROFILE

# ─── Pre-create runtime directories so chown in Dockerfile Layer 9 covers them ──
# laborant user does not exist yet at this build stage — chown happens later.
# We just ensure the directories exist so box can write into them at runtime.
mkdir -p \
  "${CB_HOME}/engine/cfml/cli/lucee-server" \
  "${CB_HOME}/engine/cfml/cli/cfml-web" \
  "${CB_HOME}/logs" \
  "${CB_HOME}/temp" \
  "${CB_HOME}/servers"

echo "[BOX] CommandBox installation complete."
