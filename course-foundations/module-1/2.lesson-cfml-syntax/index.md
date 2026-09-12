---
kind: lesson

title: CFML Syntax — Tags and Script
description: |
  Learn the two faces of CFML: HTML-like tag syntax and modern cfscript.
  Understand when to use each, and write your first real CFML pages.

name: cfml-syntax-tags-and-script
slug: cfml-syntax-tags-and-script

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
        echo "syntax_tag.cfm does not exist or does not use tag syntax"
        exit 1
      fi
      echo "Tag syntax page is working"

  verify_script_syntax:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tag_syntax
    run: |
      BODY=$(curl -s http://localhost:8500/syntax_script.cfm)
      if ! echo "${BODY}" | grep -qi "script"; then
        echo "syntax_script.cfm does not exist or does not use cfscript"
        exit 1
      fi
      echo "Script syntax page is working"

  verify_cfif:
    machine: dev-machine
    user: laborant
    needs:
      - verify_script_syntax
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/syntax_script.cfm"
      if ! grep -q "if\|cfif" "${FILE}" 2>/dev/null; then
        echo "Expected a conditional (if/cfif) in syntax_script.cfm"
        exit 1
      fi
      echo "Conditional logic found in syntax_script.cfm"

  verify_loop_syntax:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfif
    run: |
      BODY=$(curl -s http://localhost:8500/syntax_loop.cfm)
      for n in 1 2 3 4 5; do
        if ! echo "${BODY}" | grep -q "${n}"; then
          echo "syntax_loop.cfm does not output number ${n}"
          exit 1
        fi
      done
      echo "Loop outputs 1-5 correctly"

  verify_loop_all:
    machine: dev-machine
    user: laborant
    needs:
      - verify_loop_syntax
    run: |
      BODY=$(curl -s http://localhost:8500/syntax_loop_all.cfm)
      for word in "CFML" "Java" "count"; do
        if ! echo "${BODY}" | grep -qi "${word}"; then
          echo "syntax_loop_all.cfm is missing expected output: ${word}"
          exit 1
        fi
      done
      echo "All loop forms present in syntax_loop_all.cfm"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_loop_all
    run: |
      echo "Lesson complete — well done!"

---
