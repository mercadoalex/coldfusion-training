---
kind: unit

title: Unit 1 Challenge — Solution Review

name: unit1-challenge-review-unit-1
---

This lesson walks through the complete solution to the Unit 1 Challenge. Read it only after you have made a genuine attempt — the explanations are most useful when you have already wrestled with the problem yourself.

---

## What you built

Three files working together as a self-contained ColdFusion application:

| File | Responsibility |
|---|---|
| `Application.cfc` | Application lifecycle — boots the app, starts sessions |
| `PortfolioService.cfc` | OOP service layer — encapsulates data and logic |
| `index.cfm` | Presentation layer — renders HTML, reads from scopes |

---

## `Application.cfc` — annotated

```cfml
component {
  this.name              = "Unit1Challenge";  // (1)
  this.sessionManagement = true;              // (2)
  this.sessionTimeout    = createTimeSpan(0, 0, 30, 0); // (3)

  public void function onApplicationStart() {
    application.launchTime = now();           // (4)
  }

  public void function onSessionStart() {
    session.visitCount = 0;                   // (5)
  }
}
```

**(1) `this.name`** — uniquely identifies this application on the server. ColdFusion uses this name to scope the `application` variable separately from other apps running on the same engine. Without it CF generates a name from the directory path, which is fragile.

**(2) `this.sessionManagement = true`** — enables the `session` scope. Without this, `session.*` variables silently fail or throw errors depending on the CF version.

**(3) `createTimeSpan(0, 0, 30, 0)`** — sets the session timeout to 30 minutes (days, hours, minutes, seconds). This is the standard default for most applications.

**(4) `application.launchTime = now()`** — fires once when the application first boots or is restarted. Stored in the `application` scope so every subsequent request can read it — it persists for the lifetime of the running application.

**(5) `session.visitCount = 0`** — fires once per new user session. Initialising to zero here means `index.cfm` can increment it safely on every request without a `structKeyExists` guard in `onSessionStart`. The guard in `index.cfm` is a belt-and-suspenders defence in case the session was started before this code was deployed.

---

## `PortfolioService.cfc` — annotated

```cfml
component {

  public PortfolioService function init(required string authorName) { // (1)
    variables.authorName = arguments.authorName;                      // (2)
    return this;                                                       // (3)
  }

  public array function getProjects() {
    return [                                                           // (4)
      { title: "Help Desk App",   description: "Ticket management system in CFML", type: "web"  },
      { title: "REST API",        description: "JSON REST API with cfhttp",         type: "api"  },
      { title: "ORM Entity Demo", description: "Hibernate ORM with Ticket.cfc",     type: "data" }
    ];
  }

  public string function getSummary() {
    var sb = createObject("java", "java.lang.StringBuilder").init(""); // (5)
    sb.append("Portfolio by ");
    sb.append(variables.authorName);                                   // (6)
    sb.append(" — ");
    sb.append(arrayLen(getProjects()));                                // (7)
    sb.append(" projects");
    return sb.toString();                                              // (8)
  }

}
```

**(1) Constructor return type matches the component name** — `public PortfolioService function init(...)` — this is the ColdFusion convention. The return type tells callers what `new PortfolioService()` gives them back.

**(2) `variables.authorName = arguments.authorName`** — stores the constructor argument in the `variables` scope, which is the instance scope inside a CFC. This makes `authorName` available to all methods without passing it as an argument every time.

**(3) `return this`** — required in ColdFusion constructors. Without it, `new PortfolioService("...")` returns `null` instead of the component instance.

**(4) Array literal return** — `[ {...}, {...} ]` is a CFML array literal containing struct literals. No database needed here — hardcoded data is perfectly valid for a portfolio. In a real app this would call `queryExecute()` against a datasource.

**(5) `createObject("java", "java.lang.StringBuilder").init("")`** — instantiates Java's `StringBuilder` class directly from CFML. The `.init("")` call runs the Java constructor with an empty string. This is the Java interop pattern from Lesson 5 — Activity 5.

**(6) `variables.authorName`** — because `getSummary()` is a method on the same instance, it can read `variables.*` values set by the constructor.

**(7) `arrayLen(getProjects())`** — calls the sibling method directly by name. Inside a CFC, methods can call each other without `this.` or any prefix — they resolve through the `variables` scope chain.

**(8) `sb.toString()`** — converts the Java `StringBuilder` object back to a CFML string. Always required — CF will not auto-convert a Java object to a string in output contexts.

---

## `index.cfm` — annotated

