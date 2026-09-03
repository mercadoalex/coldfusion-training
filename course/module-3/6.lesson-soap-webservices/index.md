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

tasks:
  verify_ws_consumer:
    machine: dev-machine
    user: laborant
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "soap_consumer.cfm not found"
        exit 1
      fi
      echo "soap_consumer.cfm exists"

  verify_cfinvoke_used:
    machine: dev-machine
    user: laborant
    needs:
      - verify_ws_consumer
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/soap_consumer.cfm"
      if ! grep -qi "cfinvoke\|createObject.*webservice" "${FILE}" 2>/dev/null; then
        echo "No cfinvoke or createObject webservice call found"
        exit 1
      fi
      echo "Web service invocation found"

  verify_exposed_service:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cfinvoke_used
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8500/StudentService.cfc?wsdl")
      if [ "${STATUS}" != "200" ]; then
        echo "StudentService.cfc WSDL not accessible (got ${STATUS})"
        exit 1
      fi
      echo "SOAP WSDL is accessible"
---

## Consuming a SOAP web service

```cfml
<cfscript>
  ws = createObject("webservice", "http://example.com/service?wsdl");
  result = ws.getStudentById(1);
  writeOutput("Name: " & result.name);
</cfscript>
```

## Using cfinvoke

```cfml
<cfinvoke
  webservice="http://example.com/StudentService?wsdl"
  method="getAll"
  returnvariable="students">
</cfinvoke>

<cfdump var="#students#">
```

## Exposing a CFC as a SOAP web service

```cfml
// StudentService.cfc
component displayname="StudentService" style="document" {

  remote struct function getStudentById(required numeric id)
    returntype="struct"
    access="remote"
    output="false"
  {
    var q = queryExecute(
      "SELECT id, name, email FROM students WHERE id = :id",
      {id: {value: arguments.id, cfsqltype: "cf_sql_integer"}},
      {datasource: "training_db"}
    );
    return {id: q.id, name: q.name, email: q.email};
  }

}
```

Access the WSDL at:
```
http://localhost:8500/StudentService.cfc?wsdl
```
