---
kind: unit

title: Security Hardening ColdFusion

name: security-hardening-coldfusion-unit-1
---

## The hardening checklist

::image-box
---
:src: __static__/cf-security-hardening-checklist-v1.png
:alt: Numbered checklist card with five items — 1. Restrict CF Admin (allow 127.0.0.1 only, nginx deny all), 2. Encode all output (encodeForHTML prevents XSS), 3. Use cfqueryparam (prevents SQL injection), 4. Add security headers (CSP, X-Frame-Options, X-Content-Type-Options), 5. Enforce HTTPS (redirect HTTP to HTTPS in nginx) — each item has a checkbox on the left and a short code snippet or command on the right
:max-width: 860px
---
_Five-point ColdFusion hardening checklist — cover all five before going to production._
::

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

::image-box
---
:src: __static__/xss-attack-vs-encoded-output-v1.png
:alt: Side-by-side comparison showing two browser outputs — left panel labelled "UNSAFE: #url.name#" shows the raw browser rendering of <script>alert('XSS')</script> triggering an alert dialog; right panel labelled "SAFE: encodeForHTML(url.name)" shows the same input rendered as escaped HTML entities (&lt;script&gt;alert(&#x27;XSS&#x27;)&lt;/script&gt;) — displayed as harmless text
:max-width: 860px
---
_`encodeForHTML()` converts `<script>` tags to harmless HTML entities — never output raw user input in HTML._
::

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

## Activity 1 — Restrict the CF Admin

In production the CF Admin (`/CFIDE/administrator/`) should never be publicly reachable. In this lab it is intentionally open for learning — the task verifies it returns a non-200 response, which a hardened setup would produce.

Check the current status:

```bash
curl -s -o /dev/null -w "CF Admin status: %{http_code}\n" http://localhost:8500/CFIDE/administrator/index.cfm
```

::hint-box
---
:summary: 💡 How to restrict CF Admin in a real nginx setup
---

In production, add this block to your nginx config to block all external access to CF Admin:

```nginx
location /CFIDE/administrator {
  allow 127.0.0.1;
  deny  all;
}
```

Only requests from localhost (your application server itself) are allowed. Everything else gets a 403.
::

::simple-task
---
:tasks: tasks
:name: verify_admin_restricted
---
#active
Check that `/CFIDE/administrator/index.cfm` returns a non-200 response.

#completed
CF Admin is restricted. ✓
::

---

## Activity 2 — Prevent XSS with encodeForHTML()

Create `/opt/coldfusion2025/cfusion/wwwroot/input_demo.cfm` that safely encodes user input:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/input_demo.cfm << 'EOF'
<cfscript>
  name = structKeyExists(url, "name") ? encodeForHTML(url.name) : "Guest";
  writeOutput("Hello, " & name & "!");
</cfscript>
EOF
```

Test it — the `<script>` tag must come back as HTML entities, not as a live script:

```bash
curl -s "http://localhost:8500/input_demo.cfm?name=<script>alert(1)</script>"
# Expected: Hello, &lt;script&gt;alert(1)&lt;/script&gt;!
```

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

---

## Activity 3 — Use cfqueryparam in every query

Open `tickets.cfm` (created in the SQL lesson) and confirm every parameterised value uses `cfqueryparam`. The task scans the entire web root for at least one usage:

```bash
grep -r "cfqueryparam\|queryParam" /opt/coldfusion2025/cfusion/wwwroot/
```

If `tickets.cfm` does not exist yet, create a minimal version:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/tickets.cfm << 'EOF'
<cfscript>
  result = queryExecute(
    "SELECT id, title, status FROM hd_tickets WHERE id > :minId",
    { minId: { value: 0, cfsqltype: "cf_sql_integer" } },
    { datasource: "training_db" }
  );
  writeOutput(result.recordCount & " ticket(s) found");
</cfscript>
EOF
```

::simple-task
---
:tasks: tasks
:name: verify_queryparam_sql
---
#active
Use `cfqueryparam` or named bindings in at least one query in the web root.

#completed
`cfqueryparam` is used — SQL injection protection in place. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
Hit **Check** to mark this lesson complete and unlock the next one.

#completed
Lesson complete — on to Performance Tuning! 🚀
::

::remark-box
Found a bug or an issue with this lesson? Please reach out — your feedback helps improve the course for everyone.

📧 Alex — mercadoalex[at]gmail.com
::
