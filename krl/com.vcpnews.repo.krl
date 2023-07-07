ruleset com.vcpnews.repo {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares krl, pico_eci
  }
  global {
    krl = function(rid){
      rid => ent:src{rid} | ent:src.keys()
    }
    pico_eci = function(){
      ent:eci
    }
    event_domain = "introspect_repo"
    tags = ["introspect","repo"]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      ) setting(channel)
    }
    fired {
      raise introspect_repo event "channel_created"
      raise introspect_repo event "source_changed" attributes event:attrs
      ent:eci := channel{"id"}
    }
  }
  rule keepChannelsClean {
    select when introspect_repo channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule storeRulesetSource {
    select when introspect_repo new_source
                rid re#(.+)# setting(rid)
                where event:attr("src").length()
             or introspect_repo source_changed
                rid re#(.+)# setting(rid)
                where event:attr("src").length()
    pre {
      line_break = (chr(13)+"?"+chr(10)).as("RegExp")
      lines = event:attr("src").split(line_break)
      count = lines.length()
        .klog("count")
    }
    fired {
      ent:src{rid} := lines.join(chr(10))
    }
  }
  rule redirectBack {
    select when introspect_repo source_changed
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
