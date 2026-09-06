---
kind: unit

title: Lucee Server — Configuration & Administration

name: lucee-server-configuration-unit-1
---

## Lucee vs Adobe ColdFusion 2025

Both engines execute the same CFML language core but differ in licensing, configuration format, and some built-in capabilities.

| Feature | Lucee 7 | Adobe CF 2025 |
|---|---|---|
| License | Open source (LGPL) | Commercial |
| Admin URL | `/lucee/admin/` | `/CFIDE/administrator/` |
| Config format | JSON / `.CFConfig.json` | XML (`neo-*.xml`) |
| Cold start speed | Fast (~5–10 s) | Moderate (~30 s) |
| PDF generation | Via extension | Native (`<cfdocument>`) |

In this lab: Adobe CF 2025 runs on port **8500**, Lucee 7 runs on port **8888**.

---

## Lucee admin console

Browse to `http://localhost:8888/lucee/admin/` to access the Lucee admin panel. Default password: `training`.

Key sections:
- **Services → Datasource** — add/edit datasources
- **Services → Mail** — configure SMTP
- **Settings → Performance** — template cache size
- **Extensions** — install PDF, S3, and other extensions

---

## lucee_info.cfm — check versions

Create this file at `/home/laborant/app/lucee_info.cfm`:

```cfml
<cfscript>
  writeOutput("Lucee version: " & server.lucee.version & "<br>");
  writeOutput("Java version: " & server.java.version & "<br>");
</cfscript>
```

Access via the Lucee tab: `http://localhost:8888/lucee_info.cfm`

---

## CFConfig — JSON-based configuration

CommandBox ships with the `cfconfig` module for managing Lucee settings as JSON. This enables reproducible, version-controlled server configuration.

```json
{
  "datasources": {
    "training_db": {
      "type": "H2",
      "database": "/opt/lucee/db/training",
      "username": "sa",
      "password": ""
    }
  }
}
```

Apply a config:

```bash
box cfconfig import from=.CFConfig.json to=default@lucee5
```

---

## Key differences to watch for

| Behaviour | Lucee | Adobe CF |
|---|---|---|
| Null support | `isNull()` works natively | Requires `fullnullsupport` setting |
| Array/struct literals | Same syntax | Same syntax |
| `systemOutput()` | Available | Not available (use `<cflog>`) |
| `fileSystemUtil` | Built-in | Different API |
| Default var scope | Strict (must declare) | More permissive |

---

## Exercises

1. Verify Lucee is running:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/index.cfm
```

2. Create `/home/laborant/app/lucee_info.cfm` and verify it outputs the Lucee version string:

```bash
curl -s http://localhost:8888/lucee_info.cfm
```

3. Verify the `training_db` datasource works from Lucee:

```bash
curl -s http://localhost:8888/verify_ds.cfm
```
