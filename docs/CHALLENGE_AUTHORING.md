# iximiuz Labs — Challenge Authoring Rules

Lessons learned the hard way. Follow these rules exactly or the challenge will
show "Couldn't load the challenge" on the platform.

---

## 1. Directory structure

```
challenges/
  <challenge-name>/
    index.md        ← single file, contains EVERYTHING
```

There is no `unit-1.md` for challenges. One file only.

---

## 2. `index.md` structure

The file has two sections separated by the closing `---`:

```
[frontmatter]
---
[body content]
```

### Frontmatter

```yaml
---
kind: challenge

title: 'Your Challenge Title'

description: |
  One paragraph description shown in the challenge card.

categories:
  - programming

tagz:
  - coldfusion
  - cfml

difficulty: easy   # easy | medium | hard

createdAt: 2026-09-03
updatedAt: 2026-09-03

playground:
  name: cf-alex-edcdf975   # exact playground name from labctl playground list

tasks:
  task_name_1:
    machine: dev-machine
    user: laborant
    run: |
      # bash script that exits 0 on success, 1 on failure
      echo "ok"

  task_name_2:
    machine: dev-machine
    user: laborant
    needs:
      - task_name_1
    run: |
      echo "ok"
---
```

**Critical rules:**
- NO `name:` field in the frontmatter — the platform assigns the name/slug at
  creation time. Adding `name:` causes issues.
- `playground.name` must exactly match the playground slug from
  `labctl playground list`
- Task names must be valid identifiers (lowercase, underscores, no hyphens)
- `needs:` creates a dependency chain — a task only runs after its dependency passes

### Body content

The body is the student-facing challenge page. It **must** contain
`::simple-task` blocks wired to each task in the frontmatter — without them
the platform shows "Couldn't load the challenge".

```markdown
## Your challenge title

Explanation of what the student needs to do.

### Step 1 — Do something

Instructions here.

::simple-task
---
:tasks: tasks
:name: task_name_1
---
#active
Waiting for task_name_1 to pass...

#completed
Task 1 complete. ✓
::

::simple-task
---
:tasks: tasks
:name: task_name_2
---
#active
Waiting for task_name_2 to pass...

#completed
Task 2 complete. ✓
::
```

**Every task in the frontmatter must have a matching `::simple-task` in the body.**

---

## 3. Creating and pushing a challenge

### Step 1 — Create on the platform (first time only)

```bash
labctl content create challenge <local-name> -d challenges/<local-name> --no-open -q
```

This prints the platform-assigned slug, e.g. `my-challenge-a1b2c3d4`.
**Save this slug** — you need it everywhere.

### Step 2 — Push content

```bash
labctl content push -f challenge <platform-slug> -d challenges/<local-name>
```

### Step 3 — Wire the challenge into the lesson

In the lesson `index.md`, add under the frontmatter:

```yaml
challenges:
  <platform-slug>: {}
```

In the lesson `unit-1.md`, add at the very end:

```markdown
::card
---
:challenge: challenges.<platform-slug>
---
::
```

### Step 4 — Push the course

```bash
labctl content push -f course <course-slug> -d course-foundations
```

**Both the challenge AND the course must be pushed** — pushing only one is not enough.

---

## 4. Linking from a lesson — `::card` syntax

The `::card` block in `unit-1.md` is what embeds the challenge card at the
bottom of the lesson. The exact syntax is:

```markdown
::card
---
:challenge: challenges.<platform-slug>
---
::
```

- Use `challenges.` prefix for challenges
- Use `tutorials.` prefix for tutorials
- The slug must exactly match what the platform assigned

---

## 5. Common errors and fixes

| Error | Cause | Fix |
|---|---|---|
| "Couldn't load the challenge" | No `::simple-task` blocks in body | Add a `::simple-task` for every task |
| "Couldn't load the challenge" | Wrong slug in `::card` | Check slug with `labctl content list` |
| Challenge loads but tasks don't run | `needs:` chain broken | Verify task names match exactly |
| Challenge not visible in lesson | Course not pushed after index.md change | Run `labctl content push -f course ...` |
| `labctl: Couldn't get content: not found` | Pushing before creating | Run `labctl content create` first |

---

## 6. Checking existing slugs

```bash
# List all your challenges
labctl content list | grep -A3 "kind: challenge"

# List all tutorials
labctl content list | grep -A3 "pageUrl.*tutorials"

# Pull what the platform actually has for a slug
labctl content pull challenge <slug> -d /tmp/check-pull
```

---

## 7. Full working example

See `challenges/multimedia/index.md` — this is a tested, working challenge
linked from `course-foundations/module-1/7.lesson-multimedia/`.

Platform slug: `multimedia-2ed52176`
Lesson index: `course-foundations/module-1/7.lesson-multimedia/index.md`
Lesson unit: `course-foundations/module-1/7.lesson-multimedia/unit-1.md`

---

## 8. Slugs reference

### Challenges

| Local directory | Platform slug |
|---|---|
| `challenges/multimedia` | `multimedia-2ed52176` |

### Course

| Course | Platform slug |
|---|---|
| ColdFusion 2025: Foundations | `ColdFusion-2025-Foundations-5151cba6` |
| ColdFusion 2025: Production & AI | `ColdFusion-2025-Production-and-AI-6124d4b3` |
