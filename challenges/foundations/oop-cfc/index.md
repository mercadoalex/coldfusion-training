---
kind: challenge

title: Build a TicketService CFC

description: |
  Create a ColdFusion Component (CFC) called TicketService.cfc in the web root.
  It must have an init() constructor, a public getAll() method that queries
  hd_tickets, and at least one private helper method. Then instantiate it
  from a test page using the new keyword.

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
      FILE="/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc"
      if [ ! -f "$FILE" ]; then
        echo "TicketService.cfc not found in web root"
        exit 1
      fi
      echo "TicketService.cfc found"

  verify_cfc_component:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_exists
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc"
      if ! grep -qi "^component" "$FILE"; then
        echo "No component declaration found in TicketService.cfc"
        exit 1
      fi
      echo "component declaration found"

  verify_init_constructor:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfc_component
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc"
      if ! grep -qi "function init" "$FILE"; then
        echo "No init() constructor found in TicketService.cfc"
        exit 1
      fi
      echo "init() constructor found"

  verify_public_method:
    machine: dev-machine
    user: laborant
    needs:
      - verify_init_constructor
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc"
      if ! grep -qi "public.*function" "$FILE"; then
        echo "No public function found in TicketService.cfc"
        exit 1
      fi
      echo "public function found"

  verify_private_method:
    machine: dev-machine
    user: laborant
    needs:
      - verify_public_method
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc"
      if ! grep -qi "private.*function" "$FILE"; then
        echo "No private function found in TicketService.cfc"
        exit 1
      fi
      echo "private function found"

  verify_instantiation:
    machine: dev-machine
    user: laborant
    needs:
      - verify_private_method
    run: |
      BODY=$(curl -s http://localhost:8500/test_cfc.cfm 2>/dev/null)
      if echo "$BODY" | grep -qi "error\|exception"; then
        echo "test_cfc.cfm returned an error"
        exit 1
      fi
      if [ -z "$BODY" ]; then
        echo "test_cfc.cfm not found or returned empty response"
        exit 1
      fi
      echo "test_cfc.cfm instantiates TicketService successfully"
---

## Your mission

Build a `TicketService.cfc` that demonstrates ColdFusion OOP — a proper class with a constructor, public methods, and a private helper.

### Step 1 — Create `TicketService.cfc`

Create `/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc`:

```cfml
component displayname="TicketService" {

  public TicketService function init(string datasource = "training_db") {
    variables.datasource = arguments.datasource;
    return this;
  }

  public array function getAll() {
    var q = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets ORDER BY id DESC",
      {}, { datasource: variables.datasource }
    );
    return queryToArray(q);
  }

  private boolean function isValidPriority(required string priority) {
    return listFind("low,medium,high,critical", arguments.priority) GT 0;
  }

}
```

### Step 2 — Create `test_cfc.cfm`

Create `/opt/coldfusion2025/cfusion/wwwroot/test_cfc.cfm`:

```cfml
<cfscript>
  svc     = new TicketService();
  tickets = svc.getAll();
  writeDump(tickets);
</cfscript>
```

### Step 3 — Verify

```bash
curl -s http://localhost:8500/test_cfc.cfm | grep -vi "error\|exception"
```
