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

## Conditionals & Loops

::image-box
---
:src: __static__/cfml-loops-conditionals-cheatsheet-v1.png
:alt: Two-column cheat-sheet showing equivalent tag and script syntax for the three most common CFML control structures — cfif/if-else, cfloop index/for loop, and cfloop list/for-in — with matching colour coding so tag and script versions are visually paired
:max-width: 900px
---
_Quick reference: CFML tag syntax (left) vs. cfscript syntax (right) for conditionals and loops._
::


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

::hint-box
---
:summary: Is cfscript similar to JavaScript?
---

Yes — deliberately so. When Adobe introduced cfscript as the full-language syntax in ColdFusion 9 (2009), they modelled it closely on ECMAScript to lower the learning curve for web developers already familiar with JavaScript.

> **cfscript is NOT ECMAScript.** It runs on the JVM — on the server — never in a browser engine. The resemblance is purely syntactic, adopted to ease the learning curve. You cannot run cfscript in a browser, import ES modules, use `Promise`, `fetch`, or touch the DOM. It is a server-side language that happens to use curly braces and `for` loops.

| | cfscript | JavaScript |
|---|---|---|
| **Runs on** | JVM (server) | Browser engine / Node.js |
| **ECMAScript compliant** | No — inspired by, not conforming | Yes (ES5/ES6+) |
| **Accesses** | Databases, filesystem, mail, HTTP | DOM, Web APIs, fetch |
| **Compiled to** | Java bytecode | V8 bytecode / interpreted |
| **Standard** | Adobe / Lucee spec | ECMA-262 |

**What feels the same:**
- Curly-brace blocks `{ }`, `if / else if / else`, `for`, `while`, `do...while`
- `var` for local variable declaration inside functions
- Array literals `[1, 2, 3]` and struct/object literals `{key: "value"}`
- Arrow-style ternary `condition ? a : b`
- String concatenation with `&` (CF) vs `+` (JS) — the one operator that differs

**What is different:**
- **No `this` binding complexity** — CF components (`.cfc`) use `this` for instance scope but it behaves predictably, unlike JS
- **Hash interpolation** — `"Hello, #name#!"` inside strings is CF-only; JS uses template literals `` `Hello, ${name}!` ``
- **Semicolons are optional** in cfscript — CF tolerates their absence; JS has ASI rules that can bite you
- **Typed function signatures** — CF lets you declare `string function getName()` with return types and argument types, closer to TypeScript than plain JS
- **No async/await** — CF handles concurrency through `cfthread` and scheduled tasks, not promises

**The practical takeaway:** if you know JavaScript, cfscript will feel immediately readable. The mental model — functions, objects, loops, conditionals — is the same. The differences are surface-level and pick up quickly as you go.

::

::hint-box
---
:summary: How does ColdFusion interact with React, Angular, or Vue?
---

This is one of the most common questions from developers coming from a modern JS stack — and the answer is: **very well, and it is increasingly common.**

**The pattern: ColdFusion as a JSON API backend**

ColdFusion handles everything the browser cannot — database queries, authentication, file I/O, email, third-party integrations — and exposes the results as a JSON REST API. The frontend framework (React, Angular, Vue, Svelte, anything) consumes that API over `fetch` or `axios`, exactly as it would with a Node.js or Java backend.

```
React / Vue / Angular        ColdFusion 2025
─────────────────────        ───────────────────────
fetch("/api/tickets")  →     tickets.cfm queries DB
                       ←     returns JSON array
renders ticket list          done — CF is invisible
```

**Is it common in production?**

Yes — and growing. Many enterprise teams that have ColdFusion backends are adding React or Vue frontends without replacing CF. The typical stack looks like:

| Layer | Technology |
|---|---|
| Frontend SPA | React / Vue / Angular |
| API layer | ColdFusion REST endpoints (`.cfm` or CFC remoting) |
| Database | MySQL / PostgreSQL / MSSQL via CF datasource |
| Auth | CF session or JWT tokens validated server-side |

**What ColdFusion brings to this stack:**
- Mature, battle-tested database connectivity with connection pooling
- Built-in PDF generation, email, file handling — no extra services needed
- Single deployment unit — no separate Node API server to manage
- Existing CF codebase can be gradually modernised by adding a JS frontend without a full rewrite

**What to watch for:**
- Set `Content-Type: application/json` and CORS headers (`Access-Control-Allow-Origin`) on every CF endpoint the frontend calls
- Use `cfqueryparam` on every query — the frontend is now a public API surface
- Return consistent JSON error shapes (`{"error": "message"}`) so the frontend can handle failures gracefully

**The bottom line:** ColdFusion as a headless JSON backend paired with a modern JS framework is a legitimate, production-proven architecture. This course covers exactly that pattern in the REST APIs lesson.

::

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/syntax_tag.cfm` — output the text **"tag"** using `<cfset>` and `<cfoutput>`.
2. Create `syntax_script.cfm` — output the text **"script"** using `writeOutput()` inside `<cfscript>`, and add an `if` condition.
3. Verify:

```bash
curl -s http://localhost:8500/syntax_tag.cfm
curl -s http://localhost:8500/syntax_script.cfm
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_tag_syntax
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/syntax_tag.cfm` using `<cfset>` and `<cfoutput>` — the response must contain the word **tag**.

#completed
`syntax_tag.cfm` returns tag-syntax output. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_script_syntax
---
#active
Create `syntax_script.cfm` using `<cfscript>` and `writeOutput()` — the response must contain the word **script**.

#completed
`syntax_script.cfm` returns script-syntax output. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cfif
---
#active
Add an `if` or `<cfif>` conditional to `syntax_script.cfm`.

#completed
Conditional logic is present in `syntax_script.cfm`. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.cfml-syntax-18c13331
---
::