```cfml
<!DOCTYPE html>                                                         <!-- (1) -->
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Unit 1 Challenge — Portfolio</title>
  <style>...</style>
</head>
<body>
<cfscript>
  session.visitCount = (structKeyExists(session, "visitCount")          // (2)
    ? session.visitCount : 0) + 1;
  svc      = new PortfolioService("ColdFusion Student");                // (3)
  projects = svc.getProjects();
  summary  = svc.getSummary();
</cfscript>

<h1>ColdFusion Portfolio</h1>
<p class="meta">
  <cfoutput>
    Summary: #encodeForHTML(summary)# &nbsp;·&nbsp;                     <!-- (4) -->
    Launched: #dateTimeFormat(application.launchTime, "dd-mmm-yyyy HH:nn")# &nbsp;·&nbsp; <!-- (5) -->
    Visits this session: #session.visitCount#                           <!-- (6) -->
  </cfoutput>
</p>

<cfoutput>
  <cfloop array="#projects#" index="p">                                 <!-- (7) -->
    <div class="card">
      <strong>#encodeForHTML(p.title)#</strong> — #encodeForHTML(p.description)#
      <span style="color:#64748b;font-size:.8rem">[#encodeForHTML(p.type)#]</span>
    </div>
  </cfloop>
</cfoutput>

<script>
  var projects = <cfoutput>#serializeJSON(projects)#</cfoutput>;        <!-- (8) -->
  console.log("Projects loaded:", projects);
</script>

<audio controls style="margin-top:1.5rem">                             <!-- (9) -->
  <source src="https://www.w3schools.com/html/horse.mp3" type="audio/mpeg">
  Your browser does not support the audio element.
</audio>

</body>
</html>
```

**(1) `<!DOCTYPE html>`** — the HTML5 doctype. The task checker verifies this exact string. Always required on modern HTML pages — without it browsers fall into quirks mode.

**(2) Visit counter guard** — `structKeyExists(session, "visitCount")` handles the edge case where the session existed before `Application.cfc` defined `onSessionStart`. The ternary returns `0` as a fallback, then `+ 1` increments it. On every page load, the counter grows by one.

**(3) `new PortfolioService("ColdFusion Student")`** — instantiates the CFC using the modern `new` syntax. The string argument is passed to `init(required string authorName)`. The CFC file must be in the same directory (`unit1challenge/`) for CF to resolve it by name without a full path.

**(4) `encodeForHTML(summary)`** — wraps all dynamic output in `encodeForHTML()` to prevent XSS. Even though this is hardcoded data, the habit of always encoding output is correct practice. The task checker also validates that dynamic output is present.

**(5) `application.launchTime`** — reads directly from the `application` scope, which was populated by `onApplicationStart()` when the app first booted. `dateTimeFormat()` formats the timestamp using the mask `"dd-mmm-yyyy HH:nn"`.

**(6) `session.visitCount`** — reads from the `session` scope, which is per-user and per-browser. Reload the page and watch the counter increment. Open a new browser and it starts from 1 again.

**(7) `<cfloop array="#projects#" index="p">`** — iterates the array returned by `getProjects()`. Inside the loop, `p` is each struct. `p.title`, `p.description`, and `p.type` access the struct keys — case-insensitive in CFML.

**(8) `serializeJSON(projects)`** — converts the CFML array of structs to a JSON string and injects it into a JavaScript variable. This is the bridge between server-side CF data and client-side JS. The `<cfoutput>` tags are needed because `#...#` expressions only evaluate inside `cfoutput` blocks.

**(9) `<audio controls>`** — satisfies the HTML5 media element requirement. The `controls` attribute renders the native browser audio player. The `<source>` fallback chain lets the browser pick the best format it supports.

---

## What this challenge tested

| Concept | Where it appeared |
|---|---|
| Application lifecycle | `Application.cfc` — `this.*` settings, `onApplicationStart`, `onSessionStart` |
| Variable scopes | `application.launchTime`, `session.visitCount`, `variables.authorName` |
| OOP with CFCs | `PortfolioService` — constructor, instance scope, public methods |
| Java interop | `createObject("java", "java.lang.StringBuilder")` in `getSummary()` |
| HTML5 | `<!DOCTYPE html>`, `<audio controls>` |
| Security | `encodeForHTML()` on all dynamic output |
| Data serialisation | `serializeJSON()` to pass CF data to JavaScript |

---

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
Read through the review and hit **Check** when you are done.

#completed
Unit 1 complete — well done! You have finished all seven lessons and the challenge. On to Module 2.
::
