ruleset io.picolabs.plan.roster {
  meta {
    use module io.picolabs.subscription alias subs
    shares roster
  }
  global {
    by = function(key){
      function(a,b){a{key}.encode() cmp b{key}.encode()}
    }
    roster = function(){
      entries = subs:established("Rx_role","affiliate list")
        .map(function(s){
          Id = s.get("Id")
          s.put("Tx_name", ent:data.get([Id,"name"]))
        })
        .sort(by("Tx_name"))
<<<h1>Alphabetic List</h1>
<table>
<tr>
<th>Name</th>
<th>Phone</th>
<th>Email</th>
<th>wellKnown_Rx</th>
</tr>
#{entries.map(function(s){
  Id = s.get("Id")
  <<<tr>
<td>#{s.get("Tx_name")}</td>
<td>#{ent:data.get([Id,"phone"]) || ""}</td>
<td>#{ent:data.get([Id,"email"]) || ""}</td>
<td><button>#{ent:data.get([Id,"wellKnown_Rx"])}</button></td>
</tr>
>>
}).join("")}</table>
>>
    }
  }
  rule acceptAffiliate {
    select when wrangler inbound_pending_subscription_added
    pre {
      new_affiliate = event:attrs{"Rx_role"} == "affiliate list"
                    && event:attrs{"Tx_role"} == "affiliate"
    }
    if new_affiliate then noop()
    fired {
      raise wrangler event "pending_subscription_approval" attributes event:attrs
    }
  }
  rule memoizeData {
    select when io_picolabs_plan_roster data_provided
      Id re#(.+)#
      setting(Id)
    fired {
      ent:data{Id} := event:attrs.get("data")
    }
  }
  rule forgetFormerAffiliate {
    select when wrangler subscription_removed
    fired {
      ent:data{event:attrs.get("Id")} := null
    }
  }
}
