---
kind: unit

title: CI/CD for CFML Applications

name: cicd-cfml-applications-unit-1
---

## What is CI/CD?

**CI (Continuous Integration)** means every code change is automatically tested before it is merged. **CD (Continuous Delivery)** means every passing build is automatically packaged and ready to deploy.

For a ColdFusion application the full pipeline looks like this:

::image-box
---
:src: __static__/cfml-cicd-pipeline-v1.png
:alt: Linear pipeline diagram showing five stages connected by rightward arrows — stage 1 "Git push", stage 2 "CI server triggered", stage 3 "box install + box testbox run" with a red X showing failing tests stop the pipeline, stage 4 "docker build -t cfml-app", stage 5 "push to registry and deploy"
:max-width: 900px
---
_Tests gate the build — a failing TestBox run stops the Docker image from being created._
::

::remark-box
**📌 Scope of this lesson**

Running a complete CI/CD pipeline requires a Git server, a container registry, and a CI runner. That infrastructure is out of scope for this foundations course.

**In this lesson** you will build the two artefacts the pipeline depends on: a `box.json` manifest and a `Dockerfile`. Then you will build a Docker image locally — the same command the pipeline runs.

The full pipeline — Git server, registry, automated tests, and deployments using **Gitea** — is covered in the **ColdFusion Advanced course**.
::

---

## 1. box.json — the project manifest

`box.json` is the CommandBox project manifest. It declares your app name, version, and ForgeBox dependencies — similar to `package.json` in Node.js or `composer.json` in PHP.

```json
{
  "name": "helpdesk-app",
  "version": "1.0.0",
  "dependencies": {
    "testbox": "^5.0.0"
  }
}
```

`box install` reads this file and installs all declared packages into a `modules/` directory. In a CI pipeline the build agent runs `box install` first — this file is the only thing it needs to recreate the full dependency tree on a clean machine.

---

## 2. Dockerfile — containerise your app

::image-box
---
:src: __static__/commandbox-dockerfile-anatomy-v1.png
:alt: Annotated Dockerfile with four callout labels — FROM ortussolutions/commandbox:latest labelled "Official CommandBox base image (Java + Lucee bundled)"; COPY and WORKDIR labelled "Copy project files"; RUN box install --production labelled "Install dependencies, skip dev packages"; EXPOSE 8888 and CMD labelled "Start server in foreground"
:max-width: 760px
---
_The base image handles the runtime — you just copy code and install packages._
::

```dockerfile
FROM ortussolutions/commandbox:latest

COPY . /app
WORKDIR /app

RUN box install --production

EXPOSE 8888
CMD ["box", "server", "start", "--console"]
```

| Line | What it does |
|---|---|
| `FROM ortussolutions/commandbox:latest` | Official CommandBox base — Java + Lucee already bundled |
| `COPY . /app` | Copies your CFML project files into the image |
| `RUN box install --production` | Installs ForgeBox dependencies, skips dev packages like TestBox |
| `EXPOSE 8888` | Documents which port the server listens on |
| `CMD [...]` | Starts the Lucee server in the foreground when the container runs |

::hint-box
---
:summary: 💡 Why not bake credentials into the Dockerfile?
---

A Docker image is a portable artefact — anyone who can pull it can inspect every layer. Credentials baked into the image (datasource passwords, API keys) are exposed to anyone with registry access, and they end up in git history too.

The right pattern is to inject credentials at **runtime** via environment variables. In a CI pipeline, secrets are stored in the CI server (GitHub Actions Secrets, Gitea Secrets) and passed to the container on start — never written into the image.
::

---

## Activity 1 — Create box.json

::remark-box
---
kind: info
---
**Why `/home/laborant/app/` and not `wwwroot/student/`?**

`box.json` and `Dockerfile` are **source code artefacts**, not served files. They belong in a project directory — the kind you would commit to Git and hand to a CI runner. Putting them inside the CF web root (`wwwroot/`) would expose them over HTTP, which is a security risk.

`/home/laborant/app/` is the student's project home — it already exists in the lab environment (it was seeded with the CommandBox `server.json` scaffold when the image was built). In a real project this would be your Git repository root.
::

Create `/home/laborant/app/box.json`:

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

Verify:

```bash
cat /home/laborant/app/box.json
```

::simple-task
---
:tasks: tasks
:name: verify_box_json
---
#active
Create `box.json` in `/home/laborant/app/`.

#completed
`box.json` found. ✓
::

---

## Activity 2 — Create the Dockerfile

Create `/home/laborant/app/Dockerfile`:

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

Verify:

```bash
cat /home/laborant/app/Dockerfile
```

::simple-task
---
:tasks: tasks
:name: verify_dockerfile
---
#active
Create a `Dockerfile` in `/home/laborant/app/`.

#completed
`Dockerfile` found. ✓
::

---

## Activity 3 — Build the Docker image

Build the image tagged `cfml-app`:

```bash
docker build -t cfml-app /home/laborant/app/
```

Confirm it exists:

```bash
docker images | grep cfml
```

::hint-box
---
:summary: 🐢 First build is slow — here is why.
---

Docker pulls the `ortussolutions/commandbox:latest` base image on the first build — roughly 500 MB. Subsequent builds reuse cached layers and complete in seconds. The `RUN box install --production` step is also cached after the first run as long as `box.json` has not changed.
::

::simple-task
---
:tasks: tasks
:name: verify_docker_build
---
#active
Build the Docker image: `docker build -t cfml-app /home/laborant/app/` — must appear in `docker images`.

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
