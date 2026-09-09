---
kind: tutorial

title: File Upload and Image Resize with cffile and cfimage

description: |
  Build a file upload form that accepts images, saves them to disk,
  and generates a thumbnail using cfimage.

createdAt: 2026-09-03
updatedAt: 2026-09-03

categories:
- programming

tagz:
- coldfusion
- cffile
- cfimage
- multimedia

playground:
  name: cf-alex-edcdf975
---

## Steps

### 1. Create the upload directory

```bash
mkdir -p /opt/coldfusion2025/cfusion/wwwroot/uploads/media
chmod 755 /opt/coldfusion2025/cfusion/wwwroot/uploads/media
```

### 2. Create media_demo.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/media_demo.cfm`:

```cfml
<!DOCTYPE html>
<html>
<body>
  <h1>Upload Media</h1>
  <form method="post" action="upload_media.cfm" enctype="multipart/form-data">
    <input type="file" name="mediaFile" accept="image/*,video/*,audio/*">
    <button type="submit">Upload</button>
  </form>

  <h2>Sample Video Embed</h2>
  <video controls width="480" preload="metadata">
    <source src="/media/sample.mp4" type="video/mp4">
    Your browser does not support HTML5 video.
  </video>
</body>
</html>
```

### 3. Create upload_media.cfm

Create `/opt/coldfusion2025/cfusion/wwwroot/upload_media.cfm`:

```cfml
<cfscript>
  if (structKeyExists(form, "mediaFile")) {
    cffile(
      action      = "upload",
      filefield   = "mediaFile",
      destination = expandPath("/uploads/media/"),
      accept      = "image/jpeg,image/png,image/gif,video/mp4,audio/mpeg",
      nameconflict = "makeunique"
    );
    writeOutput("Uploaded: " & cffile.serverFile & " (" & cffile.fileSize & " bytes)");

    // Generate thumbnail for images
    if (findNoCase("image/", cffile.contentType)) {
      cfimage(
        action    = "resize",
        source    = cffile.serverDirectory & "/" & cffile.serverFile,
        dest      = expandPath("/uploads/media/thumb_" & cffile.serverFile),
        width     = "200",
        height    = "200",
        overwrite = true
      );
      writeOutput("<br>Thumbnail created.");
    }
  } else {
    writeOutput("No file submitted.");
  }
</cfscript>
```

### 4. Verify

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/media_demo.cfm
curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/upload_media.cfm
```

Both should return **200**.
