---
kind: lesson

title: Integration via Web Services (SOAP)
description: |
  Understand SOAP web service architecture, consume external WSDL services
  from ColdFusion, and expose your own CFC methods as web services.

name: soap-web-services-integration
slug: soap-web-services-integration

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- soap
- web-services
- wsdl

playground:
  name: cf-alex-edcdf975

challenges:
  soap_webservices_8f4e8ae9: {}

tasks:
  verify_ws_consumer:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/student/soap_consumer.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "soap_consumer.cfm not found"
        exit 1
      fi
      if ! grep -qi "cfinvoke\|createObject.*webservice" "${FILE}" 2>/dev/null; then
        echo "No cfinvoke or createObject webservice call found in soap_consumer.cfm"
        exit 1
      fi
      echo "soap_consumer.cfm exists with web service invocation"

  verify_exposed_service:
    machine: dev-machine
    user: laborant
    needs:
      - verify_ws_consumer
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc"
      if [ ! -f "${FILE}" ]; then
        echo "TicketService.cfc not found"
        exit 1
      fi
      if ! grep -qi "access.*remote\|remote.*function" "${FILE}" 2>/dev/null; then
        echo "No remote function found in TicketService.cfc"
        exit 1
      fi
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8500/TicketService.cfc?wsdl")
      if [ "${STATUS}" != "200" ]; then
        echo "TicketService.cfc WSDL not accessible (got ${STATUS})"
        exit 1
      fi
      echo "SOAP WSDL is accessible at TicketService.cfc?wsdl"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_exposed_service
    run: |
      echo "Lesson complete — well done!"

---
