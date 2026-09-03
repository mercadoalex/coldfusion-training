<!--- api-test.cfm — demonstrates basic CFML data types and output --->
<cfscript>
  // Build a simple struct to serialize as JSON
  result = {
    "status"    : "ok",
    "engine"    : server.coldfusion.productName,
    "version"   : server.coldfusion.productVersion,
    "timestamp" : dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss"),
    "message"   : "ColdFusion CFML is running!"
  };
</cfscript>

<cfheader name="Content-Type" value="application/json">
<cfoutput>#serializeJSON(result)#</cfoutput>
