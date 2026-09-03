---
kind: challenge

title: Student REST API
description: |
  Build a REST endpoint /api/students.cfm that returns a JSON array
  of all students from the training_db. The endpoint must return HTTP 200,
  Content-Type application/json, and a non-empty JSON array.


createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- rest
- api
- sql

playground:
  name: cf-alex-edcdf975
---

## Task

Create `/opt/coldfusion2025/cfusion/wwwroot/api/students.cfm` that:
- Queries `SELECT * FROM students` from `training_db`
- Returns a JSON array
- Sets `Content-Type: application/json`

## Verify

```bash
curl -s http://localhost:8500/api/students.cfm | python3 -m json.tool
```