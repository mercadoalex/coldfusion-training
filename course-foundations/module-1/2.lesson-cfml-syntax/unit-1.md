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

**Activity:** In your lab, click the **Terminal** tab. Create `syntax_tag.cfm` in the ColdFusion web root using `sudo tee`:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/syntax_tag.cfm << 'EOF'
<cfset message = "I am using tag syntax">
<cfoutput>#message# — tag</cfoutput>
EOF
```

To see the rendered page in the browser:

1. Click the **ColdFusion 2025** tab in your lab — it shows the CF Admin login page inside the lab frame.
2. **Right-click** that tab button and choose **"Open Link in New Tab"** — this opens the engine's root URL in a real browser window with a full address bar.
3. In the address bar, replace whatever path is shown with `/syntax_tag.cfm` and press Enter.

::hint-box
---
:summary: Why can't I just type the URL directly?
---

Each lab VM gets a **unique, temporary hostname** that changes every time you start a new session — something like `https://6aa4b837d4c87b4fa0370284-3ec630.node-eu-13e2.iximiuz.com/`. That prefix is yours alone and only valid for the current session, so there is no fixed URL to share or bookmark. The reliable way to get it is to open the ColdFusion tab in a new browser window (right-click → Open Link in New Tab) and read it from the address bar. Then append your filename:

```
https://<your-session-id>.iximiuz.com/syntax_tag.cfm
```

::

You can also verify from the Terminal without opening a browser at all:

```bash
curl -s http://localhost:8500/syntax_tag.cfm
# Expected output: I am using tag syntax — tag
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

**Activity:** Still in the Terminal, create `syntax_script.cfm`:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/syntax_script.cfm << 'EOF'
<cfscript>
  writeOutput("I am using cfscript — script syntax");
</cfscript>
EOF
```

In the browser window you opened earlier, change the path to `/syntax_script.cfm` and reload. Or from the Terminal:

```bash
curl -s http://localhost:8500/syntax_script.cfm
# Expected output: I am using cfscript — script syntax
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

**Activity:** Update `syntax_script.cfm` to add a conditional. In the Terminal, overwrite the file:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/syntax_script.cfm << 'EOF'
<cfscript>
  writeOutput("I am using cfscript — script syntax");
  score = 85;
  if (score >= 90) {
    writeOutput(" — Grade: A");
  } else if (score >= 80) {
    writeOutput(" — Grade: B");
  } else {
    writeOutput(" — Grade: C");
  }
</cfscript>
EOF
```

Reload `/syntax_script.cfm` in the browser window to see the grade appended to the output. Or from the Terminal:

```bash
curl -s http://localhost:8500/syntax_script.cfm
# Expected: I am using cfscript — script syntax — Grade: B
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

**Activity:** In the Terminal, create `syntax_loop.cfm`:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/syntax_loop.cfm << 'EOF'
<cfscript>
  for (i = 1; i <= 5; i++) {
    writeOutput(i & "<br>");
  }
</cfscript>
EOF
```

Change the path to `/syntax_loop.cfm` in the browser window — the `<br>` tags render properly so the numbers appear on separate lines. Or from the Terminal:

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

## All loop forms — putting it together

CFML has four loop constructs you will encounter in real codebases. This exercise writes them all into a single file so you can see how they look side by side.

| Form | Use when |
|---|---|
| `for (i = 1; i <= n; i++)` | You need a numeric counter |
| `for (item in array)` | Iterating every element of an array |
| `for (key in struct)` | Iterating every key of a struct |
| `while (condition)` | Repeating until a condition is false |

**Activity:** In the Terminal, create `syntax_loop_all.cfm`:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/syntax_loop_all.cfm << 'EOF'
<cfscript>
  // 1. Index loop — numeric counter
  writeOutput("<strong>Index loop:</strong><br>");
  for (i = 1; i <= 3; i++) {
    writeOutput("  step #i#<br>");
  }

  // 2. For-in loop — array
  writeOutput("<br><strong>Array loop:</strong><br>");
  languages = ["CFML", "Java", "JavaScript"];
  for (lang in languages) {
    writeOutput("  #lang#<br>");
  }

  // 3. For-in loop — struct
  writeOutput("<br><strong>Struct loop:</strong><br>");
  info = {engine: "ColdFusion", version: "2025", port: "8500"};
  for (key in info) {
    writeOutput("  #key# = #info[key]#<br>");
  }

  // 4. While loop
  writeOutput("<br><strong>While loop:</strong><br>");
  count = 1;
  while (count <= 3) {
    writeOutput("  count is #count#<br>");
    count++;
  }
</cfscript>
EOF
```

Change the path to `/syntax_loop_all.cfm` in your browser window to see all four loop types rendered. Or from the Terminal:

```bash
curl -s http://localhost:8500/syntax_loop_all.cfm
```

::hint-box
---
:summary: Need to fix a file? Edit it with vi
---

If a file has a typo or you want to tweak it without rewriting the whole thing, `vi` (or `vim`) is available in the lab Terminal.

**Open the file:**
```bash
vi /opt/coldfusion2025/cfusion/wwwroot/syntax_loop_all.cfm
```

**Basic vi commands:**

| Key | What it does |
|---|---|
| `i` | Enter **insert** mode — you can now type and edit |
| `Esc` | Leave insert mode, go back to **normal** mode |
| `dd` | Delete the current line (normal mode) |
| `u` | Undo the last change (normal mode) |
| `:w` + Enter | **Save** the file (normal mode) |
| `:q` + Enter | **Quit** vi (normal mode, only if no unsaved changes) |
| `:wq` + Enter | **Save and quit** in one step |
| `:q!` + Enter | **Quit without saving** (discard changes) |

**Quickest edit workflow:**
1. `vi filename.cfm` — open the file
2. Navigate to the line you want to change (arrow keys work)
3. Press `i` to enter insert mode
4. Make your edit
5. Press `Esc` to return to normal mode
6. Type `:wq` and press Enter to save and exit

::

::simple-task
---
:tasks: tasks
:name: verify_loop_all
---
#active
Create `syntax_loop_all.cfm` with all four loop types — the response must contain **CFML**, **Java**, and **count**.

#completed
`syntax_loop_all.cfm` runs all four loop constructs. ✓
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
