---
kind: unit

title: Security Hardening ColdFusion

name: security-hardening-coldfusion-unit-1
---

## What is hardening — and why does it matter?

**Hardening** is the process of reducing the attack surface of a system by removing unnecessary exposure, enforcing safe defaults, and adding defensive controls. A default ColdFusion installation is configured for convenience — it is not configured for production security.

The gap between "it works" and "it is secure" is where most breaches happen.

**What companies are facing right now:**

- **Exposed admin consoles** — ColdFusion's `/CFIDE/administrator/` is reachable from the internet on thousands of servers. Automated scanners find it in minutes. In 2023, Adobe issued emergency patches for two critical ColdFusion vulnerabilities (CVE-2023-29298 and CVE-2023-38203) that were actively exploited in the wild — attackers specifically targeted exposed CF admin endpoints to achieve remote code execution.

- **SQL injection** — still the #1 web application vulnerability after 20+ years (OWASP Top 10, every year). A single unparameterised query is enough to dump an entire database. ColdFusion's `cfqueryparam` has been available since CF5 — yet production systems are still found without it.

- **Cross-site scripting (XSS)** — rendering unsanitised user input in HTML allows attackers to inject JavaScript that runs in other users' browsers — stealing sessions, redirecting to phishing pages, or silently exfiltrating data. ColdFusion outputs raw variables by default — encoding must be explicit.

- **Missing security headers** — browsers have built-in protections (CSP, X-Frame-Options, HSTS) that applications must opt into. Without them, clickjacking, MIME-type confusion attacks, and protocol downgrades are trivially exploitable.

- **Plain HTTP in production** — unencrypted traffic exposes session tokens, form data, and credentials to anyone on the same network. HTTPS is not optional in 2025.

**Hardening does not require a security specialist.** The five controls in this lesson are well-understood, well-documented, and take less than an hour to implement. They eliminate the vast majority of common attack vectors against a ColdFusion application.

**The industry standard reference — OWASP:**

