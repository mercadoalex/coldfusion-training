---
kind: unit

title: ORM Relationships — One-to-Many, Many-to-One, and Beyond

name: orm-relationships-unit-1
---

## Why relationships matter in ORM

In a relational database, tables are linked via **foreign keys**. In an object model, the same connections are expressed as **associations** — one object holds a reference (or a collection of references) to another.

ColdFusion Hibernate ORM lets you declare those associations directly on `cfproperty` using the `fieldtype` attribute. Once declared, Hibernate manages the SQL JOINs, lazy loading, and cascaded saves/deletes automatically.

::details-box
---
:summary: Key concepts — source, target, direction, and multiplicity
---

Before writing any code it helps to understand the vocabulary:

| Term | Meaning |
|---|---|
| **Source object** | The object that holds the reference to the related object |
| **Target object** | The object being referred to |
| **Unidirectional** | Only the source knows about the target; the target has no reference back |
| **Bidirectional** | Both objects hold a reference to each other |
| **Multiplicity** | How many objects can be on each side — one-to-one, one-to-many, many-to-one, many-to-many |

**Bidirectional example — Person and Address:**

```cfml
// Make the association bidirectional
person.setAddress(address);   // person → address (unidirectional so far)
address.setPerson(person);    // address → person (now bidirectional)
```

In a bidirectional relationship one side must set `inverse="true"` to avoid Hibernate writing the relationship twice to the database (see the Inverse section below).

::

---

## The four relationship types

Set `fieldtype` on `cfproperty` to one of:

| fieldtype | When to use |
|---|---|
| `one-to-one` | Each source has exactly one target, and vice-versa |
| `one-to-many` | One source has many targets (source holds a collection) |
| `many-to-one` | Many sources reference the same target (foreign key on source table) |
| `many-to-many` | Both sides hold collections — requires a link table |

---

## One-to-one relationships

A one-to-one relationship means the source object has one, and only one, associated target object.

**Example:** An `Employee` has one `OfficeCubicle`.

There are two variants:

### Primary key association

Both tables share the same primary key. The dependent table's PK is a foreign key to the primary table's PK.

```cfml
// Employee.cfc
component persistent="true" table="Employee" {
  property name="id"             fieldtype="id"       generator="native";
  property name="firstname";
  property name="lastname";
  property name="officecubicle"  fieldtype="one-to-one" cfc="OfficeCubicle";
}
```

```cfml
// OfficeCubicle.cfc  — PK is a foreign key to Employee.id
component persistent="true" table="OfficeCubicle" {
  property name="id"       fieldtype="id"       generator="foreign"
                           params="{property='Employee'}" ormtype="int";
  property name="Employee" fieldtype="one-to-one" cfc="Employee" constrained="true";
  property name="Location";
  property name="Size";
}
```

`constrained="true"` on the `OfficeCubicle` side means the OfficeCubicle table's PK has a foreign-key constraint referencing the Employee PK. `generator="foreign"` tells Hibernate to copy the PK value from the related `Employee` object rather than generating a new one.

### Unique foreign key association

The dependent table has its own auto-generated PK plus a unique foreign key column pointing to the other table.

```cfml
// Employee.cfc — the "mappedby" side
component persistent="true" table="Employee" {
  property name="EmployeeID"    fieldtype="id"       generator="native";
  property name="firstname";
  property name="lastname";
  property name="officecubicle" fieldtype="one-to-one" cfc="OfficeCubicle"
                                mappedby="Employee";
}
```

```cfml
// OfficeCubicle.cfc — holds the FK column
component persistent="true" table="OfficeCubicle" {
  property name="id"       fieldtype="id"       generator="native";
  property name="Employee" fieldtype="one-to-one" cfc="Employee"
                           fkcolumn="EmployeeID";
  property name="Location";
  property name="Size";
}
```

`fkcolumn="EmployeeID"` identifies the foreign key column in `OfficeCubicle`. The `Employee` side uses `mappedby="Employee"` to point back to that property — `fkcolumn` must **not** be specified on the `mappedby` side.

---

## One-to-many relationships

A one-to-many relationship means one source object is associated with a **collection** of target objects. The foreign key lives in the **target** table and points back to the source.

