---
kind: lesson

title: Testing & Debugging CFML
description: |
  Debug CFML applications using cfdump, cflog, and the CF debugger.
  Write unit tests with TestBox and run them via CommandBox.

name: testing-debugging-cfml
slug: testing-debugging-cfml

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- testbox
- debugging

playground:
  name: cf-alex-edcdf975

tasks:
  verify_testbox_installed:
    machine: dev-machine
    user: laborant
    run: |
      if [ ! -d "/home/laborant/app/testbox" ] && [ ! -d "/opt/coldfusion2025/cfusion/wwwroot/testbox" ]; then
        echo "TestBox not found — run: box install testbox"
        exit 1
      fi
      echo "TestBox is installed"

  verify_test_exists:
    machine: dev-machine
    user: laborant
    needs:
      - verify_testbox_installed
    run: |
      COUNT=$(find /opt/coldfusion2025/cfusion/wwwroot /home/laborant/app -name "*Test*.cfc" -o -name "*Spec*.cfc" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No TestBox test or spec CFC files found"
        exit 1
      fi
      echo "Found ${COUNT} test/spec file(s)"

  verify_tests_pass:
    machine: dev-machine
    user: laborant
    needs:
      - verify_test_exists
    run: |
      BODY=$(curl -s "http://localhost:8500/testbox/system/runners/TextRunner.cfm?directory=tests")
      if echo "${BODY}" | grep -qi "failures.*[^0]\|errors.*[^0]"; then
        echo "TestBox tests are failing"
        exit 1
      fi
      echo "TestBox tests pass"
---

## Debugging with cfdump

```cfml
<cfset data = {name: "Alex", scores: [95, 87, 72]}>
<cfdump var="#data#" label="Student data">
```

## Logging with cflog

```cfml
<cflog file="myapp" text="User #session.userId# logged in" type="information">
```

## Install TestBox

```bash
box install testbox
```

## Write a test spec

```cfml
component extends="testbox.system.BaseSpec" {
  function run() {
    describe("TicketService", function() {
      it("should return all tickets as an array", function() {
        var svc = new TicketService();
        var result = svc.getAll();
        expect(result).toBeArray();
        expect(arrayLen(result)).toBeGTE(0);
      });

      it("should return a single ticket by id", function() {
        var svc = new TicketService();
        var ticket = svc.getById(1);
        expect(ticket).toBeStruct();
        expect(ticket).toHaveKey("title");
      });
    });
  }
}
```

## Run tests

```bash
box testbox run runner="http://localhost:8500/testbox/system/runners/TextRunner.cfm"
```
