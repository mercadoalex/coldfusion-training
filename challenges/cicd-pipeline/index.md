---
kind: challenge

title: Dockerised CFML App

description: |
  Create box.json and a Dockerfile in the app directory, then build
  a Docker image tagged "cfml-app". The image must appear in docker images output.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- ci-cd

tagz:
- coldfusion
- docker

playground:
  name: cf-alex-edcdf975

tasks:
  verify_box_json:
    machine: dev-machine
    user: laborant
    run: |
      FILE=$(find /home/laborant /opt/coldfusion2025/cfusion/wwwroot \
        -name "box.json" 2>/dev/null | head -1)
      if [ -z "${FILE}" ]; then
        echo "box.json not found"
        exit 1
      fi
      echo "box.json found at ${FILE}"

  verify_dockerfile:
    machine: dev-machine
    user: laborant
    needs:
      - verify_box_json
    run: |
      FILE=$(find /home/laborant /opt/coldfusion2025/cfusion/wwwroot \
        -name "Dockerfile" 2>/dev/null | head -1)
      if [ -z "${FILE}" ]; then
        echo "Dockerfile not found"
        exit 1
      fi
      echo "Dockerfile found at ${FILE}"

  verify_docker_image:
    machine: dev-machine
    user: laborant
    needs:
      - verify_dockerfile
    run: |
      if ! docker images 2>/dev/null | grep -q "cfml"; then
        echo "No cfml Docker image found — run: docker build -t cfml-app ."
        exit 1
      fi
      echo "cfml Docker image exists"
---

## Your mission

1. Create `box.json` in `/home/laborant/app/`:

```json
{"name":"helpdesk-app","version":"1.0.0"}
```

2. Create `Dockerfile` in the same directory:

```dockerfile
FROM ortussolutions/commandbox:latest
COPY . /app
WORKDIR /app
EXPOSE 8888
CMD ["box", "server", "start", "--console"]
```

3. Build the image:

```bash
docker build -t cfml-app /home/laborant/app/
docker images | grep cfml
```
