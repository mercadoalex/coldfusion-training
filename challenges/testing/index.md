---
kind: challenge

title: TestBox Passing Test Suite

description: |
  Install TestBox, write a spec for TicketService with at least two
  passing tests, and run the suite via the TextRunner. The runner must
  report zero failures and zero errors.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- testbox

playground:
  name: cf-alex-edcdf975

tasks:
  verify_testbox_installed:
    machine: dev-machine
    user: laborant
    run: |
      if [ ! -d "/opt/coldfusion2025/cfusion/wwwroot/testbox" ] && \
         [ ! -d "/home/laborant/app/testbox" ]; then
        echo "TestBox not found — run: box install testbox"
        exit 1
      fi
      echo "TestBox installed"

  verify_test_file:
    machine: dev-machine
    user: laborant
    needs:
      - verify_testbox_installed
    run: |
      COUNT=$(find /opt/coldfusion2025/cfusion/wwwroot /home/laborant/app \
        -name "*Test*.cfc" -o -name "*Spec*.cfc" 2>/dev/null | wc -l)
      if [ "${COUNT}" -lt 1 ]; then
        echo "No TestBox spec or test CFC found"
        exit 1
      fi
      echo "Found ${COUNT} test file(s)"

  verify_tests_pass:
    machine: dev-machine
    user: laborant
    needs:
      - verify_test_file
    run: |
      BODY=$(curl -s \
        "http://localhost:8500/testbox/system/runners/TextRunner.cfm?directory=tests")
      if echo "${BODY}" | grep -qi "failures.*[^0]\|errors.*[^0]"; then
        echo "TestBox tests are failing"
        exit 1
      fi
      echo "TestBox tests pass"
---

## Your mission

1. Install TestBox: `box install testbox`
2. Create `tests/TicketServiceTest.cfc` with at least two `it()` blocks
3. Run the suite and confirm zero failures:

```bash
curl -s "http://localhost:8500/testbox/system/runners/TextRunner.cfm?directory=tests" \
  | grep -E "Tests:|Failures:|Errors:"
```