The [Open Worldwide Application Security Project (OWASP)](https://owasp.org) is a non-profit foundation that publishes free, vendor-neutral security guidance used by developers, security teams, and auditors worldwide. Two resources are directly relevant to this lesson:

- **[OWASP Top 10](https://owasp.org/www-project-top-ten/)** — the ten most critical web application security risks, updated every few years based on real breach data. SQL injection, XSS, and security misconfiguration (exposed admin consoles, missing headers) appear in every edition. When a company says "we follow OWASP", this is what they mean.

- **[OWASP Application Security Verification Standard (ASVS)](https://owasp.org/www-project-application-security-verification-standard/)** — a detailed checklist of security controls organised by level (L1 basic → L3 advanced). Used as a benchmark in security audits and penetration tests.

Everything in this lesson maps directly to OWASP Top 10 categories — you are not learning theory, you are implementing the controls that security auditors check for.

::image-box
---
:src: __static__/owasp-top10-reference-v1.png
:alt: OWASP Top 10 2021 reference card — ten numbered rows, three highlighted in amber: A03 Injection (SQL injection and XSS), A05 Security Misconfiguration (exposed admin, missing headers). Other seven rows in grey. Caption: "This lesson covers A03 and A05 — the most common vulnerabilities found in ColdFusion applications."
:max-width: 700px
---
_The OWASP Top 10 — items highlighted in amber are covered in this lesson._
::

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

The CF Admin console (`/CFIDE/administrator/`) should never be publicly reachable in production. In a hardened setup a reverse proxy (nginx or Apache) sits in front of ColdFusion and blocks all external access to the admin path:

```nginx
location /CFIDE/administrator {
  allow 127.0.0.1;
  deny  all;
}
```

Only the server itself can reach the admin — everything else gets a `403 Forbidden`.

**In this lab the admin is intentionally open** so you can explore it. The activity below asks you to check what it currently returns and understand what a hardened response would look like.

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

ColdFusion does **not** encode output automatically — you must do it explicitly every time you output user-controlled data into HTML.

Other encoding functions for different contexts:

| Function | Use when outputting into... |
|---|---|
| `encodeForHTML()` | HTML body content |
| `encodeForHTMLAttribute()` | HTML tag attribute values |
| `encodeForJavaScript()` | Inside `<script>` blocks |
| `encodeForURL()` | URL query string parameters |

Using the wrong encoder for the context is as dangerous as not encoding at all — `encodeForHTML()` inside a `<script>` block does not protect against JavaScript injection.

---

## 3. Prevent SQL injection — cfqueryparam

Never interpolate user input directly into SQL:

```cfml
<!--- DANGEROUS — do not do this --->
WHERE id = #url.id#

<!--- SAFE --->
WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
```

`cfqueryparam` sends the value as a **bind parameter** — the database driver keeps the value and the SQL structure completely separate. Even if an attacker passes `1 OR 1=1` as the value, it is treated as a literal string, not as SQL syntax.

---

## 4. Security headers

Add these headers in `Application.cfc` `onRequestStart` — they tell browsers to enable built-in protections:

```cfml
<cfheader name="Content-Security-Policy"   value="default-src 'self'">
<cfheader name="X-Frame-Options"           value="DENY">
<cfheader name="X-Content-Type-Options"    value="nosniff">
<cfheader name="Referrer-Policy"           value="no-referrer">
<cfheader name="Permissions-Policy"        value="geolocation=(), microphone=()">
```

| Header | What it prevents |
|---|---|
| `Content-Security-Policy` | Limits where scripts, styles, and resources can be loaded from |
| `X-Frame-Options: DENY` | Prevents your page being embedded in an iframe (clickjacking) |
| `X-Content-Type-Options: nosniff` | Stops browsers guessing the content type (MIME confusion attacks) |
| `Referrer-Policy: no-referrer` | Prevents leaking your URL to third-party sites |

Run this now — you will get **empty output** because the default CF installation sends no security headers:

```bash
curl -s -I http://localhost:8500/index.cfm | grep -i "x-frame\|content-security\|x-content-type"
```

That empty response means browsers visiting your application have none of their built-in protections enabled. Activity 4 below fixes this.

---

## Activity 1 — Audit the CF Admin endpoint

Check what the CF Admin returns in this lab environment:

```bash
curl -s -o /dev/null -w "CF Admin status: %{http_code}\n" http://localhost:8500/CFIDE/administrator/index.cfm
```

You will see **HTTP 200** — the admin is open. In a production hardened server this endpoint should return **403** (blocked by nginx) or be unreachable entirely.

```bash
# Also check what headers it returns
curl -s -I http://localhost:8500/CFIDE/administrator/index.cfm | head -10
```

::hint-box
---
:summary: 💡 What should a hardened response look like?
---

In production with nginx in front of ColdFusion, the same request should return:

```
HTTP/1.1 403 Forbidden
```

Because nginx intercepts the request before it ever reaches ColdFusion:

```nginx
location /CFIDE/administrator {
  allow 127.0.0.1;   # only the server itself
  deny  all;         # everyone else gets 403
}
```

The CF process never even sees the request — nginx rejects it at the network layer. This is the correct approach: defence at the proxy layer, not inside the application.
::

::simple-task
---
:tasks: tasks
:name: verify_admin_restricted
---
#active
Run `curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/CFIDE/administrator/index.cfm` and check the response code.

#completed
CF Admin endpoint audited. ✓ In production this must return 403 — never 200.
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

## Activity 4 — Add security headers to Application.cfc

First confirm the headers are missing right now:

```bash
curl -s -I http://localhost:8500/index.cfm | grep -i "x-frame\|content-security\|x-content-type"
# Expected: empty output — no headers yet
```

Add the security headers to your existing `Application.cfc`. If you already have an `onRequestStart` method, add the `cfheader` calls inside it. If not, add the whole method:

```bash
# Check if Application.cfc already exists
ls /opt/coldfusion2025/cfusion/wwwroot/Application.cfc
```

**If it exists** — open it and add inside `onRequestStart`:

```cfml
cfheader(name="Content-Security-Policy",  value="default-src 'self'");
cfheader(name="X-Frame-Options",          value="DENY");
cfheader(name="X-Content-Type-Options",   value="nosniff");
cfheader(name="Referrer-Policy",          value="no-referrer");
```

**If it does not exist** — create a minimal one:

```bash
sudo tee /opt/coldfusion2025/cfusion/wwwroot/Application.cfc << 'EOF'
<cfcomponent>
  <cfset this.name = "training_app">
  <cfset this.datasource = "training_db">

  <cffunction name="onRequestStart">
    <cfheader name="Content-Security-Policy"  value="default-src 'self'">
    <cfheader name="X-Frame-Options"          value="DENY">
    <cfheader name="X-Content-Type-Options"   value="nosniff">
    <cfheader name="Referrer-Policy"          value="no-referrer">
  </cffunction>
</cfcomponent>
EOF
```

Now verify the headers appear:

```bash
curl -s -I http://localhost:8500/index.cfm | grep -i "x-frame\|content-security\|x-content-type"
```

You should now see all three headers in the response.

::simple-task
---
:tasks: tasks
:name: verify_security_headers
---
#active
Add security headers to `Application.cfc` — `X-Frame-Options`, `Content-Security-Policy`, and `X-Content-Type-Options` must appear in the response headers.

#completed
Security headers are present. ✓
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
