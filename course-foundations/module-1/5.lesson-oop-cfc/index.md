---
kind: lesson

title: Object-Oriented Programming with CFCs

description: |
  Learn how ColdFusion Components (CFCs) bring full OOP to CFML —
  classes, properties, methods, access modifiers, inheritance, and the
  constructor pattern. Build a reusable TicketService CFC from scratch.

createdAt: 2026-09-03
updatedAt: 2026-09-03

playground:
  name: cf-alex-edcdf975

tasks:
  verify_cfc_exists:
    machine: dev-machine
    user: laborant
    run: |
      FILE=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" | head -1)
      if [ -z "$FILE" ]; then
        echo "No .cfc file found in the web root"
        exit 1
      fi
      echo "CFC found: $FILE"

  verify_cfc_component:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_exists
    run: |
      FILE=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" | head -1)
      if ! grep -qi "component" "$FILE"; then
        echo "No component declaration found"
        exit 1
      fi
      echo "component declaration found"

  verify_cfc_method:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_component
    run: |
      FILE=$(find /opt/coldfusion2025/cfusion/wwwroot -name "*.cfc" | head -1)
      if ! grep -qi "function" "$FILE"; then
        echo "No function defined in CFC"
        exit 1
      fi
      echo "Function found in CFC"
---
