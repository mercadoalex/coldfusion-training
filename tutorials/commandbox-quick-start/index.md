---
kind: tutorial

title: CommandBox Quick Start
description: |
  Install a Lucee app with CommandBox in under 5 minutes.
  Start the server, install a package, and browse the app.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- commandbox
- lucee
- coldfusion

playground:
  name: cf-alex-edcdf975
---

## Steps

```bash
# 1 — create project dir
mkdir /home/laborant/myapp && cd /home/laborant/myapp

# 2 — create index.cfm
echo '<cfoutput>Hello from CommandBox + Lucee! #now()#</cfoutput>' > index.cfm

# 3 — start Lucee server
box server start cfengine=lucee@7.0.4.34 port=8888 openbrowser=false

# 4 — test it
curl http://localhost:8888/

# 5 — stop server
box server stop
```