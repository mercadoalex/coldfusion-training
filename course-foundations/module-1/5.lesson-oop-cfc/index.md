---
kind: lesson

title: Object-Oriented Programming with CFCs
description: |
  Learn how ColdFusion Components (CFCs) bring full OOP to CFML —
  classes, properties, methods, access modifiers, inheritance, and the
  constructor pattern. Build a reusable GreetingService CFC from scratch.

name: oop-coldfusion-components
slug: oop-coldfusion-components

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- oop

playground:
  name: cf-alex-edcdf975

tasks:
  verify_cfc_exists:
    machine: dev-machine
    user: laborant
    run: |
      FILE=$(find /opt/coldfusion2025/cfusion/wwwroot -name "GreetingService.cfc" | head -1)
      if [ -z "$FILE" ]; then
        echo "GreetingService.cfc not found in the web root"
        exit 1
      fi
      echo "CFC found: $FILE"

  verify_cfc_component:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_exists
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/GreetingService.cfc"
      if ! grep -qi "component" "$FILE"; then
        echo "No component declaration found in GreetingService.cfc"
        exit 1
      fi
      BODY=$(curl -s http://localhost:8500/test_cfc.cfm)
      if echo "$BODY" | grep -qi "error\|exception"; then
        echo "test_cfc.cfm returned an error — check GreetingService.cfc"
        exit 1
      fi
      echo "component declaration found and test_cfc.cfm runs cleanly"

  verify_cfc_method:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_component
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/GreetingService.cfc"
      COUNT=$(grep -ci "function" "$FILE")
      if [ "$COUNT" -lt 2 ]; then
        echo "Expected at least 2 functions in GreetingService.cfc (got $COUNT)"
        exit 1
      fi
      echo "$COUNT functions found in GreetingService.cfc"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_method
    run: |
      echo "Lesson complete — well done!"

---
