---
kind: tutorial

title: Tag Syntax vs cfscript — Side by Side

description: |
  Write the same logic in both CFML tag syntax and cfscript,
  run both pages and compare the output.

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
---

## Steps

### 1. Create the tag-syntax page

In VS Code, create `/opt/coldfusion2025/cfusion/wwwroot/syntax_tag.cfm`:

```cfml
<cfset language = "ColdFusion">
<cfset year = year(now())>
<cfoutput>
  <p>Language: #language# (tag syntax)</p>
  <p>Year: #year#</p>
</cfoutput>
```

### 2. Create the script-syntax page

Create `/opt/coldfusion2025/cfusion/wwwroot/syntax_script.cfm`:

```cfml
<cfscript>
  language = "ColdFusion";
  year     = year(now());
  if (year >= 2025) {
    writeOutput("<p>Language: #language# (script syntax)</p>");
    writeOutput("<p>Year: #year# — current!</p>");
  }
</cfscript>
```

### 3. Test both

```bash
curl -s http://localhost:8500/syntax_tag.cfm
curl -s http://localhost:8500/syntax_script.cfm
```

Both should output the language name and year. Notice the script version uses an `if` condition — the lesson task checks for this.

### 4. Key differences

| Tag syntax | Script syntax |
|---|---|
| `<cfset x = 1>` | `x = 1;` |
| `<cfoutput>#x#</cfoutput>` | `writeOutput(x);` |
| `<cfif x GT 0>...</cfif>` | `if (x > 0) { ... }` |
| `<cfloop ...>` | `for / while` |
