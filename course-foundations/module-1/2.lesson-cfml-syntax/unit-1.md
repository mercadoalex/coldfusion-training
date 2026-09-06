---
kind: unit

title: CFML Syntax — Tags and Script

name: cfml-syntax-tags-and-script-unit-1
---

## Tag syntax (classic)

CFML started as an HTML-like templating language. Every built-in operation is also available as an HTML-style tag.

```cfml
<cfset name = "World">
<cfoutput>Hello, #name#!</cfoutput>
```

Tags are case-insensitive and must be paired (or self-closed). The hash signs `#name#` signal variable interpolation inside a `<cfoutput>` block.

---

## Script syntax (modern)

Since ColdFusion 9, the full language is available in ECMAScript-style syntax inside a `<cfscript>` block. Modern CF codebases tend to use script exclusively.

```cfml
<cfscript>
  name = "World";
  writeOutput("Hello, #name#!");
</cfscript>
```

Both syntaxes compile to the same bytecode. You can mix them freely — a common pattern is to keep business logic in `<cfscript>` and HTML structure in tags.

---

## When to use each

| Use case | Recommendation |
|---|---|
| New code | `<cfscript>` — cleaner, less noise |
| Embedded SQL | `<cfquery>` tags are still idiomatic |
| Legacy templates | Keep tag syntax to avoid breaking changes |
| CFCs (components) | Script-only files (`.cfc`) are preferred |

---

## Conditionals

```cfml
<cfscript>
  score = 85;
  if (score >= 90) {
    writeOutput("A");
  } else if (score >= 80) {
    writeOutput("B");
  } else {
    writeOutput("C");
  }
</cfscript>
```

Tag equivalent:

```cfml
<cfif score GTE 90>
  A
<cfelseif score GTE 80>
  B
<cfelse>
  C
</cfif>
```

---

## Loops

```cfml
<cfscript>
  for (i = 1; i <= 5; i++) {
    writeOutput("Item #i#<br>");
  }
</cfscript>
```

ColdFusion also supports `for...in` over arrays and structs, and `while` loops. The tag equivalent is `<cfloop>`.

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/syntax_tag.cfm` — output the text **"tag"** using `<cfset>` and `<cfoutput>`.
2. Create `syntax_script.cfm` — output the text **"script"** using `writeOutput()` inside `<cfscript>`, and add an `if` condition.
3. Verify:

```bash
curl -s http://localhost:8500/syntax_tag.cfm
curl -s http://localhost:8500/syntax_script.cfm
```
