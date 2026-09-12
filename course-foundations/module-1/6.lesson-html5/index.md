---
kind: lesson

title: HTML5 and Advanced ColdFusion Features
description: |
  Integrate HTML5 capabilities with ColdFusion applications.
  Learn how to combine CFML with modern HTML5 APIs, dynamic components,
  and considerations for modern web applications.

name: html5-advanced-coldfusion
slug: html5-advanced-coldfusion

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- html5
- cfml

playground:
  name: cf-alex-edcdf975

tasks:
  verify_html5_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/html5_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "html5_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "html5_demo.cfm is accessible"

  verify_html5_doctype:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_page
    run: |
      BODY=$(curl -s http://localhost:8500/html5_demo.cfm)
      if ! echo "${BODY}" | grep -qi "<!DOCTYPE html>"; then
        echo "html5_demo.cfm is missing HTML5 doctype"
        exit 1
      fi
      echo "HTML5 doctype is present"

  verify_dynamic_output:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_doctype
    run: |
      BODY=$(curl -s http://localhost:8500/html5_demo.cfm)
      FILE="/opt/coldfusion2025/cfusion/wwwroot/html5_demo.cfm"
      if ! grep -q "cfoutput\|writeOutput\|serializeJSON" "${FILE}" 2>/dev/null; then
        echo "No dynamic CFML output found in html5_demo.cfm"
        exit 1
      fi
      echo "Dynamic CFML output is present"

  verify_form_validation:
    machine: dev-machine
    user: laborant
    needs:
      - verify_dynamic_output
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/html5_form_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "html5_form_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      FILE="/opt/coldfusion2025/cfusion/wwwroot/html5_form_demo.cfm"
      if ! grep -q 'type="email"' "${FILE}" 2>/dev/null; then
        echo "html5_form_demo.cfm is missing type=\"email\" input"
        exit 1
      fi
      if ! grep -q 'type="date"' "${FILE}" 2>/dev/null; then
        echo "html5_form_demo.cfm is missing type=\"date\" input"
        exit 1
      fi
      echo "HTML5 form validation demo is present with email and date inputs"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_form_validation
    run: |
      echo "Lesson complete — well done!"

---
