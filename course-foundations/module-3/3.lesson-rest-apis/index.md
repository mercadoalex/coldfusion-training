---
kind: lesson

title: Building REST APIs with CFML
description: |
  Build JSON REST APIs using CFML. Learn cfheader, serializeJSON,
  deserializeJSON, REST annotations, and how to test endpoints with curl.

name: building-rest-apis-cfml
slug: building-rest-apis-cfml

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- rest
- api

playground:
  name: cf-alex-edcdf975

tasks:
  verify_api_endpoint:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/api/students.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "API endpoint /api/students.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "API endpoint is accessible"

  verify_json_content_type:
    machine: dev-machine
    user: laborant
    needs:
      - verify_api_endpoint
    run: |
      CONTENT_TYPE=$(curl -s -I http://localhost:8500/api/students.cfm | grep -i "content-type")
      if ! echo "${CONTENT_TYPE}" | grep -qi "application/json"; then
        echo "API is not returning Content-Type: application/json"
        exit 1
      fi
      echo "API returns correct Content-Type: application/json"

  verify_json_valid:
    machine: dev-machine
    user: laborant
    needs:
      - verify_json_content_type
    run: |
      BODY=$(curl -s http://localhost:8500/api/students.cfm)
      if ! echo "${BODY}" | python3 -m json.tool > /dev/null 2>&1; then
        echo "API response is not valid JSON"
        exit 1
      fi
      echo "API response is valid JSON"
---

## Simple JSON endpoint

```cfml
<!--- /api/students.cfm --->
<cfheader name="Content-Type" value="application/json">
<cfquery name="students" datasource="training_db">
  SELECT id, name, email FROM students
</cfquery>
<cfoutput>#serializeJSON(queryToArray(students))#</cfoutput>
```

## Test with curl

```bash
curl -s http://localhost:8500/api/students.cfm | python3 -m json.tool
```

## Accept JSON input

```cfml
<cfscript>
  rawBody = toString(getHttpRequestData().content);
  data = deserializeJSON(rawBody);
  writeOutput("Name received: " & data.name);
</cfscript>
```

## Return correct HTTP status codes

```cfml
<cfscript>
  if (!structKeyExists(url, "id")) {
    cfheader(statuscode="400", statustext="Bad Request");
    writeOutput(serializeJSON({error: "id is required"}));
    abort;
  }
</cfscript>
```
