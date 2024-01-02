ruleset com.vcpnews.w {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.wovyn-sensors alias ws
    shares now
  }
  global {
    now = function(_headers){
      <<<!DOCTYPE HTML>
<html>
  <head>
    <title>Wovyn sensors now</title>
    <meta charset="UTF-8">
<style type="text/css">
body { font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; }
th { text-align: left; }
th:first-child { min-width: 100px; }
th:nth-child(2) { min-width: 80px; }
</style>
  </head>
  <body>
<h1>Wovyn sensors now</h1>
<h2>#{time:now().split("T").head()}</h2>
#{ws:summary()}  </body>
</html>
>>
    }
    tags = ["wovyn-sensors","summary"]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    if wrangler:channels(tags).length() == 0 then
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":"com_vcpnews_w","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      ) setting(channel)
  }
}
