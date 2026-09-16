---
kind: unit

title: Testing & Debugging CFML

name: testing-debugging-cfml-unit-1
---

## Why testing and debugging matter

Writing code that works once in a happy path is easy. Writing code that keeps working as requirements change, that fails clearly when something is wrong, and that you can fix quickly when it breaks — that requires two disciplines: **debugging** and **testing**.

**Debugging** is how you understand what your code is actually doing right now. ColdFusion gives you `cfdump`, `cflog`, and the CF Admin debugger — tools that let you inspect any variable, trace execution, and read structured log entries without touching production.

**Testing** is how you prove your code does what it should — and keep proving it every time you change something. ColdFusion's testing ecosystem is built around **TestBox**, the standard BDD/TDD framework for CFML.

In this lesson you will:
1. Use `cfdump` to inspect live data structures in the browser
2. Write structured log entries with `cflog` and read them from the terminal
3. Install TestBox and write a test spec against the `TicketService` already running in your lab
4. Run the test suite and verify it passes

> **Who does this?** Debugging tools are used by every developer daily. Unit testing is a developer responsibility — not something reserved for QA. In a well-run team, tests live alongside the code and run on every commit.

---

## 1. Debugging with cfdump

`cfdump` renders any ColdFusion variable as a colour-coded HTML table — the fastest way to inspect data during development.

```cfml
<cfset data = {name: "Alex", scores: [95, 87, 72]}>
<cfdump var="#data#" label="Student data">
```

::image-box
---
:src: __static__/cfdump-output-example-v1.png
:alt: Example cfdump HTML output — a colour-coded nested table labelled Student data at the top; outer row shows type struct with key name value Alex type string and key scores type array; the array expands to show three numeric cells 95 87 72 — styled with the classic ColdFusion blue header bar and alternating white and grey rows
:max-width: 640px
---
_`cfdump` renders any CF variable as a colour-coded interactive table — the fastest debugging tool in CFML._
::

Useful `cfdump` attributes:

| Attribute | Purpose |
|---|---|
| `var` | Variable to dump (required) |
| `label` | Heading above the dump |
| `top` | Limit depth of nested structures — prevents huge dumps |
| `output` | `"browser"` (default) renders HTML; `"console"` writes to the CF console log |

::hint-box
---
:summary: 💡 Never leave cfdump in production code
---
`cfdump` outputs HTML directly into the response — if a `cfdump` call is left in a JSON API endpoint it will corrupt the response. Use it only during development, and always remove it before committing. A `grep -r "cfdump" /opt/coldfusion2025/cfusion/wwwroot/` before a deploy is a good habit.
::

---

## 2. Logging with cflog

`cflog` writes structured entries to a named log file in CF's log directory — visible in the terminal without touching the browser.

```cfml
<cflog file="myapp" text="Processing ticket #url.id#" type="information">
<cflog file="myapp" text="Ticket not found: #url.id#" type="warning">
<cflog file="myapp" text="DB error: #cfcatch.message#" type="error">
```

Log types: `information`, `warning`, `error`, `fatal`.

Tail the log live in the terminal:

```bash
tail -f /opt/coldfusion2025/cfusion/logs/myapp.log
```

The log format includes a timestamp, thread ID, severity, and your message — structured and grep-friendly.

::hint-box
---
:summary: 💡 cflog vs cfdump — when to use which
---
- **`cfdump`** — use during active development when you want to see a variable's full structure immediately in the browser. Remove before committing.
- **`cflog`** — use for persistent, structured audit trails: recording who did what, catching errors in background tasks, tracing slow queries. Leave it in production code — it writes to a file, not the response.
::

---

## 3. TestBox — unit testing for CFML

TestBox is the standard BDD/TDD testing framework for CFML. It runs on CommandBox (Lucee, port 8888) and lets you write readable test specs that describe expected behaviour.

