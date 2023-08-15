ruleset io.picolabs.plan.indexes {
  meta {
    description <<
      Maintains a list of indexes of affiliate picos.
    >>
    use module io.picolabs.wrangler alias wrangler
    shares indexes
  }
  global {
    indexes = function(){
      ent:indexes
    }
  }
  rule createChannel {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    pre {
      channel_tags = ["plan","indexes"]
    }
    wrangler:createChannel(
      channel_tags,
      {"allow":[{"domain":"io_picolabs_plan_indexes","name":"*"}],"deny":[]},
      {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
    )
    fired {
      raise io_picolabs_plan_indexes event "channel_created"
        attributes {"tags":channel_tags}
    }
  }
  rule keepChannelsClean {
    select when io_picolabs_plan_indexes channel_created
    foreach wrangler:channels(event:attr("tags")).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
