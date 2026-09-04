---
kind: lesson

title: Deploying to cf-prod — Multi-VM Workflow
description: |
  Use the three-VM advanced environment to practise a real deployment workflow:
  build on cf-dev, promote artifacts to cf-prod over SSH, and verify the
  production server is serving the updated application.

name: multi-vm-deployment-cf-prod
slug: multi-vm-deployment-cf-prod

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- ci-cd

tagz:
- coldfusion
- deployment
- ssh
- production

playground:
  name: cf-training-advanced-7442b9e0

tasks:
  verify_ssh_to_prod:
    machine: cf-dev
    user: laborant
    run: |
      if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
               laborant@cf-prod "echo ok" 2>/dev/null; then
        echo "Cannot SSH from cf-dev to cf-prod — check SSH key setup"
        exit 1
      fi
      echo "SSH from cf-dev → cf-prod works ✓"

  verify_cf_prod_running:
    machine: cf-prod
    user: laborant
    needs:
      - verify_ssh_to_prod
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/index.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "ColdFusion on cf-prod is not responding (HTTP ${STATUS})"
        exit 1
      fi
      echo "ColdFusion on cf-prod is running ✓"

  verify_deploy_script:
    machine: cf-dev
    user: laborant
    needs:
      - verify_cf_prod_running
    run: |
      if [ ! -f "/home/laborant/deploy.sh" ]; then
        echo "deploy.sh not found at /home/laborant/deploy.sh"
        exit 1
      fi
      if ! grep -q "cf-prod" /home/laborant/deploy.sh; then
        echo "deploy.sh does not reference cf-prod"
        exit 1
      fi
      echo "deploy.sh exists and references cf-prod ✓"

  verify_deployed_file:
    machine: cf-prod
    user: laborant
    needs:
      - verify_deploy_script
    run: |
      if [ ! -f "/opt/coldfusion2025/cfusion/wwwroot/deploy_marker.txt" ]; then
        echo "deploy_marker.txt not found on cf-prod — run deploy.sh first"
        exit 1
      fi
      echo "Deployment marker present on cf-prod ✓"
---

## Overview

Your environment has two ColdFusion VMs on the same private network:

| VM | Role | Hostname |
|---|---|---|
| `cf-dev` | Development — you write code here | `cf-dev` |
| `cf-prod` | Production target — receives deployments | `cf-prod` |

The goal of this lesson is to establish a repeatable deployment workflow:
write on `cf-dev` → test → push to `cf-prod` via `rsync` over SSH.

---

## 1. Set up SSH key-based access

Run this once on **cf-dev**:

```bash
# Generate a key pair (accept defaults)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Copy the public key to cf-prod
ssh-copy-id -i ~/.ssh/id_ed25519.pub laborant@cf-prod

# Test it
ssh laborant@cf-prod "echo SSH works"
```

---

## 2. Write a deployment script

Create `/home/laborant/deploy.sh` on **cf-dev**:

```bash
#!/bin/bash
set -euo pipefail

WWWROOT="/opt/coldfusion2025/cfusion/wwwroot"
PROD_HOST="cf-prod"
PROD_USER="laborant"

echo "[deploy] Syncing wwwroot to ${PROD_HOST}..."
rsync -avz --delete \
  --exclude="*.log" \
  --exclude=".git" \
  "${WWWROOT}/" \
  "${PROD_USER}@${PROD_HOST}:${WWWROOT}/"

# Drop a timestamp marker so we can verify the push
ssh "${PROD_USER}@${PROD_HOST}" \
  "echo 'deployed at $(date -u +%Y-%m-%dT%H:%M:%SZ)' \
   > ${WWWROOT}/deploy_marker.txt"

echo "[deploy] Done. Verifying prod..."
curl -sf http://${PROD_HOST}:8500/index.cfm > /dev/null && echo "[deploy] cf-prod responded OK"
```

```bash
chmod +x ~/deploy.sh
~/deploy.sh
```

---

## 3. Verify the deployment

From **cf-dev**:

```bash
# Check the marker landed on cf-prod
ssh laborant@cf-prod "cat /opt/coldfusion2025/cfusion/wwwroot/deploy_marker.txt"

# Curl cf-prod directly
curl -s http://cf-prod:8500/index.cfm | head -5
```

From the **Terminal (prod)** tab:

```bash
# Confirm wwwroot contents match cf-dev
ls /opt/coldfusion2025/cfusion/wwwroot/
cat /opt/coldfusion2025/cfusion/wwwroot/deploy_marker.txt
```

---

## 4. Blue/green variant

For zero-downtime, maintain two wwwroot directories and swap a symlink:

```bash
# On cf-prod — initial setup
sudo ln -sfn /opt/coldfusion2025/cfusion/wwwroot-blue \
             /opt/coldfusion2025/cfusion/wwwroot

# Deploy to inactive slot
rsync -avz "${WWWROOT}/" laborant@cf-prod:/opt/coldfusion2025/cfusion/wwwroot-green/

# Swap (atomic)
ssh laborant@cf-prod \
  "sudo ln -sfn /opt/coldfusion2025/cfusion/wwwroot-green \
                /opt/coldfusion2025/cfusion/wwwroot"
```

---

## Key takeaways

| Concept | Tool/command |
|---|---|
| Passwordless SSH | `ssh-keygen` + `ssh-copy-id` |
| File sync | `rsync -avz --delete` |
| Verify deployment | `curl -sf http://cf-prod:8500/` |
| Zero-downtime swap | symlink blue/green swap |
| Deployment marker | write a `deploy_marker.txt` with timestamp |
