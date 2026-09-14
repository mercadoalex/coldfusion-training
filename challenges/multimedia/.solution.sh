he complete #!/usr/bin/env bash
# .solution.sh — reference solution for the Unit 1 Challenge
# Builds the complete unit1challenge application in the CF wwwroot.
# Run as laborant on the dev-machine.

set -euo pipefail

CHALLENGE_DIR="/opt/coldfusion2025/cfusion/wwwroot/unit1challenge"
sudo mkdir -p "${CHALLENGE_DIR}"

# ── Application.cfc ──────────────────────────────────────────────────────────
sudo tee "${CHALLENGE_DIR}/Application.cfc" << 'EOF'
component {
  this.name            = "Unit1Challenge";
  this.sessionManagement = true;
  this.sessionTimeout  = createTimeSpan(0, 0, 30, 0);

  public void function onApplicationStart() {
    application.launchTime = now();
  }

  public void function onSessionStart() {
    session.visitCount = 0;
  }
}
EOF

# ── PortfolioService.cfc ─────────────────────────────────────────────────────
sudo tee "${CHALLENGE_DIR}/PortfolioService.cfc" << 'EOF'
component {

  public PortfolioService function init(required string authorName) {
    variables.authorName = arguments.authorName;
    return this;
  }

  public array function getProjects() {
    return [
      { title: "Help Desk App",      description: "Ticket management system in CFML", type: "web" },
      { title: "REST API",           description: "JSON REST API with cfhttp",         type: "api" },
      { title: "ORM Entity Demo",    description: "Hibernate ORM with Ticket.cfc",     type: "data" }
    ];
  }

  public string function getSummary() {
    var sb = createObject("java", "java.lang.StringBuilder").init("");
    sb.append("Portfolio by ");
    sb.append(variables.authorName);
    sb.append(" — ");
    sb.append(arrayLen(getProjects()));
    sb.append(" projects");
    return sb.toString();
  }

}
EOF

# ── index.cfm ────────────────────────────────────────────────────────────────
sudo tee "${CHALLENGE_DIR}/index.cfm" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Unit 1 Challenge — Portfolio</title>
  <style>
    body  { font-family: sans-serif; max-width: 760px; margin: 2rem auto; background: #f8fafc; }
    h1    { color: #1d4ed8; }
    .card { background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 1rem 1.25rem; margin: .75rem 0; }
    .meta { color: #64748b; font-size: .85rem; margin-bottom: 1.5rem; }
  </style>
</head>
<body>
<cfscript>
  session.visitCount = (structKeyExists(session, "visitCount") ? session.visitCount : 0) + 1;
  svc      = new PortfolioService("Alejandro Mercado");
  projects = svc.getProjects();
  summary  = svc.getSummary();
</cfscript>

<h1>ColdFusion Portfolio</h1>
<p class="meta">
  <cfoutput>
    Summary: #encodeForHTML(summary)# &nbsp;·&nbsp;
    Launched: #dateTimeFormat(application.launchTime, "dd-mmm-yyyy HH:nn")# &nbsp;·&nbsp;
    Visits this session: #session.visitCount#
  </cfoutput>
</p>

<cfoutput>
  <cfloop array="#projects#" index="p">
    <div class="card">
      <strong>#encodeForHTML(p.title)#</strong> — #encodeForHTML(p.description)#
      <span style="color:#64748b;font-size:.8rem">[#encodeForHTML(p.type)#]</span>
    </div>
  </cfloop>
</cfoutput>

<script>
  var projects = <cfoutput>#serializeJSON(projects)#</cfoutput>;
  console.log("Projects loaded:", projects);
</script>

<audio controls style="margin-top:1.5rem">
  <source src="https://www.w3schools.com/html/horse.mp3" type="audio/mpeg">
  Your browser does not support the audio element.
</audio>

</body>
</html>
EOF

echo ""
echo "Solution deployed. Verify with:"
echo "  curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:8500/unit1challenge/index.cfm"
