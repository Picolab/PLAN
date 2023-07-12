ruleset io.picolabs.plan.CloudMailin {
  meta {
    use module io.picolabs.wrangler alias wrangler
  }
  rule routeEmailRecieved {
    select when email received
    pre {
      from = event:attrs{["envelope","from"]}
      matchesAffiliate = function(c){c.get("name")==from}
      eci = wrangler:children().filter(matchesAffiliate).head().get("eci")
    }
    if eci then
      event:send({"eci":eci,"domain":"email","type":"received",
        "attrs":event:attrs})
  }
}
