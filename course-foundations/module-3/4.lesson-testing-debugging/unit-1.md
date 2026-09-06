---
kind: unit

title: Testing & Debugging CFML

name: testing-debugging-cfml-unit-1
---

## Debugging with cfdump

::image-box
---
:src: __static__/cfdump-output-example-v1.png
:alt: Example cfdump HTML output — a colour-coded nested table labelled "Student data" at the top; outer row shows type "struct" with key "name" (value "Alex", type string) and key "scores" (type array); the array expands to show three numeric cells: 95, 87, 72 — styled with the classic ColdFusion blue header bar and alternating white/grey rows
:max-width: 640px
---
_`cfdump` renders any CF variable as a colour-coded interactive table — the fastest debugging tool in CFML._
::

`<cfdump>` renders any ColdFusion variable as a colour-coded HTML table — the fastest way to inspect data during development.

```cfml
<cfset data = {name: "Alex", scores: [95, 87, 72]}>
<cfdump var="#data#" label="Student data">
```

Useful `cfdump` attributes:

| Attribute | Purpose |
|---|---|
| `var` | Variable to dump |
| `label` | Heading above the dump |
| `top` | Limit depth of nested structures |
| `output` | `"browser"` (default) or `"console"` |

---

## Logging with cflog

`<cflog>` writes structured entries to a log file in CF's log directory:

```cfml
<cflog file="myapp" text="User #session.userId# logged in" type="information">
```

Log types: `information`, `warning`, `error`, `fatal`.

Tail the log in the terminal:

```bash
tail -f /opt/coldfusion2025/cfusion/logs/myapp.log
```

---

## Install TestBox

::image-box
---
:src: __static__/testbox-bdd-spec-structure-v1.png
:alt: Annotated CFML code snippet of a TestBox BDD spec — the component extends="testbox.system.BaseSpec" line is labelled "extends BaseSpec"; the describe("TicketService", ...) block is labelled "test suite"; the it("should return all tickets", ...) block is labelled "individual test case"; the expect(result).toBeArray() line is labelled "assertion / matcher" — each label is connected to its code line by a coloured callout arrow
:max-width: 860px
---
_TestBox BDD structure: `describe` groups related tests, `it` describes a single behaviour, `expect` asserts the outcome._
::


TestBox is the CFML BDD/TDD testing framework. Install it via CommandBox:

```bash
box install testbox
```

This creates `testbox/` in your web root.

---

## Write a test spec

```cfml
// tests/TicketServiceTest.cfc
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
```

---

## Run tests

From the terminal:

```bash
box testbox run runner="http://localhost:8500/testbox/system/runners/TextRunner.cfm"
```

Or via the browser runner:

```
http://localhost:8500/testbox/system/runners/TextRunner.cfm?directory=tests
```

The task validator checks that TestBox returns no failures or errors.

---

## CF Debugger (CF Admin)

Enable request debugging in CF Admin:
1. **Debugging & Logging → Debug Output Settings**
2. Enable **Enable Request Debugging Output**
3. Add your IP to the IP address restriction list

Debugging output appears at the bottom of every rendered CF page, showing SQL queries executed, template execution times, and variable dumps.

---

## Exercises

1. Install TestBox: `box install testbox`
2. Create `tests/TicketServiceTest.cfc` with at least one `describe`/`it`/`expect` block.
3. Run tests and verify they pass:

```bash
curl -s "http://localhost:8500/testbox/system/runners/TextRunner.cfm?directory=tests" \
  | grep -i "failures\|errors\|tests"
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_testbox_installed
---
#active
Install TestBox: `box install testbox`

#completed
TestBox is installed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_test_exists
---
#active
Create at least one TestBox spec or test CFC (filename containing `Test` or `Spec`).

#completed
TestBox test/spec file found. ✓
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

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.testing-d1e51a86
---
::
