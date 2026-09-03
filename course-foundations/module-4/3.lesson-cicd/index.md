---
kind: lesson

title: CI/CD for CFML Applications
description: |
  Build automated pipelines for ColdFusion apps using CommandBox,
  GitHub Actions, and Docker. Package, test, and deploy CFML apps
  without touching a server manually.

name: cicd-cfml-applications
slug: cicd-cfml-applications

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- ci-cd

tagz:
- coldfusion
- commandbox
- docker
- github-actions

playground:
  name: cf-alex-edcdf975

tasks:
  verify_box_json:
    machine: dev-machine
    user: laborant
    run: |
      FILE=$(find /home/laborant /opt/coldfusion2025/cfusion/wwwroot -name "box.json" 2>/dev/null | head -1)
      if [ -z "${FILE}" ]; then
        echo "box.json not found — project not packaged with CommandBox"
        exit 1
      fi
      echo "box.json found at ${FILE}"

  verify_dockerfile:
    machine: dev-machine
    user: laborant
    needs:
      - verify_box_json
    run: |
      FILE=$(find /home/laborant /opt/coldfusion2025/cfusion/wwwroot -name "Dockerfile" 2>/dev/null | head -1)
      if [ -z "${FILE}" ]; then
        echo "Dockerfile not found"
        exit 1
      fi
      echo "Dockerfile found at ${FILE}"

  verify_docker_build:
    machine: dev-machine
    user: laborant
    needs:
      - verify_dockerfile
    run: |
      if ! docker images 2>/dev/null | grep -q "cfml"; then
        echo "No cfml Docker image built yet — run: docker build -t cfml-app ."
        exit 1
      fi
      echo "cfml Docker image exists"
---

## Dockerfile

```dockerfile
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install --production

EXPOSE 8888
CMD ["box", "server", "start", "--console"]
```

## Build and run

```bash
docker build -t cfml-app .
docker run -p 8888:8888 cfml-app
```

## GitHub Actions workflow

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install CommandBox
        run: |
          curl -fsSl https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
          sudo apt-get install commandbox
      - name: Install dependencies
        run: box install
      - name: Run tests
        run: box testbox run
```
