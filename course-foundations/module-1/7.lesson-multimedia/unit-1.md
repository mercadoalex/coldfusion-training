---
kind: unit

title: Multimedia Content Integration

name: multimedia-content-integration-unit-1
---

## HTML5 video element

::image-box
---
:src: __static__/cffile-upload-flow-v1.png
:alt: Three-step upload flow diagram — step 1 "Browser" shows a multipart/form-data POST request with a file field highlighted; step 2 "ColdFusion cffile" shows the cffile tag parsing the upload, validating MIME type against the allowed list, and resolving name conflicts; step 3 "Disk" shows the final file written to /uploads/media/ with the serverFile, serverDirectory, and fileSize properties labelled on the output arrow
:max-width: 860px
---
_`cffile action="upload"` handles the entire multipart pipeline — parsing, validation, name-conflict resolution, and disk write._
::

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

---

## File upload with cffile

`cffile action="upload"` handles multipart form submissions:

```cfml
<cfscript>
  if (structKeyExists(form, "mediaFile")) {
    allowedTypes = "video/mp4,video/webm,audio/mpeg,audio/ogg";
    cffile(
      action      = "upload",
      filefield   = "mediaFile",
      destination = expandPath("/uploads/media/"),
      accept      = allowedTypes,
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

Key `cffile` properties after upload:

| Property | Value |
|---|---|
| `cffile.serverFile` | Filename on disk (after conflict resolution) |
| `cffile.serverDirectory` | Destination directory |
| `cffile.fileSize` | Size in bytes |
| `cffile.contentType` | MIME type reported by the browser |

---

## Image manipulation with cfimage

::image-box
---
:src: __static__/cfimage-operations-overview-v1.png
:alt: Grid of six labelled boxes showing cfimage actions — resize (thumbnail icon), rotate (circular arrow with degree label), convert (two file extension labels jpg↔png), addBorder (image with thick border), watermark (semi-transparent text overlaid on a photo), and captcha (distorted text challenge image) — each box has the action name in bold and a one-line description below
:max-width: 860px
---
_`cfimage` actions reference — resize, rotate, convert, addBorder, watermark, and captcha all ship in the core runtime._
::


ColdFusion ships with a built-in image manipulation library:

```cfml
<cfscript>
  cfimage(
    action    = "resize",
    source    = "/uploads/original.jpg",
    dest      = "/uploads/thumb.jpg",
    width     = "200",
    height    = "200",
    overwrite = true
  );
</cfscript>
```

Other `cfimage` actions: `rotate`, `convert`, `addBorder`, `watermark`, `captcha`.

---

## Security considerations

- Always validate file extensions **and** MIME type server-side — never trust the browser.
- Store uploaded files outside the web root if they should not be directly accessible.
- Use `nameconflict="makeunique"` to prevent filename collisions.

---

## Exercises

1. Create `/opt/coldfusion2025/cfusion/wwwroot/media_demo.cfm` with an HTML5 `<video>` or `<audio>` element.
2. Create `/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm` with a `cffile` upload handler.
3. Verify:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/media_demo.cfm
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/upload_media.cfm
```

---

## Hands-on checks

::simple-task
---
:tasks: tasks
:name: verify_media_page
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/media_demo.cfm` — must return HTTP 200.

#completed
`media_demo.cfm` is accessible. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_html5_video
---
#active
Add a `<video>` or `<audio>` HTML5 element to `media_demo.cfm`.

#completed
HTML5 media element is present. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_upload_handler
---
#active
Create `/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm` with a `cffile action="upload"` handler.

#completed
`upload_media.cfm` exists. ✓
::


---

## Challenge

Put your skills to the test — complete the hands-on challenge for this lesson.

::card
---
:challenge: challenges.multimedia-04988437
---
::
