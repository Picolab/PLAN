ruleset io.picolabs.plan.affiliates {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.mailjet.sdk alias email
    shares lastResponse
  }
  global {
    lastResponse = function(){
      ent:lastResponse
    }
  }
  rule validateEmailSubmission {
    select when io_picolabs_plan_affiliates email_address_submitted
      email_address re#^([\w\d.%+-]+@[\w\d.-]+\.[a-zA-Z]+)#
      setting(email_address)
    pre {
      referrer = event:attr{["_headers","referer"]} //sic
.klog("referrer")
      expected = referrer.match(re#^https://plan.picolabs.io#i)
.klog("expected")
    }
  }
  rule returningAffiliate {
    select when io_picolabs_plan_affiliates email_address_submitted
      email_address re#^([\w\d.%+-]+@[\w\d.-]+\.[a-zA-Z]+)#
      setting(email_address)
    pre {
      matches = function(c){c{"name"}==email_address}
      child = wrangler:children().filter(matches).head()
      child_eci = child.get("eci")
      appsRID = "io.picolabs.plan.apps"
      childRIDs = child_eci => wrangler:picoQuery(
        child_eci,"io.picolabs.wrangler","installedRIDs") | []
      hasRID = childRIDs >< appsRID
      url = hasRID => wrangler:picoQuery(
        child_eci,appsRID,"app_anchor",{"rid":appsRID}) | null
      is_here = "Your pico is here: " + url
    }
    if child && url then
      email:send_text(email_address,"your pico",is_here) setting(res)
    fired {
      ent:lastResponse := res
    } 
  }
}