::image-box
---
:src: __static__/testbox-bdd-spec-structure-v1.png
:alt: Annotated CFML code snippet of a TestBox BDD spec — the component extends testbox.system.BaseSpec line is labelled Extends BaseSpec; the describe TicketService block is labelled Test suite groups related tests; the it should return all tickets block is labelled Individual test case one behaviour; the expect result toBeArray line is labelled Assertion checks the result — each label is connected to its code line by a dashed callout line
:max-width: 860px
---
_TestBox BDD structure: `describe` groups related tests, `it` defines one behaviour, `expect` asserts the outcome._
::

### Install TestBox

TestBox installs into your student app directory via CommandBox:

```bash
cd ~/app
box install testbox
```

This downloads TestBox into `~/app/testbox/` and makes the test runner available at `http://localhost:8888/testbox/`.

::hint-box
---
:summary: 💡 Why does TestBox run on port 8888 and not 8500?
---
TestBox is a CommandBox package — it installs into the Lucee app at `~/app/` and runs under the Lucee server on port 8888. The ColdFusion server on port 8500 is a separate runtime. Your test specs can test CFCs that live in the CF wwwroot, but the test runner itself is served by Lucee/CommandBox.
::

### Write a test spec

Create the tests directory and a spec file:

```bash
mkdir -p ~/app/tests
sudo tee ~/app/tests/TicketServiceTest.cfc << 'EOF'
component extends="testbox.system.BaseSpec" {

  function run() {

    describe("TicketService", function() {

      it("should return all tickets as an array", function() {
        var svc    = new TicketService();
        var result = svc.getAll();
        expect(result).toBeArray();
        expect(arrayLen(result)).toBeGTE(0);
      });

      it("should return a single ticket by id", function() {
        var svc    = new TicketService();
        var ticket = svc.getById(1);
        expect(ticket).toBeStruct();
        expect(ticket).toHaveKey("title");
      });

    });

  }
}
EOF
```

### Run the tests

```bash
cd ~/app
box testbox run runner="http://localhost:8888/testbox/system/runners/TextRunner.cfm?directory=tests"
```

A passing suite looks like:

```
TestBox v6.x.x
Tests: 2  |  Passed: 2  |  Failed: 0  |  Errors: 0  |  Skipped: 0
```

::details-box
---
:summary: 📖 BDD vs TDD — what's the difference?
---

Both are testing approaches, but they frame tests differently:

**TDD (Test-Driven Development)** — write the test first, watch it fail, then write the code to make it pass. The test is written from a technical perspective: "assert that `getAll()` returns an array."

**BDD (Behaviour-Driven Development)** — write tests that describe expected *behaviour* in plain language. The test reads like a specification: "it should return all tickets as an array." TestBox supports both styles, but the `describe`/`it`/`expect` syntax you see here is BDD.

The practical difference is readability. A BDD spec failure message says:

```
TicketService > should return all tickets as an array — FAILED
```

That tells a developer (and a product manager) exactly what stopped working, without reading the assertion code.

**Common TestBox matchers:**

| Matcher | What it checks |
|---|---|
| `toBeArray()` | Value is an array |
| `toBeStruct()` | Value is a struct |
| `toBeTrue()` / `toBeFalse()` | Boolean result |
| `toBe(value)` | Strict equality |
| `toHaveKey("key")` | Struct contains the key |
| `toBeGTE(n)` | Greater than or equal to n |
| `toInclude("text")` | String or array contains value |
| `toThrow()` | Wrapped code throws an exception |
::

---

## 4. CF Admin Debugger

For deeper request-level tracing, ColdFusion's built-in debugger appends a full diagnostic panel to every rendered page — showing SQL queries executed, their times, template execution times, and variable scopes.

Enable it in CF Admin:
1. Open CF Admin → **Debugging & Logging → Debug Output Settings**
2. Check **Enable Request Debugging Output**
3. Add `127.0.0.1` to the IP address restriction list so only your terminal sees the output

