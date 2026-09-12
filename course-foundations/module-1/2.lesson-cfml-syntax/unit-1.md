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

::image-box
---
:src: __static__/cfml-tag-anatomy-v1.png
:alt: Annotated diagram of a CFML tag showing the opening angle bracket, tag name (cfoutput), optional attributes (query="myQuery"), tag body text with hash-delimited variable expression (#name#), and the matching closing tag (</cfoutput>) — each part labelled with an arrow and short description
:max-width: 860px
---
_Anatomy of a CFML tag: opening tag, optional attributes, hash-delimited interpolation, and closing tag._
::

**Activity:** Create `/opt/coldfusion2025/cfusion/wwwroot/syntax_tag.cfm` — use `<cfset>` to assign a variable and `<cfoutput>` to print the word **tag**.

```cfml
<cfset message = "I am using tag syntax">
<cfoutput>#message# — tag</cfoutput>
```

Verify it works:

```bash
curl -s http://localhost:8500/syntax_tag.cfm
```

::simple-task
---
:tasks: tasks
:name: verify_tag_syntax
---
#active
Create `syntax_tag.cfm` using `<cfset>` and `<cfoutput>` — the response must contain the word **tag**.

#completed
`syntax_tag.cfm` is working with tag syntax. ✓
::

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

::image-box
---
:src: __static__/cfml-compilation-pipeline-v1.png
:alt: Diagram showing two paths merging into one pipeline — on the left a .cfm file using tag syntax, on the right a .cfc file using cfscript syntax, both arrows pointing into a central "CFML Compiler" box, which outputs a single "Java bytecode (.class)" box, which feeds into "JVM execution" — illustrating that both syntaxes produce identical bytecode
:max-width: 800px
---
_Both syntaxes are compiled by the same CFML engine to identical JVM bytecode._
::

**Activity:** Create `syntax_script.cfm` — use `<cfscript>` and `writeOutput()` to print the word **script**.

```cfml
<cfscript>
  writeOutput("I am using cfscript — script syntax");
</cfscript>
```

```bash
curl -s http://localhost:8500/syntax_script.cfm
```

::simple-task
---
:tasks: tasks
:name: verify_script_syntax
---
#active
Create `syntax_script.cfm` using `<cfscript>` and `writeOutput()` — the response must contain the word **script**.

#completed
`syntax_script.cfm` is working with cfscript syntax. ✓
::

---

## When to use each

| Use case | Recommendation |
|---|---|
| New code | `<cfscript>` — cleaner, less noise |
| Embedded SQL | `<cfquery>` tags are still idiomatic |
| Legacy templates | Keep tag syntax to avoid breaking changes |
| CFCs (components) | Script-only files (`.cfc`) are preferred |

## What does production look like today?

In modern CFML codebases (2020 onward), **cfscript dominates**. Here's why:

- **Frameworks are script-first.** ColdBox, the most widely adopted CFML MVC framework, writes everything in cfscript. If you work on any ColdBox application — which covers a large share of active CF projects — you write script exclusively.
- **Tooling favours script.** Code formatters (CFFormat), linters (CFLint), and IDE plugins all have better support for script syntax. Tag-heavy files produce more false positives and formatting noise.
- **Readability at scale.** In a large CFC with 20+ functions, tag syntax adds significant visual noise. Script reads closer to Java or JavaScript, which most CF developers already know.
- **The one exception: `<cfquery>`.** Even in fully script-based codebases, many teams keep SQL in `<cfquery>` tags because the SQL sits naturally inside the tag body without string concatenation. `queryExecute()` is the script alternative, but `<cfquery>` is still widely accepted and idiomatic.

::hint-box
---
:summary: So should I learn tag syntax at all?
---

Yes — for two reasons. First, you will encounter tag syntax in legacy codebases and online examples written before 2015. Being able to read it is essential. Second, a handful of tags (`<cfquery>`, `<cfmail>`, `<cffile>`) remain idiomatic even in script-first projects because they read more clearly than their function equivalents.

**The practical rule:** write all new logic in cfscript, keep `<cfquery>` for SQL, and read tag syntax fluently.

::

---

## Conditionals

CFML conditionals work in both syntaxes. The cfscript form mirrors JavaScript; the tag form uses attribute-style operators like `GTE`, `LTE`, `EQ`, `NEQ`.

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
<cfset score = 85>
<cfif score GTE 90>
  A
<cfelseif score GTE 80>
  B
<cfelse>
  C
</cfif>
```

::image-box
---
:src: __static__/cfml-loops-conditionals-cheatsheet-v1.png
:alt: Two-column cheat-sheet showing equivalent tag and script syntax for the three most common CFML control structures — cfif/if-else, cfloop index/for loop, and cfloop list/for-in — with matching colour coding so tag and script versions are visually paired
:max-width: 900px
---
_Quick reference: CFML tag syntax (left) vs. cfscript syntax (right) for conditionals and loops._
::

**Activity:** Add a conditional to `syntax_script.cfm`. Check a variable against a threshold and output a different message for each branch.

```cfml
<cfscript>
  score = 85;
  if (score >= 90) {
    writeOutput("Grade: A");
  } else if (score >= 80) {
    writeOutput("Grade: B");
  } else {
    writeOutput("Grade: C");
  }
</cfscript>
```

::simple-task
---
:tasks: tasks
:name: verify_cfif
---
#active
Add an `if` / `else` conditional (or `<cfif>`) to `syntax_script.cfm` — the file must contain the keyword `if` or `cfif`.

#completed
Conditional logic is present in `syntax_script.cfm`. ✓
::

---

## Loops

ColdFusion supports `for`, `while`, and `for...in` in cfscript, and `<cfloop>` in tag syntax. The most common is the index loop:

```cfml
<cfscript>
  for (i = 1; i <= 5; i++) {
    writeOutput("Item #i#<br>");
  }
</cfscript>
```

Tag equivalent:

```cfml
<cfloop index="i" from="1" to="5">
  Item #i#<br>
</cfloop>
```

ColdFusion also supports iterating over arrays and structs:

```cfml
<cfscript>
  fruits = ["apple", "banana", "cherry"];
  for (fruit in fruits) {
    writeOutput("#fruit#<br>");
  }
</cfscript>
```

**Activity:** Create `/opt/coldfusion2025/cfusion/wwwroot/syntax_loop.cfm`. Use a `for` loop (cfscript or `<cfloop>` tag) to output the numbers 1 through 5, one per line.

```cfml
<cfscript>
  for (i = 1; i <= 5; i++) {
    writeOutput(i & "<br>");
  }
</cfscript>
```

```bash
curl -s http://localhost:8500/syntax_loop.cfm
# Expected: 1<br>2<br>3<br>4<br>5<br>
```

::simple-task
---
:tasks: tasks
:name: verify_loop_syntax
---
#active
Create `syntax_loop.cfm` that uses a loop to output numbers 1 through 5 — the response must contain **1**, **2**, **3**, **4**, and **5**.

#completed
`syntax_loop.cfm` loops and outputs numbers 1–5. ✓
::

---

::hint-box
---
:summary: Is cfscript similar to JavaScript?
---

Yes — deliberately so. When Adobe introduced cfscript as the full-language syntax in ColdFusion 9 (2009), they modelled it closely on ECMAScript to lower the learning curve for web developers already familiar with JavaScript.

> **cfscript is NOT ECMAScript.** It runs on the JVM — on the server — never in a browser engine. The resemblance is purely syntactic. You cannot run cfscript in a browser, import ES modules, use `Promise`, `fetch`, or touch the DOM.

| | cfscript | JavaScript |
|---|---|---|
| **Runs on** | JVM (server) | Browser engine / Node.js |
| **ECMAScript compliant** | No — inspired by, not conforming | Yes (ES5/ES6+) |
| **Accesses** | Databases, filesystem, mail, HTTP | DOM, Web APIs, fetch |
| **Compiled to** | Java bytecode | V8 bytecode / interpreted |
| **Standard** | Adobe / Lucee spec | ECMA-262 |

**What feels the same:** curly-brace blocks, `if/else`, `for`, `while`, array literals `[1,2,3]`, struct literals `{key: "value"}`, ternary `condition ? a : b`.

**What is different:** string concatenation uses `&` not `+`, hash interpolation `"Hello, #name#!"` is CF-only, and there is no `async/await` — CF handles concurrency through `cfthread`.

::

::hint-box
---
:summary: How does ColdFusion interact with React, Angular, or Vue?
---

**The pattern: ColdFusion as a JSON API backend.**

ColdFusion handles everything the browser cannot — database queries, authentication, file I/O, email, third-party integrations — and exposes the results as a JSON REST API. The frontend framework consumes that API over `fetch` or `axios`, exactly as it would with a Node.js or Java backend.

```
React / Vue / Angular        ColdFusion 2025
─────────────────────        ───────────────────────
fetch("/api/tickets")  →     tickets.cfm queries DB
                       ←     returns JSON array
renders ticket list          done — CF is invisible
```

This is covered in depth in the REST APIs lesson.

::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All done? Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete. On to the next one!
::
