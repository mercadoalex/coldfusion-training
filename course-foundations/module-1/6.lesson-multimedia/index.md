---
kind: lesson

title: Multimedia Content Integration
description: |
  Embed and manage video, audio and other multimedia in ColdFusion applications.
  Use HTML5 media elements, manage uploads, and handle compatibility
  and performance considerations.

name: multimedia-content-integration
slug: multimedia-content-integration

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- html5
- multimedia
- video

playground:
  name: cf-alex-edcdf975

tasks:
  verify_media_page:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/media_demo.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "media_demo.cfm not found (got ${STATUS})"
        exit 1
      fi
      echo "media_demo.cfm is accessible"

  verify_html5_video:
    machine: dev-machine
    user: laborant
    needs:
      - verify_media_page
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/media_demo.cfm"
      if ! grep -qi "<video\|<audio" "${FILE}" 2>/dev/null; then
        echo "No HTML5 video or audio element found in media_demo.cfm"
        exit 1
      fi
      echo "HTML5 media element is present"

  verify_upload_handler:
    machine: dev-machine
    user: laborant
    needs:
      - verify_html5_video
    run: |
      FILE="/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm"
      if [ ! -f "${FILE}" ]; then
        echo "upload_media.cfm not found"
        exit 1
      fi
      echo "Upload handler exists"
---

## HTML5 video element

Store media metadata in a database table and serve files from a known path.
This example uses the Help Desk `hd_tickets` table to demonstrate query + HTML5 output together.

```cfml
<cfquery name="tickets" datasource="training_db">
  SELECT id, title, description FROM hd_tickets
  WHERE  status = 'open'
  ORDER  BY created_at DESC
</cfquery>

<cfoutput query="tickets">
  <article>
    <h2>#encodeForHTML(title)#</h2>
    <p>#encodeForHTML(description)#</p>
    <!--- Placeholder: replace with real video src when media files are present --->
    <video controls width="640" preload="metadata">
      <source src="/media/ticket_#id#.mp4" type="video/mp4">
      Your browser does not support HTML5 video.
    </video>
  </article>
</cfoutput>
```

## File upload with cffile

```cfml
<cfscript>
  if (structKeyExists(form, "mediaFile")) {
    allowedTypes = "video/mp4,video/webm,audio/mpeg,audio/ogg";
    cffile(
      action    = "upload",
      filefield = "mediaFile",
      destination = expandPath("/uploads/media/"),
      accept    = allowedTypes,
      nameconflict = "makeunique"
    );
    writeOutput("Uploaded: " & cffile.serverFile);
  }
</cfscript>

<form method="post" enctype="multipart/form-data">
  <input type="file" name="mediaFile" accept="video/*,audio/*">
  <button type="submit">Upload</button>
</form>
```

## Image manipulation with cfimage

```cfml
<cfscript>
  cfimage(
    action  = "resize",
    source  = "/uploads/original.jpg",
    dest    = "/uploads/thumb.jpg",
    width   = "200",
    height  = "200",
    overwrite = true
  );
</cfscript>
```
