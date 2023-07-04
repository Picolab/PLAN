ruleset io.picolabs.plan.apps {
  meta {
    name "applications"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares main_url, apps
  }
  global {
    channel_tags = ["applications"]
    event_domain = "io_picolabs_plan_apps"
    event_url = function(event_type,event_id){
      eid = event_id || "none"
      <<#{meta:host}/sky/event/#{meta:eci}/#{eid}/#{event_domain}/#{event_type}>>
    }
    query_url = function(query_name){
      <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/#{query_name}>>
    }
    main_url = function(){
      query_url("apps.html")
    }
    apps = function(_headers){
      html:header("manage applications","",null,null,_headers)
      + <<
<h1>Manage applications</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        channel_tags,
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise io_picolabs_plan_apps event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when io_picolabs_plan_apps factory_reset
    foreach wrangler:channels(channel_tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
