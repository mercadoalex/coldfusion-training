---
kind: tutorial

title: Querying the H2 Embedded Database
description: |
  Use cfquery to read from the embedded H2 training_db datasource.
  Create a simple table, insert rows, and display results.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- h2
- sql
- cfquery

playground:
  name: cf-alex-edcdf975
---

## Steps

```cfml
<!--- setup.cfm — run once --->
<cfquery datasource="training_db">
  CREATE TABLE IF NOT EXISTS items (
    id    INT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(100) NOT NULL
  )
</cfquery>

<cfquery datasource="training_db">
  INSERT INTO items (label) VALUES ('ColdFusion'), ('Lucee'), ('CommandBox')
</cfquery>

<cfquery name="rows" datasource="training_db">
  SELECT id, label FROM items ORDER BY id
</cfquery>

<cfoutput query="rows">
  #rows.id# — #rows.label#<br>
</cfoutput>
```