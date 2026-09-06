---
kind: unit

title: Security Hardening ColdFusion

name: security-hardening-coldfusion-unit-1
---

## The hardening checklist

1. **Restrict CF Admin** — allow only localhost or VPN IP
2. **Encode all output** — prevent XSS with `encodeForHTML()`
3. **Use cfqueryparam** — prevent SQL injection
4. **Add security headers** — CSP, X-Frame-Options, X-Content-Type-Options
5. **Enforce HTTPS** — redirect HTTP to HTTPS in nginx/Apache

---

## 1. Restrict CF Admin (nginx)

The CF Admin console (`/CFIDE/administrator/`) should never be publicly reachable in production.

```nginx
location /CFIDE/administrator {
  allow 127.0.0.1;
  deny  all;
}
```

In the lab, the admin is intentionally accessible for learning purposes. The task checks that it returns a non-200 response — which it does in a hardened setup.

---

## 2. Prevent XSS — encode all output

Never render user-supplied input directly into HTML. Use `encodeForHTML()`:

```cfml
<cfoutput>#encodeForHTML(url.name)#</cfoutput>
```

Other encoding functions:

| Function | Use case |
|---|---|
| `encodeForHTML()` | HTML body content |
| `encodeForHTMLAttribute()` | HTML attribute values |
| `encodeForJavaScript()` | Inside `<script>` blocks |
| `encodeForURL()` | URL query string parameters |

---

## 3. Prevent SQL injection — cfqueryparam

Never interpolate user input directly into SQL:

```cfml
<!--- DANGEROUS — do not do this --->
WHERE id = #url.id#

<!--- SAFE --->
WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
```

The task checks that `cfqueryparam` is used somewhere in the web root. Make sure every parameterised query uses it.

---

## 4. Security headers

Add security headers in `Application.cfc` `onRequestStart` or in a front controller:

```cfml
<cfheader name="Content-Security-Policy"   value="default-src 'self'">
<cfheader name="X-Frame-Options"           value="DENY">
<cfheader name="X-Content-Type-Options"    value="nosniff">
<cfheader name="Referrer-Policy"           value="no-referrer">
<cfheader name="Permissions-Policy"        value="geolocation=(), microphone=()">
```

Verify headers are sent:

```bash
curl -s -I http://localhost:8500/index.cfm | grep -i "x-frame\|content-security\|x-content-type"
```

---

## 5. Input validation pattern

Create `input_demo.cfm` that demonstrates safe input handling:

```cfml
<cfscript>
  name = structKeyExists(url, "name") ? encodeForHTML(url.name) : "Guest";
  writeOutput("Hello, " & name & "!");
</cfscript>
```

Test for XSS:

```bash
curl -s "http://localhost:8500/input_demo.cfm?name=<script>alert(1)</script>"
# Should output the encoded entity — not the raw script tag
```

---

## Exercises

1. Create `input_demo.cfm` that takes `url.name` and outputs it with `encodeForHTML()`.
2. Confirm `cfqueryparam` is used in the existing `tickets.cfm` (from the SQL lesson).
3. Add the security headers to `Application.cfc`.
4. Verify the admin is inaccessible from outside (the task uses `curl` to check the HTTP status).

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_admin_restricted
---
#active
The CF Admin at `/CFIDE/administrator/index.cfm` must return a non-200 response.

#completed
CF Admin is restricted. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_no_xss
---
#active
Create `input_demo.cfm` — passing `?name=<script>alert(1)</script>` must NOT output the raw script tag.

#completed
Input is properly HTML-encoded — no XSS. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_queryparam_sql
---
#active
Use `cfqueryparam` at least once somewhere in the web root.

#completed
`cfqueryparam` is used — SQL injection protection in place. ✓
::
