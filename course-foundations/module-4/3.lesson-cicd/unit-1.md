---
kind: unit

title: CI/CD for CFML Applications

name: cicd-cfml-applications-unit-1
---

## What is CI/CD?

**CI (Continuous Integration)** means every code change is automatically tested before it is merged. **CD (Continuous Delivery)** means every passing build is automatically packaged and ready to deploy — or deployed automatically.

For a ColdFusion application the pipeline looks like this:

::image-box
---
:src: __static__/cfml-cicd-pipeline-v1.png
:alt: Linear pipeline diagram showing five stages connected by rightward arrows — stage 1 "Git push" (dev laptop icon), stage 2 "GitHub Actions triggered" (GitHub logo), stage 3 "box install + box testbox run" (CommandBox logo, green checkmark), stage 4 "docker build -t cfml-app" (Docker whale logo), stage 5 "docker run deployed" (server rack icon) — a red X on stage 3 shows that failing tests stop the pipeline and no image is built
:max-width: 900px
---
_Tests gate the build — a failing TestBox run stops the Docker image from being created._
::

```
Git push
  └─► GitHub Actions
        ├─► box install
        ├─► box testbox run      ← failing tests stop here
        └─► docker build -t cfml-app .
              └─► docker run -p 8888:8888 cfml-app
```

---

## 1. box.json — package your project

`box.json` is the CommandBox project manifest. It declares your app name, version, and ForgeBox dependencies — similar to `package.json` in Node or `composer.json` in PHP.

```json
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "dependencies": {
    "testbox": "^5.0.0"
  }
}
```

`box install` reads this file and installs all declared packages into a `modules/` directory.

::hint-box
---
:summary: 💡 Why does box.json matter for CI/CD?
---

In a CI pipeline the build agent starts with a clean environment — nothing is pre-installed. `box install` is the command that rebuilds your dependency tree from scratch using `box.json` as the source of truth. Without it, the pipeline has no way to know what packages your app needs.

This is the same reason Node projects commit `package.json` and PHP projects commit `composer.json` — the manifest is what makes the build reproducible.
::

---

## 2. Dockerfile — package your app as a container

::image-box
---
:src: __static__/commandbox-dockerfile-anatomy-v1.png
:alt: Annotated Dockerfile showing four lines — FROM ortussolutions/commandbox:latest labelled "Official CommandBox base image (includes Java + Lucee)"; COPY . /app and WORKDIR /app labelled "Copy project files"; RUN box install --production labelled "Install ForgeBox dependencies (no dev packages)"; EXPOSE 8888 and CMD box server start --console labelled "Expose port and start server in foreground" — each label is a callout to its line
:max-width: 760px
---
_The CommandBox Dockerfile is minimal — the base image handles the runtime, you just copy code and install packages._
::

```dockerfile
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install --production

EXPOSE 8888
CMD ["box", "server", "start", "--console"]
```

This image:
1. Uses the official CommandBox base (Java + Lucee bundled)
2. Copies your CFML project into `/app`
3. Installs only production ForgeBox dependencies
4. Starts the Lucee server on port 8888 in the foreground

::hint-box
---
:summary: 💡 Why --production?
---

`box install --production` skips dev-only packages (like TestBox). Your running container does not need a test framework — keeping it out reduces image size and attack surface. Tests run in the CI pipeline, not in the deployed container.
::

---

## 3. GitHub Actions workflow

Push this file to `.github/workflows/ci.yml` and GitHub will run it automatically on every push and pull request:

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
          sudo apt-get update && sudo apt-get install commandbox

      - name: Install dependencies
        run: box install

      - name: Run tests
        run: box testbox run

      - name: Build Docker image
        run: docker build -t cfml-app .
```

::hint-box
---
:summary: 💡 What happens when a test fails?
---

GitHub Actions runs each step in sequence. If `box testbox run` exits with a non-zero code (which TestBox does when tests fail), GitHub Actions stops immediately — the `docker build` step never runs. This is the gate that prevents broken code from being packaged and deployed.

You can see the exact failing test in the Actions log on GitHub — click the red ✗ next to the run.
::

---

## 4. CFConfig — inject config at runtime

Never hard-code datasource credentials in your image. Use CFConfig to inject them at container start-time via environment variables:

```bash
# In your Dockerfile or entrypoint script
box cfconfig set datasourceUsername=$DB_USER \
               datasourcePassword=$DB_PASSWORD \
               datasourceDatabase=training
```

In GitHub Actions, store secrets under **Settings → Secrets and variables → Actions** and reference them as `${{ secrets.DB_PASSWORD }}`.

::hint-box
---
:summary: 💡 Why not just put credentials in the Dockerfile?
---

A Docker image is a portable artefact — it gets pushed to a registry where anyone with access can pull it and inspect every layer. Credentials baked into the image are exposed to anyone who can pull it, and they end up in your git history too.

Environment variables injected at runtime stay out of the image entirely. The container gets the secret only when it starts, and only in memory.
::

---

## Activity 1 — Create box.json

Create a `box.json` file in `/home/laborant/app/` to package the project with CommandBox:

```bash
mkdir -p /home/laborant/app
tee /home/laborant/app/box.json << 'EOF'
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "dependencies": {
    "testbox": "^5.0.0"
  }
}
EOF
```

Verify it exists:

```bash
cat /home/laborant/app/box.json
```

::simple-task
---
:tasks: tasks
:name: verify_box_json
---
#active
Create `box.json` in `/home/laborant/app/` to package the project with CommandBox.

#completed
`box.json` found. ✓
::

---

## Activity 2 — Create the Dockerfile

Create a `Dockerfile` in the same directory using the CommandBox base image:

```bash
tee /home/laborant/app/Dockerfile << 'EOF'
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install --production

EXPOSE 8888
CMD ["box", "server", "start", "--console"]
EOF
```

Verify it exists:

```bash
cat /home/laborant/app/Dockerfile
```

::simple-task
---
:tasks: tasks
:name: verify_dockerfile
---
#active
Create a `Dockerfile` in `/home/laborant/app/` using the CommandBox base image.

#completed
`Dockerfile` found. ✓
::

---

## Activity 3 — Build the Docker image

Build the Docker image tagged `cfml-app`:

```bash
docker build -t cfml-app /home/laborant/app/
```

Confirm the image was created:

```bash
docker images | grep cfml
```

::hint-box
---
:summary: 🐢 Build taking a long time? That is normal on first run.
---

Docker pulls the `ortussolutions/commandbox:latest` base image on the first build — that is roughly 500 MB. Subsequent builds reuse the cached layers and are much faster. The `RUN box install --production` step is also cached after the first run as long as `box.json` does not change.
::

::simple-task
---
:tasks: tasks
:name: verify_docker_build
---
#active
Build the Docker image: `docker build -t cfml-app /home/laborant/app/` — a `cfml` image must appear in `docker images`.

#completed
Docker image built successfully. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete — on to Production Readiness! 🚀
::

::remark-box
Found a bug or an issue with this lesson? Please reach out — your feedback helps improve the course for everyone.

📧 Alex — mercadoalex[at]gmail.com
::
