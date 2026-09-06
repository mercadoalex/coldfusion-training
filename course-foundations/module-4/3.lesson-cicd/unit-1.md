---
kind: unit

title: CI/CD for CFML Applications

name: cicd-cfml-applications-unit-1
---

## The CI/CD pipeline

The goal: push code → tests run automatically → a Docker image is built → the image is deployed. No manual SSH required.

```
Git push
  └─► GitHub Actions
        ├─► box install
        ├─► box testbox run
        └─► docker build -t cfml-app .
              └─► docker run -p 8888:8888 cfml-app
```

---

## 1. Dockerfile

Use the official CommandBox image as the base:

```dockerfile
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install --production

EXPOSE 8888
CMD ["box", "server", "start", "--console"]
```

This image:
1. Copies your CFML project into `/app`
2. Installs ForgeBox dependencies
3. Starts the Lucee server on port 8888 in the foreground

---

## 2. Build and run locally

```bash
docker build -t cfml-app .
docker run -p 8888:8888 cfml-app
```

Test it:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm
```

The task checks that a Docker image named `cfml` exists: `docker images | grep cfml`.

---

## 3. GitHub Actions workflow

```yaml
# .github/workflows/ci.yml
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
          sudo apt-get update && sudo apt-get install commandbox

      - name: Install dependencies
        run: box install

      - name: Run tests
        run: box testbox run
```

Push this file to `.github/workflows/ci.yml` and GitHub will run it on every push.

---

## 4. box.json — declare dependencies

```json
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "dependencies": {
    "testbox": "^5.0.0"
  }
}
```

`box install` reads this file and installs all declared packages.

---

## 5. CFConfig for environment config

Use CFConfig to inject datasource settings at container start-time (no hard-coded credentials in your image):

```bash
# In your Dockerfile or entrypoint
box cfconfig set datasourceUsername=training_db_user \
               datasourcePassword=$DB_PASSWORD \
               datasourceDatabase=training
```

---

## Exercises

1. Create `box.json` in `/home/laborant/app/` or `/opt/coldfusion2025/cfusion/wwwroot/`.
2. Create a `Dockerfile` in the same directory (it doesn't need to build successfully — the task just checks it exists).
3. Build a Docker image tagged `cfml-app`:

```bash
docker build -t cfml-app /home/laborant/app/
# or
docker build -t cfml-app /opt/coldfusion2025/cfusion/wwwroot/
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_box_json
---
#active
Create `box.json` in the app directory to package the project with CommandBox.

#completed
`box.json` found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_dockerfile
---
#active
Create a `Dockerfile` in the same directory using the CommandBox base image.

#completed
`Dockerfile` found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_docker_build
---
#active
Build the Docker image: `docker build -t cfml-app .` — a `cfml` image must appear in `docker images`.

#completed
Docker image exists. ✓
::
