ruleset io.picolabs.plan.roster {
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
