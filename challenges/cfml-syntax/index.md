---
kind: challenge

title: Tag and Script Syntax

description: |
  Create two CFML pages: syntax_tag.cfm using tag syntax that outputs the
  word "tag", and syntax_script.cfm using cfscript that outputs "script"
  and includes an if/else conditional. Both pages must return HTTP 200.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- cfscript

playground:
  name: cf-alex-edcdf975

tasks:
  verify_tag_syntax:
    machine: dev-machine
    user: laborant
    run: |
      BODY=$(curl -s http://localhost:8500/syntax_tag.cfm)
      if ! echo "${BODY}" | grep -qi "tag"; then
        echo "syntax_tag.cfm does not output 'tag'"
        exit 1
      fi
      echo "Tag syntax page OK"

  verify_script_syntax:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tag_syntax
    run: |
      BODY=$(curl -s http://localhost:8500/syntax_script.cfm)
      if ! echo "${BODY}" | grep -qi "script"; then
        echo "syntax_script.cfm does not output 'script'"
        exit 1
      fi
      echo "Script syntax page OK"

  verify_conditional:
    machine: dev-machine
    user: laborant
    needs:
      - verify_script_syntax
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/syntax_script.cfm"
      if ! grep -q "if\|cfif" "${FILE}" 2>/dev/null; then
        echo "No conditional found in syntax_script.cfm"
        exit 1
      fi
      echo "Conditional logic present"
---

## Your mission

Create two files in the ColdFusion web root (`/opt/coldfusion2025/cfusion/wwwroot/`):

**syntax_tag.cfm** — use `<cfset>` and `<cfoutput>` to output the word **tag** somewhere in the response.

**syntax_script.cfm** — use a `<cfscript>` block with `writeOutput()` to output **script**, and include an `if/else` conditional.

```bash
# Verify both pages
curl -s http://localhost:8500/syntax_tag.cfm
curl -s http://localhost:8500/syntax_script.cfm
```