**Example:** One `Artist` has many `Art` pieces.

ColdFusion supports the collection as either an **array** or a **struct**.

### Array collection

```cfml
// Artist.cfc
component persistent="true" table="Artists" {
  property name="id"   fieldtype="id" generator="native";
  property name="name";
  property name="art"  fieldtype="one-to-many" cfc="Art"
                       fkcolumn="ARTISTID" type="array";
}
```

```cfml
// Art.cfc
component persistent="true" table="Art" {
  property name="id"       fieldtype="id"      generator="native";
  property name="title";
  property name="issold"   ormtype="boolean";
  property name="artist"   fieldtype="many-to-one" cfc="Artist"
                           fkcolumn="ARTISTID";
}
```

- `fkcolumn="ARTISTID"` — the foreign key column in the `Art` table that references `Artists.id`
- `type="array"` — the `artist.getArt()` method returns an array of `Art` objects

### Struct collection

```cfml
property name="art" fieldtype="one-to-many" cfc="Art" fkcolumn="ARTISTID"
         type="struct" structkeycolumn="ArtID" structkeytype="int";
```

`structkeycolumn` specifies which column in the target table to use as the struct key.

### Filtering the collection

Use the `where` attribute to load only a subset of associated objects:

```cfml
// Only unsold artwork for this artist
property name="unsoldArts" cfc="Art" fieldtype="one-to-many"
         fkcolumn="ARTISTID" where="issold=0";
```

::hint-box
---
:summary: Lazy loading — collections are not loaded until accessed
---

By default (`lazy="true"`), Hibernate does **not** hit the database when you load an `Artist`. The `Art` collection is fetched only when you call `artist.getArt()` for the first time. This avoids loading large collections you may not need.

Set `lazy="false"` to load the collection immediately with a JOIN — useful when you always need the related objects and want to avoid the extra query.

Set `lazy="extra"` for very large collections — individual items are loaded on demand rather than all at once.

::

---

## Many-to-one relationships

A many-to-one relationship is the inverse of one-to-many. Many source objects reference the same target object. The foreign key lives in the **source** table.

**Example:** Many `Art` pieces belong to one `Artist`.

```cfml
// Art.cfc
component persistent="true" table="Art" {
  property name="id"     fieldtype="id"       generator="native";
  property name="title";
  property name="artist" fieldtype="many-to-one" cfc="Artist"
                         fkcolumn="ARTISTID";
}
```

`fkcolumn="ARTISTID"` is the column in the `Art` table that holds the foreign key to `Artists`.

In practice, **many-to-one and one-to-many are two sides of the same relationship**. Declare `many-to-one` on the child (the table holding the FK) and `one-to-many` on the parent (the table whose PK is referenced).

---

## Many-to-many relationships

A many-to-many relationship means both sides hold collections of each other. It requires a **link table** containing foreign keys to both participating tables.

**Example:** An `Order` has many `Product` objects, and a `Product` appears in many `Order` objects. The link table `Order_Product` holds `(orderId, productId)` pairs.

```cfml
// Order.cfc
component persistent="true" table="Orders" {
  property name="id"       fieldtype="id" generator="native";
  property name="products" fieldtype="many-to-many" cfc="Product"
                           linktable="Order_Product"
                           fkcolumn="orderId"
                           inversejoincolumn="productId"
                           cascade="all"
                           lazy="true"
                           orderby="productId";
}
```

```cfml
// Product.cfc
component persistent="true" table="Products" {
  property name="id"     fieldtype="id" generator="native";
  property name="name";
  property name="orders" fieldtype="many-to-many" cfc="Order"
                         linktable="Order_Product"
                         fkcolumn="productId"
                         inversejoincolumn="orderId"
                         cascade="all"
                         lazy="true"
                         orderby="orderId";
}
```

- `linktable` — name of the join table
- `fkcolumn` — foreign key in the link table pointing to **this** entity's PK
- `inversejoincolumn` — foreign key in the link table pointing to the **other** entity's PK

::details-box
---
:summary: Relationship attributes reference table
---

