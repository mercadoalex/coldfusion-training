---
kind: unit

title: SQL Fundamentals — A Primer for ColdFusion Developers

name: sql-fundamentals-primer-unit-1
---

::hint-box
---
:summary: 💡 Already comfortable with SQL? Skip this lesson
---
This lesson is a primer for developers who are new to SQL or need a quick refresher. If you already know how to write `SELECT`, `INSERT`, `UPDATE`, and `DELETE` statements and understand `WHERE`, `ORDER BY`, and `JOIN`, you can skip straight to the next lesson — **SQL with cfquery & queryParam** — where you will apply SQL inside ColdFusion.
::

---

## What is SQL?

**Structured Query Language (SQL)** is the standard language for interacting with relational databases. Every database supported by ColdFusion — MySQL, PostgreSQL, Microsoft SQL Server, H2, Oracle — speaks SQL. All ColdFusion tags that access a database (`<cfquery>`, ORM, etc.) pass SQL statements directly to the database engine.

A **query** is a request to a database. It can:

- **Read** data from the database (`SELECT`)
- **Add** new data to the database (`INSERT`)
- **Change** existing data (`UPDATE`)
- **Remove** data (`DELETE`)

---

## SQL statements — the four verbs

| Verb | What it does |
|---|---|
| `SELECT` | Retrieves records from one or more tables |
| `INSERT` | Adds a new row to a table |
| `UPDATE` | Changes values in existing rows |
| `DELETE` | Removes rows from a table |

---

## 1. Reading data with SELECT

`SELECT` is the most commonly used SQL statement in ColdFusion. It reads data from a database and returns it as a record set — a table of rows and columns.

### Select all columns

```sql
SELECT * FROM employees
```

The `*` wildcard means "all columns". This returns every row and every column from the `employees` table.

### Filter rows with WHERE

```sql
SELECT * FROM employees WHERE DeptID = 3
```

Returns only the rows where `DeptID` equals `3`.

### Select specific columns

```sql
SELECT LastName, FirstName FROM employees WHERE DeptID = 3
```

Returns only the `LastName` and `FirstName` columns for rows matching the `WHERE` condition.

### Sort results with ORDER BY

By default a database does not guarantee the order of returned rows. Use `ORDER BY` to sort:

```sql
SELECT * FROM employees ORDER BY LastName
```

Sort by multiple columns — rows are sorted by the first column, then by the second within ties:

```sql
SELECT * FROM employees ORDER BY DepartmentID, LastName
```

Add `ASC` (ascending, default) or `DESC` (descending) after any column:

```sql
SELECT * FROM employees ORDER BY LastName DESC
```

### Combine conditions with AND / OR

```sql
SELECT * FROM employees WHERE DeptID = 3 AND Title = 'Engineer'
```

```sql
SELECT * FROM employees WHERE DeptID = 3 OR DeptID = 5
```

### Rename a column with AS

Useful when a column name conflicts with a ColdFusion reserved word, or when you want a friendlier output name:

```sql
SELECT EmpID, LastName, EQ AS MyEQ FROM employees
```

The result set will have a column named `MyEQ` instead of `EQ`.

::details-box
---
:summary: 📖 Full SELECT syntax
---

```sql
SELECT column_names
FROM table_names
[ WHERE search_condition ]
[ GROUP BY group_expression ] [ HAVING condition ]
[ ORDER BY order_condition [ ASC | DESC ] ]
```

Everything in `[ ]` is optional. The minimum valid `SELECT` statement is `SELECT column FROM table`.
::

---

## 2. Filtering with operators

The `WHERE` clause supports a rich set of operators:

| Operator | Description | Example |
|---|---|---|
| `=` | Equal to | `WHERE DeptID = 3` |
| `<>` | Not equal to | `WHERE Status <> 'closed'` |
| `<` | Less than | `WHERE Salary < 50000` |
| `>` | Greater than | `WHERE Salary > 100000` |
| `<=` | Less than or equal to | `WHERE Age <= 65` |
| `>=` | Greater than or equal to | `WHERE Age >= 18` |
| `AND` | Both conditions must be true | `WHERE DeptID = 3 AND Active = 1` |
| `OR` | At least one condition must be true | `WHERE DeptID = 3 OR DeptID = 5` |
| `NOT` | Exclude the condition | `WHERE NOT Status = 'closed'` |
| `LIKE` | Pattern match (`%` = wildcard) | `WHERE LastName LIKE 'Sm%'` |
| `IN` | Match against a list of values | `WHERE DeptID IN (1, 3, 5)` |
| `BETWEEN` | Match a range of values | `WHERE Salary BETWEEN 40000 AND 80000` |

---

## 3. Joining multiple tables

Real databases spread related data across multiple tables. You join them in a `SELECT` by matching shared columns:

```sql
SELECT LastName, FirstName, Street, City, State, Zip
FROM employees, addresses
WHERE employees.EmpID = addresses.EmpID
ORDER BY LastName, FirstName
```

When the same column name (`EmpID`) appears in both tables, prefix it with the table name to avoid ambiguity: `employees.EmpID`, `addresses.EmpID`.

