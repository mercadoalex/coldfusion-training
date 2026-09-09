---
kind: tutorial

title: Dockerise a CFML App and Run a GitHub Actions Pipeline

description: |
  Create a Dockerfile for a CommandBox app, build the image locally,
  then write a GitHub Actions workflow that installs dependencies and runs tests.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- ci-cd

tagz:
- coldfusion
- docker
- github-actions

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Initialise box.json

```bash
cd /home/laborant/app
cat > box.json << 'EOF'
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "dependencies": {
    "testbox": "^5.0.0"
  }
}
EOF
```

### 2. Create the Dockerfile

```bash
cat > /home/laborant/app/Dockerfile << 'EOF'
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install --production

EXPOSE 8888
CMD ["box", "server", "start", "--console"]
EOF
```

### 3. Build the Docker image

```bash
docker build -t cfml-app /home/laborant/app/
```

Verify the image exists:

```bash
docker images | grep cfml
```

### 4. Run the container

```bash
docker run -d -p 8889:8888 --name cfml-test cfml-app
sleep 20
curl -s -o /dev/null -w "%{http_code}" http://localhost:8889/index.cfm
docker stop cfml-test && docker rm cfml-test
```

### 5. Write the GitHub Actions workflow

On your local machine (not in the lab), create `.github/workflows/ci.yml`:

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
          echo "deb https://downloads.ortussolutions.com/debs/noarch /" \
            | sudo tee /etc/apt/sources.list.d/commandbox.list
          sudo apt-get update && sudo apt-get install -y commandbox
      - name: Install dependencies
        run: box install
      - name: Run tests
        run: box testbox run
```