Debugging output appears at the bottom of every CF page response. It is automatically hidden from any IP not on the list — safe to leave enabled in the lab, but always disable it before any public deployment.

---

## Activity 1 — Inspect data with cfdump

Create a page that dumps a struct and an array so you can see cfdump in action:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/debug-demo.cfm << 'EOF'
<cfscript>
  ticket = {
    id:       1,
    title:    "Cannot connect to VPN",
    status:   "open",
    priority: "high",
    tags:     ["network", "remote", "urgent"]
  };
</cfscript>

<cfdump var="#ticket#" label="Sample ticket struct">
EOF
```

Open the **ColdFusion** browser tab and navigate to `/debug-demo.cfm`. You should see the colour-coded dump table with the nested `tags` array expanded inline.

::simple-task
---
:tasks: tasks
:name: verify_cfdump_file
---
#active
Create `debug-demo.cfm` in the CF wwwroot — it must exist and return HTTP 200.

#completed
`debug-demo.cfm` found and accessible. ✓
::

---

## Activity 2 — Write a log entry and read it

Add a `cflog` call to your debug page and tail the log file:

```bash
sudo tee -a /opt/coldfusion2025/cfusion/wwwroot/debug-demo.cfm << 'EOF'
<cflog file="training" text="debug-demo.cfm loaded by #cgi.REMOTE_ADDR#" type="information">
EOF
```

Now tail the log in a second terminal tab while you refresh the page:

```bash
tail -f /opt/coldfusion2025/cfusion/logs/training.log
```

Each page load should add a new timestamped line to the log.

::simple-task
---
:tasks: tasks
:name: verify_cflog_entry
---
#active
A `training.log` file must exist in the CF logs directory.

#completed
`training.log` found — cflog is writing. ✓
::

---

## Activity 3 — Install TestBox and write a test spec

Install TestBox into your student app, then create the test spec:

```bash
cd ~/app && box install testbox
```

Then create the spec:

```bash
mkdir -p ~/app/tests
sudo tee ~/app/tests/TicketServiceTest.cfc << 'EOF'
component extends="testbox.system.BaseSpec" {

  function run() {

    describe("TicketService", function() {

      it("should return all tickets as an array", function() {
        var svc    = new TicketService();
        var result = svc.getAll();
        expect(result).toBeArray();
        expect(arrayLen(result)).toBeGTE(0);
      });

      it("should return a single ticket by id", function() {
        var svc    = new TicketService();
        var ticket = svc.getById(1);
        expect(ticket).toBeStruct();
        expect(ticket).toHaveKey("title");
      });

    });

  }
}
EOF
```

::simple-task
---
:tasks: tasks
:name: verify_testbox_installed
---
#active
Install TestBox: run `cd ~/app && box install testbox`

#completed
TestBox is installed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_test_exists
---
#active
Create `~/app/tests/TicketServiceTest.cfc` with at least one `describe`/`it`/`expect` block.

#completed
TestBox spec file found. ✓
::

---

## Activity 4 — Run the tests

```bash
cd ~/app
box testbox run runner="http://localhost:8888/testbox/system/runners/TextRunner.cfm?directory=tests"
```

All tests must pass — zero failures, zero errors.

::hint-box
---
:summary: 💡 TicketService is in the CF wwwroot, not ~/app — how does Lucee find it?
---
`TicketService.cfc` lives at `/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc`. When the test spec calls `new TicketService()`, Lucee resolves it via its mapping configuration. If you see a "component not found" error, copy the CFC into `~/app/` as well:

```bash
cp /opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc ~/app/
```
::

::simple-task
---
:tasks: tasks
:name: verify_tests_pass
---
#active
Run the TestBox suite — all tests must pass with zero failures and zero errors.

#completed
TestBox tests pass. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All done? Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete. On to the next one!
::

::remark-box
Found a bug or an issue with this lesson? Please reach out — your feedback helps improve the course for everyone.

📧 Alex — mercadoalex[at]gmail.com
::