The result is a single record set that combines columns from both tables. Notice that `EmpID` was used to link the tables but was not included in the output — you only select the columns you actually need.

---

## 4. Adding data with INSERT

```sql
INSERT INTO employees(EmpID, LastName, FirstName)
VALUES(51, 'Smith', 'John')
```

- **Column names** go in parentheses after the table name
- **Values** go in the same order inside `VALUES(...)`
- String values must be wrapped in **single quotes** — `'Smith'`
- Numeric values do not need quotes — `51`
- Columns omitted from the statement are set to `NULL`

::hint-box
---
:summary: ⚠️ NULL means no value — not zero, not empty string
---
`NULL` indicates the absence of a value. If a column does not allow `NULL` and you omit it from an `INSERT`, the database will throw an error. Always check whether a column is nullable before omitting it.
::

---

## 5. Updating data with UPDATE

```sql
UPDATE employees
SET Email = 'jsmith@mycompany.com'
WHERE EmpID = 51
```

- `SET` specifies the column(s) to change and their new values
- `WHERE` limits which rows are affected

::hint-box
---
:summary: ⚠️ Always include a WHERE clause on UPDATE
---
Omitting `WHERE` updates **every row** in the table:

```sql
-- This updates the Email for ALL employees — almost certainly not what you want
UPDATE employees SET Email = 'jsmith@mycompany.com'
```

Always double-check your `WHERE` clause before running an `UPDATE`.
::

---

## 6. Deleting data with DELETE

```sql
DELETE FROM employees WHERE EmpID = 51
```

Removes only the row where `EmpID` is `51`.

Without a `WHERE` clause:

```sql
-- Deletes EVERY row in the table
DELETE FROM employees
```

The same warning applies as with `UPDATE` — always include a `WHERE` clause unless you intentionally want to clear the whole table.

---

## 7. Transactions — wrapping multiple statements

A **transaction** groups multiple SQL statements into a single unit of work. If any statement fails, the entire transaction is rolled back — leaving the database unchanged. This is critical when related changes must either all succeed or all fail.

In ColdFusion, use the `<cftransaction>` tag:

```cfml
<cftransaction>

    <cfquery name="qInsertEmployee" datasource="myDB">
        INSERT INTO Employees (FirstName, LastName, Email, Phone, Department)
        VALUES ('Simon', 'Horwith', 'shorwith@co.com', '(202)-797-6570', 'R&D')
    </cfquery>

    <cfquery name="qGetNewID" datasource="myDB">
        SELECT MAX(Emp_ID) AS NewEmployee FROM Employees
    </cfquery>

</cftransaction>
```

If the `INSERT` succeeds but the `SELECT` fails, the entire block is rolled back and neither change is committed to the database.

---

## 8. Case sensitivity

ColdFusion itself is **case-insensitive** — `<cfset foo="bar">` and `<CFSET FOO="BAR">` are identical. SQL keywords (`SELECT`, `FROM`, `WHERE`) are also case-insensitive in most databases.

However, **table and column names** in the database may be case-sensitive depending on the database and operating system:

```sql
-- These may be two different tables on a case-sensitive database (e.g. Linux MySQL)
SELECT LastName FROM EMPLOYEES
SELECT LASTNAME FROM employees
```

Always match the exact case of your table and column names. Check your database documentation to confirm its case-sensitivity behaviour.

---

## 9. A note on SQL dialects

SQL is a standard (ANSI/ISO) but every database vendor adds its own extensions. ColdFusion does **not** validate SQL — it passes the statement directly to the database engine. This means you can use any syntax your database supports, including vendor-specific features, but the same query may not work on a different database.

::hint-box
---
:summary: 💡 Using ColdFusion variables in SQL — PreserveSingleQuotes
---
If you embed a ColdFusion variable in a SQL statement and that variable contains single quotes, wrap it in `PreserveSingleQuotes()` to prevent ColdFusion from interpreting them:

```cfml
<cfset cityList = "'San Francisco', 'San Diego', 'Oakland'">

<cfquery name="getCenters" datasource="myDB">
    SELECT Name, City FROM Centers
    WHERE City IN (#PreserveSingleQuotes(cityList)#)
</cfquery>
```

In the next lesson you will learn `<cfqueryparam>` — the modern, safe way to pass values into SQL that eliminates SQL injection risk entirely.
::

---

## Quick reference

| Statement | Syntax | Purpose |
|---|---|---|
| `SELECT` | `SELECT cols FROM table WHERE ... ORDER BY ...` | Read rows |
| `INSERT` | `INSERT INTO table(cols) VALUES(vals)` | Add a row |
| `UPDATE` | `UPDATE table SET col=val WHERE ...` | Change rows |
| `DELETE` | `DELETE FROM table WHERE ...` | Remove rows |

| Clause | Purpose |
|---|---|
| `WHERE` | Filter rows by condition |
| `ORDER BY` | Sort result rows |
| `GROUP BY` | Group rows for aggregation |
| `HAVING` | Filter after grouping |

---

When you are ready, move on to the next lesson — **SQL with cfquery & queryParam** — where you will write these statements inside ColdFusion using `<cfquery>` and protect them with `<cfqueryparam>`.
