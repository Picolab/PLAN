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
    <title>Wovyn sensors</title>
    <meta charset="UTF-8">
<style type="text/css">
body {
  font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
}
</style>
  </head>
  <body>
<h1>Wovyn sensors now</h1>
  </body>
</html>
>>
    }
    tags = ["wovyn-sensors","summary"]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":"com_vcpnews_w","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      ) setting(channel)
    }
    fired {
      raise com_vcpnews_w event "channel_created"
    }
  }
  rule keepChannelsClean {
    select when com_vcpnews_w channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
