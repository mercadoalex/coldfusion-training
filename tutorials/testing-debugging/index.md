---
kind: tutorial

title: Debug with cfdump and Write Tests with TestBox

description: |
  Use cfdump and cflog to inspect variables, then install TestBox
  and write your first passing test spec for TicketService.cfc.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- testbox
- debugging

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Use cfdump to inspect data

Create `/opt/coldfusion2025/cfusion/wwwroot/debug_dump.cfm`:

```cfml
<cfscript>
  data = {
    name:   "Alex",
    scores: [95, 87, 72],
    meta:   {course: "CF Foundations", year: 2026}
  };
</cfscript>
<cfdump var="#data#" label="Student data">
<cfdump var="#application#" label="Application scope" top="2">
```

```bash
curl -s http://localhost:8500/debug_dump.cfm | head -30
```

### 2. Add cflog to Application.cfc

In `onRequestStart`:

```cfml
cflog(file="helpdesk", text="Request: #arguments.targetPage#", type="information");
```

```bash
tail -5 /opt/coldfusion2025/cfusion/logs/helpdesk.log
```

### 3. Install TestBox

```bash
cd /opt/coldfusion2025/cfusion/wwwroot && box install testbox
```

### 4. Write TicketServiceTest.cfc

Create `/opt/coldfusion2025/cfusion/wwwroot/tests/TicketServiceTest.cfc`:

```cfml
component extends="testbox.system.BaseSpec" {
  function run() {
    describe("TicketService", function() {
      it("should return all tickets as an array", function() {
        var svc    = new TicketService();
        var result = svc.getAll();
        expect(result).toBeArray();
        expect(arrayLen(result)).toBeGTE(1);
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

### 5. Run tests

```bash
curl -s "http://localhost:8500/testbox/system/runners/TextRunner.cfm?directory=tests" \
  | grep -E "Tests|Failures|Errors"
```
