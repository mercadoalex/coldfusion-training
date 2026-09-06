---
kind: tutorial

title: XSS Prevention and Security Headers

description: |
  Build an input demo page that safely encodes URL parameters,
  add HTTP security headers, and verify no XSS payload gets through.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming
- security

tagz:
- coldfusion
- security
- xss

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Create input_demo.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/input_demo.cfm`:

```cfml
<cfscript>
  // Safe — always encode user-supplied values
  name = structKeyExists(url, "name") ? encodeForHTML(url.name) : "Guest";
</cfscript>
<!DOCTYPE html>
<html>
<head>
  <cfheader name="Content-Security-Policy"   value="default-src 'self'">
  <cfheader name="X-Frame-Options"           value="DENY">
  <cfheader name="X-Content-Type-Options"    value="nosniff">
</head>
<body>
  <cfoutput><p>Hello, #name#!</p></cfoutput>
</body>
</html>
```

### 2. Test normal input

```bash
curl -s "http://localhost:8500/input_demo.cfm?name=Alex"
```

### 3. Test XSS attack — must be encoded, not executed

```bash
curl -s "http://localhost:8500/input_demo.cfm?name=<script>alert(1)</script>"
```

The response must contain `&lt;script&gt;` — **not** the raw tag.

### 4. Verify security headers are sent

```bash
curl -s -I http://localhost:8500/input_demo.cfm | grep -i "x-frame\|content-security\|x-content-type"
```

### 5. Verify cfqueryparam coverage

```bash
grep -r "cfqueryparam\|queryParam" /opt/coldfusion2025/cfusion/wwwroot/ | wc -l
```

Should be > 0 — the lesson task checks this.
