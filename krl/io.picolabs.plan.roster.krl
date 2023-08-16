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
          s.put("Tx_name",ent:names.get(Id))
        })
        .sort(by("Tx_name"))
<<<h1>Alphabetic List</h1>
<pre>#{entries.encode()}</pre>
<dl>
#{entries.map(function(s){
  <<<dt>#{s.get("Tx_name")}</dt><dd>#{s.get("Tx")}</dd>
>>
}).join("")}</dl>
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
  rule memoizeName {
    select when io_picolabs_plan_roster name_provided
      Id re#(.+)#
      name re#(.+)#
      setting(Id,name)
    fired {
      ent:names{Id} := name
    }
  }
}
