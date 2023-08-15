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
      ent:indexes := {} if ent:indexes.isnull()
      raise io_picolabs_plan_indexes event "channel_created"
        attributes {"tags":channel_tags}
    }
  }
  rule keepChannelsClean {
    select when io_picolabs_plan_indexes channel_created
    foreach wrangler:channels(event:attr("tags")).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule addAnIndex {
    select when io_picolabs_plan_indexes updated_index
      index_name re#(.+)#
      index_eci re#(.+)#
      setting(index_name,index_eci)
    pre {
      spec = {"name":index_name,"eci":index_eci}
    }
    fired {
      ent:indexes{index_name} := spec
      raise io_picolabs_plan_indexes event "index_updated" attributes spec
    }
  }
}