| Attribute | Applies to | Default | Description |
|---|---|---|---|
| `cfc` | all | — | **Required.** Name of the associated CFC |
| `fieldtype` | all | `column` | **Required.** Relationship type: `one-to-one`, `one-to-many`, `many-to-one`, `many-to-many` |
| `fkcolumn` | all | auto | Foreign key column name |
| `inversejoincolumn` | all | auto | FK column in the link table pointing to the target PK |
| `linktable` | all | — | Name of the link table (many-to-many) |
| `cascade` | all | — | Cascade behaviour — see Cascade options below |
| `lazy` | all | `true` | `true`, `false`, or `extra` (one-to-many/many-to-many) |
| `fetch` | all | `select` | `join` or `select` — how related objects are loaded |
| `inverse` | one-to-many, many-to-many | `false` | Suppress SQL for this side of a bidirectional relationship |
| `mappedby` | all | — | Property name in the referenced CFC whose FK column drives this side |
| `type` | one-to-many, many-to-many | `array` | Collection type: `array` or `struct` |
| `orderby` | one-to-many, many-to-many | — | SQL ORDER BY string for the collection |
| `where` | one-to-many, many-to-many | — | SQL WHERE filter applied when loading the collection |
| `constrained` | one-to-one | `false` | Add a FK constraint on this table's PK referencing the other table |
| `batchsize` | one-to-many, many-to-many | — | Number of collections loaded at once when lazy-loading |

::

---

## Cascade options

Cascade tells Hibernate to automatically apply an operation performed on the **parent** to its **children**.

| Value | What it does |
|---|---|
| `all` | Cascade every operation (save, update, delete, refresh) to child objects |
| `save-update` | Save/update child objects when the parent is saved |
| `delete` | Delete child objects when the parent is deleted |
| `delete-orphan` | Delete children whose association has been removed (one-to-many only) |
| `all-delete-orphan` | `all` + `delete-orphan` — the most common choice for owned collections |
| `refresh` | Cascade the `refresh` action — reloads the child from the database |

```cfml
// Artist owns its Art — deleting the artist removes all art pieces
property name="art" fieldtype="one-to-many" cfc="Art" fkcolumn="ARTISTID"
         cascade="all-delete-orphan";
```

**Rules of thumb:**
- For owned one-to-many collections: use `all-delete-orphan`
- When children can exist independently (e.g. tags shared across many records): use `save-update`
- Avoid `cascade` on `many-to-one` and `many-to-many` — it can cause unintended deletes

---

## Inverse

In a **bidirectional** relationship both sides reference each other. Without `inverse`, Hibernate would issue SQL to persist the association **twice** — once from each side. Use `inverse="true"` on one side to tell Hibernate to ignore that side when generating SQL.

