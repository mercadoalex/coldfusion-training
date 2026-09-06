---
kind: unit

title: Object-Oriented Programming with CFCs

name: oop-coldfusion-components-unit-1
---

## Is ColdFusion object-oriented?

Yes — fully. ColdFusion supports classes, properties, methods, inheritance, interfaces, and access modifiers. The building block is a **CFC** (ColdFusion Component) — a `.cfc` file that defines a reusable object.

| OOP concept | ColdFusion implementation |
|---|---|
| **Class** | CFC file (`.cfc`) — `component { }` |
| **Instantiation** | `new TicketService()` or `createObject("component", "TicketService")` |
| **Properties** | `property name="title" type="string"` |
| **Methods** | `public string function getName() { }` |
| **Inheritance** | `component extends="BaseService" { }` |
| **Interfaces** | `component implements="IService" { }` |
| **Access modifiers** | `public`, `private`, `package`, `remote` |
| **Constructor** | `function init() { return this; }` |

CF is **not** purely OOP — you can write procedural `.cfm` pages with no components at all. But for any serious application, CFCs are the standard pattern.

::image-box
---
:src: __static__/cfc-anatomy-overview-v1.png
:alt: Annotated diagram of a ColdFusion Component file — the component declaration at the top is labelled "class definition", property declarations are labelled "instance properties with type hints", the init() function is labelled "constructor — returns this", a public function is labelled "public method", and a private function is labelled "private helper — not accessible from outside"
:max-width: 860px
---
_Anatomy of a CFC — one file defines the class, its properties, and all its methods._
::

---

## CFC anatomy

```cfml
// TicketService.cfc
component displayname="TicketService" hint="Manages help desk tickets" {

  // Properties (optional — document the object's state)
  property name="datasource" type="string" default="training_db";

  // Constructor
  public TicketService function init(string datasource = "training_db") {
    variables.datasource = arguments.datasource;
    return this;
  }

  // Public method
  public array function getAll() {
    var q = queryExecute(
      "SELECT id, title, status, priority FROM hd_tickets ORDER BY id DESC",
      {}, { datasource: variables.datasource }
    );
    return queryToArray(q);
  }

  // Public method with argument
  public struct function getById(required numeric id) {
    var q = queryExecute(
      "SELECT id, title, status, priority, description FROM hd_tickets WHERE id = :id",
      { id: { value: arguments.id, cfsqltype: "cf_sql_integer" } },
      { datasource: variables.datasource }
    );
    if (q.recordCount == 0) { return {}; }
    return queryToArray(q)[1];
  }

  // Private helper — not callable from outside
  private boolean function isValidPriority(required string priority) {
    return listFind("low,medium,high,critical", arguments.priority) GT 0;
  }

}
```

---

## Access modifiers

| Modifier | Accessible from |
|---|---|
| `public` | Anywhere — other CFCs, `.cfm` pages, remote callers |
| `private` | Inside this CFC only |
| `package` | This CFC and CFCs in the same directory |
| `remote` | Public **plus** exposed as a web service (REST or SOAP) |

The `remote` modifier is unique to ColdFusion — it turns any method into an automatic web service endpoint with no extra configuration.

---

## Instantiation

```cfml
// Modern syntax (preferred)
svc = new TicketService();

// With constructor argument
svc = new TicketService(datasource="training_db");

// Equivalent older syntax
svc = createObject("component", "TicketService").init();

// Call a method
tickets = svc.getAll();
ticket  = svc.getById(3);
```

::image-box
---
:src: __static__/cfc-instantiation-methods-v1.png
:alt: Side-by-side comparison showing two equivalent ways to instantiate a CFC — left panel shows "new TicketService()" modern syntax with a green "preferred" badge; right panel shows "createObject('component','TicketService').init()" legacy syntax with a grey "still valid" badge — an equals sign between them shows they produce the same result
:max-width: 860px
---
_`new TicketService()` and `createObject("component","TicketService").init()` are identical — prefer the `new` syntax._
::

---

## Inheritance

```cfml
// BaseService.cfc
component {
  public string function getTimestamp() {
    return dateTimeFormat(now(), "iso8601");
  }
}

// TicketService.cfc — inherits getTimestamp()
component extends="BaseService" {
  public array function getAll() {
    // ... query logic
  }
}

// Usage
svc = new TicketService();
svc.getAll();          // defined in TicketService
svc.getTimestamp();    // inherited from BaseService
```

Use `super.methodName()` to call the parent's version of an overridden method.

---

## The `variables` scope inside a CFC

Inside a CFC, `variables.*` is the **instance scope** — shared across all methods of the same instance, but private to that instance. It is the equivalent of instance fields in Java.

```cfml
component {
  public function init() {
    variables.createdAt = now();  // instance field
    return this;
  }

  public function getAge() {
    return dateDiff("s", variables.createdAt, now()) & " seconds old";
  }
}
```

> **Gotcha:** Always use `var` for local variables inside functions. Without `var`, the variable bleeds into the `variables` scope and is shared across method calls — a classic CF concurrency bug.

```cfml
public array function getAll() {
  var q = queryExecute(...);  // local — correct
  // NOT: q = queryExecute(...)  ← would be variables.q — shared!
  return queryToArray(q);
}
```

---

## Calling Java from a CFC

Because ColdFusion runs on the JVM, you can instantiate any Java class:

```cfml
// Use Java's UUID generator
uuid = createObject("java", "java.util.UUID").randomUUID().toString();

// Use Java's StringBuilder
sb = createObject("java", "java.lang.StringBuilder").init();
sb.append("Hello");
sb.append(", World!");
writeOutput(sb.toString());
```

This is rarely needed for everyday CF work, but it means the entire Java ecosystem is available when you need it.

::hint-box
---
:summary: CFCs vs .cfm pages — when to use each?
---

**Use a `.cfm` page when:**
- You are rendering an HTTP response (a web page or an API endpoint)
- The logic is request-specific and not reused elsewhere
- You are doing a quick prototype or one-off script

**Use a `.cfc` component when:**
- You are writing reusable business logic (a service, a DAO, a utility)
- You want to unit-test the logic with TestBox
- You are building an ORM entity (`persistent="true"`)
- You are exposing a method as a web service (`access="remote"`)

**The practical rule:** keep your `.cfm` files thin — they receive the request, call a CFC service, and render the response. All real logic lives in CFCs.

::

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/TicketService.cfc` with:
   - An `init()` constructor
   - A `public` method `getAll()` that queries `hd_tickets`
   - A `private` helper method

2. Create `test_cfc.cfm` that instantiates it and calls `getAll()`:

```cfml
<cfscript>
  svc     = new TicketService();
  tickets = svc.getAll();
  writeDump(tickets);
</cfscript>
```

3. Verify:

```bash
curl -s http://localhost:8500/test_cfc.cfm | grep -vi "error\|exception"
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_cfc_exists
---
#active
Create at least one `.cfc` file in `/opt/coldfusion2025/cfusion/wwwroot/`.

#completed
CFC file found in the web root. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cfc_component
---
#active
The CFC must contain a `component` declaration.

#completed
`component` declaration found. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cfc_method
---
#active
The CFC must define at least one `function`.

#completed
Function defined in CFC. ✓
::

---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.scope-inspector-3260417b
---
::
