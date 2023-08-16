ruleset io.picolabs.plan.roster {
  meta {
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    shares roster
  }
  global {
    roster = function(){
      entries = subs:established("Rx_role","affiliate list")
<<<h1>Alphabetic List</h1>
<pre>#{entries.encode()}</pre>
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
