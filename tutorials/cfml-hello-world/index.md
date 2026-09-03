---
kind: tutorial

title: Your First CFML Page
description: |
  Write and run your very first CFML page in the lab environment.
  Covers file creation, rendering, and basic cfoutput.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cfml
- beginner

playground:
  name: cf-alex-edcdf975
---

## Steps

1. Open code-server at `http://localhost:50061`
2. Create `/opt/coldfusion2025/cfusion/wwwroot/hello.cfm`
3. Add:

```cfml
<cfset name = "Hungry Minds">
<cfoutput>Hello, #name#! Today is #dateFormat(now(), "long")#.</cfoutput>
```

4. Open `http://localhost:8500/hello.cfm`
5. Verify the date and greeting appear.