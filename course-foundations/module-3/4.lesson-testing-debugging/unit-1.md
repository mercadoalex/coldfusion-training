---
kind: unit

title: Testing & Debugging CFML

name: testing-debugging-cfml-unit-1
---

## Debugging with cfdump

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
