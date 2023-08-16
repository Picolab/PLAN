ruleset io.picolabs.plan.roster {
  meta {
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    shares roster
  }
  global {
    wrangler_rid = "io.picolabs.wrangler"
    roster = function(){
      entries = subs:established("Rx_role","affiliate list")
        .map(function(s){
          eci = s.get("Tx")
          name = wrangler:picoQuery(eci,wrangler_rid,"name")
          s.put("Tx_name",name)
        })
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
}
