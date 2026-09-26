---
kind: unit

title: Variables, Data Types & Scopes

name: variables-data-types-scopes-unit-1
---

## Data types

ColdFusion is dynamically typed. Variables are created on assignment and their type is inferred at runtime — no `int`, `String`, or `var` declarations required.

| Type | Example | Notes |
|---|---|---|
| String | `"Hello"` | Immutable; `&` concatenates |
| Numeric | `42`, `3.14` | Integer and float unified |
| Boolean | `true`, `false`, `yes`, `no` | `yes`/`no` are aliases |
| Date | `now()`, `"2026-09-03"` | Rich date/time functions built in |
| Array | `[1, 2, 3]` | 1-based index |
| Struct | `{name: "Alex", age: 30}` | Key-value map; keys case-insensitive |
| Query | result of `cfquery` / `queryExecute()` | Tabular result set |

::image-box
---
:src: __static__/cfml-data-types-overview-v1.png
:alt: Six labelled boxes arranged in a 2×3 grid on a white background — String (orange border, example "Hello World"), Numeric (blue, example 42 and 3.14), Boolean (green, example true/false/yes/no), Array (purple, bracket notation [1,2,3]), Struct (teal, curly-brace notation {key: value}), and Query (grey, table icon with rows and columns) — each box shows the type name and a short CFML literal example
:max-width: 860px
---
_CFML's six core data types — dynamically inferred at runtime, no explicit type declarations needed._
::

**Activity:** Create `data_types.cfm` to explore all six data types.

**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/student/data_types.cfm << 'EOF'
<cfscript>
  // String
  myString = "Hello ColdFusion";
  writeOutput("<strong>String:</strong> " & myString & "<br>");

  // Numeric
  myInt  = 42;
  myFloat = 3.14;
  writeOutput("<strong>Numeric:</strong> " & myInt & " / " & myFloat & "<br>");

  // Boolean
  isActive = true;
  writeOutput("<strong>Boolean:</strong> " & isActive & "<br>");

  // Date
  today = now();
  writeOutput("<strong>Date:</strong> " & dateFormat(today, "yyyy-mm-dd") & "<br>");

  // Array
  fruits = ["apple", "banana", "cherry"];
  writeOutput("<strong>Array[1]:</strong> " & fruits[1] & "<br>");

  // Struct
  person = {name: "Alex", age: 30};
  writeOutput("<strong>Struct:</strong> " & person.name & " is " & person.age & "<br>");
</cfscript>
EOF
```

::details-box
---
:summary: ✏️ Using the IDE tab instead? Create the file here
---
In the **IDE tab**, click **File → Open Folder…**, type `/opt/coldfusion2025/cfusion/wwwroot/student` and press **Enter**. If VS Code asks _"The folder does not exist. Would you like to create it?"_ — click **Yes**. Then right-click in the Explorer panel → **New File** → name it `data_types.cfm`, paste the content below, and save with **Ctrl+S**:

::image-box
---
:src: __static__/folder-student-does-not-exist-v1.png
:alt: VS Code dialog asking "The folder /opt/coldfusion2025/cfusion/wwwroot/student does not exist. Would you like to create it?" with a Yes button highlighted
:max-width: 560px
---
_VS Code will offer to create the `student` folder — click **Yes**._
::

```cfml
<cfscript>
  // String
  myString = "Hello ColdFusion";
  writeOutput("<strong>String:</strong> " & myString & "<br>");

  // Numeric
  myInt  = 42;
  myFloat = 3.14;
  writeOutput("<strong>Numeric:</strong> " & myInt & " / " & myFloat & "<br>");

  // Boolean
  isActive = true;
  writeOutput("<strong>Boolean:</strong> " & isActive & "<br>");

  // Date
  today = now();
  writeOutput("<strong>Date:</strong> " & dateFormat(today, "yyyy-mm-dd") & "<br>");

  // Array
  fruits = ["apple", "banana", "cherry"];
  writeOutput("<strong>Array[1]:</strong> " & fruits[1] & "<br>");

  // Struct
  person = {name: "Alex", age: 30};
  writeOutput("<strong>Struct:</strong> " & person.name & " is " & person.age & "<br>");