**Rule:** Set `inverse="true"` on the **one-to-many** side (the parent's collection property). The **many-to-one** side (the child that holds the FK column) is the authoritative side.

```cfml
// Artist.cfc — parent — set inverse here
property name="art" fieldtype="one-to-many" cfc="Art"
         fkcolumn="ARTISTID" inverse="true" cascade="all-delete-orphan";
```

```cfml
// Art.cfc — child — owns the FK column, so this side persists the link
property name="artist" fieldtype="many-to-one" cfc="Artist"
         fkcolumn="ARTISTID";
```

For many-to-many relationships, set `inverse="true"` on either side — just pick one consistently.

---

## Activity 1 — Define a one-to-many relationship

**Activity:** Create `Category.cfc` and update `Ticket.cfc` so that each category has many tickets and each ticket belongs to one category.

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/Category.cfc << 'EOF'
component persistent="true" table="hd_categories" {

  property name="id"      fieldtype="id"       generator="native";
  property name="name"    ormtype="string";
  property name="tickets" fieldtype="one-to-many" cfc="Ticket"
                          fkcolumn="category_id" type="array"
                          cascade="all-delete-orphan" inverse="true";

}
EOF
```

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/Ticket.cfc << 'EOF'
component persistent="true" table="hd_tickets" {

  property name="id"          fieldtype="id"         generator="native";
  property name="title"       ormtype="string";
  property name="description" ormtype="string";
  property name="status"      ormtype="string"       default="open";
  property name="priority"    ormtype="string"       default="medium";
  property name="category"    fieldtype="many-to-one" cfc="Category"
                              fkcolumn="category_id";

}
EOF
```

Verify the relationship fieldtype is present:

```bash
grep -h "fieldtype" /opt/coldfusion2025/cfusion/wwwroot/Category.cfc \
                    /opt/coldfusion2025/cfusion/wwwroot/Ticket.cfc
```

::image-box
---
:src: __static__/terminal-orm-relationship-cfcs-v1.png
:alt: Terminal showing Category.cfc and Ticket.cfc being written with tee, followed by grep confirming fieldtype="one-to-many" in Category.cfc and fieldtype="many-to-one" in Ticket.cfc
:max-width: 860px
---
_`Category.cfc` owns the collection; `Ticket.cfc` holds the foreign key column `category_id`._
::

::simple-task
---
:tasks: tasks
:name: verify_orm_relationship_cfcs
---
#active
Run both `sudo tee` commands above to create `Category.cfc` and update `Ticket.cfc` with the relationship `fieldtype` attributes.

#completed
ORM relationship CFCs are in place. ✓
::

---

## Activity 2 — Test the relationship with a CFM page

**Activity:** Create `orm_rel_test.cfm` to reload ORM, create a category, add a ticket to it, and read the relationship back:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/orm_rel_test.cfm << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ORM Relationship Test</title>
  <style>
    body  { font-family: sans-serif; max-width: 820px; margin: 2rem auto; }
    .box  { padding: 1rem; background: #f0f4ff; border-left: 4px solid #3b82d4; margin: 1rem 0; }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th    { background: #3b82d4; color: #fff; padding: .5rem .75rem; text-align: left; }
    td    { padding: .45rem .75rem; border-bottom: 1px solid #e5e7eb; }
  </style>
</head>
<body>
  <h1>ORM Relationship Test</h1>

  <cfscript>
    ORMReload();

    // Create a Category and a Ticket linked to it
    cat = EntityNew("Category");
    cat.setName("Hardware");
    EntitySave(cat);

    t = EntityNew("Ticket");
    t.setTitle("Monitor flickering");
    t.setStatus("open");
    t.setPriority("high");
    t.setCategory(cat);
    EntitySave(t);

    ORMFlush();

    // Navigate the many-to-one: ticket → category
    loaded = EntityLoadByPK("Ticket", t.getId());
    catName = loaded.getCategory().getName();

    // Navigate the one-to-many: category → tickets
    tickets = EntityLoad("Ticket");
  </cfscript>

  <div class="box">
    <strong>Ticket category (many-to-one):</strong>
    <cfoutput>#encodeForHTML(catName)#</cfoutput>
  </div>

  <h2>All Tickets</h2>
  <table>
    <tr><th>ID</th><th>Title</th><th>Priority</th><th>Category</th></tr>
    <cfoutput>
      <cfloop array="#tickets#" index="tk">
        <tr>
          <td>#tk.getId()#</td>
          <td>#encodeForHTML(tk.getTitle())#</td>
          <td>#encodeForHTML(tk.getPriority())#</td>
          <td>
            <cfif isObject(tk.getCategory())>
              #encodeForHTML(tk.getCategory().getName())#
            <cfelse>
              —
            </cfif>
          </td>
        </tr>
      </cfloop>
    </cfoutput>
  </table>

</body>
</html>
EOF
```

Open `/orm_rel_test.cfm` in the **ColdFusion 2025** browser tab. You should see the ticket's category name loaded via the many-to-one association, and the full ticket list with their categories.

```bash
curl -s http://localhost:8500/orm_rel_test.cfm | grep -i "hardware"
```

::image-box
---
:src: __static__/browser-orm-rel-test-v1.png
:alt: Browser showing orm_rel_test.cfm with a blue result box displaying "Ticket category (many-to-one): Hardware" and a table below listing tickets with their ID, title, priority, and resolved category name
:max-width: 860px
---
_`orm_rel_test.cfm` — the many-to-one association navigated in both directions: ticket → category and category name resolved without a manual JOIN._
::

::simple-task
---
:tasks: tasks
:name: verify_relationship_page
---
#active
Run the `sudo tee` command above to create `orm_rel_test.cfm`, then open `/orm_rel_test.cfm` in the browser to confirm the relationship loads without errors.

#completed
`orm_rel_test.cfm` runs without errors — ORM relationships are working. ✓
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
