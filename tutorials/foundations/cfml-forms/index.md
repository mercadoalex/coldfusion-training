---
kind: tutorial

title: Handling HTML Forms with CFML
description: |
  Build a simple HTML form and process POST submissions using CFML form scope.
  Validate required fields and display confirmation.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- forms

playground:
  name: cf-alex-edcdf975
---

## form.cfm

```cfml
<cfif structKeyExists(form, "submitted")>
  <cfif len(trim(form.name)) EQ 0>
    <p style="color:red">Name is required.</p>
  <cfelse>
    <cfoutput><p>Hello, #encodeForHTML(form.name)#!</p></cfoutput>
  </cfif>
</cfif>

<form method="post">
  <input type="hidden" name="submitted" value="1">
  <label>Name: <input type="text" name="name"></label>
  <button type="submit">Submit</button>
</form>
```