</cfscript>
```
::

::image-box
---
:src: __static__/data-types-v1.png
:alt: VS Code editor in the IDE tab showing data_types.cfm open with the six cfscript blocks for String, Numeric, Boolean, Date, Array, and Struct — no unsaved-changes dot on the editor tab, confirming the file has been saved to disk
:max-width: 860px
---
_`data_types.cfm` saved in the `student/` folder — ready to run._
::

Open `/data_types.cfm` in the **ColdFusion 2025** browser tab (right-click → Open Link in New Tab, then change the path). Or from the Terminal:

```bash
curl -s http://localhost:8500/student/data_types.cfm
```

::image-box
---
:src: __static__/browser-output-data-types-v1.png
:alt: Browser window showing the rendered output of data_types.cfm — six lines each prefixed with a bold type label: String showing Hello ColdFusion, Numeric showing 42 / 3.14, Boolean showing true, Date showing the current date in yyyy-mm-dd format, Array[1] showing apple, Struct showing Alex is 30
:max-width: 860px
---
_All six data types rendered — each line shows the type name and its value._
::

::simple-task
---
:tasks: tasks
:name: verify_data_types
---
#active
Create `data_types.cfm` — the response must contain **String**, **Numeric**, and **Boolean**.

#completed
`data_types.cfm` demonstrates all six data types. ✓
::

---

## Variable scopes

ColdFusion organises variables into named scopes. Every scope has a different lifetime and visibility.

| Scope | Prefix | Lifetime | Typical use |
|---|---|---|---|
| `variables` | `variables.` | Single request | Default local scope for a page/CFC |
| `url` | `url.` | Single request | Query-string parameters |
| `form` | `form.` | Single request | POST form fields |
| `request` | `request.` | Single request | Pass data between included files |
| `session` | `session.` | User session | Per-user state (cart, login) |
| `application` | `application.` | App lifetime | Shared config, counters |
| `server` | `server.` | Server lifetime | Rarely written; read CF/Lucee version |

The `variables` scope is the default when you omit a prefix. Always prefix `session.*` and `application.*` explicitly.

::image-box
---
:src: __static__/cfml-scope-lifetimes-v1.png
:alt: Horizontal bar chart showing CFML scope lifetimes from shortest to longest — from top: url/form/request (single request, narrow bar), variables (single request, same width), local/arguments (function call duration, shortest), session (user session lifetime, medium bar), application (application lifetime, long bar), server (server process lifetime, longest bar) — bars are colour-coded from short (red) to long (green)
:max-width: 860px
---
_Scope lifetimes compared — request-scoped variables are cheapest; application-scoped variables persist for the life of the process._
::

**Activity:** Create `scopes.cfm` to demonstrate the `variables` scope.

**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/student/scopes.cfm << 'EOF'
<cfscript>
  // variables scope — explicit prefix
  variables.name    = "Alex";
  variables.course  = "ColdFusion 2025";

  writeOutput("<strong>variables.name:</strong> "   & variables.name   & "<br>");
  writeOutput("<strong>variables.course:</strong> " & variables.course & "<br>");

  // url scope — reads ?name= from the query string
  urlName = url.name ?: "no name passed";
  writeOutput("<strong>url.name:</strong> " & urlName & "<br>");
</cfscript>
EOF
```

::details-box
---
:summary: ✏️ Using the IDE tab instead? Create the file here
---
In the **IDE tab**, right-click in the Explorer panel → **New File** → name it `scopes.cfm`, paste the content below, and save with **Ctrl+S**:

```cfml
<cfscript>
  // variables scope — explicit prefix
  variables.name    = "Alex";
  variables.course  = "ColdFusion 2025";

  writeOutput("<strong>variables.name:</strong> "   & variables.name   & "<br>");
  writeOutput("<strong>variables.course:</strong> " & variables.course & "<br>");

  // url scope — reads ?name= from the query string
  urlName = url.name ?: "no name passed";
  writeOutput("<strong>url.name:</strong> " & urlName & "<br>");
</cfscript>
```
::

::image-box
---
:src: __static__/scopes-v1.png
:alt: VS Code editor in the IDE tab showing scopes.cfm open with the cfscript block for variables and url scopes — no unsaved-changes dot on the editor tab, confirming the file has been saved to disk
:max-width: 860px
---
_`scopes.cfm` saved in the `student/` folder — ready to run._
::

Open `/scopes.cfm` in the browser to confirm the `variables` scope output:

```bash
curl -s http://localhost:8500/student/scopes.cfm
```

::image-box
---
:src: __static__/browser-output-scopes-v1.png
:alt: Browser window showing the rendered output of scopes.cfm — three lines: variables.name showing Alex, variables.course showing ColdFusion 2025, url.name showing no name passed (because no query string was provided)
:max-width: 860px
---
_`scopes.cfm` with no query string — `variables.*` values are set, `url.name` falls back to the default._
::

::simple-task
---
:tasks: tasks
:name: verify_scopes_page
---
#active
Create `scopes.cfm` — the response must contain the word **variables**.

#completed
`scopes.cfm` demonstrates variable scopes. ✓
::

---

Now verify that the `variables.` prefix is used explicitly in the file:

::simple-task
---
:tasks: tasks
:name: verify_variables_scope
---
#active
Confirm `scopes.cfm` uses the `variables.` prefix explicitly — the file must contain `variables.`.

#completed
The `variables` scope is explicitly prefixed. ✓
::

---

## URL scope

Pass a query-string parameter and read it back with `url.name`:

```bash
curl -s "http://localhost:8500/student/scopes.cfm?name=TestUser"
# Expected: url.name: TestUser
```

Or in the browser, append `?name=TestUser` to the URL:

```
https://<your-session-id>.iximiuz.com/scopes.cfm?name=TestUser
```

::image-box
---
:src: __static__/browser-output-scopes-url-v1.png
:alt: Browser window showing the rendered output of scopes.cfm?name=TestUser — three lines: variables.name showing Alex, variables.course showing ColdFusion 2025, url.name showing TestUser (the value passed in the query string)
:max-width: 860px
---
_With `?name=TestUser` appended, `url.name` resolves to **TestUser** instead of the default._
::

::simple-task
---
:tasks: tasks
:name: verify_url_scope
---
#active
Visit `scopes.cfm?name=TestUser` — the response must echo back **TestUser** from the URL scope.

#completed
URL scope is working — `?name=TestUser` is reflected in the output. ✓
::

---

## Scope resolution order

::image-box
---
:src: __static__/cfml-scope-resolution-order-v1.png
:alt: Numbered vertical flowchart showing ColdFusion's unqualified variable lookup order — step 1: local (inside CFC function), step 2: arguments, step 3: thread, step 4: query (inside cfloop query), step 5: variables, step 6: cgi/file/url/form/cookie/client — each step is a rounded rectangle, connected by downward arrows, with a "found → stop" branch on the right side of each box
:max-width: 640px
---
_When you omit a scope prefix, CF walks this resolution chain top-to-bottom — always prefix to be explicit._
::

When you write just `name` without a prefix, ColdFusion checks scopes in this order:

1. `local` (inside a CFC function)
2. `arguments`
3. `thread`
4. `query` (inside a `<cfloop query="...">`)
5. `variables`
6. `cgi`, `file`, `url`, `form`, `cookie`, `client`

**Always prefix to be explicit and avoid scope-bleed bugs.** In a large application, an unqualified variable that accidentally resolves from `url` instead of `variables` can cause hard-to-trace security issues.

## Inspecting scopes with cfdump

ColdFusion has a built-in debugging tool — `<cfdump>`. It renders any variable, struct, array, query, or entire scope as a colour-coded HTML table directly in the browser. It is the fastest way to see exactly what is in scope at runtime.

```cfml
<cfdump var="#variables#" label="variables scope">
<cfdump var="#url#"       label="url scope">
<cfdump var="#session#"   label="session scope">
```

> **Rule of thumb:** add `<cfdump>` while you develop, remove it before going to production. Leaving it in exposes internal variable names and values to anyone who can reach the page.

**Activity:** Create `cfdump_demo.cfm` to dump the `variables` and `url` scopes side by side.

**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/student/cfdump_demo.cfm << 'EOF'
<cfscript>
  variables.greeting = "Hello from cfdump";
  variables.counter  = 42;
</cfscript>

<cfdump var="#variables#" label="variables scope">
<cfdump var="#url#"       label="url scope">
EOF
```

::details-box
---
:summary: ✏️ Using the IDE tab instead? Create the file here
---
In the **IDE tab**, right-click in the Explorer panel → **New File** → name it `cfdump_demo.cfm`, paste the content below, and save with **Ctrl+S**:

```cfml
<cfscript>
  variables.greeting = "Hello from cfdump";
  variables.counter  = 42;
</cfscript>

<cfdump var="#variables#" label="variables scope">
<cfdump var="#url#"       label="url scope">
```
::

Open `/cfdump_demo.cfm` in the **ColdFusion 2025** browser tab to see the rendered dump tables. Or confirm from the Terminal that the response contains the expected variable names:

```bash
curl -s http://localhost:8500/student/cfdump_demo.cfm | grep -i "greeting"
# Expected: a line containing "greeting"
```

::image-box
---
:src: __static__/cfdump-v1.png
:alt: Browser window showing the rendered output of cfdump_demo.cfm — two colour-coded HTML tables produced by cfdump: the first labelled "variables scope" with rows for greeting (Hello from cfdump) and counter (42), the second labelled "url scope" showing an empty struct
:max-width: 860px
---
_`<cfdump>` renders each scope as a formatted table — instantly shows every variable name and value at runtime._
::

::simple-task
---
:tasks: tasks
:name: verify_cfdump
---
#active
Create `cfdump_demo.cfm` — the response must contain the word **greeting** (dumped from the `variables` scope).

#completed
`cfdump_demo.cfm` dumps the variables scope correctly. ✓
::

---

## Regionalization & locale-aware output

ColdFusion has two sets of formatting functions:

| Function | Behaviour |
|---|---|
| `dateFormat()`, `numberFormat()`, `dollarFormat()` | Fixed US English output — always the same regardless of server locale |
| `lsDateFormat()`, `lsNumberFormat()`, `lsCurrencyFormat()` | **Locale-sensitive** — output adapts to the active locale |

The `ls` prefix stands for **locale-specific**. Switch the locale for a request with `setLocale()` and read it back with `getLocale()`. The locale only applies for the duration of the current request — it does not persist to the next one.

```cfml
// Set the locale for this request
setLocale("German (Standard)");

price  = 1234567.89;
today  = now();

writeOutput(lsNumberFormat(price)   & "<br>"); // 1.234.567,89
writeOutput(lsCurrencyFormat(price) & "<br>"); // 1.234.567,89 €
writeOutput(lsDateFormat(today, "long") & "<br>"); // e.g. 3. September 2026
```

Common locale strings accepted by `setLocale()`:

| Locale string | Region |
|---|---|
| `English (US)` | United States |
| `English (UK)` | United Kingdom |
| `German (Standard)` | Germany |
| `French (Standard)` | France |
| `Spanish (Standard)` | Spain |
| `Portuguese (Brazilian)` | Brazil |
| `Japanese` | Japan |
| `Chinese (China)` | Simplified Chinese |

> **Gotcha:** `setLocale()` accepts the locale display name as a string, not an IETF tag like `en-US`. Use `getLocaleInfo()` to inspect the full list of locales available on the running JVM.

**Activity:** Create `locale_demo.cfm` to compare the same number and date formatted in three different locales side by side.

**Terminal tab:**

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/student/locale_demo.cfm << 'EOF'
<cfscript>
  price = 1234567.89;
  today = now();

  locales = [
    "English (US)",
    "German (Standard)",
    "French (Standard)"
  ];

  for (loc in locales) {
    setLocale(loc);
    writeOutput("<strong>" & loc & "</strong><br>");
    writeOutput("&nbsp;&nbsp;Number:   " & lsNumberFormat(price)          & "<br>");
    writeOutput("&nbsp;&nbsp;Currency: " & lsCurrencyFormat(price)        & "<br>");
    writeOutput("&nbsp;&nbsp;Date:     " & lsDateFormat(today, "long")    & "<br><br>");
  }
</cfscript>
EOF
```

::details-box
---
:summary: ✏️ Using the IDE tab instead? Create the file here
---
In the **IDE tab**, right-click in the Explorer panel → **New File** → name it `locale_demo.cfm`, paste the content below, and save with **Ctrl+S**:

```cfml
<cfscript>
  price = 1234567.89;
  today = now();

  locales = [
    "English (US)",
    "German (Standard)",
    "French (Standard)"
  ];

  for (loc in locales) {
    setLocale(loc);
    writeOutput("<strong>" & loc & "</strong><br>");
    writeOutput("&nbsp;&nbsp;Number:   " & lsNumberFormat(price)          & "<br>");
    writeOutput("&nbsp;&nbsp;Currency: " & lsCurrencyFormat(price)        & "<br>");
    writeOutput("&nbsp;&nbsp;Date:     " & lsDateFormat(today, "long")    & "<br><br>");
  }
</cfscript>
```
::

Open `/locale_demo.cfm` in the **ColdFusion 2025** browser tab, or from the Terminal:

```bash
curl -s http://localhost:8500/student/locale_demo.cfm
```

You should see three blocks — each showing the same number and date formatted differently:

```
English (US)
  Number:   1,234,567.89
  Currency: $1,234,567.89
  Date:     September 3, 2026

German (Standard)
  Number:   1.234.567,89
  Currency: 1.234.567,89 €
  Date:     3. September 2026

French (Standard)
  Number:   1 234 567,89
  Currency: 1 234 567,89 €
  Date:     3 septembre 2026
```

::simple-task
---
:tasks: tasks
:name: verify_locale_demo
---
#active
Create `locale_demo.cfm` — the response must contain **German (Standard)** and a comma-formatted number.

#completed
`locale_demo.cfm` renders locale-aware output correctly. ✓
::

---

::hint-box
---
:summary: 💡 Need to edit a file? The IDE is the easiest option
---

The simplest way to edit any file is to open the **IDE tab** — the file is already visible in the Explorer panel, just click it, make your changes, and save with **Ctrl+S**.

If you prefer to stay in the **Terminal**, you can also use `vi` — but be aware it has a steep learning curve if you haven't used it before. It is completely optional:

```bash
vi /opt/coldfusion2025/cfusion/wwwroot/student/scopes.cfm
```

| Key | What it does |
|---|---|
| `i` | Enter insert mode |
| `Esc` | Back to normal mode |
| `:wq` + Enter | Save and quit |
| `:q!` + Enter | Quit without saving |

If `vi` feels unfamiliar, stick with the IDE tab — it is always the safer choice.

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

::image-box
---
:src: __static__/cfdump-response-v1.png
:alt: Terminal window showing the curl response from cfdump_demo.cfm — raw HTML output containing the cfdump table markup with the greeting variable value visible in the response body
:max-width: 860px
---
_The raw `curl` response from `cfdump_demo.cfm` — the `greeting` variable is visible in the output, confirming the dump ran correctly._
::
